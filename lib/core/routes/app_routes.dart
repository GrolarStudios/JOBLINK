import 'package:flutter/material.dart';
import '../../features/pages/main/empleo/empleo_page.dart';

import '../../features/pages/main/komanda/komanda_feature.dart';
import 'route_names.dart';

class AppRoutes {
  const AppRoutes._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.empleo:
        return MaterialPageRoute(builder: (_) => const EmpleoPage(), settings: settings);
      case RouteNames.komanda:
      case RouteNames.komandaDashboard:
      case RouteNames.komandaNewOrderTable:
      case RouteNames.komandaNewOrderProducts:
      case RouteNames.komandaOrderSummary:
      case RouteNames.komandaChefOrders:
      case RouteNames.komandaWaiterCalls:
      case RouteNames.komandaHistory:
        return MaterialPageRoute(
          builder: (_) => KomandaFeature(
            initialRoute: settings.name,
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const KomandaFeature(
            initialRoute: RouteNames.komanda,
          ),
          settings: const RouteSettings(
            name: RouteNames.komanda,
          ),
        );
    }
  }
}