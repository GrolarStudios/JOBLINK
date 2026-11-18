class KomandaPermissions {
  const KomandaPermissions._();

  static String _role(String role) => role.trim().toLowerCase();

  static bool isAdmin(String role) => _role(role) == 'admin';
  static bool isOrderTaker(String role) => _role(role) == 'order_taker';
  static bool isKitchen(String role) => _role(role) == 'chef';
  static bool isWaiter(String role) => _role(role) == 'waiter';

  static bool canCreateOrders(String role) => isAdmin(role) || isOrderTaker(role) || isWaiter(role);
  static bool canUseKitchen(String role) => isAdmin(role) || isKitchen(role);
  static bool canCharge(String role) => isAdmin(role) || isWaiter(role);
  static bool canViewHistory(String role) => isAdmin(role);
  static bool canViewOrderStatus(String role) => isAdmin(role) || isOrderTaker(role) || isWaiter(role);
  static bool canManageCatalog(String role) => isAdmin(role);
  static bool canManageRestaurant(String role) => isAdmin(role);
  static bool canUseWaiterArea(String role) => false;
}
