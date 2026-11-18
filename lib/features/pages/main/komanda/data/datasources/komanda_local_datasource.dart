import 'package:hive_flutter/hive_flutter.dart';

import '../../core/komanda_box_names.dart';
import '../../core/komanda_constants.dart';

abstract class KomandaLocalDataSource {
  Future<void> init();

  Future<List<Map<dynamic, dynamic>>> getProducts();
  Future<void> saveProduct(Map<String, dynamic> product);
  Future<void> deleteProduct(String productId);

  Future<List<Map<dynamic, dynamic>>> getOrders();
  Future<void> saveOrder(Map<String, dynamic> order);

  Future<List<Map<dynamic, dynamic>>> getWaiterCalls();
  Future<void> saveWaiterCall(Map<String, dynamic> call);

  Future<List<Map<dynamic, dynamic>>> getWaiters();
  Future<void> saveWaiter(Map<String, dynamic> waiter);

  Future<Map<dynamic, dynamic>?> getTicketConfig();
  Future<void> saveTicketConfig(Map<String, dynamic> config);

  Future<String?> getAuthToken();
  Future<void> saveAuthToken(String? token);
  Future<List<Map<String, dynamic>>> getPendingSyncOperations();
  Future<void> savePendingSyncOperation(Map<String, dynamic> operation);
  Future<void> deletePendingSyncOperation(String operationId);
  Future<String?> getRemoteId(String entityType, String localId);
  Future<void> saveRemoteId(String entityType, String localId, String remoteId);
  Future<String?> getLocalId(String entityType, String remoteId);
}


class HiveKomandaLocalDataSource implements KomandaLocalDataSource {
  final String restaurantId;

  HiveKomandaLocalDataSource({required this.restaurantId});

  Box? _productsBox;
  Box? _ordersBox;
  Box? _waiterCallsBox;
  Box? _waitersBox;
  Box? _settingsBox;
  Box? _syncBox;

  Box get productsBox => _productsBox ?? (throw StateError('Komanda Hive products box no inicializada'));
  Box get ordersBox => _ordersBox ?? (throw StateError('Komanda Hive orders box no inicializada'));
  Box get waiterCallsBox => _waiterCallsBox ?? (throw StateError('Komanda Hive waiter calls box no inicializada'));
  Box get waitersBox => _waitersBox ?? (throw StateError('Komanda Hive waiters box no inicializada'));
  Box get settingsBox => _settingsBox ?? (throw StateError('Komanda Hive settings box no inicializada'));
  Box get syncBox => _syncBox ?? (throw StateError('Komanda Hive sync box no inicializada'));

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _productsBox ??= await Hive.openBox(KomandaBoxNames.products(restaurantId));
    _ordersBox ??= await Hive.openBox(KomandaBoxNames.orders(restaurantId));
    _waiterCallsBox ??= await Hive.openBox(KomandaBoxNames.waiterCalls(restaurantId));
    _waitersBox ??= await Hive.openBox(KomandaBoxNames.waiters(restaurantId));
    _settingsBox ??= await Hive.openBox(KomandaBoxNames.settings(restaurantId));
    _syncBox ??= await Hive.openBox(KomandaBoxNames.sync(restaurantId));

    await _migrateProductOptions();

  }

  @override
  Future<List<Map<dynamic, dynamic>>> getProducts() async =>
      productsBox.values.whereType<Map>().toList();

  @override
  Future<void> saveProduct(Map<String, dynamic> product) async =>
      productsBox.put(product['id'], {...product, 'restaurantId': restaurantId});

  @override
  Future<void> deleteProduct(String productId) => productsBox.delete(productId);

  @override
  Future<List<Map<dynamic, dynamic>>> getOrders() async =>
      ordersBox.values.whereType<Map>().toList();

  @override
  Future<void> saveOrder(Map<String, dynamic> order) async =>
      ordersBox.put(order['id'], {...order, 'restaurantId': restaurantId});

  @override
  Future<List<Map<dynamic, dynamic>>> getWaiterCalls() async =>
      waiterCallsBox.values.whereType<Map>().toList();

  @override
  Future<void> saveWaiterCall(Map<String, dynamic> call) async =>
      waiterCallsBox.put(call['id'], {...call, 'restaurantId': restaurantId});

  @override
  Future<List<Map<dynamic, dynamic>>> getWaiters() async =>
      waitersBox.values.whereType<Map>().toList();

  @override
  Future<void> saveWaiter(Map<String, dynamic> waiter) async =>
      waitersBox.put(waiter['id'], {...waiter, 'restaurantId': restaurantId});

  @override
  Future<Map<dynamic, dynamic>?> getTicketConfig() async {
    final value = settingsBox.get('ticket');
    return value is Map ? value : null;
  }

  @override
  Future<void> saveTicketConfig(Map<String, dynamic> config) =>
      settingsBox.put('ticket', {...config, 'restaurantId': restaurantId});


  @override
  Future<String?> getAuthToken() async => syncBox.get('authToken')?.toString();

  @override
  Future<void> saveAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await syncBox.delete('authToken');
    } else {
      await syncBox.put('authToken', token);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final raw = syncBox.get('pendingOperations', defaultValue: const <dynamic>[]);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Future<void> savePendingSyncOperation(Map<String, dynamic> operation) async {
    final operations = await getPendingSyncOperations();
    operations.removeWhere((item) =>
        item['kind'] == operation['kind'] &&
        item['entityId'] == operation['entityId']);
    operations.add(operation);
    await syncBox.put('pendingOperations', operations);
  }

  @override
  Future<void> deletePendingSyncOperation(String operationId) async {
    final operations = await getPendingSyncOperations();
    operations.removeWhere((item) => item['id'] == operationId);
    await syncBox.put('pendingOperations', operations);
  }

  String _remoteMapKey(String entityType, String localId) =>
      'remoteId:$entityType:$localId';

  String _localMapKey(String entityType, String remoteId) =>
      'localId:$entityType:$remoteId';

  @override
  Future<String?> getRemoteId(String entityType, String localId) async =>
      syncBox.get(_remoteMapKey(entityType, localId))?.toString();

  @override
  Future<void> saveRemoteId(
    String entityType,
    String localId,
    String remoteId,
  ) async {
    await syncBox.put(_remoteMapKey(entityType, localId), remoteId);
    await syncBox.put(_localMapKey(entityType, remoteId), localId);
  }

  @override
  Future<String?> getLocalId(String entityType, String remoteId) async =>
      syncBox.get(_localMapKey(entityType, remoteId))?.toString();


  Future<void> _migrateProductOptions() async {
    for (final seed in KomandaSeedData.products) {
      final id = seed['id'];
      if (id == null) continue;
      final current = productsBox.get(id);
      if (current is! Map) continue;

      final currentOptions = current['optionGroups'];
      if (currentOptions is List && currentOptions.isNotEmpty) continue;

      await productsBox.put(
        id,
        <String, dynamic>{
          ...Map<String, dynamic>.from(current),
          'optionGroups': seed['optionGroups'] ?? const <Map<String, dynamic>>[],
        },
      );
    }
  }

  Future<void> _seedProductsIfNeeded() async {
    if (productsBox.isNotEmpty) return;
    for (final product in KomandaSeedData.products) {
      await productsBox.put(product['id'], product);
    }
  }
}
