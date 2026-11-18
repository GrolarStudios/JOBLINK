import 'package:flutter/material.dart';

class AppUiMessages {
  const AppUiMessages._();

  static const String loadingTitle = 'Cargando información...';
  static const String loadingMessage =
      'Estamos consultando la información. El menú de acciones permanece disponible.';

  static const String loadFailed =
      'No pudimos cargar la información en este momento.';

  static const String connectionError =
      'No hay conexión a internet o la red está fallando. Revisa tu conexión e intenta nuevamente.';

  static const String serverError =
      'El servidor no respondió correctamente. Intenta actualizar nuevamente.';

  static const String unexpectedError =
      'Ocurrió un problema inesperado. Intenta actualizar nuevamente.';

  static const String emptyProducts =
      'No se encontraron productos para mostrar en este momento.';

  static const String emptyAuctions =
      'No se encontraron subastas para mostrar en este momento.';

  static const String retryButton = 'Actualizar';

  static String requestError({
    required bool isConnectionError,
    required bool isServerError,
    String? fallback,
  }) {
    if (isConnectionError) return connectionError;
    if (isServerError) return serverError;

    final value = fallback?.trim() ?? '';
    if (value.isNotEmpty) return value;

    return unexpectedError;
  }

  static SnackBar snack({
    required String message,
    Color backgroundColor = const Color(0xFF2563EB),
    Color foregroundColor = Colors.white,
  }) {
    return SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: TextStyle(color: foregroundColor),
      ),
    );
  }
}