import 'package:dio/dio.dart';

/// Cliente HTTP centralizado para toda la app.
/// Aquí puedes poner baseUrl, headers, timeouts e interceptores.
class AppDioClient {
  const AppDioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        // TODO: Cambia esto por tu baseUrl real.
        // baseUrl: 'https://tu-api.com',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );

    return dio;
  }
}
