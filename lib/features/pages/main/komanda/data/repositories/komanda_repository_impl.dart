import 'dart:convert';

import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_session.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../../domain/entities/waiter_call.dart';
import '../../domain/entities/komanda_category.dart';
import '../../domain/entities/komanda_table.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_option_catalog.dart';
import '../../domain/repositories/komanda_repository.dart';
import '../datasources/komanda_remote_datasource.dart';

/// Repositorio 100% remoto.
///
/// No guarda productos, pedidos, meseros, llamados ni configuración en Hive.
/// Cada operación termina únicamente cuando el backend confirma el guardado.
class KomandaRepositoryImpl implements KomandaRepository {
  final KomandaRemoteDataSource remoteDataSource;
  final KomandaSession session;

  final Set<String> _remoteProductIds = <String>{};
  final Set<String> _remoteOrderIds = <String>{};
  final Set<String> _remoteWaiterIds = <String>{};
  final Set<String> _remoteCallIds = <String>{};

  // Relación entre el ID operativo de waiters y el ID real de users.
  // Ejemplo: waiters.id=3 -> users.id=15.
  final Map<String, String> _waiterUserIdByOperationalId = <String, String>{};
  final Map<String, String> _waiterOperationalIdByUserId = <String, String>{};

  KomandaRepositoryImpl({
    required this.remoteDataSource,
    required this.session,
  }) {
    remoteDataSource.setToken(session.token);
  }

  @override
  Future<void> init() async {
    remoteDataSource.setToken(session.token);
    final healthy = await remoteDataSource.health();
    if (!healthy) {
      throw const KomandaApiException(
        'No fue posible conectar con el backend de Komanda.',
      );
    }
  }

  @override
  Future<List<KomandaProduct>> getProducts() async {
    final rows = await remoteDataSource.getProducts();
    _remoteProductIds
      ..clear()
      ..addAll(rows.map((row) => (row['id'] ?? '').toString()));

    final products = rows.map(_productFromRemote).toList();
    products.sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  @override
  Future<void> saveProduct(KomandaProduct product) async {
    final body = _productToRemote(product);
    if (_remoteProductIds.contains(product.id)) {
      await remoteDataSource.updateProduct(product.id, body);
      return;
    }

    final createdId = await remoteDataSource.createProduct(body);
    if (createdId.isNotEmpty) _remoteProductIds.add(createdId);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await remoteDataSource.deleteProduct(productId);
    _remoteProductIds.remove(productId);
  }

  @override
  Future<List<KomandaOrder>> getOrders() async {
    final rows = await remoteDataSource.getOrders();
    _remoteOrderIds
      ..clear()
      ..addAll(rows.map((row) => (row['id'] ?? '').toString()));

    final orders = rows.map(_orderFromRemote).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<Map<String, dynamic>> createManualTicket(double amount, double received) =>
      remoteDataSource.createManualTicket(amount, received);

  @override
  Future<void> saveOrder(KomandaOrder order) async {
    if (!_remoteOrderIds.contains(order.id)) {
      final created = await remoteDataSource.createOrder(_orderToRemote(order));
      final createdId = (created['id'] ?? order.id).toString();
      if (createdId.isNotEmpty) _remoteOrderIds.add(createdId);

      // Siempre normalizamos a users.id antes de asignar.
      // Un pedido leído del backend puede traer waiter_id = waiters.id.
      final waiterUserId = _resolveWaiterUserId(order.waiterId);
      if (waiterUserId.isNotEmpty) {
        await remoteDataSource.assignWaiter(
          createdId.isEmpty ? order.id : createdId,
          waiterUserId,
        );
      }
      return;
    }

    final waiterUserId = _resolveWaiterUserId(order.waiterId);
    if (waiterUserId.isNotEmpty) {
      await remoteDataSource.assignWaiter(order.id, waiterUserId);
    }

    // Si hay un pago pendiente, se aplica ANTES de reenviar el estado.
    // Esto permite cobrar una diferencia incluso si el pedido ya estaba
    // entregado y la edición lo dejó temporalmente con saldo pendiente.
    if (order.isPaid && order.paymentMethod.trim().isNotEmpty) {
      await remoteDataSource.payOrder(order.id, {
        'paymentMethod': _paymentApiValue(order.paymentMethod),
        'amountReceived': order.amountReceived,
        'tipAmount': order.tipAmount,
        'tipMode': order.tipMode,
        'tipPercentage': order.tipPercentage,
        // La API calcula el saldo real desde MySQL. No usar order.amountDue:
        // el estado local ya contiene paidAmount actualizado y devolvería cero.
      });
    }

    await remoteDataSource.updateOrderStatus(order.id, order.status.name);
  }

  @override
  Future<void> updateOrder(KomandaOrder order) async {
    await remoteDataSource.updateOrder(order.id, _orderToRemote(order));
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    KomandaOrderStatus status,
  ) async {
    await remoteDataSource.updateOrderStatus(orderId, status.name);
  }

  @override
  Future<void> assignWaiterToOrder(
    String orderId,
    KomandaWaiter waiter,
  ) async {
    final waiterUserId = waiter.userId.trim();
    if (waiterUserId.isEmpty) {
      throw StateError(
        'El mesero no tiene user_id vinculado. Actualiza la lista de meseros.',
      );
    }

    // El backend de asignación busca al mesero mediante users.id / waiters.user_id.
    await remoteDataSource.assignWaiter(
      orderId,
      waiterUserId,
    );
  }

  @override
  Future<List<WaiterCall>> getWaiterCalls() async {
    final rows = await remoteDataSource.getWaiterCalls();
    _remoteCallIds
      ..clear()
      ..addAll(rows.map((row) => (row['id'] ?? '').toString()));

    final calls = rows.map(_callFromRemote).toList();
    calls.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return calls;
  }

  @override
  Future<void> saveWaiterCall(WaiterCall call) async {
    if (!_remoteCallIds.contains(call.id)) {
      final createdId = await remoteDataSource.createWaiterCall({
        'table': call.table,
        'message': call.message,
        'type': call.type.name,
        'waiterName': call.waiterName,
      });
      if (createdId.isNotEmpty) _remoteCallIds.add(createdId);
      return;
    }

    await remoteDataSource.updateWaiterCallStatus(call.id, call.status.name);
  }

  @override
  Future<void> updateWaiterCallStatus(
    String callId,
    WaiterCallStatus status, {
    KomandaWaiter? waiter,
  }) async {
    await remoteDataSource.updateWaiterCallStatus(callId, status.name);
  }

  @override
  Future<List<KomandaWaiter>> getWaiters() async {
    final rows = await remoteDataSource.getWaiters();
    _remoteWaiterIds
      ..clear()
      ..addAll(
        rows
            .map(_waiterOperationalId)
            .where((id) => id.trim().isNotEmpty),
      );

    _waiterUserIdByOperationalId.clear();
    _waiterOperationalIdByUserId.clear();

    final waiters = rows
        .map(_waiterFromRemote)
        .where((waiter) => waiter.id.trim().isNotEmpty)
        .toList();

    for (final waiter in waiters) {
      final operationalId = waiter.id.trim();
      final userId = waiter.userId.trim();
      if (operationalId.isEmpty || userId.isEmpty) continue;
      _waiterUserIdByOperationalId[operationalId] = userId;
      _waiterOperationalIdByUserId[userId] = operationalId;
    }
    waiters.sort((a, b) => a.name.compareTo(b.name));
    return waiters;
  }

  @override
  Future<void> saveWaiter(KomandaWaiter waiter) async {
    final body = <String, dynamic>{
      'name': waiter.name,
      'username': waiter.username,
      'active': waiter.active ? 1 : 0,
      if (waiter.password.trim().isNotEmpty) 'password': waiter.password.trim(),
    };

    if (_remoteWaiterIds.contains(waiter.id)) {
      await remoteDataSource.updateWaiter(waiter.id, body);
      return;
    }

    final createdId = await remoteDataSource.createWaiter(body);
    if (createdId.isNotEmpty) _remoteWaiterIds.add(createdId);
  }

  @override
  Future<KomandaTicketConfig> getTicketConfig() async {
    final row = await remoteDataSource.getTicketConfig();
    return KomandaTicketConfig(
      businessName: _text(row, 'businessName', 'business_name'),
      address: _text(row, 'address'),
      phone: _text(row, 'phone'),
      footer: _text(row, 'footer'),
      showFolio: _bool(row['showFolio'] ?? row['show_folio'], fallback: true),
      showWaiter: _bool(row['showWaiter'] ?? row['show_waiter'], fallback: true),
      showTable: _bool(row['showTable'] ?? row['show_table'], fallback: true),
      showDate: _bool(row['showDate'] ?? row['show_date'], fallback: true),
      showItemSpecifications: _bool(
        row['showItemSpecifications'] ?? row['show_item_specifications'],
        fallback: true,
      ),
      showTip: _bool(row['showTip'] ?? row['show_tip'], fallback: true),
      plateLabel: (row['plateLabel'] ?? row['plate_label'] ?? 'Plato').toString(),
      logoBase64: (row['logoBase64'] ?? row['logo_base64'] ?? '').toString(),
      fontScale: _double(row['fontScale'] ?? row['font_scale']) == 0 ? 1.0 : _double(row['fontScale'] ?? row['font_scale']),
      fontWeight: _int(row['fontWeight'] ?? row['font_weight']) == 0 ? 400 : _int(row['fontWeight'] ?? row['font_weight']),
    );
  }

  @override
  Future<void> saveTicketConfig(KomandaTicketConfig config) async {
    await remoteDataSource.saveTicketConfig({
      'businessName': config.businessName,
      'address': config.address,
      'phone': config.phone,
      'footer': config.footer,
      'showFolio': config.showFolio,
      'showWaiter': config.showWaiter,
      'showTable': config.showTable,
      'showDate': config.showDate,
      'showItemSpecifications': config.showItemSpecifications,
      'showTip': config.showTip,
      'plateLabel': config.plateLabel,
      'logoBase64': config.logoBase64,
      'fontScale': config.fontScale,
      'fontWeight': config.fontWeight,
    });

    if (config.logoBase64.trim().isNotEmpty) {
      await remoteDataSource.uploadTicketLogo(config.logoBase64);
    }
  }

  @override Future<void> deleteWaiter(String waiterId) async { await remoteDataSource.deleteWaiter(waiterId); _remoteWaiterIds.remove(waiterId); }
  @override Future<List<KomandaCategory>> getCategories() async => (await remoteDataSource.getCategories()).map((r)=>KomandaCategory(id:(r['id']??'').toString(),name:(r['name']??'').toString(),printPrefix:(r['printPrefix']??r['print_prefix']??'').toString(),active:_bool(r['active'],fallback:true))).toList()..sort((a,b)=>_carneFirstCompare(a.name,b.name));
  @override Future<void> saveCategory(KomandaCategory c) async { final body={'name':c.name,'printPrefix':c.printPrefix,'active':c.active?1:0}; if(c.id.isNotEmpty && !c.id.startsWith('local_')) await remoteDataSource.updateCategory(c.id,body); else await remoteDataSource.createCategory(body); }
  @override Future<void> deleteCategory(String id) => remoteDataSource.deleteCategory(id);
  @override
  Future<List<KomandaOptionCatalog>> getOptionCatalogs() async {
    final rows = await remoteDataSource.getOptionCatalogs();
    return rows.map((r) {
      final values = (r['values'] as List? ?? const []).whereType<Map>().map((v) => KomandaOptionCatalogValue(
        id: (v['id'] ?? '').toString(),
        label: (v['label'] ?? '').toString(),
        active: _bool(v['active'], fallback: true),
        sortOrder: _int(v['sortOrder'] ?? v['sort_order']),
        extraPrice: _double(v['extraPrice'] ?? v['extra_price']),
        complementId: (v['complementId'] ?? v['complement_id'] ?? '').toString(),
        linkedProductId: (v['linkedProductId'] ?? v['linked_product_id'] ?? '').toString(),
        defaultQuantity: _int(v['defaultQuantity'] ?? v['default_quantity']) <= 0 ? 1 : _int(v['defaultQuantity'] ?? v['default_quantity']),
      )).toList()..sort((a,b)=>_carneFirstCompare(a.label,b.label));
      return KomandaOptionCatalog(
        id: (r['id'] ?? '').toString(),
        name: (r['name'] ?? '').toString(),
        slug: (r['slug'] ?? '').toString(),
        active: _bool(r['active'], fallback: true),
        sortOrder: _int(r['sortOrder'] ?? r['sort_order']),
        values: values,
      );
    }).toList()..sort((a,b)=>_carneFirstCompare(a.name,b.name));
  }

  Map<String,dynamic> _optionCatalogToRemote(KomandaOptionCatalog c) => {
    'name': c.name,
    'slug': c.slug,
    'active': c.active ? 1 : 0,
    'sortOrder': c.sortOrder,
    'values': c.values.map((v) => {
      'label': v.label,
      'active': v.active ? 1 : 0,
      'sortOrder': v.sortOrder,
      'extraPrice': v.extraPrice,
      'complementId': v.complementId.isEmpty ? null : v.complementId,
      'linkedProductId': v.linkedProductId.isEmpty ? null : v.linkedProductId,
      'defaultQuantity': v.defaultQuantity,
    }).toList(),
  };

  @override Future<void> saveOptionCatalog(KomandaOptionCatalog c) async {
    final body = _optionCatalogToRemote(c);
    if (c.id.isNotEmpty && !c.id.startsWith('local_')) {
      await remoteDataSource.updateOptionCatalog(c.id, body);
    } else {
      await remoteDataSource.createOptionCatalog(body);
    }
  }

  @override Future<void> deleteOptionCatalog(String id) => remoteDataSource.deleteOptionCatalog(id);

  @override Future<List<KomandaTable>> getTables() async => (await remoteDataSource.getTables()).map((r)=>KomandaTable(id:(r['id']??'').toString(),name:(r['name']??'').toString(),capacity:_int(r['capacity']),active:_bool(r['active'],fallback:true))).toList()..sort((a,b)=>a.name.compareTo(b.name));
  @override Future<void> saveTable(KomandaTable t) async { final body={'name':t.name,'capacity':t.capacity,'active':t.active?1:0}; if(t.id.isNotEmpty && !t.id.startsWith('local_')) await remoteDataSource.updateTable(t.id,body); else await remoteDataSource.createTable(body); }
  @override Future<void> deleteTable(String id)=>remoteDataSource.deleteTable(id);
  @override Future<List<KomandaCashClose>> getCashClosures() async => (await remoteDataSource.getCashClosures()).map((r)=>KomandaCashClose(id:(r['id']??'').toString(),openedAt:_date(r['openedAt']??r['opened_at'])??DateTime.now(),closedAt:_date(r['closedAt']??r['closed_at'])??DateTime.now(),openingCash:_double(r['openingCash']??r['opening_cash']),cashTotal:_double(r['cashTotal']??r['cash_total']),cardTotal:_double(r['cardTotal']??r['card_total']),transferTotal:_double(r['transferTotal']??r['transfer_total']),tipsTotal:_double(r['tipsTotal']??r['tips_total']),expectedTotal:_double(r['expectedTotal']??r['expected_total']),countedCash:_double(r['countedCash']??r['counted_cash']),difference:_double(r['difference']),paidOrders:_int(r['paidOrders']??r['paid_orders']),notes:(r['notes']??'').toString())).toList();
  @override Future<void> saveCashClose(KomandaCashClose c)=>remoteDataSource.createCashClose({'openedAt':c.openedAt.toIso8601String(),'closedAt':c.closedAt.toIso8601String(),'openingCash':c.openingCash,'cashTotal':c.cashTotal,'cardTotal':c.cardTotal,'transferTotal':c.transferTotal,'tipsTotal':c.tipsTotal,'expectedTotal':c.expectedTotal,'countedCash':c.countedCash,'difference':c.difference,'paidOrders':c.paidOrders,'notes':c.notes,'allowMultiple':c.allowMultiple});


  static int _carneFirstCompare(String a, String b) {
    int rank(String value) {
      final v = value.trim().toLowerCase();
      if (v == 'carne') return 0;
      if (v.startsWith('carne')) return 1;
      return 2;
    }
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.toLowerCase().compareTo(b.toLowerCase());
  }

  String _paymentApiValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'efectivo':
      case 'cash':
        return 'cash';
      case 'tarjeta':
      case 'card':
        return 'card';
      case 'transferencia':
      case 'transfer':
        return 'transfer';
      default:
        return value.trim().toLowerCase();
    }
  }

  KomandaProduct _productFromRemote(Map<String, dynamic> row) {
    final groups = (row['optionGroups'] as List? ?? const [])
        .whereType<Map>()
        .map((group) {
          final details = (group['options'] as List? ?? const [])
              .map((raw) {
                if (raw is Map) {
                  final linkedRaw = raw['linkedProduct'];
                  return KomandaProductOption(
                    id: (raw['id'] ?? '').toString(),
                    label: (raw['label'] ?? '').toString(),
                    extraPrice: _double(raw['extraPrice'] ?? raw['extra_price']),
                    complementId: (raw['complementId'] ?? raw['complement_id'] ?? '').toString(),
                    linkedProductId: (raw['linkedProductId'] ?? raw['linked_product_id'] ?? '').toString(),
                    defaultQuantity: _int(raw['defaultQuantity'] ?? raw['default_quantity']) <= 0
                        ? 1
                        : _int(raw['defaultQuantity'] ?? raw['default_quantity']),
                    linkedProduct: linkedRaw is Map
                        ? _productFromRemote(Map<String, dynamic>.from(linkedRaw))
                        : null,
                  );
                }
                return KomandaProductOption(id: '', label: raw.toString());
              })
              .where((e) => e.label.isNotEmpty)
              .toList()..sort((a,b)=>_carneFirstCompare(a.label,b.label));
          return KomandaProductOptionGroup(
            id: (group['id'] ?? '').toString(),
            name: (group['name'] ?? '').toString(),
            options: details.map((e) => e.label).toList(),
            optionDetails: details,
            multiple: _bool(group['multiple']),
            required: _bool(group['required']),
            minSelections: _int(group['minSelections'] ?? group['min_selections']),
            maxSelections: (group['maxSelections'] ?? group['max_selections']) == null
                ? null
                : _int(group['maxSelections'] ?? group['max_selections']),
            allowRepeats: _bool(group['allowRepeats'] ?? group['allow_repeats']),
            catalogId: (group['catalogId'] ?? group['catalog_id'] ?? '').toString(),
            catalogName: (group['catalogName'] ?? group['catalog_name'] ?? '').toString(),
          );
        })
        .toList();

    return KomandaProduct(
      id: (row['id'] ?? '').toString(),
      name: (row['name'] ?? '').toString(),
      printName: (row['printName'] ?? row['print_name'] ?? row['name'] ?? '').toString(),
      category: (row['category'] ?? '').toString(),
      price: _double(row['price']),
      available: _bool(row['available'], fallback: true),
      productKind: (row['productKind'] ?? row['product_kind'] ?? 'simple').toString(),
      pricingMode: (row['pricingMode'] ?? row['pricing_mode'] ?? 'fixed').toString(),
      description: (row['description'] ?? '').toString(),
      optionGroups: groups,
    );
  }

  Map<String, dynamic> _productToRemote(KomandaProduct product) => {
        'name': product.name,
        'category': product.category,
        'price': product.price,
        'available': product.available ? 1 : 0,
        'description': product.description,
        'productKind': product.productKind,
        'pricingMode': product.pricingMode,
        'optionGroups': product.optionGroups.map((group) => {
          'name': group.name,
          'catalogId': group.catalogId.isEmpty ? null : group.catalogId,
          'multiple': group.multiple ? 1 : 0,
          'required': group.required ? 1 : 0,
          'minSelections': group.minSelections,
          'maxSelections': group.maxSelections,
          'allowRepeats': group.allowRepeats ? 1 : 0,
          'options': (group.catalogId.isNotEmpty
              ? <KomandaProductOption>[]
              : (group.optionDetails.isNotEmpty
                  ? group.optionDetails
                  : group.options.map((label) => KomandaProductOption(id: '', label: label)).toList()))
            .map((option) => {
              'label': option.label,
              'extraPrice': option.extraPrice,
              'complementId': option.complementId.isEmpty ? null : option.complementId,
              'linkedProductId': option.linkedProductId.isEmpty ? null : option.linkedProductId,
              'defaultQuantity': option.defaultQuantity,
            }).toList(),
        }).toList(),
      };

  /// Convierte cualquier identificador de mesero al users.id real.
  ///
  /// - Si recibe waiters.id (ej. 3), devuelve users.id (ej. 15).
  /// - Si ya recibe users.id (ej. 15), lo conserva.
  /// - Si todavía no existe una relación cargada, conserva el valor para
  ///   mantener compatibilidad, aunque normalmente getWaiters() se carga
  ///   junto con el snapshot antes de operar pedidos.
  String _resolveWaiterUserId(String rawId) {
    final value = rawId.trim();
    if (value.isEmpty) return '';

    final mapped = _waiterUserIdByOperationalId[value];
    if (mapped != null && mapped.trim().isNotEmpty) {
      return mapped.trim();
    }

    if (_waiterOperationalIdByUserId.containsKey(value)) {
      return value;
    }

    return value;
  }

  KomandaOrder _orderFromRemote(Map<String, dynamic> row) {
    final paymentData = row['payment'] is Map
        ? Map<String, dynamic>.from(row['payment'] as Map)
        : const <String, dynamic>{};
    final items = (row['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => KomandaOrderItem(
            productId: (item['productId'] ?? item['product_id'] ?? '').toString(),
            name: (item['name'] ?? item['productName'] ?? item['product_name'] ?? '').toString(),
            category: (item['category'] ?? item['productCategory'] ?? item['product_category'] ?? '').toString(),
            quantity: _int(item['quantity']),
            unitPrice: _double(item['unitPrice'] ?? item['unit_price']),
            specifications: _specifications(
              item['specifications'] ??
                  item['details'] ??
                  item['detail'] ??
                  item['options'],
            ),
          ),
        )
        .toList();

    return KomandaOrder(
      id: (row['id'] ?? '').toString(),
      folio: _text(row, 'folio'),
      table: _text(row, 'table', 'tableName', 'table_name'),
      orderType: KomandaOrderTypeX.fromValue(
        row['orderType'] ?? row['order_type'],
        legacyTakeaway: _bool(row['isTakeaway'] ?? row['is_takeaway']),
      ),
      customerName: _text(row, 'customerName', 'customer_name'),
      kitchenName: _text(row, 'kitchenName', 'kitchen_name'),
      customerPhone: _text(row, 'customerPhone', 'customer_phone'),
      deliveryAddress: _text(row, 'deliveryAddress', 'delivery_address'),
      deliveryFee: _double(row['deliveryFee'] ?? row['delivery_fee']),
      createdAt: _date(row['createdAt'] ?? row['created_at']) ?? DateTime.now(),
      status: KomandaOrderStatus.values.firstWhere(
        (status) => status.name == (row['status'] ?? '').toString(),
        orElse: () => KomandaOrderStatus.pending,
      ),
      items: items,
      notes: _text(row, 'notes'),
      waiterId: _text(row, 'waiterId', 'waiter_id'),
      waiterName: _text(row, 'waiterName', 'waiter_name'),
      tipAmount: _double(row['tipAmount'] ?? row['tip_amount'] ?? paymentData['tipAmount'] ?? paymentData['tip_amount']),
      tipMode: _text(row, 'tipMode', 'tip_mode').isNotEmpty
          ? _text(row, 'tipMode', 'tip_mode')
          : ((paymentData['tipMode'] ?? paymentData['tip_mode'] ?? 'none').toString()),
      tipPercentage: _double(row['tipPercentage'] ?? row['tip_percentage'] ?? paymentData['tipPercentage'] ?? paymentData['tip_percentage']),
      deliveredAt: _date(
        row['deliveredAt'] ??
            row['delivered_at'] ??
            (((row['status'] ?? '').toString() == 'atTable' ||
                    (row['status'] ?? '').toString() == 'completed')
                ? (row['updatedAt'] ?? row['updated_at'])
                : null),
      ),
      releasedAt: _date(row['releasedAt'] ?? row['released_at']),
      isUrgent: _bool(row['isUrgent'] ?? row['is_urgent']),
      isPaid: _bool(row['isPaid'] ?? row['is_paid'] ?? paymentData['isPaid'] ?? paymentData['is_paid']),
      paymentMethod: _text(row, 'paymentMethod', 'payment_method').isNotEmpty
          ? _text(row, 'paymentMethod', 'payment_method')
          : ((paymentData['paymentMethod'] ?? paymentData['payment_method'] ?? paymentData['method'] ?? '').toString()),
      amountReceived: _double(row['amountReceived'] ?? row['amount_received'] ?? paymentData['amountReceived'] ?? paymentData['amount_received']),
      changeAmount: _double(row['changeAmount'] ?? row['change_amount'] ?? paymentData['changeAmount'] ?? paymentData['change_amount']),
      paidAmount: _double(row['paidAmount'] ?? row['paid_amount'] ?? paymentData['paidAmount'] ?? paymentData['paid_amount']),
      paidAt: _date(row['paidAt'] ?? row['paid_at'] ?? paymentData['paidAt'] ?? paymentData['paid_at']),
      preparingAt: _date(
        row['preparingAt'] ??
            row['preparing_at'] ??
            row['preparationStartedAt'] ??
            row['preparation_started_at'] ??
            ((row['status'] ?? '').toString() == 'preparing'
                ? (row['updatedAt'] ?? row['updated_at'])
                : null),
      ),
      readyAt: _date(
        row['readyAt'] ??
            row['ready_at'] ??
            row['preparedAt'] ??
            row['prepared_at'] ??
            row['preparationFinishedAt'] ??
            row['preparation_finished_at'] ??
            ((row['status'] ?? '').toString() == 'waiting'
                ? (row['updatedAt'] ?? row['updated_at'])
                : null),
      ),
    );
  }

  Map<String, dynamic> _orderToRemote(KomandaOrder order) => {
        // El backend multi-restaurante acepta el ID enviado por el cliente.
        // Esto permite que la misma orden conserve su identificador en todos
        // los dispositivos sin usar mapeos locales.
        'id': order.id,
        'folio': order.folio,
        'table': order.table,
        'orderType': order.orderType.apiValue,
        'isTakeaway': order.isTakeaway, // compatibilidad con backend anterior
        'customerName': order.customerName.trim(),
        'kitchenName': order.kitchenName.trim(),
        'customerPhone': order.customerPhone.trim(),
        'deliveryAddress': order.deliveryAddress.trim(),
        'deliveryFee': order.deliveryFee,
        'isUrgent': order.isUrgent,
        'status': order.status.name,
        'notes': order.notes.trim(),
        'items': order.items
            .map(
              (item) => {
                'productId': item.productId.isEmpty ? null : item.productId,
                'name': item.name.trim(),
                'category': item.category.trim(),
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'specifications': _compactSpecifications(item.specifications), // [] permitido sin complementos
              },
            )
            .toList(),
      };


  static List<String> _compactSpecifications(List<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (clean.isEmpty || !seen.add(clean)) continue;
      result.add(clean);
    }
    return result;
  }

  /// [KomandaWaiter.id] representa waiters.id para administrar el registro.
  /// [KomandaWaiter.userId] representa users.id y es el identificador que
  /// usa PATCH /orders/{id}/waiter para localizar waiters.user_id.
  KomandaWaiter _waiterFromRemote(Map<String, dynamic> row) {
    final operationalId = _waiterOperationalId(row);
    final userId = _text(row, 'userId', 'user_id', 'userID').trim();

    return KomandaWaiter(
      id: operationalId,
      userId: userId,
      name: (row['name'] ?? '').toString(),
      username: (row['username'] ?? '').toString(),
      active: _bool(row['active'], fallback: true),
    );
  }

  static String _waiterOperationalId(Map<String, dynamic> row) {
    // Preferimos explícitamente el ID de la tabla waiters. Algunos endpoints
    // antiguos devolvían `id` como users.id y agregaban el ID operativo en
    // otra propiedad. Este orden evita enviar users.id por accidente.
    const keys = <String>[
      'waiterId',
      'waiter_id',
      'linkedWaiterId',
      'linked_waiter_id',
      'operationalId',
      'operational_id',
      'id',
    ];

    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  WaiterCall _callFromRemote(Map<String, dynamic> row) => WaiterCall(
        id: (row['id'] ?? '').toString(),
        table: _text(row, 'table', 'table_name'),
        message: _text(row, 'message'),
        type: WaiterCallType.values.firstWhere(
          (type) => type.name == (row['type'] ?? '').toString(),
          orElse: () => WaiterCallType.call,
        ),
        status: WaiterCallStatus.values.firstWhere(
          (status) => status.name == (row['status'] ?? '').toString(),
          orElse: () => WaiterCallStatus.pending,
        ),
        createdAt: _date(row['createdAt'] ?? row['created_at']) ?? DateTime.now(),
        waiterId: _text(row, 'waiterId', 'waiter_id'),
        waiterName: _text(row, 'waiterName', 'waiter_name'),
      );


  static List<String> _specifications(dynamic value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
      }
      if (decoded is Map) {
        return decoded.entries.map((entry) => '${entry.key}: ${entry.value}').toList();
      }
    } catch (_) {}
    return <String>[raw];
  }

  static String _text(Map<String, dynamic> row, String key, [
    String? key2,
    String? key3,
  ]) {
    final value = row[key] ?? (key2 == null ? null : row[key2]) ??
        (key3 == null ? null : row[key3]);
    return value?.toString() ?? '';
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : DateTime.tryParse(text);
  }
}
