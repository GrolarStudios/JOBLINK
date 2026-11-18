import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_state.dart';
import '../shared/widgets/komanda_item_detail_view.dart';
import '../shared/widgets/komanda_order_sections_view.dart';
import '../shared/widgets/komanda_payment_dialog.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_cash_close_page.dart';
import 'komanda_public_order_status_page.dart';

class KomandaCheckoutPage extends StatefulWidget {
  const KomandaCheckoutPage({super.key});

  @override
  State<KomandaCheckoutPage> createState() => _KomandaCheckoutPageState();
}

class _KomandaCheckoutPageState extends State<KomandaCheckoutPage> {
  int _page=0; static const _pageSize=50;
  String search = '';
  String delivery = 'Todos';
  String paymentStatus = 'Pendientes';
  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final chargeableOrders = state.orders
            .where((order) => order.status != KomandaOrderStatus.cancelled)
            .toList();

        final query = search.trim().toLowerCase();
        final orders = chargeableOrders.where((order) {
          final matchesSearch = query.isEmpty ||
              order.shortFolio.toLowerCase().contains(query) ||
              order.table.toLowerCase().contains(query) ||
              order.waiterName.toLowerCase().contains(query) ||
              order.paymentMethod.toLowerCase().contains(query) ||
              order.customerName.toLowerCase().contains(query) ||
              order.customerPhone.toLowerCase().contains(query) ||
              order.deliveryAddress.toLowerCase().contains(query) ||
              order.items.any((item) => item.name.toLowerCase().contains(query));

          final matchesDelivery = delivery == 'Todos' ||
              (delivery == 'Para llevar' && order.isTakeaway) ||
              (delivery == 'Para aquí' && order.isDineIn) ||
              (delivery == 'Domicilio' && order.isDelivery);

          final matchesPayment = paymentStatus == 'Todos' ||
              (paymentStatus == 'Pendientes' && !order.isPaid) ||
              (paymentStatus == 'Pagados' && order.isPaid);

          return matchesSearch && matchesDelivery && matchesPayment;
        }).toList()
          ..sort((a, b) {
            if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
            return b.createdAt.compareTo(a.createdAt);
          });

        final totalCollected = orders.fold<double>(
          0,
          (sum, order) => sum + (order.isPaid ? order.total + order.tipAmount : 0),
        );

        final _pages=(orders.length/_pageSize).ceil().clamp(1,999999); if(_page>=_pages)_page=_pages-1; final _visibleOrders=orders.skip(_page*_pageSize).take(_pageSize).toList();
        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(
                title: 'Cobros',
                subtitle: 'Cobra desde que se genera el pedido',
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E8F1)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KomandaTheme.purple.withOpacity(.08),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.point_of_sale_rounded,
                                size: 19,
                                color: KomandaTheme.purple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pedidos para cobrar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${orders.length} pedidos · ${komandaMoney(totalCollected)} cobrado',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: KomandaTheme.softText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _CompactAction(
                              tooltip: 'Corte',
                              icon: Icons.calculate_outlined,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KomandaCashClosePage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _CompactAction(
                              tooltip: 'Pedidos',
                              icon: Icons.monitor_rounded,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KomandaPublicOrderStatusPage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _CompactAction(
                              tooltip: showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                              icon: showFilters
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.tune_rounded,
                              selected: showFilters,
                              onTap: () => setState(() => showFilters = !showFilters),
                            ),
                          ],
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        crossFadeState: showFilters
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (value) => setState(() => search = value),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Buscar ficha, cliente o producto',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFD),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE8E8F1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE8E8F1)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ['Pendientes', 'Pagados', 'Todos']
                                      .map(
                                        (value) => Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: KChip(
                                            text: value,
                                            selected: paymentStatus == value,
                                            onTap: () => setState(() => paymentStatus = value),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: ['Todos', 'Para aquí', 'Para llevar', 'Domicilio']
                                      .map(
                                        (value) => Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: KChip(
                                            text: value,
                                            selected: delivery == value,
                                            onTap: () => setState(() => delivery = value),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: orders.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay pedidos con estos filtros.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: KomandaTheme.softText),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        itemCount: _visibleOrders.length,
                        itemBuilder: (context, index) {
                          final order = _visibleOrders[index];
                          final paidAt = order.paidAt ?? order.createdAt;
                          final totalWithTip = order.total + order.tipAmount;

                          return KomandaCard(
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: order.isPaid ? const Color(0xFFEAF8EF) : const Color(0xFFFFF3E4),
                                    child: Icon(
                                      order.isPaid ? Icons.check_rounded : Icons.point_of_sale_rounded,
                                      color: order.isPaid ? KomandaTheme.green : KomandaTheme.orange,
                                    ),
                                  ),
                                  title: Text(
                                    order.orderType.label,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  subtitle: Text(
                                    'Ficha ${order.shortFolio} · ${order.status.label}\n'
                                    '${order.isPaid ? '${_dateTime(paidAt)} · ${order.paymentMethod.isEmpty ? 'Pagado' : order.paymentMethod}' : 'Pendiente de cobro'}',
                                  ),
                                  trailing: Text(
                                    komandaMoney(totalWithTip),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: order.isPaid ? KomandaTheme.green : KomandaTheme.orange,
                                    ),
                                  ),
                                ),
                                if (order.tipAmount > 0)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: KChip(
                                      text: 'Propina ${komandaMoney(order.tipAmount)}',
                                      color: KomandaTheme.green,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF8FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: KomandaOrderSectionsView(
                                    items: order.items,
                                    showPrice: false,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!order.isPaid)
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () => showKomandaPaymentDialog(
                                        context: context,
                                        order: order,
                                      ),
                                      icon: const Icon(Icons.point_of_sale_rounded),
                                      label: const Text('Cobrar ahora'),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => KomandaTicketPrintService.printOrder(
                                        order,
                                        state.ticketConfig,
                                      ),
                                      icon: const Icon(Icons.print_rounded),
                                      label: const Text('Reimprimir ticket'),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const BottomNavMock(index: 1),
            ],
          ),
        );
      },
    );
  }

  String _dateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _CompactAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const _CompactAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected
            ? KomandaTheme.purple.withOpacity(.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 19,
              color: selected ? KomandaTheme.purple : KomandaTheme.text,
            ),
          ),
        ),
      ),
    );
  }
}
