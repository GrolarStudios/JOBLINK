import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/komanda_api_config.dart';

class KomandaApiException implements Exception {
  final String message;
  final int? statusCode;

  const KomandaApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

abstract class KomandaRemoteDataSource {
  String? get token;
  void setToken(String? value);

  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<Map<String, dynamic>> getMyProfile();
  Future<Map<String, dynamic>> updateMyProfile(Map<String, dynamic> data);
  Future<bool> health();
  Future<List<Map<String, dynamic>>> getUsers();
  Future<String> createUser(Map<String, dynamic> user);
  Future<void> updateUser(String id, Map<String, dynamic> user);
  Future<void> deleteUser(String id);


  Future<List<Map<String, dynamic>>> getProducts();
  Future<String> createProduct(Map<String, dynamic> product);
  Future<void> updateProduct(String remoteId, Map<String, dynamic> product);
  Future<void> deleteProduct(String remoteId);
  Future<List<Map<String, dynamic>>> getComplements();
  Future<String> createComplement(Map<String, dynamic> complement);
  Future<void> updateComplement(String id, Map<String, dynamic> complement);
  Future<void> deleteComplement(String id);
  Future<List<Map<String, dynamic>>> getOptionCatalogs();
  Future<String> createOptionCatalog(Map<String, dynamic> catalog);
  Future<void> updateOptionCatalog(String id, Map<String, dynamic> catalog);
  Future<void> deleteOptionCatalog(String id);
  Future<void> setProductAvailability(String id, bool available);
  Future<void> setComplementAvailability(String id, bool active);
  Future<void> setOptionCatalogValueAvailability(String id, bool active);

  Future<List<Map<String, dynamic>>> getOrders();
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order);
  Future<Map<String, dynamic>> createManualTicket(double amount, double received);
  Future<void> updateOrder(String remoteId, Map<String, dynamic> order);
  Future<void> updateOrderStatus(String remoteId, String status);
  Future<void> assignWaiter(String remoteOrderId, String waiterUserId);
  Future<void> payOrder(String remoteOrderId, Map<String, dynamic> payment);

  Future<List<Map<String, dynamic>>> getWaiters();
  Future<String> createWaiter(Map<String, dynamic> waiter);
  Future<void> updateWaiter(String remoteId, Map<String, dynamic> waiter);
  Future<void> deleteWaiter(String remoteId);
  Future<List<Map<String, dynamic>>> getCategories();
  Future<String> createCategory(Map<String, dynamic> category);
  Future<void> updateCategory(String id, Map<String, dynamic> category);
  Future<void> deleteCategory(String id);
  Future<List<Map<String, dynamic>>> getTables();
  Future<String> createTable(Map<String, dynamic> table);
  Future<void> updateTable(String id, Map<String, dynamic> table);
  Future<void> deleteTable(String id);
  Future<List<Map<String, dynamic>>> getCashClosures();
  Future<String> createCashClose(Map<String, dynamic> close);
  Future<Map<String, dynamic>> getFinanceSummary();
  Future<List<Map<String, dynamic>>> getExpenses();
  Future<String> createExpense(Map<String, dynamic> expense);
  Future<List<Map<String, dynamic>>> getKitchenStations();
  Future<void> saveKitchenStation(String? id, Map<String, dynamic> station);
  Future<void> deleteKitchenStation(String id);

  Future<List<Map<String, dynamic>>> getWaiterCalls();
  Future<String> createWaiterCall(Map<String, dynamic> call);
  Future<void> updateWaiterCallStatus(String remoteId, String status);

  Future<Map<String, dynamic>> getTicketConfig();
  Future<void> saveTicketConfig(Map<String, dynamic> config);
  Future<String?> uploadTicketLogo(String base64Image);
}

class HttpKomandaRemoteDataSource implements KomandaRemoteDataSource {
  final http.Client client;
  String? _token;

  HttpKomandaRemoteDataSource({http.Client? client})
      : client = client ?? http.Client();

  @override
  String? get token => _token;

  @override
  void setToken(String? value) => _token = value;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = KomandaApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token?.isNotEmpty == true) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, String>? query,
        Object? body,
        bool authenticated = true,
      }) async {
    if (!KomandaApiConfig.isConfigured) {
      throw const KomandaApiException(
        'La URL del backend de Komanda no es válida.',
      );
    }

    if (authenticated && (_token == null || _token!.isEmpty)) {
      throw const KomandaApiException(
        'No hay una sesión remota activa.',
      );
    }

    final uri = _uri(path, query);

    late http.Response response;
    final encoded = body == null ? null : jsonEncode(body);

    try {
      switch (method) {
        case 'GET':
          response = await client
              .get(
            uri,
            headers: _headers,
          )
              .timeout(KomandaApiConfig.timeout);
          break;

        case 'POST':
          response = await client
              .post(
            uri,
            headers: _headers,
            body: encoded,
          )
              .timeout(KomandaApiConfig.timeout);
          break;

        case 'PUT':
          response = await client
              .put(
            uri,
            headers: _headers,
            body: encoded,
          )
              .timeout(KomandaApiConfig.timeout);
          break;

        case 'PATCH':
          response = await client
              .patch(
            uri,
            headers: _headers,
            body: encoded,
          )
              .timeout(KomandaApiConfig.timeout);
          break;

        case 'DELETE':
          response = await client
              .delete(
            uri,
            headers: _headers,
          )
              .timeout(KomandaApiConfig.timeout);
          break;

        default:
          throw KomandaApiException(
            'Método HTTP no soportado: $method',
          );
      }
    } catch (error) {
      if (error is KomandaApiException) {
        rethrow;
      }

      throw KomandaApiException(
        'No fue posible conectar con el backend: $error',
      );
    }

    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = <String, dynamic>{
        'message': response.body,
      };
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = decoded is Map
          ? (
          decoded['message'] ??
              'Error HTTP ${response.statusCode}'
      ).toString()
          : 'Error HTTP ${response.statusCode}';

      throw KomandaApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  List<Map<String, dynamic>> _dataList(dynamic response) {
    dynamic raw = response;

    if (raw is Map) {
      // Formato principal del backend: {"ok": true, "data": [...]}
      raw = raw['data'] ??
          raw['items'] ??
          raw['products'] ??
          raw['orders'] ??
          raw['waiters'] ??
          raw['waiterCalls'] ??
          raw['waiter_calls'] ??
          raw['categories'] ??
          raw['tables'] ??
          raw['cashClosures'] ??
          raw['cash_closures'] ??
          raw['users'];

      // También acepta: {"data": {"items": [...]}}
      if (raw is Map) {
        raw = raw['items'] ?? raw['data'] ?? raw['rows'];
      }
    }

    if (raw is! List) return const <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _dataMap(dynamic response) {
    if (response is! Map) return <String, dynamic>{};

    final map = Map<String, dynamic>.from(response);
    final data = map['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return map;
  }

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _request(
      'POST',
      '/auth/login',
      body: {'username': username, 'password': password},
      authenticated: false,
    );
    final map = Map<String, dynamic>.from(response as Map);
    final value = (map['token'] ?? '').toString();
    if (value.isEmpty) throw const KomandaApiException('El backend no devolvió token.');
    setToken(value);
    return map;
  }


  @override
  Future<void> logout() async {
    await _request('POST', '/auth/logout');
    setToken(null);
  }

  @override
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _request('GET', '/auth/me');
    final map = Map<String, dynamic>.from(response as Map);
    final raw = map['user'] ?? map['data'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await _request(
      'PUT',
      '/auth/me',
      body: data,
    );
    final map = Map<String, dynamic>.from(response as Map);
    final raw = map['user'] ?? map['data'];
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
  }

  @override
  Future<bool> health() async {
    try {
      await _request('GET', '/health', authenticated: false);
      return true;
    } catch (_) {
      return false;
    }
  }


  @override
  Future<List<Map<String, dynamic>>> getUsers() async =>
      _dataList(await _request('GET', '/users'));

  @override
  Future<String> createUser(Map<String, dynamic> user) async {
    final response = Map<String, dynamic>.from(
      await _request('POST', '/users', body: user) as Map,
    );
    return (response['id'] ?? '').toString();
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> user) async {
    await _request('PUT', '/users/$id', body: user);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _request('DELETE', '/users/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> getProducts() async =>
      _dataList(await _request('GET', '/products'));

  @override
  Future<String> createProduct(Map<String, dynamic> product) async {
    final response = Map<String, dynamic>.from(
      await _request('POST', '/products', body: product) as Map,
    );
    return response['id'].toString();
  }

  @override
  Future<void> updateProduct(String remoteId, Map<String, dynamic> product) async {
    await _request('PUT', '/products/$remoteId', body: product);
  }

  @override
  Future<void> deleteProduct(String remoteId) async {
    await _request('DELETE', '/products/$remoteId');
  }

  @override
  Future<List<Map<String, dynamic>>> getOrders() async =>
      _dataList(await _request('GET', '/orders'));

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final response = await _request('POST', '/orders', body: order);
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> createManualTicket(double amount, double received) async {
    final response = await _request('POST', '/orders/manual-ticket', body: {
      'amount': amount, 'amountReceived': received, 'paymentMethod': 'cash',
    });
    return _dataMap(response);
  }

  @override
  Future<void> updateOrder(String remoteId, Map<String, dynamic> order) async {
    try {
      await _request('PUT', '/orders/$remoteId', body: order);
    } on KomandaApiException catch (error) {
      // Algunos backends de Komanda exponen la edición general como PATCH.
      if (error.statusCode == 404 || error.statusCode == 405) {
        await _request('PATCH', '/orders/$remoteId', body: order);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(String remoteId, String status) async {
    await _request('PATCH', '/orders/$remoteId/status', body: {'status': status});
  }

  @override
  Future<void> assignWaiter(String remoteOrderId, String waiterUserId) async {
    final orderId = remoteOrderId.trim();
    final userId = waiterUserId.trim();

    if (orderId.isEmpty) {
      throw const KomandaApiException(
        'El pedido no tiene un ID válido.',
      );
    }

    if (userId.isEmpty) {
      throw const KomandaApiException(
        'El mesero no tiene user_id vinculado.',
      );
    }

    // IMPORTANTE: el backend localiza al mesero por waiters.user_id.
    // Por compatibilidad mantenemos waiterId, pero su valor ES users.id.
    await _request(
      'PATCH',
      '/orders/$orderId/waiter',
      body: <String, dynamic>{
        'waiterId': userId,
        'userId': userId,
      },
    );
  }

  @override
  Future<void> payOrder(String remoteOrderId, Map<String, dynamic> payment) async {
    await _request('POST', '/orders/$remoteOrderId/payment', body: payment);
  }

  @override
  Future<List<Map<String, dynamic>>> getWaiters() async =>
      _dataList(await _request('GET', '/waiters'));

  @override
  Future<String> createWaiter(Map<String, dynamic> waiter) async {
    final response = Map<String, dynamic>.from(
      await _request('POST', '/waiters', body: waiter) as Map,
    );
    return response['id'].toString();
  }

  @override
  Future<void> updateWaiter(String remoteId, Map<String, dynamic> waiter) async {
    await _request('PUT', '/waiters/$remoteId', body: waiter);
  }

  @override Future<void> deleteWaiter(String remoteId) async => _request('DELETE','/waiters/$remoteId');

  @override Future<List<Map<String,dynamic>>> getComplements() async => _dataList(await _request('GET','/complements'));
  @override Future<String> createComplement(Map<String,dynamic> complement) async { final r=Map<String,dynamic>.from(await _request('POST','/complements',body:complement) as Map); return (r['id'] ?? '').toString(); }
  @override Future<void> updateComplement(String id,Map<String,dynamic> complement) async => _request('PUT','/complements/$id',body:complement);
  @override Future<void> deleteComplement(String id) async => _request('DELETE','/complements/$id');
  @override Future<List<Map<String,dynamic>>> getOptionCatalogs() async => _dataList(await _request('GET','/option-catalogs'));
  @override Future<String> createOptionCatalog(Map<String,dynamic> catalog) async { final r=Map<String,dynamic>.from(await _request('POST','/option-catalogs',body:catalog) as Map); return (r['id'] ?? ((r['data'] is Map) ? (r['data'] as Map)['id'] : null) ?? '').toString(); }
  @override Future<void> updateOptionCatalog(String id,Map<String,dynamic> catalog) async => _request('PUT','/option-catalogs/$id',body:catalog);
  @override Future<void> deleteOptionCatalog(String id) async => _request('DELETE','/option-catalogs/$id');
  @override Future<void> setProductAvailability(String id,bool available) async => _request('PUT','/availability/products/$id',body:{'available':available?1:0});
  @override Future<void> setComplementAvailability(String id,bool active) async => _request('PUT','/availability/complements/$id',body:{'active':active?1:0});
  @override Future<void> setOptionCatalogValueAvailability(String id,bool active) async => _request('PUT','/availability/options/$id',body:{'active':active?1:0});
  @override Future<List<Map<String,dynamic>>> getCategories() async => _dataList(await _request('GET','/categories'));
  @override Future<String> createCategory(Map<String,dynamic> category) async { final r=Map<String,dynamic>.from(await _request('POST','/categories',body:category) as Map); return (r['id'] ?? ((r['data'] is Map) ? (r['data'] as Map)['id'] : null) ?? '').toString(); }
  @override Future<void> updateCategory(String id,Map<String,dynamic> category) async => _request('PUT','/categories/$id',body:category);
  @override Future<void> deleteCategory(String id) async => _request('DELETE','/categories/$id');
  @override Future<List<Map<String,dynamic>>> getTables() async => _dataList(await _request('GET','/tables'));
  @override Future<String> createTable(Map<String,dynamic> table) async { final r=Map<String,dynamic>.from(await _request('POST','/tables',body:table) as Map); return (r['id'] ?? ((r['data'] is Map) ? (r['data'] as Map)['id'] : null) ?? '').toString(); }
  @override Future<void> updateTable(String id,Map<String,dynamic> table) async => _request('PUT','/tables/$id',body:table);
  @override Future<void> deleteTable(String id) async => _request('DELETE','/tables/$id');
  @override Future<List<Map<String,dynamic>>> getCashClosures() async => _dataList(await _request('GET','/cash-closures'));
  @override Future<Map<String,dynamic>> getFinanceSummary() async => _dataMap(await _request('GET','/finances/summary'));
  @override Future<List<Map<String,dynamic>>> getExpenses() async => _dataList(await _request('GET','/expenses'));
  @override Future<String> createExpense(Map<String,dynamic> expense) async { final r=_dataMap(await _request('POST','/expenses',body:expense)); return '${r['id']??''}'; }
  @override Future<List<Map<String,dynamic>>> getKitchenStations() async => _dataList(await _request('GET','/kitchen-stations'));
  @override Future<void> saveKitchenStation(String? id, Map<String, dynamic> station) async {
    await _request(id == null ? 'POST' : 'PUT',
      id == null ? '/kitchen-stations' : '/kitchen-stations/$id', body: station);
  }
  @override Future<void> deleteKitchenStation(String id) async =>
      _request('DELETE', '/kitchen-stations/$id');

  @override Future<String> createCashClose(Map<String,dynamic> close) async { final r=Map<String,dynamic>.from(await _request('POST','/cash-closures',body:close) as Map); return (r['id'] ?? ((r['data'] is Map) ? (r['data'] as Map)['id'] : null) ?? '').toString(); }

  @override
  Future<List<Map<String, dynamic>>> getWaiterCalls() async =>
      _dataList(await _request('GET', '/waiter-calls'));

  @override
  Future<String> createWaiterCall(Map<String, dynamic> call) async {
    final response = Map<String, dynamic>.from(
      await _request('POST', '/waiter-calls', body: call) as Map,
    );
    return response['id'].toString();
  }

  @override
  Future<void> updateWaiterCallStatus(String remoteId, String status) async {
    await _request(
      'PATCH',
      '/waiter-calls/$remoteId/status',
      body: {'status': status},
    );
  }

  @override
  Future<Map<String, dynamic>> getTicketConfig() async {
    final response = await _request('GET', '/ticket-settings');
    return _dataMap(response);
  }

  @override
  Future<void> saveTicketConfig(Map<String, dynamic> config) async {
    await _request('PUT', '/ticket-settings', body: config);
  }

  @override
  Future<String?> uploadTicketLogo(String base64Image) async {
    if (base64Image.trim().isEmpty) return null;
    final bytes = base64Decode(
      base64Image.contains(',') ? base64Image.split(',').last : base64Image,
    );
    final request = http.MultipartRequest(
      'POST',
      _uri('/ticket-settings/logo'),
    );
    if (_token?.isNotEmpty == true) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'logo',
        Uint8List.fromList(bytes),
        filename: 'restaurant_logo.png',
      ),
    );
    final streamed = await client.send(request).timeout(KomandaApiConfig.timeout);
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw KomandaApiException(
        (decoded['message'] ?? 'No se pudo subir el logo').toString(),
        statusCode: response.statusCode,
      );
    }
    return decoded['logoUrl']?.toString();
  }
}
