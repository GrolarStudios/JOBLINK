import 'dart:async';

import '../../core/utils/komanda_daily_folio.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/komanda_order.dart';
import '../../core/printing/komanda_kitchen_print_service.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../../domain/entities/waiter_call.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../../domain/entities/komanda_category.dart';
import '../../domain/entities/komanda_table.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_option_catalog.dart';
import '../../domain/usecases/komanda_usecases.dart';
import 'komanda_event.dart';
import 'komanda_state.dart';

class KomandaBloc extends Bloc<KomandaEvent, KomandaState> {
  final String restaurantId;
  int _cartInstanceSequence = 0;
  bool _creatingOrder = false;
  bool _refreshing = false;
  // Evita PATCH duplicados cuando el usuario toca dos veces el mismo botón.
  final Set<String> _ordersUpdatingStatus = <String>{};
  final InitKomanda initKomanda;
  final GetKomandaProducts getProducts;
  final SaveKomandaProduct saveProduct;
  final DeleteKomandaProduct deleteProduct;
  final GetKomandaTicketConfig getTicketConfig;
  final SaveKomandaTicketConfig saveTicketConfig;
  final GetKomandaOrders getOrders;
  final SaveKomandaOrder saveOrder;
  final UpdateKomandaOrder updateOrder;
  final UpdateKomandaOrderStatus updateOrderStatus;
  final GetWaiterCalls getWaiterCalls;
  final SaveWaiterCall saveWaiterCall;
  final UpdateWaiterCallStatus updateWaiterCallStatus;
  final GetKomandaWaiters getWaiters;
  final SaveKomandaWaiter saveWaiter;
  final AssignWaiterToOrder assignWaiterToOrder;
  final DeleteKomandaWaiter deleteWaiter;

  final GetKomandaCategories getCategories;
  final SaveKomandaCategory saveCategory;
  final DeleteKomandaCategory deleteCategory;
  final GetKomandaOptionCatalogs getOptionCatalogs;
  final SaveKomandaOptionCatalog saveOptionCatalog;
  final DeleteKomandaOptionCatalog deleteOptionCatalog;

  final GetKomandaTables getTables;
  final SaveKomandaTable saveTable;
  final DeleteKomandaTable deleteTable;

  final GetKomandaCashClosures getCashClosures;
  final SaveKomandaCashClose saveCashClose;

  KomandaBloc({
    required this.restaurantId,
    required this.initKomanda,
    required this.getProducts,
    required this.saveProduct,
    required this.deleteProduct,
    required this.getTicketConfig,
    required this.saveTicketConfig,
    required this.getOrders,
    required this.saveOrder,
    required this.updateOrder,
    required this.updateOrderStatus,
    required this.getWaiterCalls,
    required this.saveWaiterCall,
    required this.updateWaiterCallStatus,
    required this.getWaiters,
    required this.saveWaiter,
    required this.assignWaiterToOrder,
    required this.deleteWaiter,
    required this.getCategories,
    required this.saveCategory,
    required this.deleteCategory,
    required this.getOptionCatalogs,
    required this.saveOptionCatalog,
    required this.deleteOptionCatalog,
    required this.getTables,
    required this.saveTable,
    required this.deleteTable,
    required this.getCashClosures,
    required this.saveCashClose,
  }) : super(const KomandaState()) {
    on<KomandaStarted>(_onStarted);
    on<KomandaRefreshed>(_onRefreshed);
    on<KomandaTableSelected>(_onTableSelected);
    on<KomandaProductAdded>(_onProductAdded);
    on<KomandaConfiguredProductAdded>(_onConfiguredProductAdded);
    on<KomandaProductRemoved>(_onProductRemoved);
    on<KomandaCartLineDeleted>((event, emit) {
      final cart = Map<String, KomandaOrderItem>.from(state.cart);
      cart.remove(event.cartKey);
      emit(state.copyWith(cart: cart));
    });
    on<KomandaCartItemRepeated>(_onCartItemRepeated);
    on<KomandaCartItemSpecificationsChanged>((event, emit) {
      final cart = Map<String, KomandaOrderItem>.from(state.cart);
      final current = cart[event.cartKey];
      if (current == null) return;
      cart[event.cartKey] = current.copyWith(specifications: event.specifications);
      emit(state.copyWith(cart: cart));
    });
    on<KomandaCartItemNoteChanged>(_onCartItemNoteChanged);
    on<KomandaCartCleared>(_onCartCleared);
    on<KomandaOrderCreated>(_onOrderCreated);
    on<KomandaOrderEdited>(_onOrderEdited);
    on<KomandaOrderStatusChanged>(_onOrderStatusChanged);
    on<KomandaOrderReleased>(_onOrderReleased);
    on<KomandaWaiterCallCreated>(_onWaiterCallCreated);
    on<KomandaWaiterCallCompleted>(_onWaiterCallCompleted);
    on<KomandaWaiterSaved>(_onWaiterSaved);
    on<KomandaOrderWaiterAssigned>(_onOrderWaiterAssigned);
    on<KomandaOrderPaid>(_onOrderPaid);
    on<KomandaProductSaved>(_onProductSaved);
    on<KomandaProductDeleted>(_onProductDeleted);
    on<KomandaTicketConfigSaved>(_onTicketConfigSaved);

    on<KomandaWaiterDeleted>(
      (event, emit) => _runAndReload(
        emit,
        () => deleteWaiter(event.waiterId),
      ),
    );

    on<KomandaCategorySaved>(
      (event, emit) => _runAndReload(
        emit,
        () => saveCategory(event.category),
      ),
    );

    on<KomandaCategoryDeleted>(
      (event, emit) => _runAndReload(
        emit,
        () => deleteCategory(event.categoryId),
      ),
    );

    on<KomandaOptionCatalogSaved>(
      (event, emit) => _runAndReload(
        emit,
        () => saveOptionCatalog(event.catalog),
      ),
    );

    on<KomandaOptionCatalogDeleted>(
      (event, emit) => _runAndReload(
        emit,
        () => deleteOptionCatalog(event.catalogId),
      ),
    );

    on<KomandaTableSaved>(
      (event, emit) => _runAndReload(
        emit,
        () => saveTable(event.table),
      ),
    );

    on<KomandaTableDeleted>(
      (event, emit) => _runAndReload(
        emit,
        () => deleteTable(event.tableId),
      ),
    );

    on<KomandaCashCloseSaved>(
      (event, emit) => _runAndReload(
        emit,
        () => saveCashClose(event.close),
      ),
    );
  }

  Future<void> _onStarted(
    KomandaStarted event,
    Emitter<KomandaState> emit,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.loading,
        clearError: true,
      ),
    );

    try {
      await initKomanda();
      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    KomandaRefreshed event,
    Emitter<KomandaState> emit,
  ) async {
    // Evita apilar varias cargas del catálogo/pedidos en el mismo dispositivo.
    // Esto es especialmente importante cuando hay refresco automático y el
    // usuario además hace pull-to-refresh o navega rápido entre pantallas.
    if (_refreshing) return;
    _refreshing = true;
    try {
      // Los refrescos automáticos deben ser silenciosos para no cubrir toda
      // la pantalla con "Actualizando..." cada pocos segundos.
      if (event.showLoading) {
        emit(
          state.copyWith(
            status: KomandaStatus.loading,
            clearError: true,
          ),
        );
      }

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } finally {
      _refreshing = false;
    }
  }

  void _onTableSelected(
    KomandaTableSelected event,
    Emitter<KomandaState> emit,
  ) {
    emit(
      state.copyWith(
        selectedTable: event.table.trim(),
      ),
    );
  }

  // Producto simple: siempre agrega UNA pieza.
  // KomandaProductAdded NO tiene quantity.
  void _onProductAdded(
    KomandaProductAdded event,
    Emitter<KomandaState> emit,
  ) {
    final cart =
        Map<String, KomandaOrderItem>.from(state.cart);

    final current = cart[event.product.id];

    cart[event.product.id] = KomandaOrderItem(
      productId: event.product.id,
      name: event.product.printName,
      category: event.product.category,
      quantity: (current?.quantity ?? 0) + 1,
      unitPrice: event.product.price,
    );

    emit(
      state.copyWith(
        cart: cart,
      ),
    );
  }

  // Producto configurado:
  // aquí sí se puede repetir 1, 2, 3... veces.
  void _onConfiguredProductAdded(
    KomandaConfiguredProductAdded event,
    Emitter<KomandaState> emit,
  ) {
    final cart =
        Map<String, KomandaOrderItem>.from(state.cart);

    final normalizedSpecifications =
        [...event.specifications]..sort();

    final signature =
        normalizedSpecifications.join('|');

    final baseCartKey =
        '${event.product.id}::$signature';

    final cartKey = event.separateLine
        ? '$baseCartKey::instance_${++_cartInstanceSequence}'
        : baseCartKey;

    final current = cart[cartKey];

    final int quantityToAdd =
        event.quantity < 1 ? 1 : event.quantity;

    cart[cartKey] = KomandaOrderItem(
      productId: event.product.id,
      name: event.product.printName,
      category: event.product.category,
      quantity:
          (current?.quantity ?? 0) + quantityToAdd,
      unitPrice: event.product.price,
      specifications:
          List<String>.from(event.specifications),
    );

    emit(
      state.copyWith(
        cart: cart,
      ),
    );
  }

  void _onProductRemoved(
    KomandaProductRemoved event,
    Emitter<KomandaState> emit,
  ) {
    final cart =
        Map<String, KomandaOrderItem>.from(state.cart);

    final current = cart[event.cartKey];

    if (current == null) {
      return;
    }

    if (current.quantity <= 1) {
      cart.remove(event.cartKey);
    } else {
      cart[event.cartKey] = current.copyWith(
        quantity: current.quantity - 1,
      );
    }

    emit(
      state.copyWith(
        cart: cart,
      ),
    );
  }

  void _onCartItemRepeated(
    KomandaCartItemRepeated event,
    Emitter<KomandaState> emit,
  ) {
    final cart =
        Map<String, KomandaOrderItem>.from(state.cart);

    final current = cart[event.cartKey];

    if (current == null) {
      return;
    }

    cart[event.cartKey] = current.copyWith(
      quantity: current.quantity + 1,
    );

    emit(
      state.copyWith(
        cart: cart,
      ),
    );
  }

  void _onCartItemNoteChanged(
    KomandaCartItemNoteChanged event,
    Emitter<KomandaState> emit,
  ) {
    final cart =
        Map<String, KomandaOrderItem>.from(state.cart);

    final current = cart[event.cartKey];

    if (current == null) {
      return;
    }

    final specifications = current.specifications
        .where(
          (value) =>
              !value
                  .trim()
                  .toLowerCase()
                  .startsWith('nota:'),
        )
        .toList();

    final note = event.note.trim();

    if (note.isNotEmpty) {
      specifications.add('Nota: $note');
    }

    cart[event.cartKey] = current.copyWith(
      specifications: specifications,
    );

    emit(
      state.copyWith(
        cart: cart,
      ),
    );
  }

  void _onCartCleared(
    KomandaCartCleared event,
    Emitter<KomandaState> emit,
  ) {
    emit(
      state.copyWith(
        cart: {},
        selectedTable: '',
      ),
    );
  }

  Future<void> _onOrderCreated(
    KomandaOrderCreated event,
    Emitter<KomandaState> emit,
  ) async {
    // Candado adicional: evita dobles clics/eventos encolados mientras
    // el primer pedido todavía se está guardando.
    if (_creatingOrder || !state.canSaveOrder) {
      return;
    }
    _creatingOrder = true;

    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      final now = DateTime.now();
      final id =
          now.microsecondsSinceEpoch.toString();

      final ficha = _buildNextFicha();

      final order = KomandaOrder(
        id: id,
        folio: ficha,
        table: event.orderType == KomandaOrderType.dineIn ? (event.joinedTables.length >= 2 ? event.joinedTables.join(', ') : state.selectedTable) : '',
        orderType: event.orderType,
        customerName:
            event.customerName.trim(),
        kitchenName: event.kitchenName.trim(),
        customerPhone:
            event.customerPhone.trim(),
        deliveryAddress:
            event.deliveryAddress.trim(),
        deliveryFee: event.orderType == KomandaOrderType.delivery ? event.deliveryFee : 0,
        createdAt: now,
        status: KomandaOrderStatus.pending,
        items: state.cart.values.toList(),
        notes: event.notes.trim(),
        waiterId: event.waiter?.id ?? '',
        waiterName: event.waiter?.name ?? '',
        isUrgent: event.isUrgent,
      );

      // Guardar el pedido es la operación principal. La impresión NO debe
      // mantener la pantalla en estado "saving" ni bloquear la navegación.
      await saveOrder(order);

      // El pedido ya fue confirmado por el backend. No hacemos un refresh
      // completo aquí porque eso puede dejar la UI atrapada en un ciclo de
      // "Actualizando..." justo al navegar al dashboard.
      // Actualizamos el estado local de inmediato y liberamos la pantalla.
      final updatedOrders = <KomandaOrder>[
        order,
        ...state.orders.where((item) => item.id != order.id),
      ];

      emit(
        state.copyWith(
          status: KomandaStatus.ready,
          cart: const {},
          selectedTable: '',
          orders: updatedOrders,
          clearError: true,
        ),
      );

      // Sincronización secundaria y silenciosa. Nunca vuelve a poner el estado
      // global en loading/saving y por lo tanto no muestra el overlay.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 300), () async {
          if (isClosed) return;
          try {
            add(const KomandaRefreshed(showLoading: false));
          } catch (_) {}
        }),
      );

      // La impresión automática queda completamente desacoplada del guardado.
      // Se lanza en el siguiente ciclo para permitir que Flutter procese primero
      // el estado READY y la navegación. Cancelar/cerrar el diálogo de impresión
      // o cualquier fallo del navegador nunca afecta un pedido ya guardado.
      unawaited(
        Future<void>.delayed(Duration.zero, () async {
          try {
            if (restaurantId.trim() == '2') {
              await KomandaTicketPrintService.printOrder(order, state.ticketConfig);
            } else {
              await KomandaKitchenPrintService.printOrder(
                order, state.ticketConfig, restaurantId: restaurantId);
            }
          } catch (_) {
            // La impresión es secundaria y no modifica el resultado del pedido.
          }
        }),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _creatingOrder = false;
    }
  }

  Future<void> _onOrderEdited(
    KomandaOrderEdited event,
    Emitter<KomandaState> emit,
  ) async {
    emit(state.copyWith(status: KomandaStatus.saving, clearError: true));
    try {
      await updateOrder(event.order);
      await _loadSnapshot(emit, status: KomandaStatus.ready);
    } catch (error) {
      emit(state.copyWith(
        status: KomandaStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onOrderStatusChanged(
    KomandaOrderStatusChanged event,
    Emitter<KomandaState> emit,
  ) async {
    // El primer toque toma el candado antes de cualquier await. Un segundo toque
    // al mismo pedido se ignora, evitando dos PATCH /status y el 422 por
    // intentar repetir una transición que el backend ya aplicó.
    if (!_ordersUpdatingStatus.add(event.orderId)) return;

    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await updateOrderStatus(
        event.orderId,
        event.status,
      );

      // El cambio de estado ya fue confirmado por restaurant-api. Actualizamos
      // únicamente el pedido local para evitar volver a descargar catálogo,
      // mesas, meseros, cortes y todos los pedidos al marcar Preparado/Entregado.
      final now = DateTime.now();
      final updatedOrders = state.orders.map((order) {
        if (order.id != event.orderId) return order;
        return order.copyWith(
          status: event.status,
          preparingAt: event.status == KomandaOrderStatus.preparing ? now : null,
          readyAt: event.status == KomandaOrderStatus.waiting ? now : null,
          deliveredAt: event.status == KomandaOrderStatus.atTable ? now : null,
          releasedAt: event.status == KomandaOrderStatus.completed ? now : null,
        );
      }).toList();
      emit(state.copyWith(status: KomandaStatus.ready, orders: updatedOrders));
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _ordersUpdatingStatus.remove(event.orderId);
    }
  }

  Future<void> _onOrderReleased(
    KomandaOrderReleased event,
    Emitter<KomandaState> emit,
  ) async {
    final order = state.orders
        .where(
          (item) => item.id == event.orderId,
        )
        .firstOrNull;

    if (order == null ||
        order.status == KomandaOrderStatus.completed ||
        order.status == KomandaOrderStatus.cancelled ||
        !order.isPaid) {
      emit(state.copyWith(
        status: KomandaStatus.failure,
        errorMessage: order == null
            ? 'No se encontró el pedido de esta mesa.'
            : !order.isPaid
                ? 'Falta pagar la cuenta antes de liberar la mesa.'
                : 'El pedido ya está finalizado o cancelado.',
      ));
      return;
    }

    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      // PUT /orders actualiza artículos, pero NO cambia status ni released_at.
      // PATCH /orders/{id}/status sí persiste el cierre y la liberación.
      await updateOrderStatus(event.orderId, KomandaOrderStatus.completed);

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onWaiterCallCreated(
    KomandaWaiterCallCreated event,
    Emitter<KomandaState> emit,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await saveWaiterCall(
        WaiterCall(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          table: event.table.trim(),
          message: event.message.trim(),
          type: event.type,
          status:
              WaiterCallStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onWaiterCallCompleted(
    KomandaWaiterCallCompleted event,
    Emitter<KomandaState> emit,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await updateWaiterCallStatus(
        event.callId,
        WaiterCallStatus.done,
        waiter: event.waiter,
      );

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onWaiterSaved(
    KomandaWaiterSaved event,
    Emitter<KomandaState> emit,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await saveWaiter(event.waiter);

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onOrderWaiterAssigned(
    KomandaOrderWaiterAssigned event,
    Emitter<KomandaState> emit,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await assignWaiterToOrder(
        event.orderId,
        event.waiter,
      );

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onOrderPaid(
    KomandaOrderPaid event,
    Emitter<KomandaState> emit,
  ) async {
    final order = state.orders
        .where((item) => item.id == event.orderId)
        .firstOrNull;

    if (order == null) return;

    emit(state.copyWith(status: KomandaStatus.saving, clearError: true));
    try {
      final tip = event.tipAmount < 0 ? 0.0 : event.tipAmount;
      final finalTotal = order.total + tip;
      final amountDue = (finalTotal - order.paidAmount).clamp(0, double.infinity).toDouble();
      final received = event.amountReceived < amountDue ? amountDue : event.amountReceived;
      final now = DateTime.now();
      final updated = order.copyWith(
        isPaid: true,
        paymentMethod: event.method.trim(),
        amountReceived: received,
        changeAmount: (received - amountDue).clamp(0, double.infinity).toDouble(),
        paidAmount: finalTotal,
        paidAt: now,
        tipAmount: tip,
        tipMode: event.tipMode,
        tipPercentage: event.tipMode == 'percentage' ? event.tipPercentage : 0,
      );

      await saveOrder(updated);

      // El cobro confirmado se refleja localmente sin volver a pedir todo el snapshot.
      final updatedOrders = state.orders
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      emit(state.copyWith(status: KomandaStatus.ready, orders: updatedOrders));
    } catch (error) {
      emit(state.copyWith(status: KomandaStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> _onProductSaved(
    KomandaProductSaved event,
    Emitter<KomandaState> emit,
  ) async {
    await saveProduct(event.product);

    await _loadSnapshot(
      emit,
      status: KomandaStatus.ready,
    );
  }

  Future<void> _onProductDeleted(
    KomandaProductDeleted event,
    Emitter<KomandaState> emit,
  ) async {
    await deleteProduct(
      event.productId,
    );

    await _loadSnapshot(
      emit,
      status: KomandaStatus.ready,
    );
  }

  Future<void> _onTicketConfigSaved(
    KomandaTicketConfigSaved event,
    Emitter<KomandaState> emit,
  ) async {
    await saveTicketConfig(
      event.config,
    );

    await _loadSnapshot(
      emit,
      status: KomandaStatus.ready,
    );
  }

  Future<void> _loadSnapshot(
    Emitter<KomandaState> emit, {
    required KomandaStatus status,
  }) async {
    final errors = <String>[];

    final results =
        await Future.wait<dynamic>([
      _safeLoad(
        'productos',
        getProducts,
        state.products,
        errors,
      ),
      _safeLoad(
        'pedidos',
        getOrders,
        state.orders,
        errors,
      ),
      _safeLoad(
        'llamados',
        getWaiterCalls,
        state.waiterCalls,
        errors,
      ),
      _safeLoad(
        'meseros',
        getWaiters,
        state.waiters,
        errors,
      ),
      _safeLoad(
        'ticket',
        getTicketConfig,
        state.ticketConfig,
        errors,
      ),
      _safeLoad(
        'categorías',
        getCategories,
        state.categories,
        errors,
      ),
      _safeLoad(
        'configuraciones de productos',
        getOptionCatalogs,
        state.optionCatalogs,
        errors,
      ),
      _safeLoad(
        'mesas',
        getTables,
        state.tables,
        errors,
      ),
      _safeLoad(
        'cortes de caja',
        getCashClosures,
        state.cashClosures,
        errors,
      ),
    ]);

    emit(
      state.copyWith(
        status: status,
        products:
            (results[0] as List)
                .cast<KomandaProduct>(),
        orders:
            (results[1] as List)
                .cast<KomandaOrder>(),
        waiterCalls:
            (results[2] as List)
                .cast<WaiterCall>(),
        waiters:
            (results[3] as List)
                .cast<KomandaWaiter>(),
        ticketConfig:
            results[4]
                as KomandaTicketConfig,
        categories:
            (results[5] as List)
                .cast<KomandaCategory>(),
        optionCatalogs:
            (results[6] as List)
                .cast<KomandaOptionCatalog>(),
        tables:
            (results[7] as List)
                .cast<KomandaTable>(),
        cashClosures:
            (results[8] as List)
                .cast<KomandaCashClose>(),
        errorMessage:
            errors.isEmpty
                ? null
                : 'No se pudieron actualizar: ${errors.join(', ')}.',
        clearError: errors.isEmpty,
      ),
    );
  }

  Future<T> _safeLoad<T>(
    String label,
    Future<T> Function() loader,
    T fallback,
    List<String> errors,
  ) async {
    try {
      return await loader();
    } catch (_) {
      errors.add(label);
      return fallback;
    }
  }

  Future<void> _runAndReload(
    Emitter<KomandaState> emit,
    Future<void> Function() action,
  ) async {
    emit(
      state.copyWith(
        status: KomandaStatus.saving,
        clearError: true,
      ),
    );

    try {
      await action();

      await _loadSnapshot(
        emit,
        status: KomandaStatus.ready,
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: KomandaStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  // Consecutivo diario para la vista y solicitud de creación.
  String _buildNextFicha() => komandaNextDailyFolio(state.orders, DateTime.now());

}

extension _FirstOrNullBloc<E>
    on Iterable<E> {
  E? get firstOrNull =>
      isEmpty ? null : first;
}
