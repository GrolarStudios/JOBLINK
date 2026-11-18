import '../../../../../../../core/routes/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/komanda_state.dart';
import '../../bloc/komanda_bloc.dart';
import '../../shared/widgets/komanda_widgets.dart';

class KomandaDashboardPage extends StatelessWidget {
  const KomandaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) => KomandaPageShell(
        title: 'Komanda',
        children: [
          KMetricCard(label: 'Órdenes activas', value: '${state.pendingOrders}', icon: Icons.receipt_long),
          KMetricCard(label: 'Ventas terminadas', value: '${state.completedOrders}', icon: Icons.check_circle_outline),
          KMetricCard(label: 'Llamados pendientes', value: '${state.pendingCalls}', icon: Icons.notifications_active),
          KMetricCard(label: 'Total vendido', value: money(state.salesTotal), icon: Icons.payments),
          const SizedBox(height: 8),
          KPrimaryButton(
            text: 'Nuevo pedido',
            onPressed: () => Navigator.pushNamed(context, RouteNames.komandaNewOrderTable),
          ),
          const SizedBox(height: 10),
          KPrimaryButton(
            text: 'Órdenes chef',
            onPressed: () => Navigator.pushNamed(context, RouteNames.komandaChefOrders),
          ),
          const SizedBox(height: 10),
          KPrimaryButton(
            text: 'Historial de ventas',
            onPressed: () => Navigator.pushNamed(context, RouteNames.komandaHistory),
          ),
        ],
      ),
    );
  }
}
