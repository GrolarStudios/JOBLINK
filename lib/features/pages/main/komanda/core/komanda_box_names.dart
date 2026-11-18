class KomandaBoxNames {
  const KomandaBoxNames._();

  static const session = 'komanda_session';

  static String _suffix(String restaurantId) => restaurantId
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  static String products(String restaurantId) =>
      'komanda_products_${_suffix(restaurantId)}';
  static String orders(String restaurantId) =>
      'komanda_orders_${_suffix(restaurantId)}';
  static String waiterCalls(String restaurantId) =>
      'komanda_waiter_calls_${_suffix(restaurantId)}';
  static String waiters(String restaurantId) =>
      'komanda_waiters_${_suffix(restaurantId)}';
  static String settings(String restaurantId) =>
      'komanda_settings_${_suffix(restaurantId)}';
  static String sync(String restaurantId) =>
      'komanda_sync_${_suffix(restaurantId)}';
}
