import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_product.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../../domain/entities/waiter_call.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../../domain/entities/komanda_category.dart';
import '../../domain/entities/komanda_table.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_option_catalog.dart';

abstract class KomandaEvent {
  const KomandaEvent();
}

class KomandaStarted extends KomandaEvent {
  const KomandaStarted();
}

class KomandaRefreshed extends KomandaEvent {
  final bool showLoading;
  const KomandaRefreshed({this.showLoading = true});
}

class KomandaTableSelected extends KomandaEvent {
  final String table;
  const KomandaTableSelected(this.table);
}

class KomandaProductAdded extends KomandaEvent {
  final KomandaProduct product;
  const KomandaProductAdded(this.product);
}

class KomandaConfiguredProductAdded extends KomandaEvent {
  final KomandaProduct product;
  final List<String> specifications;
  final int quantity;
  final bool separateLine;

  const KomandaConfiguredProductAdded({
    required this.product,
    this.specifications = const [],
    this.quantity = 1,
    this.separateLine = false,
  });
}

class KomandaProductRemoved extends KomandaEvent {
  final String cartKey;
  const KomandaProductRemoved(this.cartKey);
}

class KomandaCartLineDeleted extends KomandaEvent {
  final String cartKey;
  const KomandaCartLineDeleted(this.cartKey);
}

class KomandaCartItemRepeated extends KomandaEvent {
  final String cartKey;
  const KomandaCartItemRepeated(this.cartKey);
}

class KomandaCartItemSpecificationsChanged extends KomandaEvent {
  final String cartKey;
  final List<String> specifications;
  const KomandaCartItemSpecificationsChanged({required this.cartKey, required this.specifications});
}

class KomandaCartItemNoteChanged extends KomandaEvent {
  final String cartKey;
  final String note;

  const KomandaCartItemNoteChanged({
    required this.cartKey,
    required this.note,
  });
}

class KomandaCartCleared extends KomandaEvent {
  const KomandaCartCleared();
}

class KomandaOrderCreated extends KomandaEvent {
  final List<String> joinedTables;
  final String notes;
  final KomandaWaiter? waiter;
  final KomandaOrderType orderType;
  final String customerName;
  final String kitchenName;
  final String customerPhone;
  final String deliveryAddress;
  final double deliveryFee;
  final bool isUrgent;

  const KomandaOrderCreated({
    this.joinedTables = const [],
    this.notes = '',
    this.waiter,
    this.orderType = KomandaOrderType.dineIn,
    this.customerName = '',
    this.kitchenName = '',
    this.customerPhone = '',
    this.deliveryAddress = '',
    this.deliveryFee = 0,
    this.isUrgent = false,
  });
}

class KomandaOrderReleased extends KomandaEvent {
  final String orderId;
  final double tipAmount;
  final String tipMode;
  final double tipPercentage;

  const KomandaOrderReleased({
    required this.orderId,
    this.tipAmount = 0,
    this.tipMode = 'none',
    this.tipPercentage = 0,
  });
}

class KomandaOrderEdited extends KomandaEvent {
  final KomandaOrder order;
  const KomandaOrderEdited({required this.order});
}

class KomandaOrderStatusChanged extends KomandaEvent {
  final String orderId;
  final KomandaOrderStatus status;

  const KomandaOrderStatusChanged({
    required this.orderId,
    required this.status,
  });
}

class KomandaOrderWaiterAssigned extends KomandaEvent {
  final String orderId;
  final KomandaWaiter waiter;

  const KomandaOrderWaiterAssigned({
    required this.orderId,
    required this.waiter,
  });
}

class KomandaWaiterCallCreated extends KomandaEvent {
  final String table;
  final String message;
  final WaiterCallType type;

  const KomandaWaiterCallCreated({
    required this.table,
    required this.message,
    required this.type,
  });
}

class KomandaWaiterCallCompleted extends KomandaEvent {
  final String callId;
  final KomandaWaiter? waiter;

  const KomandaWaiterCallCompleted(
    this.callId, {
    this.waiter,
  });
}

class KomandaWaiterSaved extends KomandaEvent {
  final KomandaWaiter waiter;
  const KomandaWaiterSaved(this.waiter);
}

class KomandaOrderPaid extends KomandaEvent {
  final String orderId;
  final String method;
  final double amountReceived;
  final double tipAmount;
  final String tipMode;
  final double tipPercentage;

  const KomandaOrderPaid({
    required this.orderId,
    required this.method,
    required this.amountReceived,
    this.tipAmount = 0,
    this.tipMode = 'none',
    this.tipPercentage = 0,
  });
}

class KomandaProductSaved extends KomandaEvent {
  final KomandaProduct product;
  const KomandaProductSaved(this.product);
}

class KomandaProductDeleted extends KomandaEvent {
  final String productId;
  const KomandaProductDeleted(this.productId);
}

class KomandaTicketConfigSaved extends KomandaEvent {
  final KomandaTicketConfig config;
  const KomandaTicketConfigSaved(this.config);
}

class KomandaWaiterDeleted extends KomandaEvent {
  final String waiterId;
  const KomandaWaiterDeleted(this.waiterId);
}

class KomandaCategorySaved extends KomandaEvent {
  final KomandaCategory category;
  const KomandaCategorySaved(this.category);
}

class KomandaCategoryDeleted extends KomandaEvent {
  final String categoryId;
  const KomandaCategoryDeleted(this.categoryId);
}

class KomandaOptionCatalogSaved extends KomandaEvent {
  final KomandaOptionCatalog catalog;
  const KomandaOptionCatalogSaved(this.catalog);
}

class KomandaOptionCatalogDeleted extends KomandaEvent {
  final String catalogId;
  const KomandaOptionCatalogDeleted(this.catalogId);
}

class KomandaTableSaved extends KomandaEvent {
  final KomandaTable table;
  const KomandaTableSaved(this.table);
}

class KomandaTableDeleted extends KomandaEvent {
  final String tableId;
  const KomandaTableDeleted(this.tableId);
}

class KomandaCashCloseSaved extends KomandaEvent {
  final KomandaCashClose close;
  const KomandaCashCloseSaved(this.close);
}
