import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../shared/widgets/komanda_payment_dialog.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_tables_admin_page.dart';

class KomandaTablesOverviewPage extends StatefulWidget {
  const KomandaTablesOverviewPage({super.key});

  @override
  State<KomandaTablesOverviewPage> createState() => _KomandaTablesOverviewPageState();
}

class _KomandaTablesOverviewPageState extends State<KomandaTablesOverviewPage> {
  String _search = '';

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
        final query = _search.trim().toLowerCase();
        final tables = state.tables.where((t) {
          if (!t.active) return false;
          final order = state.openOrderForTable(t.name);
          return query.isEmpty ||
              t.name.toLowerCase().contains(query) ||
              (order?.shortFolio.toLowerCase().contains(query) ?? false) ||
              (order?.waiterName.toLowerCase().contains(query) ?? false) ||
              (order?.status.label.toLowerCase().contains(query) ?? false);
        }).toList()..sort((a, b) {
          final re = RegExp(r'(\d+)');
          final na = int.tryParse(re.firstMatch(a.name)?.group(0) ?? '');
          final nb = int.tryParse(re.firstMatch(b.name)?.group(0) ?? '');
          if (na != null && nb != null) return na.compareTo(nb);
          return a.name.compareTo(b.name);
        });

        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(
                title: 'Mesas',
                subtitle: 'Vista general',
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              KomandaSearchField(
                hintText: 'Buscar folio o nombre',
                onChanged: (value) => setState(() => _search = value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KomandaTablesAdminPage()),
                      );
                      if (context.mounted) context.read<KomandaBloc>().add(const KomandaRefreshed());
                    },
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Administrar mesas'),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: KomandaTheme.purple.withOpacity(.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: KomandaTheme.purple.withOpacity(.18)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility_outlined, color: KomandaTheme.purple),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Esta pantalla es solo informativa. Para levantar un pedido usa “Nuevo pedido”.',
                                style: TextStyle(color: KomandaTheme.text, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tables.isEmpty)
                        const KomandaCard(child: Text('No hay mesas que coincidan con la búsqueda.'))
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tables.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.sizeOf(context).width < 390 ? 2 : 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: MediaQuery.sizeOf(context).width < 390 ? .58 : .68,
                          ),
                          itemBuilder: (context, index) {
                            final table = tables[index].name;
                            return _TableVisualCard(table: table, order: state.openOrderForTable(table));
                          },
                        ),
                    ],
                  ),
              ),
              const BottomNavMock(index: 1),
            ],
          ),
        );
      },
    );
  }
}

class _TableVisualCard extends StatelessWidget {
  final String table;
  final KomandaOrder? order;
  const _TableVisualCard({required this.table, required this.order});

  @override
  Widget build(BuildContext context) {
    final occupied = order != null;
    final color = occupied ? KomandaTheme.orange : KomandaTheme.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, color: color, size: 20),
          const SizedBox(height: 2),
          Text(table, maxLines: 1, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: KomandaTheme.text, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(occupied ? 'Ocupada' : 'Disponible', maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
          if (order != null) ...[
            const SizedBox(height: 1),
            Text('#${order!.shortFolio}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: KomandaTheme.softText, fontSize: 10, fontWeight: FontWeight.w700)),
            Text(order!.waiterName.isEmpty ? order!.status.label : order!.waiterName,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: KomandaTheme.softText, fontSize: 9)),
            SizedBox(
              height: 34,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 2)),
                onPressed: () => KomandaTicketPrintService.printOrder(
                  order!, context.read<KomandaBloc>().state.ticketConfig),
                icon: const Icon(Icons.print_outlined, size: 17),
                label: const Text('Cuenta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            if (!order!.isPaid)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text('Pendiente de pago',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            SizedBox(
              height: 34,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 3)),
                onPressed: () async {
                  if (!order!.isPaid) {
                    await showKomandaPaymentDialog(context: context, order: order!);
                  } else {
                    context.read<KomandaBloc>().add(KomandaOrderReleased(orderId: order!.id));
                  }
                },
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(order!.isPaid ? 'Liberar mesa' : 'Cobrar',
                  maxLines: 1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
