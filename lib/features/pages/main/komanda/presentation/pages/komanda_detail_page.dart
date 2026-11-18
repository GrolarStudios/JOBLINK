import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import '../shared/widgets/komanda_item_detail_view.dart';
import '../shared/widgets/komanda_order_sections_view.dart';

class KomandaDetailPage extends StatelessWidget {
  final KomandaOrder? order;

  const KomandaDetailPage({
    super.key,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final current = order == null
            ? (state.openOrders.isNotEmpty
                ? state.openOrders.first
                : (state.orders.isNotEmpty ? state.orders.first : null))
            : state.orders.where((item) => item.id == order!.id).firstOrNull ??
                order;

        if (current == null) {
          return const KomandaPhoneFrame(
            child: Column(
              children: [
                KomandaHeader(title: 'Detalle del pedido'),
                Expanded(
                  child: Center(
                    child: Text('No hay pedidos registrados.'),
                  ),
                ),
              ],
            ),
          );
        }

        final statusColor = current.isPaid
            ? KomandaTheme.green
            : _statusColor(current.status);

        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(
                title: 'Detalle del pedido',
                subtitle: _headerSubtitle(current),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      KomandaCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Color(0xFFF1EAFF),
                                  child: Icon(
                                    Icons.shopping_cart_outlined,
                                    color: KomandaTheme.purple,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        current.isDelivery
                                            ? 'Domicilio'
                                            : current.isTakeaway
                                                ? 'Para llevar'
                                                : 'Para aquí',
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: KomandaTheme.text,
                                        ),
                                      ),
                                      Text(
                                        '${current.totalItems} productos en total',
                                        style: const TextStyle(
                                          color: KomandaTheme.softText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    KChip(
                                      text: current.isPaid
                                          ? 'Pedido finalizado'
                                          : _statusLabel(current.status),
                                      color: statusColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _time(current.createdAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: KomandaTheme.softText,
                                      ),
                                    ),
                                    Text(
                                      _date(current.createdAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: KomandaTheme.softText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _InfoBox(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Folio',
                                  value: '#${current.shortFolio}',
                                ),
                                const SizedBox(width: 8),
                                _InfoBox(
                                  icon: Icons.attach_money,
                                  title: 'Total',
                                  value:
                                      komandaMoney(current.total + current.tipAmount),
                                  green: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    KomandaTicketPrintService.printOrder(
                                  current,
                                  state.ticketConfig,
                                ),
                                icon: const Icon(Icons.print_rounded),
                                label: Text(
                                  current.isPaid
                                      ? 'Imprimir ticket'
                                      : 'Imprimir cuenta',
                                ),
                              ),
                            ),
                            if (current.status == KomandaOrderStatus.preparing) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: state.status == KomandaStatus.saving ? null : () => context.read<KomandaBloc>().add(
                                        KomandaOrderStatusChanged(
                                          orderId: current.id,
                                          status: KomandaOrderStatus.waiting,
                                        ),
                                      ),
                                  icon: state.status == KomandaStatus.saving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.check_circle_outline_rounded),
                                  label: Text(state.status == KomandaStatus.saving ? 'Actualizando...' : 'Preparado'),
                                ),
                              ),
                            ],
                            if (current.status == KomandaOrderStatus.waiting) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: state.status == KomandaStatus.saving ? null : () => context.read<KomandaBloc>().add(
                                        KomandaOrderStatusChanged(
                                          orderId: current.id,
                                          status: KomandaOrderStatus.atTable,
                                        ),
                                      ),
                                  icon: state.status == KomandaStatus.saving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.delivery_dining_rounded),
                                  label: Text(state.status == KomandaStatus.saving ? 'Actualizando...' : 'Entregar pedido'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (current.isDelivery && current.deliveryAddress.trim().isNotEmpty)
                        KomandaCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF1EAFF),
                              child: Icon(Icons.home_outlined, color: KomandaTheme.purple),
                            ),
                            title: const Text(
                              'Domicilio',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              current.deliveryAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: KomandaTheme.text,
                              ),
                            ),
                          ),
                        ),
                      KomandaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productos distintos (${current.items.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: KomandaTheme.text,
                              ),
                            ),
                            KomandaOrderSectionsView(
                              items: current.items,
                              showPrice: true,
                            ),
                          ],
                        ),
                      ),
                      if (current.isPaid)
                        KomandaCard(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFEAF8EF),
                                  child: Icon(
                                    Icons.payments_outlined,
                                    color: KomandaTheme.green,
                                  ),
                                ),
                                title: const Text(
                                  'Método de pago',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                subtitle: Text(
                                  current.paymentMethod.trim().isEmpty
                                      ? 'Método no registrado'
                                      : current.paymentMethod,
                                ),
                                trailing: current.tipAmount > 0
                                    ? Text(
                                        'Propina\n${komandaMoney(current.tipAmount)}',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: KomandaTheme.green,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      KomandaCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF1EAFF),
                            child: Icon(
                              Icons.notes,
                              color: KomandaTheme.purple,
                            ),
                          ),
                          title: const Text(
                            'Notas del pedido',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle:
                              Text(current.notes.isEmpty ? 'Sin notas' : current.notes),
                        ),
                      ),
                      KomandaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Historial de estado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: KomandaTheme.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _TimeLine(
                              time: _time(current.createdAt),
                              title: 'Pedido recibido',
                              text: 'El pedido fue registrado.',
                              color: KomandaTheme.orange,
                            ),
                            _TimeLine(
                              time: current.preparingAt != null
                                  ? _time(current.preparingAt!)
                                  : current.status.index >=
                                          KomandaOrderStatus.preparing.index
                                      ? '✓'
                                      : '—',
                              title: 'En preparación',
                              text: current.status.index >=
                                      KomandaOrderStatus.preparing.index
                                  ? 'El pedido entró al flujo de cocina.'
                                  : 'Pendiente',
                              color: current.status.index >=
                                      KomandaOrderStatus.preparing.index
                                  ? KomandaTheme.orange
                                  : const Color(0xFFA4A8BA),
                            ),
                            if (current.readyAt != null)
                              _TimeLine(
                                time: _time(current.readyAt!),
                                title: 'Preparación terminada',
                                text: 'El pedido quedó pendiente de entrega.',
                                color: KomandaTheme.blue,
                              ),
                            if (current.deliveredAt != null)
                              _TimeLine(
                                time: _time(current.deliveredAt!),
                                title: 'Pedido entregado',
                                text: 'El pedido fue llevado al cliente.',
                                color: KomandaTheme.purple,
                              ),
                            if (current.isPaid)
                              _TimeLine(
                                time: current.paidAt == null
                                    ? '✓'
                                    : _time(current.paidAt!),
                                title: 'Pedido pagado',
                                text: current.paymentMethod.trim().isEmpty
                                    ? 'Pago registrado.'
                                    : 'Pago con ${current.paymentMethod}.',
                                color: KomandaTheme.green,
                              ),
                            if (current.releasedAt != null)
                              _TimeLine(
                                time: _time(current.releasedAt!),
                                title: 'Mesa liberada',
                                text: 'La atención de la mesa terminó.',
                                color: KomandaTheme.green,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _headerSubtitle(KomandaOrder order) {
    final preparing = order.preparingAt == null
        ? '—'
        : '${_date(order.preparingAt!)} ${_time(order.preparingAt!)}';
    final ready = order.readyAt == null
        ? '—'
        : '${_date(order.readyAt!)} ${_time(order.readyAt!)}';
    final delivered = order.deliveredAt == null
        ? '—'
        : '${_date(order.deliveredAt!)} ${_time(order.deliveredAt!)}';

    return '#${order.shortFolio}\n'
        'Preparando: $preparing  ·  Terminó: $ready  ·  Entregado: $delivered';
  }

  static String _time(DateTime value) =>
      '${value.toLocal().hour.toString().padLeft(2, '0')}:'
      '${value.toLocal().minute.toString().padLeft(2, '0')}';

  static String _date(DateTime value) =>
      '${value.toLocal().day.toString().padLeft(2, '0')}/'
      '${value.toLocal().month.toString().padLeft(2, '0')}/'
      '${value.toLocal().year}';

  static Color _statusColor(KomandaOrderStatus status) {
    if (status == KomandaOrderStatus.completed) return KomandaTheme.green;
    if (status == KomandaOrderStatus.cancelled) return KomandaTheme.red;
    if (status == KomandaOrderStatus.delivering) return KomandaTheme.orange;
    if (status == KomandaOrderStatus.waiting) return KomandaTheme.blue;
    return KomandaTheme.purple;
  }

  static String _statusLabel(KomandaOrderStatus status) {
    switch (status) {
      case KomandaOrderStatus.pending:
        return 'Pendiente';
      case KomandaOrderStatus.preparing:
        return 'Preparando';
      case KomandaOrderStatus.waiting:
        return 'Pendiente de entrega';
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
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool green;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: KomandaTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: KomandaTheme.softText),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: KomandaTheme.softText,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: green ? KomandaTheme.green : KomandaTheme.text,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  final String time;
  final String title;
  final String text;
  final Color color;

  const _TimeLine({
    required this.time,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  text,
                  style: const TextStyle(
                    color: KomandaTheme.softText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
