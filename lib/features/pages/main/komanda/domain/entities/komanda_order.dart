enum KomandaOrderStatus { pending, preparing, waiting, delivering, atTable, completed, cancelled }

extension KomandaOrderStatusX on KomandaOrderStatus {
  String get label {
    switch (this) {
      case KomandaOrderStatus.pending: return 'Pendiente';
      case KomandaOrderStatus.preparing: return 'Preparando';
      case KomandaOrderStatus.waiting: return 'Pendiente de entrega';
      case KomandaOrderStatus.delivering: return 'En entrega';
      case KomandaOrderStatus.atTable: return 'Entregado';
      case KomandaOrderStatus.completed: return 'Finalizado';
      case KomandaOrderStatus.cancelled: return 'Cancelado';
    }
  }
}

enum KomandaOrderType { dineIn, takeaway, delivery }

extension KomandaOrderTypeX on KomandaOrderType {
  String get label {
    switch (this) {
      case KomandaOrderType.dineIn: return 'Para aquí';
      case KomandaOrderType.takeaway: return 'Para llevar';
      case KomandaOrderType.delivery: return 'Domicilio';
    }
  }

  String get apiValue {
    switch (this) {
      case KomandaOrderType.dineIn: return 'DINE_IN';
      case KomandaOrderType.takeaway: return 'TAKEAWAY';
      case KomandaOrderType.delivery: return 'DELIVERY';
    }
  }

  static KomandaOrderType fromValue(Object? value, {bool legacyTakeaway = false}) {
    final normalized = (value ?? '').toString().trim().toUpperCase();
    if (normalized == 'DELIVERY' || normalized == 'DOMICILIO') return KomandaOrderType.delivery;
    if (normalized == 'TAKEAWAY' || normalized == 'PARA_LLEVAR' || legacyTakeaway) return KomandaOrderType.takeaway;
    return KomandaOrderType.dineIn;
  }
}

class KomandaOrderItem {
  final String productId;
  final String name;
  final String category;
  final int quantity;
  final double unitPrice;
  final List<String> specifications;
  const KomandaOrderItem({
    required this.productId,
    required this.name,
    this.category = '',
    required this.quantity,
    required this.unitPrice,
    this.specifications = const [],
  });
  double get total => quantity * unitPrice;
  KomandaOrderItem copyWith({
    String? productId, String? name, String? category, int? quantity, double? unitPrice, List<String>? specifications,
  }) => KomandaOrderItem(
    productId: productId ?? this.productId, name: name ?? this.name, category: category ?? this.category, quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice, specifications: specifications ?? this.specifications,
  );
}

class KomandaOrder {
  final String id;
  final String folio;
  final String table; // Se conserva por compatibilidad; el flujo nuevo no usa mesas.
  final KomandaOrderType orderType;
  final String customerName;
  final String kitchenName;
  final String customerPhone;
  final String deliveryAddress;
  final double deliveryFee;
  final DateTime createdAt;
  final KomandaOrderStatus status;
  final List<KomandaOrderItem> items;
  final String notes;
  final String waiterId;
  final String waiterName;
  final double tipAmount;
  final String tipMode;
  final double tipPercentage;
  final DateTime? deliveredAt;
  final DateTime? releasedAt;
  final bool isUrgent;
  final bool isPaid;
  final String paymentMethod;
  final double amountReceived;
  final double changeAmount;
  final double paidAmount;
  final DateTime? paidAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;

  const KomandaOrder({
    required this.id, this.folio = '', this.table = '', this.orderType = KomandaOrderType.dineIn,
    this.customerName = '', this.kitchenName = '', this.customerPhone = '', this.deliveryAddress = '', this.deliveryFee = 0,
    required this.createdAt, required this.status, required this.items, this.notes = '',
    this.waiterId = '', this.waiterName = '', this.tipAmount = 0, this.tipMode = 'none', this.tipPercentage = 0,
    this.deliveredAt, this.releasedAt, this.isUrgent = false, this.isPaid = false, this.paymentMethod = '',
    this.amountReceived = 0, this.changeAmount = 0, this.paidAmount = 0, this.paidAt, this.preparingAt, this.readyAt,
  });

  double get itemsTotal => items.fold(0, (sum, item) => sum + item.total);
  double get total => itemsTotal + (isDelivery ? deliveryFee : 0);
  double get amountDue => ((total + tipAmount) - paidAmount).clamp(0, double.infinity).toDouble();
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isOpen => status != KomandaOrderStatus.completed && status != KomandaOrderStatus.cancelled;
  bool get isAttended => status == KomandaOrderStatus.completed;
  bool get isTakeaway => orderType == KomandaOrderType.takeaway;
  bool get isDelivery => orderType == KomandaOrderType.delivery;
  bool get isDineIn => orderType == KomandaOrderType.dineIn;
  String get shortFolio {
    if (folio.trim().isNotEmpty) return folio.trim();
    return id.substring(id.length > 6 ? id.length - 6 : 0);
  }
  String get displayReference => 'Ficha $shortFolio · ${orderType.label}${customerName.trim().isEmpty ? '' : ' · $customerName'}';

  KomandaOrder copyWith({
    String? id, String? folio, String? table, KomandaOrderType? orderType, String? customerName, String? kitchenName, String? customerPhone,
    String? deliveryAddress, double? deliveryFee, DateTime? createdAt, KomandaOrderStatus? status, List<KomandaOrderItem>? items, String? notes,
    String? waiterId, String? waiterName, double? tipAmount, String? tipMode, double? tipPercentage,
    DateTime? deliveredAt, DateTime? releasedAt, bool clearDeliveredAt = false, bool clearReleasedAt = false,
    bool? isUrgent, bool? isPaid, String? paymentMethod, double? amountReceived, double? changeAmount, double? paidAmount,
    DateTime? paidAt, bool clearPaidAt = false, DateTime? preparingAt, bool clearPreparingAt = false,
    DateTime? readyAt, bool clearReadyAt = false,
  }) => KomandaOrder(
    id: id ?? this.id, folio: folio ?? this.folio, table: table ?? this.table, orderType: orderType ?? this.orderType,
    customerName: customerName ?? this.customerName, kitchenName: kitchenName ?? this.kitchenName, customerPhone: customerPhone ?? this.customerPhone,
    deliveryAddress: deliveryAddress ?? this.deliveryAddress, deliveryFee: deliveryFee ?? this.deliveryFee, createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status, items: items ?? this.items, notes: notes ?? this.notes, waiterId: waiterId ?? this.waiterId,
    waiterName: waiterName ?? this.waiterName, tipAmount: tipAmount ?? this.tipAmount, tipMode: tipMode ?? this.tipMode,
    tipPercentage: tipPercentage ?? this.tipPercentage, deliveredAt: clearDeliveredAt ? null : deliveredAt ?? this.deliveredAt,
    releasedAt: clearReleasedAt ? null : releasedAt ?? this.releasedAt, isUrgent: isUrgent ?? this.isUrgent,
    isPaid: isPaid ?? this.isPaid, paymentMethod: paymentMethod ?? this.paymentMethod, amountReceived: amountReceived ?? this.amountReceived,
    paidAmount: paidAmount ?? this.paidAmount,
    changeAmount: changeAmount ?? this.changeAmount, paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
    preparingAt: clearPreparingAt ? null : preparingAt ?? this.preparingAt,
    readyAt: clearReadyAt ? null : readyAt ?? this.readyAt,
  );
}
