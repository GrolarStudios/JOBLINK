import 'dart:convert';
import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../../domain/entities/waiter_call.dart';


List<String> _readSpecifications(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }
  if (value is Map) {
    return value.entries.map((entry) => '${entry.key}: ${entry.value}').toList();
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

extension KomandaProductMapper on KomandaProduct {
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'printName': printName,
        'category': category,
        'price': price,
        'available': available,
        'productKind': productKind,
        'pricingMode': pricingMode,
        'description': description,
        'optionGroups': optionGroups.map((group) => {
          'id': group.id,
          'name': group.name,
          'catalogId': group.catalogId,
          'catalogName': group.catalogName,
          'multiple': group.multiple,
          'required': group.required,
          'minSelections': group.minSelections,
          'maxSelections': group.maxSelections,
          'allowRepeats': group.allowRepeats,
          'options': (group.optionDetails.isNotEmpty
              ? group.optionDetails.map((o) => {
                  'id': o.id,
                  'label': o.label,
                  'extraPrice': o.extraPrice,
                  'complementId': o.complementId,
                  'linkedProductId': o.linkedProductId,
                  'defaultQuantity': o.defaultQuantity,
                  if (o.linkedProduct != null) 'linkedProduct': o.linkedProduct!.toMap(),
                }).toList()
              : group.options),
        }).toList(),
      };

  static KomandaProduct fromMap(Map<dynamic, dynamic> map) => KomandaProduct(
        id: (map['id'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        printName: (map['printName'] ?? map['name'] ?? '').toString(),
        category: (map['category'] ?? '').toString(),
        price: (map['price'] as num? ?? 0).toDouble(),
        available: map['available'] == true,
        productKind: (map['productKind'] ?? 'simple').toString(),
        pricingMode: (map['pricingMode'] ?? 'fixed').toString(),
        description: (map['description'] ?? '').toString(),
        optionGroups: ((map['optionGroups'] ?? []) as List).whereType<Map>().map((group) {
          final details = ((group['options'] ?? []) as List).map((raw) {
            if (raw is Map) {
              return KomandaProductOption(
                id: (raw['id'] ?? '').toString(),
                label: (raw['label'] ?? '').toString(),
                extraPrice: (raw['extraPrice'] as num? ?? 0).toDouble(),
                complementId: (raw['complementId'] ?? '').toString(),
                linkedProductId: (raw['linkedProductId'] ?? '').toString(),
                defaultQuantity: (raw['defaultQuantity'] as num? ?? 1).toInt(),
                linkedProduct: raw['linkedProduct'] is Map ? KomandaProductMapper.fromMap(raw['linkedProduct'] as Map) : null,
              );
            }
            return KomandaProductOption(id: '', label: raw.toString());
          }).toList();
          return KomandaProductOptionGroup(
            id: (group['id'] ?? '').toString(),
            name: (group['name'] ?? '').toString(),
            options: details.map((e) => e.label).toList(),
            optionDetails: details,
            multiple: group['multiple'] == true,
            required: group['required'] == true,
            minSelections: (group['minSelections'] as num? ?? 0).toInt(),
            maxSelections: (group['maxSelections'] as num?)?.toInt(),
            allowRepeats: group['allowRepeats'] == true,
            catalogId: (group['catalogId'] ?? '').toString(),
            catalogName: (group['catalogName'] ?? '').toString(),
          );
        }).toList(),
      );
}

extension KomandaOrderItemMapper on KomandaOrderItem {
  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'specifications': specifications,
      };

  static KomandaOrderItem fromMap(Map<dynamic, dynamic> map) => KomandaOrderItem(
        productId: (map['productId'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        category: (map['category'] ?? map['productCategory'] ?? map['product_category'] ?? '').toString(),
        quantity: (map['quantity'] as num? ?? 0).toInt(),
        unitPrice: (map['unitPrice'] as num? ?? 0).toDouble(),
        specifications: _readSpecifications(
          map['specifications'] ?? map['details'] ?? map['detail'] ?? map['options'],
        ),
      );
}

extension KomandaOrderMapper on KomandaOrder {
  Map<String, dynamic> toMap() => {
        'id': id,
        'folio': folio,
        'table': table,
        'orderType': orderType.apiValue,
        'customerName': customerName,
        'kitchenName': kitchenName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'deliveryFee': deliveryFee,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'waiterId': waiterId,
        'waiterName': waiterName,
        'tipAmount': tipAmount,
        'tipMode': tipMode,
        'tipPercentage': tipPercentage,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'releasedAt': releasedAt?.toIso8601String(),
        'isTakeaway': isTakeaway,
        'isUrgent': isUrgent,
        'isPaid': isPaid,
        'paymentMethod': paymentMethod,
        'amountReceived': amountReceived,
        'changeAmount': changeAmount,
        'paidAmount': paidAmount,
        'paidAt': paidAt?.toIso8601String(),
        'preparingAt': preparingAt?.toIso8601String(),
        'readyAt': readyAt?.toIso8601String(),
        'items': items.map((item) => item.toMap()).toList(),
      };

  static KomandaOrder fromMap(Map<dynamic, dynamic> map) => KomandaOrder(
        id: (map['id'] ?? '').toString(),
        folio: (map['folio'] ?? '').toString(),
        table: (map['table'] ?? '').toString(),
        orderType: KomandaOrderTypeX.fromValue(
          map['orderType'] ?? map['order_type'],
          legacyTakeaway: map['isTakeaway'] == true,
        ),
        customerName: (map['customerName'] ?? map['customer_name'] ?? '').toString(),
        kitchenName: (map['kitchenName'] ?? map['kitchen_name'] ?? '').toString(),
        customerPhone: (map['customerPhone'] ?? map['customer_phone'] ?? '').toString(),
        deliveryAddress: (map['deliveryAddress'] ?? map['delivery_address'] ?? '').toString(),
        deliveryFee: ((map['deliveryFee'] ?? map['delivery_fee']) as num? ?? 0).toDouble(),
        createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        status: KomandaOrderStatus.values.firstWhere(
          (status) => status.name == map['status'],
          orElse: () => KomandaOrderStatus.pending,
        ),
        notes: (map['notes'] ?? '').toString(),
        waiterId: (map['waiterId'] ?? '').toString(),
        waiterName: (map['waiterName'] ?? '').toString(),
        tipAmount: (map['tipAmount'] as num? ?? 0).toDouble(),
        tipMode: (map['tipMode'] ?? 'none').toString(),
        tipPercentage: (map['tipPercentage'] as num? ?? 0).toDouble(),
        deliveredAt: DateTime.tryParse((map['deliveredAt'] ?? '').toString()),
        releasedAt: DateTime.tryParse((map['releasedAt'] ?? '').toString()),
        isUrgent: map['isUrgent'] == true,
        isPaid: map['isPaid'] == true || map['isPaid'] == 1 || map['isPaid'] == '1',
        paymentMethod: (map['paymentMethod'] ?? '').toString(),
        amountReceived: (map['amountReceived'] as num? ?? 0).toDouble(),
        changeAmount: (map['changeAmount'] as num? ?? 0).toDouble(),
        paidAmount: ((map['paidAmount'] ?? map['paid_amount']) as num? ?? 0).toDouble(),
        paidAt: DateTime.tryParse((map['paidAt'] ?? '').toString()),
        preparingAt: DateTime.tryParse((map['preparingAt'] ?? map['preparing_at'] ?? map['preparationStartedAt'] ?? map['preparation_started_at'] ?? '').toString()),
        readyAt: DateTime.tryParse((map['readyAt'] ?? map['ready_at'] ?? map['preparedAt'] ?? map['prepared_at'] ?? map['preparationFinishedAt'] ?? map['preparation_finished_at'] ?? '').toString()),
        items: ((map['items'] ?? []) as List)
            .whereType<Map>()
            .map(KomandaOrderItemMapper.fromMap)
            .toList(),
      );
}

extension WaiterCallMapper on WaiterCall {
  Map<String, dynamic> toMap() => {
        'id': id,
        'table': table,
        'message': message,
        'type': type.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'waiterId': waiterId,
        'waiterName': waiterName,
      };

  static WaiterCall fromMap(Map<dynamic, dynamic> map) => WaiterCall(
        id: (map['id'] ?? '').toString(),
        table: (map['table'] ?? '').toString(),
        message: (map['message'] ?? '').toString(),
        type: WaiterCallType.values.firstWhere(
          (type) => type.name == map['type'],
          orElse: () => WaiterCallType.call,
        ),
        status: WaiterCallStatus.values.firstWhere(
          (status) => status.name == map['status'],
          orElse: () => WaiterCallStatus.pending,
        ),
        createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
            DateTime.now(),
        waiterId: (map['waiterId'] ?? '').toString(),
        waiterName: (map['waiterName'] ?? '').toString(),
      );
}

extension KomandaWaiterMapper on KomandaWaiter {
  Map<String, dynamic> toMap() => {
        // id = ID operativo de waiters.
        'id': id,
        // userId = users.id. Este es el ID que se usa para asignar pedidos.
        'userId': userId,
        'user_id': userId,
        'name': name,
        'username': username,
        'active': active,
      };

  static KomandaWaiter fromMap(Map<dynamic, dynamic> map) {
    final userId = (map['userId'] ?? map['user_id'] ?? '').toString().trim();
    final waiterId = (map['waiterId'] ?? map['waiter_id'] ?? map['id'] ?? '').toString().trim();

    return KomandaWaiter(
      id: waiterId,
      userId: userId,
      name: (map['name'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      active: map['active'] == true || map['active'] == 1 || map['active'] == '1',
    );
  }
}


extension KomandaTicketConfigMapper on KomandaTicketConfig {
  Map<String, dynamic> toMap() => {
    'businessName': businessName, 'address': address, 'phone': phone,
    'footer': footer, 'showFolio': showFolio, 'showWaiter': showWaiter,
    'showTable': showTable, 'showDate': showDate,
    'showItemSpecifications': showItemSpecifications, 'showTip': showTip,
    'plateLabel': plateLabel, 'logoBase64': logoBase64, 'fontScale': fontScale, 'fontWeight': fontWeight,
  };
  static KomandaTicketConfig fromMap(Map<dynamic, dynamic> map) => KomandaTicketConfig(
    businessName: (map['businessName'] ?? 'Mi restaurante').toString(),
    address: (map['address'] ?? '').toString(), phone: (map['phone'] ?? '').toString(),
    footer: (map['footer'] ?? 'Gracias por su compra').toString(),
    showFolio: map['showFolio'] != false, showWaiter: map['showWaiter'] != false,
    showTable: map['showTable'] != false, showDate: map['showDate'] != false,
    showItemSpecifications: map['showItemSpecifications'] != false,
    showTip: map['showTip'] != false,
    plateLabel: (map['plateLabel'] ?? 'Plato').toString(),
    logoBase64: (map['logoBase64'] ?? '').toString(),
    fontScale: double.tryParse((map['fontScale'] ?? '1').toString()) ?? 1.0,
    fontWeight: int.tryParse((map['fontWeight'] ?? '400').toString()) ?? 400,
  );
}
