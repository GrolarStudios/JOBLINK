import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/komanda_order.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_state.dart';
import '../../shared/widgets/komanda_widgets.dart';
import '../../shared/widgets/komanda_item_detail_view.dart';

class KomandaSalesHistoryPage extends StatefulWidget {
  const KomandaSalesHistoryPage({super.key});
  @override
  State<KomandaSalesHistoryPage> createState() => _KomandaSalesHistoryPageState();
}

class _KomandaSalesHistoryPageState extends State<KomandaSalesHistoryPage> {
  final searchController = TextEditingController();
  String period = 'Todos';
  int page = 0;
  static const int pageSize = 50;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    switch (period) {
      case 'Hoy':
        return !date.isBefore(startToday);
      case 'Semana':
        return !date.isBefore(startToday.subtract(const Duration(days: 7)));
      case 'Mes':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final query = searchController.text.trim().toLowerCase();
        final sales = state.orders.where((order) {
          final searchable = '${order.table} ${order.id} ${order.items.map((e) => e.name).join(' ')}'.toLowerCase();
          return order.status == KomandaOrderStatus.completed &&
              _matchesPeriod(order.createdAt) &&
              (query.isEmpty || searchable.contains(query));
        }).toList();
        final total = sales.fold<double>(0, (sum, order) => sum + order.total);
        final pages = sales.isEmpty ? 1 : ((sales.length + pageSize - 1) ~/ pageSize);
        if (page >= pages) page = pages - 1;
        final visibleSales = sales.skip(page * pageSize).take(pageSize).toList();

        return KomandaPageShell(
          title: 'Historial de ventas',
          children: [
            KMetricCard(label: 'Total filtrado', value: money(total), icon: Icons.attach_money),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar por mesa, folio o producto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['Todos', 'Hoy', 'Semana', 'Mes']
                  .map((value) => ChoiceChip(
                        label: Text(value),
                        selected: period == value,
                        onSelected: (_) => setState(() => period = value),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            if (sales.isEmpty) const KCard(child: Text('No hay ventas completadas con estos filtros.')),
            for (final order in visibleSales)
              KCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text('${order.table} · ${money(order.total)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('${order.totalItems} productos · ${formatDate(order.createdAt)}'),
                  children: [
                    for (final item in order.items)
                      KomandaItemDetailView(item: item, showPrice: true),
                    if (order.notes.isNotEmpty)
                      Align(alignment: Alignment.centerLeft, child: Text('Notas: ${order.notes}')),
                  ],
                ),
              ),
            if (sales.length > pageSize) Padding(padding: const EdgeInsets.only(top: 12), child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[IconButton(onPressed: page>0?()=>setState(()=>page--):null,icon:const Icon(Icons.chevron_left)),Text('Página ${page+1} de $pages · 50 por página',style:const TextStyle(fontWeight:FontWeight.w700)),IconButton(onPressed: page+1<pages?()=>setState(()=>page++):null,icon:const Icon(Icons.chevron_right))])),
          ],
        );
      },
    );
  }
}
