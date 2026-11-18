import 'package:flutter/material.dart';
import '../../utils/colors/gs_colors.dart';

class AppTableStateView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onRetry;
  final bool loading;

  const AppTableStateView({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onRetry,
    this.loading = false,
  });

  factory AppTableStateView.loading({
    String title = 'Cargando productos...',
    String message = 'Espera un momento mientras se consulta la información.',
  }) {
    return AppTableStateView(
      loading: true,
      icon: Icons.hourglass_empty_rounded,
      iconColor: GSColors.primaryLight,
      title: title,
      message: message,
      buttonText: '',
      onRetry: () {},
    );
  }

  factory AppTableStateView.error({
    required String message,
    required VoidCallback onRetry,
    bool isConnectionError = false,
    bool isServerError = false,
  }) {
    IconData icon = Icons.error_outline;
    Color iconColor = Colors.red;
    String title = 'Ocurrió un error';

    if (isConnectionError) {
      icon = Icons.wifi_off_rounded;
      iconColor = Colors.orange;
      title = 'Sin conexión';
    } else if (isServerError) {
      icon = Icons.cloud_off_rounded;
      iconColor = Colors.redAccent;
      title = 'Problema con el servidor';
    }

    return AppTableStateView(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      buttonText: 'Intentar nuevamente',
      onRetry: onRetry,
    );
  }

  factory AppTableStateView.empty({
    required String message,
    required VoidCallback onRetry,
    String title = 'No hay productos disponibles',
    String buttonText = 'Actualizar',
  }) {
    return AppTableStateView(
      icon: Icons.inventory_2_outlined,
      iconColor: GSColors.primaryLight.withOpacity(0.85),
      title: title,
      message: message,
      buttonText: buttonText,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando productos...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: GSColors.onSurfaceLight,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Espera un momento mientras se consulta la información.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: GSColors.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GSColors.primaryLight,
                  foregroundColor: GSColors.onPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
