class RouteNames {
  const RouteNames._();

  static const String empleo = '/empleo';

  // ================= KOMANDA APP ROUTES =================
  static const String komanda = '/komanda';

  // Estas rutas viven dentro del Navigator interno de KomandaFeature.
  static const String komandaDashboard = '/komanda/dashboard';
  static const String komandaNewOrderTable = '/komanda/order/table';
  static const String komandaNewOrderProducts = '/komanda/order/products';
  static const String komandaOrderSummary = '/komanda/order/summary';
  static const String komandaChefOrders = '/komanda/chef/orders';
  static const String komandaWaiterCalls = '/komanda/waiter/calls';
  static const String komandaHistory = '/komanda/history';

  // Alias opcionales por si tu proyecto ya usa estos nombres.
  static const String dashboard = komandaDashboard;
  static const String newOrderTable = komandaNewOrderTable;
  static const String newOrderProducts = komandaNewOrderProducts;
  static const String orderSummary = komandaOrderSummary;
  static const String chefOrders = komandaChefOrders;
  static const String waiterCalls = komandaWaiterCalls;
  static const String history = komandaHistory;

  // Alias de compatibilidad con diseños anteriores.
  static const String orderFlow = komandaNewOrderTable;
  static const String detail = komandaChefOrders;
}
