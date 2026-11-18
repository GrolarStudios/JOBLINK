import 'komanda_touch_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/printing/komanda_ticket_print_service.dart';
import '../../bloc/komanda_state.dart';
import '../../../core/utils/komanda_money.dart';
import '../../../domain/entities/komanda_order.dart';
import '../../bloc/komanda_bloc.dart';
import '../../bloc/komanda_event.dart';

Future<bool> showKomandaPaymentDialog({
  required BuildContext context,
  required KomandaOrder order,
}) async {
  String method = 'Efectivo';
  final isAdditionalPayment = order.paidAmount > 0;
  String tipMode = isAdditionalPayment ? order.tipMode : 'none';
  double percentage = isAdditionalPayment && order.tipPercentage > 0 ? order.tipPercentage : 10;
  final receivedController = TextEditingController(text: order.amountDue.toStringAsFixed(2));
  final manualTipController = TextEditingController(text: isAdditionalPayment && order.tipAmount > 0 ? order.tipAmount.toStringAsFixed(2) : '');

  double tipAmount() {
    if (isAdditionalPayment) return order.tipAmount;
    if (tipMode == 'percentage') return order.total * percentage / 100;
    if (tipMode == 'manual') {
      return double.tryParse(manualTipController.text.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  final result = await showDialog<_KomandaPaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: StatefulBuilder(
      builder: (context, setLocal) {
        final tip = tipAmount();
        final finalTotal = order.total + tip;
        final amountDue = (finalTotal - order.paidAmount).clamp(0, double.infinity).toDouble();

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: KomandaTheme.green.withOpacity(.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.point_of_sale_rounded, color: KomandaTheme.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cobrar pedido',
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              order.displayReference,
                              style: const TextStyle(
                                color: KomandaTheme.softText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isAdditionalPayment ? 'Nuevo total' : 'Cuenta', style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          komandaMoney(finalTotal),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  if (isAdditionalPayment) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KomandaTheme.orange.withOpacity(.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Ya pagado', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(komandaMoney(order.paidAmount)),
                        ]),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Diferencia por cobrar', style: TextStyle(fontWeight: FontWeight.w900)),
                          Text(komandaMoney(amountDue), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                        ]),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Método de pago',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Efectivo', 'Tarjeta', 'Transferencia']
                        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setLocal(() {
                      method = value ?? method;
                      if (method != 'Efectivo') {
                        receivedController.text = amountDue.toStringAsFixed(2);
                      }
                    }),
                  ),
                  if (!isAdditionalPayment) ...[
                  const Divider(height: 30),
                  const Text('Propina', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Sin propina'),
                        selected: tipMode == 'none',
                        onSelected: (_) => setLocal(() {
                          tipMode = 'none';
                          receivedController.text = order.total.toStringAsFixed(2);
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Porcentaje'),
                        selected: tipMode == 'percentage',
                        onSelected: (_) => setLocal(() {
                          tipMode = 'percentage';
                          receivedController.text = (order.total + tipAmount()).toStringAsFixed(2);
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Manual'),
                        selected: tipMode == 'manual',
                        onSelected: (_) => setLocal(() {
                          tipMode = 'manual';
                          receivedController.text = order.total.toStringAsFixed(2);
                        }),
                      ),
                    ],
                  ),
                  if (tipMode == 'percentage') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [10, 15, 20]
                          .map(
                            (value) => ChoiceChip(
                              label: Text('$value%'),
                              selected: percentage == value,
                              onSelected: (_) => setLocal(() {
                                percentage = value.toDouble();
                                receivedController.text =
                                    (order.total + tipAmount()).toStringAsFixed(2);
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (tipMode == 'manual') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: manualTipController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setLocal(() {
                        if (method == 'Efectivo') {
                          receivedController.text =
                              (order.total + tipAmount()).toStringAsFixed(2);
                        }
                      }),
                      decoration: InputDecoration(
                        suffixIcon: KomandaTouchKeyboard.button(context, manualTipController, numeric: true, onChanged: (_) => setLocal(() {
                          if (method == 'Efectivo') {
                            receivedController.text = (order.total + tipAmount()).toStringAsFixed(2);
                          }
                        })),
                        labelText: 'Monto de propina',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: KomandaTheme.green.withOpacity(.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: KomandaTheme.green.withOpacity(.16)),
                    ),
                    child: Column(
                      children: [
                        if (tip > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Propina'),
                              Text(komandaMoney(tip)),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a cobrar', style: TextStyle(fontWeight: FontWeight.w900)),
                            Text(
                              komandaMoney(amountDue),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: KomandaTheme.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: receivedController,
                    builder: (context, receivedValue, _) => method == 'Efectivo' ? Column(
                      children: [
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: KomandaTheme.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => KomandaTouchKeyboard.show(context, receivedController, numeric: true, onChanged: (_) => setLocal(() {})),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recibí', style: TextStyle(fontWeight: FontWeight.w900)),
                          Text(komandaMoney(double.tryParse(receivedValue.text.replaceAll(',', '.')) ?? 0),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: KomandaTheme.green)),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 10),
                    Builder(builder: (_) {
                      final received = double.tryParse(receivedValue.text.replaceAll(',', '.')) ?? 0;
                      final difference = received - amountDue;
                      final isExact = difference.abs() < 0.005;
                      final isOver = difference > 0;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: (isExact ? KomandaTheme.green : isOver ? KomandaTheme.purple : KomandaTheme.orange).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isExact ? 'Pago exacto' : isOver ? 'Cambio' : 'Falta por pagar',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              isExact ? komandaMoney(0) : komandaMoney(difference.abs()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isExact ? KomandaTheme.green : isOver ? KomandaTheme.purple : KomandaTheme.orange,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                    ) : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            final tip = tipAmount();
                            final total = order.total + tip;
                            final due = (total - order.paidAmount).clamp(0, double.infinity).toDouble();
                            final received = method == 'Efectivo'
                                ? (double.tryParse(receivedController.text.replaceAll(',', '.')) ?? 0)
                                : due;

                            if (tip < 0) return;
                            if (method == 'Efectivo' && received < due) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('El monto recibido es menor al total con propina.'),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              _KomandaPaymentResult(
                                method: method,
                                amountReceived: received,
                                tipAmount: tip,
                                tipMode: tipMode,
                                tipPercentage: tipMode == 'percentage' ? percentage : 0,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Confirmar pago'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    ),
  );

  receivedController.dispose();
  manualTipController.dispose();

  if (result == null || !context.mounted) return false;

  final bloc = context.read<KomandaBloc>();
  bloc.add(
        KomandaOrderPaid(
          orderId: order.id,
          method: result.method,
          amountReceived: result.amountReceived,
          tipAmount: result.tipAmount,
          tipMode: result.tipMode,
          tipPercentage: result.tipPercentage,
        ),
      );

  // Imprimir únicamente después de que la API confirme el cobro.
  // El mismo diálogo se usa en Pedidos, Cobros, Cortes y Meseros.
  try {
    final confirmed = await bloc.stream.firstWhere((state) {
      if (state.status == KomandaStatus.failure) return true;
      return state.status == KomandaStatus.ready &&
          state.orders.any((item) => item.id == order.id && item.isPaid);
    }).timeout(const Duration(seconds: 20));

    if (confirmed.status == KomandaStatus.failure) return false;
    final paidOrder = confirmed.orders.firstWhere((item) => item.id == order.id);
    await KomandaTicketPrintService.printOrder(
      paidOrder,
      confirmed.ticketConfig,
    );
    return true;
  } catch (_) {
    // Si no se confirma el guardado, no imprimir un ticket de pago.
    return false;
  }
}

class _KomandaPaymentResult {
  final String method;
  final double amountReceived;
  final double tipAmount;
  final String tipMode;
  final double tipPercentage;

  const _KomandaPaymentResult({
    required this.method,
    required this.amountReceived,
    required this.tipAmount,
    required this.tipMode,
    required this.tipPercentage,
  });
}
