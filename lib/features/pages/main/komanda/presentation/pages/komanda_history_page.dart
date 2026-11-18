import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/routes/route_names.dart';
import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_order_sections.dart';
import '../../core/utils/komanda_money.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import 'komanda_detail_page.dart';

class KomandaHistoryPage extends StatefulWidget {
  const KomandaHistoryPage({super.key});

  @override
  State<KomandaHistoryPage> createState() => _KomandaHistoryPageState();
}

class _KomandaHistoryPageState extends State<KomandaHistoryPage> {
  int _page=0; static const _pageSize=50;
  String query = '';
  String filter = 'Todos';
  DateTime? selectedDate;


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final orders = state.orders.where((order) => (_isHistoryOrder(order)) && _matches(order)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final paidOrders = orders.where((order) => order.isPaid).toList();
        final sales = paidOrders.fold<double>(
          0,
          (sum, order) => sum + order.total + order.tipAmount,
        );
        final average = paidOrders.isEmpty ? 0.0 : sales / paidOrders.length;

        final _pages=(orders.length/_pageSize).ceil().clamp(1,999999); if(_page>=_pages)_page=_pages-1; final _visibleOrders=orders.skip(_page*_pageSize).take(_pageSize).toList();
        return KomandaPhoneFrame(
          child: Column(
            children: [
              const KomandaHeader(title: 'Historial de ventas'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar folio o nombre...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: KomandaTheme.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          selectedDate == null
                              ? 'Fecha'
                              : '${selectedDate!.day}/${selectedDate!.month}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: ['Todos', 'Hoy', 'Ayer', 'Esta semana', 'Este mes']
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: KChip(
                            text: value,
                            selected: filter == value,
                            onTap: () => setState(() {
                              filter = value;
                              selectedDate = null;
                            }),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      KomandaCard(
                        child: Row(
                          children: [
                            _MiniMetric(icon: Icons.attach_money, title: 'Ventas', value: komandaMoney(sales)),
                            const _MetricDivider(),
                            _MiniMetric(icon: Icons.receipt_long, title: 'Pedidos', value: '${orders.length}'),
                            const _MetricDivider(),
                            _MiniMetric(icon: Icons.bar_chart, title: 'Ticket promedio', value: komandaMoney(average)),
                          ],
                        ),
                      ),
                      KomandaCard(
                        padding: EdgeInsets.zero,
                        child: orders.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(30),
                                child: Center(child: Text('No hay ventas con estos filtros')),
                              )
                            : Column(
                                children: _visibleOrders.map((order) => _SaleRow(order: order)).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const BottomNavMock(index: -1),
            ],
          ),
        );
      },
    );
  }

  bool _isHistoryOrder(KomandaOrder order) {
    return order.isPaid ||
        order.status == KomandaOrderStatus.atTable ||
        order.status == KomandaOrderStatus.completed;
  }

  bool _matches(KomandaOrder order) {
    final q = query.toLowerCase().trim();
    if (q.isNotEmpty &&
        !order.id.toLowerCase().contains(q) &&
        !order.shortFolio.toLowerCase().contains(q) &&
        !order.table.toLowerCase().contains(q) &&
        !order.waiterName.toLowerCase().contains(q)) {
      return false;
    }

    final now = DateTime.now();
    final date = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
    final today = DateTime(now.year, now.month, now.day);

    if (selectedDate != null) {
      return date == DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
    }

    switch (filter) {
      case 'Hoy':
        return date == today;
      case 'Ayer':
        return date == today.subtract(const Duration(days: 1));
      case 'Esta semana':
        final start = today.subtract(Duration(days: today.weekday - 1));
        return !date.isBefore(start);
      case 'Este mes':
        return date.year == today.year && date.month == today.month;
      default:
        return true;
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        selectedDate = date;
        filter = 'Todos';
      });
    }
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _MiniMetric({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: KomandaTheme.purple.withOpacity(.10),
              child: Icon(icon, size: 21, color: KomandaTheme.purple),
            ),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w700, fontSize: 11)),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: KomandaTheme.text, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        color: KomandaTheme.border,
      );
}

class _SaleRow extends StatelessWidget {
  final KomandaOrder order;
  const _SaleRow({required this.order});

  @override
  Widget build(BuildContext context) {
    const color = KomandaTheme.green;
    final customer = order.customerName.trim();
    final sectionSummary = KomandaOrderSections.compactSummary(order.items);
    final secondaryText = customer.isEmpty
        ? '${order.orderType.label} · $sectionSummary'
        : '${order.orderType.label} · $customer · $sectionSummary';
    final date =
        '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
    final time =
        '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KomandaDetailPage(order: order)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ficha #${order.shortFolio}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: KomandaTheme.text,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              KChip(
                                text: order.isPaid ? 'Pagado' : 'Entregado',
                                color: KomandaTheme.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            secondaryText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: KomandaTheme.softText,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: KomandaTheme.softText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: KomandaTheme.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KomandaTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: KomandaTheme.softText,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                '$date · $time',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: KomandaTheme.softText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: KomandaTheme.softText,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            komandaMoney(order.total + order.tipAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: KomandaTheme.text,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: KomandaTheme.border),
      ],
    );
  }
}

String _statusLabel(KomandaOrderStatus status) {
  switch (status) {
    case KomandaOrderStatus.pending:
      return 'Pendiente';
    case KomandaOrderStatus.preparing:
      return 'Preparando';
    case KomandaOrderStatus.waiting:
      return 'Listo para entrega';
    case KomandaOrderStatus.delivering:
      return 'Llevando pedido';
    case KomandaOrderStatus.atTable:
      return 'Pedido en mesa';
    case KomandaOrderStatus.completed:
      return 'Mesa liberada';
    case KomandaOrderStatus.cancelled:
      return 'Cancelada';
  }
}
