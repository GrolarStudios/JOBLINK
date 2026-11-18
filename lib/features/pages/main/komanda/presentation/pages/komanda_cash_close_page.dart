import '../shared/widgets/komanda_touch_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/komanda_theme.dart';
import '../../core/printing/komanda_ticket_print_service.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_order.dart';
import '../bloc/komanda_bloc.dart';
import '../bloc/komanda_event.dart';
import '../bloc/komanda_state.dart';
import '../widgets/komanda_widgets.dart';
import '../shared/widgets/komanda_payment_dialog.dart';

class KomandaCashClosePage extends StatefulWidget {
  const KomandaCashClosePage({super.key});

  @override
  State<KomandaCashClosePage> createState() => _KomandaCashClosePageState();
}

class _KomandaCashClosePageState extends State<KomandaCashClosePage> {
  DateTime selectedDate = DateTime.now();
  bool allowMultiple = false;
  final Map<int, TextEditingController> denominations = {
    for (final value in [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000])
      value: TextEditingController(text: '0'),
  };
  final notesController = TextEditingController();
  final openingCashController = TextEditingController(text: '0');
  bool showTop = false;
  bool useDenominations = false;
  final totalCashController = TextEditingController();
  bool showPendingDetails = false;
  final Map<String, bool> _expandedSections = {};

  Widget _section(String title, Widget child) {
    final expanded = _expandedSections[title] ?? true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerRight, child: TextButton.icon(
        onPressed: () => setState(() => _expandedSections[title] = !expanded),
        icon: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
        label: Text('${expanded ? 'Ocultar' : 'Mostrar'} $title'),
      )),
      if (expanded) child,
    ]);
  }


  @override
  void dispose() {
    for (final controller in denominations.values) { controller.dispose(); }
    notesController.dispose();
    openingCashController.dispose();
    totalCashController.dispose();
    super.dispose();
  }

  DateTime get shiftStart => DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  DateTime get shiftEnd => DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KomandaBloc, KomandaState>(
      builder: (context, state) {
        final allOrders = _ordersForShift(state.orders);
        final previous = state.cashClosures.where((c) => _sameDay(c.openedAt, selectedDate)).toList()
          ..sort((a,b) => b.closedAt.compareTo(a.closedAt));
        final orders = allowMultiple && previous.isNotEmpty
            ? allOrders.where((o) => o.createdAt.isAfter(previous.first.closedAt)).toList()
            : allOrders;
        final unpaid = orders.where((o) => !o.isPaid).toList();
        final unpaidTotal = unpaid.fold<double>(0, (sum,o) => sum + o.total);
        // Incluye pedidos preparados aunque aún estén pendientes de cobro.
        final prepared = orders.where((o) =>
          o.status == KomandaOrderStatus.waiting ||
          o.status == KomandaOrderStatus.delivering ||
          o.status == KomandaOrderStatus.atTable ||
          o.status == KomandaOrderStatus.completed).toList();
        final paid = orders.where((o) => o.isPaid).toList();
        final cash = _sumByMethod(paid, 'cash');
        final card = _sumByMethod(paid, 'card');
        final transfer = _sumByMethod(paid, 'transfer');
        final tips = paid.fold<double>(0, (sum, o) => sum + o.tipAmount);
        final sales = orders.fold<double>(0, (sum, o) => sum + o.total);
        final totalCollected = paid.fold<double>(0, (sum,o) => sum + o.total) + tips;
        final openingCash = double.tryParse(openingCashController.text.replaceAll(',', '')) ?? 0.0;
        final expectedCash = cash + openingCash;
        final countedCash = useDenominations
            ? denominations.entries.fold<double>(0.0, (sum, entry) => sum + entry.key * (int.tryParse(entry.value.text) ?? 0))
            : (double.tryParse(totalCashController.text.replaceAll(',', '')) ?? 0.0);
        final difference = countedCash - expectedCash;

        final existingClose = state.cashClosures.where((close) {
          return _sameDay(close.openedAt, selectedDate);
        }).toList();

        return KomandaPhoneFrame(
          child: Column(
            children: [
              KomandaHeader(
                title: 'Cobros y cortes',
                subtitle: 'Resumen, arqueo y cierre de caja',
                onLeadingTap: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    _topVisibilityControl(),
                    const SizedBox(height: 10),
                    _section('pedidos del día', KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Pedidos del día', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        Chip(label: Text('Preparados: ${prepared.length}')),
                        Chip(label: Text('Pagados: ${paid.length}')),
                        Chip(label: Text('Pendientes: ${unpaid.length}')),
                      ]),
                      if (prepared.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Pedidos preparados', style: TextStyle(fontWeight: FontWeight.w800)),
                        ...prepared.map((o) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text('Folio ${o.shortFolio}')),
                            Text(o.isPaid ? 'Pagado' : 'Pendiente de cobro',
                              style: TextStyle(color: o.isPaid ? const Color(0xFF16856C) : KomandaTheme.orange)),
                            const SizedBox(width: 10),
                            Text(_money(o.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                            if (!o.isPaid) ...[
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => showKomandaPaymentDialog(context: context, order: o),
                                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                                label: const Text('Cobrar'),
                              ),
                            ],
                          ]),
                        )),
                      ],
                    ]))),

                    if (showTop) ...[
                      const SizedBox(height: 10),
                      _section('periodo del corte', _selectorCard()),
                      const SizedBox(height: 12),
                      if (existingClose.isNotEmpty) _alreadyClosedBanner(existingClose.last),
                      _section('resumen de ventas', _summaryHeader(orders.length, sales)),
                      const SizedBox(height: 12),
                    ],
                    if (showTop) ...[
                    _section('indicadores', _kpiGrid(
                      sales: sales,
                      tips: tips,
                      cash: cash,
                      card: card,
                      transfer: transfer,
                    )),
                    const SizedBox(height: 12),
                    _section('desglose de cobros', _moneyBreakdown(cash, card, transfer, tips, totalCollected)),
                    const SizedBox(height: 12),
                    _section('estado de pedidos', KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Estado de pedidos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        Chip(avatar: const Icon(Icons.restaurant_menu_rounded, size: 18), label: Text('Preparados: ${prepared.length}')),
                        Chip(avatar: const Icon(Icons.check_circle_outline_rounded, size: 18), label: Text('Pagados: ${paid.length}')),
                        Chip(avatar: const Icon(Icons.pending_actions_rounded, size: 18), label: Text('Pendientes de pago: ${unpaid.length}')),
                      ]),
                      const SizedBox(height: 6),
                      const Text('Los preparados sin pagar se incluyen en ventas, pero no en efectivo cobrado.', style: TextStyle(fontSize: 12, color: KomandaTheme.softText)),
                    ]))),

                    ],
                    _section('pedidos por cobrar', KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: KomandaTheme.orange.withOpacity(.10), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.pending_actions_rounded, color: KomandaTheme.orange)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Por cobrar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          Text('${unpaid.length} pedidos pendientes', style: const TextStyle(color: KomandaTheme.softText)),
                        ])),
                        Text(_money(unpaidTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KomandaTheme.orange)),
                      ]),
                      if (unpaid.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(onPressed: () => setState(() => showPendingDetails = !showPendingDetails), icon: Icon(showPendingDetails ? Icons.expand_less : Icons.expand_more), label: Text(showPendingDetails ? 'Ocultar pedidos' : 'Ver pedidos pendientes')),
                        if (showPendingDetails) ...unpaid.map((o) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Expanded(child: Text('Folio ${o.shortFolio}', style: const TextStyle(fontWeight: FontWeight.w700))),
                            const Text('Sin pagar', style: TextStyle(color: KomandaTheme.orange)),
                            const SizedBox(width: 12),
                            Text(_money(o.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => showKomandaPaymentDialog(context: context, order: o),
                              icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                              label: const Text('Cobrar'),
                            ),
                          ]),
                        )),
                      ],
                    ]))),
                    const SizedBox(height: 12),
                    _section('fondo inicial de caja', KomandaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Fondo inicial de caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: openingCashController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(labelText: '¿Con cuánto dinero empezaste?', prefixText: '\$ ', suffixIcon: KomandaTouchKeyboard.button(context, openingCashController, numeric: true, onChanged: (_) { if (mounted) setState(() {}); })),
                      ),
                      const SizedBox(height: 8),
                      Text('Fondo inicial: ${_money(openingCash)}'),
                      Text('Efectivo generado: ${_money(cash)}'),
                      Text('Total que debes tener: ${_money(expectedCash)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ]))),
                    const SizedBox(height: 12),
                    _section('arqueo de caja', _cashAudit(expectedCash, countedCash, difference)),
                    const SizedBox(height: 12),
                    _section('notas', _notes()),
                    const SizedBox(height: 14),
                    Center(child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _saveButton(
                      state: state,
                      orders: orders,
                      cash: cash,
                      card: card,
                      transfer: transfer,
                      tips: tips,
                      expectedCash: expectedCash,
                      countedCash: countedCash,
                      difference: difference,
                      existingClose: existingClose.isNotEmpty,
                    ),
                        const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => KomandaTicketPrintService.printCashClose(
                          KomandaCashClose(
                            id: 'vista-previa-${DateTime.now().millisecondsSinceEpoch}',
                            openedAt: shiftStart,
                            closedAt: DateTime.now(),
                            cashTotal: cash,
                            cardTotal: card,
                            transferTotal: transfer,
                            tipsTotal: tips,
                            openingCash: double.tryParse(openingCashController.text.replaceAll(',', '')) ?? 0,
                            expectedTotal: expectedCash,
                            countedCash: countedCash,
                            difference: difference,
                            paidOrders: orders.where((o) => o.isPaid).length,
                            notes: notesController.text.trim(),
                          allowMultiple: allowMultiple,
                          ),
                          state.ticketConfig,
                        ),
                        icon: const Icon(Icons.print_rounded),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: const BorderSide(color: KomandaTheme.primary, width: 1.2),
                          foregroundColor: KomandaTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        label: const Text('Imprimir ticket del corte', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                      ]),
                    )),
                    const SizedBox(height: 18),
                    _section('historial de cortes', _history(state.cashClosures, state)),
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

  Widget _topVisibilityControl() {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => showTop = !showTop),
        icon: Icon(showTop ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
        label: Text(showTop ? 'Ocultar periodo y resumen' : 'Mostrar periodo y resumen'),
      ),
    );
  }

  Widget _selectorCard() {
    return KomandaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periodo del corte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Por defecto se realiza un corte por día completo.',
            style: TextStyle(
                color: KomandaTheme.softText, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KomandaTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: KomandaTheme.purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_date(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Permitir cortes adicionales', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Actívalo solo si necesitas dos o más cortes el mismo día.'),
            value: allowMultiple,
            onChanged: (value) => setState(() => allowMultiple = value),
          ),
        ],
      ),
    );
  }

  Widget _summaryHeader(int orders, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          KomandaTheme.purple.withOpacity(.10),
          KomandaTheme.blue.withOpacity(.05),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KomandaTheme.purple.withOpacity(.13)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.point_of_sale_rounded, color: KomandaTheme.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corte diario · ${_date(selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('$orders pedidos registrados',
                    style: const TextStyle(
                        color: KomandaTheme.softText,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(_money(total),
              style: const TextStyle(
                  fontSize: 20,
                  color: KomandaTheme.purple,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _kpiGrid({
    required double sales,
    required double tips,
    required double cash,
    required double card,
    required double transfer,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 800 ? 4 : 2;
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _kpi(width, 'Total vendido', sales, Icons.trending_up_rounded),
          _kpi(width, 'Propinas', tips, Icons.volunteer_activism_outlined),
          _kpi(width, 'Cobrado efectivo', cash, Icons.money_rounded),
          _kpi(width, 'Tarjeta y transferencia', card + transfer, Icons.credit_card_rounded),
        ],
      );
    });
  }

  Widget _kpi(double width, String label, double value, IconData icon) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KomandaTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: KomandaTheme.purple),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          color: KomandaTheme.softText,
                          fontWeight: FontWeight.w700)),
                  Text(_money(value),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyBreakdown(double cash, double card, double transfer, double tips,
      double total) {
    return KomandaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Desglose del turno',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _row('Efectivo', cash),
          _row('Tarjeta', card),
          _row('Transferencia', transfer),
          _row('Propinas', tips),
          const Divider(height: 22),
          _row('Total cobrado', total, strong: true),
        ],
      ),
    );
  }

  Widget _cashAudit(double expected, double counted, double difference) {
    final isBalanced = difference.abs() < 0.01;
    final differenceColor = isBalanced ? KomandaTheme.green : difference < 0 ? KomandaTheme.red : KomandaTheme.orange;
    return KomandaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Conteo de efectivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Selecciona cómo quieres contar el efectivo.', style: TextStyle(color: KomandaTheme.softText)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) => SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.edit_outlined), label: Text('Monto general')),
              ButtonSegment(value: true, icon: Icon(Icons.payments_outlined), label: Text('Monedas y billetes')),
            ],
            selected: {useDenominations},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() => useDenominations = value.first),
          ),
        )),
        const SizedBox(height: 14),
        if (!useDenominations)
          TextField(
            controller: totalCashController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: 'Efectivo contado',
              hintText: '0.00',
              prefixText: '\$ ',
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              suffixIcon: KomandaTouchKeyboard.button(context, totalCashController, numeric: true, onChanged: (_) => setState(() {})),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          )
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 5 : constraints.maxWidth >= 440 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: constraints.maxWidth < 350 ? 1.65 : 1.9,
              children: denominations.entries.map((entry) => TextField(
                controller: entry.value,
                onTap: () => entry.value.selection = TextSelection(baseOffset: 0, extentOffset: entry.value.text.length),
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '\$${entry.key}',
                  suffixIcon: KomandaTouchKeyboard.button(context, entry.value, numeric: true, onChanged: (_) => setState(() {})),
                  helperText: entry.key <= 10 ? 'Moneda' : 'Billete',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              )).toList(),
            );
          }),
        const SizedBox(height: 14),
        _row('Efectivo esperado', expected),
        _row('Efectivo contado', counted, strong: true),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: differenceColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: differenceColor.withOpacity(0.25))),
          child: Row(children: [
            Expanded(child: Text('Diferencia', style: TextStyle(fontWeight: FontWeight.w900, color: differenceColor))),
            Text(_money(difference), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: differenceColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _notes() {
    return KomandaCard(
      child: TextField(
        controller: notesController,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Observaciones del corte',
          suffixIcon: KomandaTouchKeyboard.button(context, notesController),
          hintText: 'Ej. retiro de efectivo, diferencia revisada, incidencia...',
          prefixIcon: Icon(Icons.notes_rounded),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _saveButton({
    required KomandaState state,
    required List<KomandaOrder> orders,
    required double cash,
    required double card,
    required double transfer,
    required double tips,
    required double expectedCash,
    required double countedCash,
    required double difference,
    required bool existingClose,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        onPressed: state.status == KomandaStatus.saving || (existingClose && !allowMultiple)
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Confirmar corte'),
                    content: Text(
                      'Se guardará el corte del ${_date(selectedDate)} a las ${_time(DateTime.now())}.\n\n'
                      'Tickets: ${orders.length}\n'
                      'Efectivo esperado: ${_money(expectedCash)}\n'
                      'Efectivo contado: ${_money(countedCash)}\n'
                      'Diferencia: ${_money(difference)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Guardar corte'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true || !mounted) return;

                context.read<KomandaBloc>().add(
                      KomandaCashCloseSaved(
                        KomandaCashClose(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          openedAt: shiftStart,
                          closedAt: DateTime.now(),
                          cashTotal: cash,
                          cardTotal: card,
                          transferTotal: transfer,
                          tipsTotal: tips,
                          openingCash: double.tryParse(openingCashController.text.replaceAll(',', '')) ?? 0,
                            expectedTotal: expectedCash,
                          countedCash: countedCash,
                          difference: difference,
                          paidOrders: orders.where((o) => o.isPaid).length,
                          notes: notesController.text.trim(),
                          allowMultiple: allowMultiple,
                        ),
                      ),
                    );
              },
        icon: state.status == KomandaStatus.saving
            ? const Text(
                'Actualizando...',
                style: TextStyle(fontWeight: FontWeight.w800),
              )
            : const Icon(Icons.lock_rounded),
        label: const Text('Cerrar y guardar corte'),
      ),
    );
  }

  Widget _history(List<KomandaCashClose> closes, KomandaState state) {
    final sorted = closes.where((c) => _sameDay(c.openedAt, selectedDate)).toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return KomandaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Historial de cortes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Text(_date(selectedDate), style: const TextStyle(color: KomandaTheme.softText, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        const Text('Un corte diario por defecto. Puedes habilitar cortes adicionales cuando sea necesario.', style: TextStyle(fontSize: 11, color: KomandaTheme.softText, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('No hay cortes guardados en esta fecha.', style: TextStyle(color: KomandaTheme.softText))))
        else
          ...sorted.map((close) {
            final turn = 'Corte';
            final color = close.difference.abs() < .01 ? KomandaTheme.green : KomandaTheme.orange;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: color.withOpacity(.10), child: Icon(Icons.receipt_long_rounded, color: color)),
              title: Text('$turn · Realizado a las ${_time(close.closedAt)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('${close.paidOrders} tickets · Diferencia ${_money(close.difference)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_money(close.cashTotal + close.cardTotal + close.transferTotal + close.tipsTotal), style: const TextStyle(fontWeight: FontWeight.w900)),
                IconButton(tooltip: 'Imprimir corte', onPressed: () => KomandaTicketPrintService.printCashClose(close, state.ticketConfig), icon: const Icon(Icons.print_outlined)),
              ]),
            );
          }),
      ]),
    );
  }

  String _time(DateTime d) {
    final x = d.toLocal();
    return '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
  }

  Widget _alreadyClosedBanner(KomandaCashClose close) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KomandaTheme.orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KomandaTheme.orange.withOpacity(.20)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: KomandaTheme.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ya existe un corte de este día. Activa «Permitir cortes adicionales» si necesitas realizar otro.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  List<KomandaOrder> _ordersForShift(List<KomandaOrder> all) {
    return all.where((order) =>
      order.status != KomandaOrderStatus.cancelled &&
      !order.createdAt.toLocal().isBefore(shiftStart) &&
      !order.createdAt.toLocal().isAfter(shiftEnd)
    ).toList()..sort((a,b) => a.createdAt.compareTo(b.createdAt));
  }

  double _sumByMethod(List<KomandaOrder> orders, String target) {
    return orders.where((o) => _method(o.paymentMethod) == target).fold<double>(
          0,
          (sum, o) => sum + o.total + o.tipAmount,
        );
  }

  String _method(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.contains('efect') || value == 'cash') return 'cash';
    if (value.contains('tarj') || value == 'card') return 'card';
    if (value.contains('transf') || value == 'transfer') return 'transfer';
    return value;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  double _parseMoney(String value) =>
      double.tryParse(value.trim().replaceAll(',', '')) ?? 0;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _money(num value) {
    final parts = value.abs().toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '${value < 0 ? '-\$' : '\$'}$integer.${parts[1]}';
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Widget _row(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                    color: strong ? KomandaTheme.text : KomandaTheme.softText)),
          ),
          Text(_money(value),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: strong ? 17 : 14,
                  color: strong ? KomandaTheme.purple : KomandaTheme.text)),
        ],
      ),
    );
  }
}
