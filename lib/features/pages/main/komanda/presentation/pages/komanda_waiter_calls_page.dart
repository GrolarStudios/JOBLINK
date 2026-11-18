import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/utils/komanda_money.dart';
import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/waiter_call.dart';
import '../../domain/entities/komanda_waiter.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import '../shared/widgets/komanda_item_detail_view.dart';
import '../shared/widgets/komanda_payment_dialog.dart';

class KomandaWaiterCallsPage extends StatefulWidget {
  const KomandaWaiterCallsPage({super.key});

  @override
  State<KomandaWaiterCallsPage> createState() =>
      _KomandaWaiterCallsPageState();
}

class _KomandaWaiterCallsPageState extends State<KomandaWaiterCallsPage> {
  bool history = false;
  String filter = 'Para aquí';
  String search = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final query = search.trim().toLowerCase();

        bool isActiveWaiterOrder(KomandaOrder order) {
          return order.status == KomandaOrderStatus.waiting ||
              order.status == KomandaOrderStatus.delivering ||
              order.status == KomandaOrderStatus.atTable;
        }

        // Entrega debe mostrar todos los pedidos que ya salieron de cocina.
        // Esto también recupera pedidos "Para llevar" creados antes de que
        // la asignación de mesero fuera obligatoria para imprimir.
        final activeWaiterOrders = state.orders
            .where((order) => isActiveWaiterOrder(order))
            .toList();

        final hereCount = activeWaiterOrders.where((order) => !order.isTakeaway).length;
        final takeawayCount = activeWaiterOrders.where((order) => order.isTakeaway).length;
        final urgentCount = activeWaiterOrders.where((order) => order.isUrgent).length;
        final pendingCallCount = state.waiterCalls
            .where((call) => call.status == WaiterCallStatus.pending)
            .length;
        final attentionCount = activeWaiterOrders.length + pendingCallCount;

        final deliveryOrders = state.orders.where((order) {
          final matchesDeliveryFilter = switch (filter) {
            'Para llevar' => order.isTakeaway,
            'Para aquí' => !order.isTakeaway,
            'Urgentes' => order.isUrgent,
            _ => true,
          };
          if (!matchesDeliveryFilter) return false;
          if (query.isNotEmpty &&
              !order.shortFolio.toLowerCase().contains(query) &&
              !order.table.toLowerCase().contains(query) &&
              !order.waiterName.toLowerCase().contains(query) &&
              !order.items.any((item) => item.name.toLowerCase().contains(query))) {
            return false;
          }

          if (history) {
            return order.status == KomandaOrderStatus.completed;
          }

          return isActiveWaiterOrder(order);
        }).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final calls = state.waiterCalls.where((call) {
          if (history != (call.status == WaiterCallStatus.done)) return false;
          if (query.isNotEmpty &&
              !call.table.toLowerCase().contains(query) &&
              !call.message.toLowerCase().contains(query) &&
              !call.waiterName.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(
                title: 'Llamados del mesero',
                menu: true,
                bell: true,
                bellCount: attentionCount,
                onTrailingTap: _createCall,
              ),
              KomandaSearchField(
                hintText: 'Buscar mesa, folio, mesero o llamado',
                onChanged: (value) => setState(() => search = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: KChip(
                        text: 'Por atender ($attentionCount)',
                        selected: !history,
                        onTap: () => setState(() => history = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KChip(
                        text: 'Historial',
                        color: KomandaTheme.softText,
                        selected: history,
                        onTap: () => setState(() => history = true),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Para aquí', 'Para llevar', 'Urgentes'].map((item) {
                    final count = item == 'Para aquí'
                        ? hereCount
                        : item == 'Para llevar'
                            ? takeawayCount
                            : urgentCount;
                    final icon = item == 'Para aquí'
                        ? Icons.table_restaurant_rounded
                        : item == 'Para llevar'
                            ? Icons.takeout_dining_rounded
                            : Icons.priority_high_rounded;

                    return ChoiceChip(
                      avatar: Icon(icon, size: 17),
                      label: Text('$item · $count'),
                      selected: filter == item,
                      onSelected: (_) => setState(() => filter = item),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      KomandaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Pedidos para entregar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: KomandaTheme.text,
                                    ),
                                  ),
                                ),
                                KChip(
                                  text: history ? '${deliveryOrders.length}' : '$attentionCount por atender',
                                  color: KomandaTheme.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              history
                                  ? 'Pedidos atendidos, mesas liberadas y propinas registradas.'
                                  : 'Aparecen cuando cocina termina el pedido y existe un mesero asignado.',
                              style: const TextStyle(
                                color: KomandaTheme.softText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (deliveryOrders.isEmpty)
                        const KomandaCard(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(
                              child: Text(
                                'No hay pedidos para entregar en esta sección.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: KomandaTheme.softText),
                              ),
                            ),
                          ),
                        )
                      else
                        ...deliveryOrders.map(
                          (order) => _DeliveryOrderCard(order: order),
                        ),
                      KomandaCard(
                        child: Text(
                          history ? 'Historial de llamados' : 'Llamados pendientes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: KomandaTheme.text,
                          ),
                        ),
                      ),
                      if (calls.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: Text('No hay llamados en esta sección'),
                          ),
                        )
                      else
                        ...calls.map((call) => _CallCard(call: call)),
                    ],
                  ),
              ),
              const BottomNavMock(index: -1),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createCall() async {
    final table = TextEditingController();
    final message = TextEditingController();
    WaiterCallType type = WaiterCallType.call;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Nuevo llamado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: table,
                decoration: const InputDecoration(labelText: 'Mesa'),
              ),
              TextField(
                controller: message,
                decoration: const InputDecoration(labelText: 'Mensaje'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WaiterCallType>(
                value: type,
                items: WaiterCallType.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item == WaiterCallType.urgent
                              ? 'Urgente'
                              : item == WaiterCallType.message
                                  ? 'Mensaje'
                                  : 'Llamado',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setLocal(() => type = value ?? type),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                context.read<KomandaBloc>().add(
                      KomandaWaiterCallCreated(
                        table: table.text,
                        message: message.text,
                        type: type,
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  final KomandaOrder order;

  const _DeliveryOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<KomandaBloc>().state.status == KomandaStatus.saving;
    final completed = order.status == KomandaOrderStatus.completed;
    final carrying = order.status == KomandaOrderStatus.delivering;
    final atTable = order.status == KomandaOrderStatus.atTable;
    final color = completed
        ? KomandaTheme.green
        : atTable
            ? KomandaTheme.purple
            : carrying
                ? KomandaTheme.orange
                : KomandaTheme.red;

    return KomandaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDetails(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(.12),
                    child: Icon(Icons.room_service_outlined, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.table, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('Mesero: ${order.waiterName.trim().isEmpty ? 'Sin mesero asignado' : order.waiterName}', style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w800)),
                        Text('${order.totalItems} productos · Pedido #${order.shortFolio}', style: const TextStyle(color: KomandaTheme.softText, fontSize: 12)),
                        if (completed)
                          Text(
                            order.tipAmount > 0
                                ? 'Propina: ${komandaMoney(order.tipAmount)}'
                                : 'Sin propina',
                            style: const TextStyle(color: KomandaTheme.green, fontWeight: FontWeight.w900),
                          ),
                      ],
                    ),
                  ),
                  KChip(
                    text: order.isTakeaway && atTable ? 'Entregado' : order.status.label,
                    color: color,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          if (!completed) ...[
            const Divider(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                onPressed: saving ? null : order.status == KomandaOrderStatus.waiting
                    ? () => _takeOrder(context)
                    : carrying
                        ? () => _markAtTable(context)
                        : atTable && !order.isPaid
                            ? () => _chargeOrder(context)
                            : atTable && order.isPaid
                                ? () => _releaseTable(context)
                                : null,
                icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(
                  order.status == KomandaOrderStatus.waiting
                      ? Icons.delivery_dining_outlined
                      : carrying
                          ? (order.isTakeaway
                              ? Icons.check_circle_outline_rounded
                              : Icons.table_restaurant_outlined)
                          : atTable && !order.isPaid
                              ? Icons.point_of_sale_rounded
                              : Icons.lock_open_outlined,
                ),
                label: FittedBox(fit: BoxFit.scaleDown, child: Text(
                  saving ? 'Actualizando...' : order.status == KomandaOrderStatus.waiting
                      ? (order.isTakeaway ? 'Entregar pedido' : 'Llevar pedido')
                      : carrying
                          ? (order.isTakeaway ? 'Entregado al cliente' : 'Pedido en mesa')
                          : atTable && !order.isPaid
                              ? (order.isTakeaway ? 'Cobrar pedido' : 'Cobrar')
                              : (order.isTakeaway ? 'Finalizar venta' : 'Liberar mesa'),
                )),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _takeOrder(BuildContext context) {
    context.read<KomandaBloc>().add(KomandaOrderStatusChanged(orderId: order.id, status: KomandaOrderStatus.delivering));
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(order.waiterName.trim().isEmpty ? 'Pedido en proceso de entrega a ${order.table}.' : '${order.waiterName} está llevando el pedido a ${order.table}.')));
  }

  Future<void> _markAtTable(BuildContext context) async {
    if (!order.isPaid) {
      final paid = await showKomandaPaymentDialog(context: context, order: order);
      if (!paid || !context.mounted) return;
    }
    context.read<KomandaBloc>().add(KomandaOrderStatusChanged(orderId: order.id, status: KomandaOrderStatus.atTable));
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
      SnackBar(
        content: Text(
          order.isTakeaway
              ? 'El pedido fue entregado. Ahora continúa con el cobro.'
              : 'El pedido ya está en ${order.table}. Ahora continúa con el cobro.',
        ),
      ),
    );
  }

  Future<void> _chargeOrder(BuildContext context) async {
    final paid = await showKomandaPaymentDialog(
      context: context,
      order: order,
    );

    if (!context.mounted || !paid) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            order.isTakeaway
                ? 'Pago registrado. Ya puedes finalizar la venta.'
                : 'Pago registrado. Ya puedes liberar ${order.table}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _releaseTable(BuildContext context) async {
    // La mesa se libera únicamente después del cobro. Además de evitar
    // inconsistencias de caja, esto impide llamar /payment con un método vacío.
    if (!order.isPaid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Primero cobra el pedido antes de liberar la mesa.'),
          ),
        );
      return;
    }

    // La propina y el método de pago se registran en Cobros. Para pedidos
    // antiguos que ya estén pagados pero no tengan método, no bloqueamos la
    // liberación: el repositorio tampoco reenviará /payment con valor vacío.
    context.read<KomandaBloc>().add(
          KomandaOrderReleased(
            orderId: order.id,
            tipAmount: order.tipAmount,
            tipMode: order.tipMode,
            tipPercentage: order.tipPercentage,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            order.tipAmount > 0
                ? (order.isTakeaway
                    ? 'Venta finalizada. Propina registrada: ${komandaMoney(order.tipAmount)}.'
                    : '${order.table} fue liberada. Propina registrada: ${komandaMoney(order.tipAmount)}.')
                : (order.isTakeaway ? 'Venta finalizada.' : '${order.table} fue liberada.'),
          ),
        ),
      );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${order.table} · Pedido #${order.shortFolio}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mesero asignado: ${order.waiterName.trim().isEmpty ? 'Sin mesero asignado' : order.waiterName}', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('Estado: ${order.status.label}', style: const TextStyle(fontWeight: FontWeight.w800, color: KomandaTheme.purple)),
                const SizedBox(height: 12),
                ...order.items.map((item) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8F7FC), borderRadius: BorderRadius.circular(12), border: Border.all(color: KomandaTheme.border)),
                  child: KomandaItemDetailView(item: item, padding: EdgeInsets.zero),
                )),
                if (order.notes.isNotEmpty) Text('Nota general: ${order.notes}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const Divider(height: 24),
                Text('Cuenta: ${komandaMoney(order.total)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                if (order.status == KomandaOrderStatus.completed) ...[
                  Text(order.tipAmount > 0 ? 'Propina: ${komandaMoney(order.tipAmount)}' : 'Propina: No dejó', style: const TextStyle(fontWeight: FontWeight.w900, color: KomandaTheme.green)),
                  if (order.tipMode == 'percentage') Text('Calculada con ${order.tipPercentage.toStringAsFixed(order.tipPercentage % 1 == 0 ? 0 : 1)}% de la cuenta'),
                  if (order.tipMode == 'manual') const Text('Capturada manualmente'),
                  Text('Total con propina: ${komandaMoney(order.total + order.tipAmount)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  final WaiterCall call;

  const _CallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final color = call.type == WaiterCallType.urgent
        ? KomandaTheme.red
        : call.type == WaiterCallType.message
            ? KomandaTheme.purple
            : KomandaTheme.orange;
    final elapsed = DateTime.now().difference(call.createdAt);
    final ago = elapsed.inMinutes < 1 ? 'Ahora' : 'Hace ${elapsed.inMinutes} min';

    return KomandaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(.12),
                child: Icon(Icons.notifications_none, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.table,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: KomandaTheme.text,
                      ),
                    ),
                    Text(
                      call.type == WaiterCallType.message
                          ? 'Mensaje del cliente'
                          : 'Solicitud de atención',
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
                  Text(
                    '${call.createdAt.hour.toString().padLeft(2, '0')}:${call.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: KomandaTheme.softText,
                    ),
                  ),
                  Text(
                    ago,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  KChip(
                    text: call.status == WaiterCallStatus.done
                        ? 'Atendido'
                        : call.type == WaiterCallType.urgent
                            ? 'Urgente'
                            : 'Pendiente',
                    color: call.status == WaiterCallStatus.done
                        ? KomandaTheme.green
                        : color,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (call.waiterName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Atendido por: ${call.waiterName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: KomandaTheme.green,
                ),
              ),
            ),
          Text(
            call.message,
            style: const TextStyle(
              color: KomandaTheme.softText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (call.status == WaiterCallStatus.pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mensaje enviado.')),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Enviar mensaje'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _complete(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Atender'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final waiters = context.read<KomandaBloc>().state.activeWaiters;
    KomandaWaiter? selected;

    final waiter = await showDialog<KomandaWaiter>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('¿Quién atendió el llamado?'),
          content: DropdownButtonFormField<KomandaWaiter>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Mesero'),
            items: waiters
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setLocal(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(dialogContext, selected),
              child: const Text('Marcar atendido'),
            ),
          ],
        ),
      ),
    );

    if (waiter == null || !context.mounted) return;
    context
        .read<KomandaBloc>()
        .add(KomandaWaiterCallCompleted(call.id, waiter: waiter));
  }
}
