import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/routes/route_names.dart';
import '../../../../domain/entities/komanda_order.dart';
import '../../../bloc/komanda_bloc.dart';
import '../../../bloc/komanda_event.dart';
import '../../../bloc/komanda_state.dart';
import '../../../shared/widgets/komanda_widgets.dart';

class KomandaNewOrderTablePage extends StatefulWidget {
  const KomandaNewOrderTablePage({super.key});

  @override
  State<KomandaNewOrderTablePage> createState() => _KomandaNewOrderTablePageState();
}

class _KomandaNewOrderTablePageState extends State<KomandaNewOrderTablePage> {
  String search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<KomandaBloc>().add(const KomandaRefreshed());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final query = search.trim().toLowerCase();
        final tables = state.tables.where((item) {
          if (!item.active) return false;
          final order = state.openOrderForTable(item.name);
          return query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              (order?.shortFolio.toLowerCase().contains(query) ?? false) ||
              (order?.waiterName.toLowerCase().contains(query) ?? false);
        }).toList();

        return KomandaPageShell(
          title: 'Nuevo pedido · Mesa',
          children: [
            const KCard(child: Text('Selecciona la mesa para iniciar el pedido.')),
            TextField(
              onChanged: (value) => setState(() => search = value),
              decoration: const InputDecoration(
                hintText: 'Buscar mesa, folio o mesero...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (tables.isEmpty)
              const KCard(child: Text('No hay mesas que coincidan con la búsqueda.'))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tables.map((item) {
                  final table = item.name;
                  final selected = state.selectedTable == table;
                  final order = state.openOrderForTable(table);
                  return SizedBox(
                    width: 170,
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(table, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(order == null ? 'Disponible' : 'Pedido #${order.shortFolio}', style: const TextStyle(fontSize: 11)),
                          if (order != null)
                            Text(
                              '${order.status.label} · ${order.waiterName.isEmpty ? 'Sin mesero' : order.waiterName}',
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) => context.read<KomandaBloc>().add(KomandaTableSelected(table)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 18),
            KPrimaryButton(
              text: 'Continuar a productos',
              onPressed: state.canContinueToProducts
                  ? () => Navigator.pushNamed(context, RouteNames.komandaNewOrderProducts)
                  : null,
            ),
          ],
        );
      },
    );
  }
}
