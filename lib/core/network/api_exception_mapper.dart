import 'package:dio/dio.dart';

class ApiErrorState {
  final String message;
  final bool isConnectionError;
  final bool isServerError;

  const ApiErrorState({
    required this.message,
    this.isConnectionError = false,
    this.isServerError = false,
  });
}

class ApiExceptionMapper {
  ApiExceptionMapper._();

  static ApiErrorState fromDio(
    DioException e, {
    String defaultMessage = 'Ocurrió un problema al cargar la información.',
  }) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiErrorState(
        message: 'Sin conexión a internet o no se pudo conectar con el servidor.',
        isConnectionError: true,
      );
    }

    if (e.response != null) {
      return ApiErrorState(
        message: 'El servidor respondió con un error (${e.response?.statusCode ?? '-'}).',
        isServerError: true,
      );
    }

    return ApiErrorState(message: defaultMessage);
  }

  static String messageFromResponse(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;

    if (data is Map) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          fallback;
    }

    return fallback;
  }
}
