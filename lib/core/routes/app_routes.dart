import 'package:flutter/material.dart';
import '../../features/pages/main/empleo/empleo_page.dart';

/// Joblink es una aplicación independiente: ninguna ruta abre Komanda.
class AppRoutes {
  const AppRoutes._();
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const EmpleoPage(),
      settings: const RouteSettings(name: '/empleo'),
    );
  }
}
