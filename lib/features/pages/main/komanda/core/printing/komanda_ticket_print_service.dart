import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_cash_close.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../utils/komanda_item_detail_formatter.dart';
import '../utils/komanda_order_sections.dart';
import '../utils/komanda_money.dart';

enum KomandaTicketPrintScope { all, tortas, tacos }

bool _hideDetailLabel(String label) {
  final value = label.trim().toLowerCase();
  return value == 'detalle' ||
      value == 'detalles' ||
      value == 'carnes' ||
      value == 'carne' ||
      value == 'tipo de carne' ||
      value == 'tipo';
}


List<KomandaDetailLine> _compactTicketDetails(KomandaOrderItem item) {
  final source = KomandaItemDetailFormatter.lines(item.specifications)
      .where((line) {
        final label = line.label.trim().toLowerCase();
        final value = line.value.trim().toLowerCase();
        if (label == 'plato' || RegExp(r'^plato\s+\d+$').hasMatch(value)) return false;
        final isChicharron = item.category.toLowerCase().contains('chicharr') ||
            item.name.toLowerCase().contains('chicharr');
        if (isChicharron && label.contains('importe carne')) return false;
        return true;
      })
      .toList();

  if (source.isEmpty) return const <KomandaDetailLine>[];

  // Paquetes: cada encabezado Detalle (Torta/Taco/2× Taco) absorbe sus
  // rellenos/carnes en una sola línea compacta.
  if (source.any((line) => line.label.trim().toLowerCase() == 'detalle')) {
    final result = <KomandaDetailLine>[];
    String? title;
    final values = <String>[];

    void flush() {
      if (title == null) return;
      result.add(KomandaDetailLine(title!, values.join(', ')));
      values.clear();
    }

    for (final line in source) {
      if (line.label.trim().toLowerCase() == 'detalle') {
        flush();
        title = line.value.trim();
        continue;
      }
      for (final raw in line.value.split(',')) {
        final value = raw.trim();
        if (value.isNotEmpty && !values.contains(value)) values.add(value);
      }
    }
    flush();
    return result;
  }

  final category = item.category.trim().toLowerCase();
  final name = item.name.trim().toLowerCase();
  final isTaco = category.contains('taco') || name.startsWith('taco');
  final isTorta = category.contains('torta') || name.startsWith('torta');
  if (isTaco || isTorta) {
    final values = <String>[];
    final others = <KomandaDetailLine>[];
    for (final line in source) {
      final label = line.label.trim().toLowerCase();
      final isFoodOption = label.startsWith('relleno') ||
          label.startsWith('carne') ||
          label.contains('tipo de carne');
      if (!isFoodOption) {
        others.add(line);
        continue;
      }
      for (final raw in line.value.split(',')) {
        final value = raw.trim();
        if (value.isNotEmpty && !values.contains(value)) values.add(value);
      }
    }
    final result = <KomandaDetailLine>[];
    if (values.isNotEmpty) {
      // En productos normales el nombre ya aparece arriba como "1 x Torta"
      // o "1 x Taco Blando". Debajo mostramos únicamente lo que lleva.
      result.add(KomandaDetailLine(values.join(', '), ''));
    }
    result.addAll(others);
    return result;
  }

  return source;
}

class KomandaTicketPrintService {
  const KomandaTicketPrintService._();

  static const double _businessFontSize = 20;
  static const double _bodyFontSize = 13.5;
  static const double _itemFontSize = 13.5;
  static const double _detailFontSize = 11.5;

  static Future<void> printOrder(
    KomandaOrder order,
    KomandaTicketConfig config, {
    KomandaTicketPrintScope scope = KomandaTicketPrintScope.all,
  }) async {
    final doc = pw.Document();
    pw.MemoryImage? logo;

    try {
      if (config.logoBase64.trim().isNotEmpty) {
        logo = pw.MemoryImage(
          Uint8List.fromList(base64Decode(config.logoBase64)),
        );
      }
    } catch (_) {}

    final filteredItems = _itemsForScope(order.items, scope);
    final isPartial = scope != KomandaTicketPrintScope.all;
    final double scale = config.fontScale.clamp(.80, 1.50).toDouble();
    final businessSize = _businessFontSize * scale;
    final bodySize = _bodyFontSize * scale;
    final itemSize = _itemFontSize * scale;
    final detailSize = _detailFontSize * scale;
    final bodyWeight = config.fontWeight >= 700 ? pw.FontWeight.bold : pw.FontWeight.normal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, _ticketHeightMm(filteredItems, config) * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.fromLTRB(7, 2, 7, 2),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            if (logo != null)
              pw.Center(
                child: pw.Image(logo, height: 55, fit: pw.BoxFit.contain),
              )
            else
              pw.Center(
                child: pw.Container(
                  width: 42,
                  height: 42,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(width: 1.2),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'K',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            pw.SizedBox(height: 2),
            pw.Text(
              config.businessName.trim().isEmpty
                  ? 'Mi restaurante'
                  : config.businessName.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: businessSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (config.address.trim().isNotEmpty)
              pw.Text(config.address, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
            if (config.phone.trim().isNotEmpty)
              pw.Text(config.phone, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
            pw.Divider(),
            pw.Text('TIPO DE SERVICIO: ${order.isDelivery ? 'DOMICILIO' : order.isTakeaway ? 'PARA LLEVAR' : 'PARA AQUÍ'}', style: pw.TextStyle(fontSize: bodySize, fontWeight: pw.FontWeight.bold)),
            if (!order.isDelivery && !order.isTakeaway && order.table.trim().isNotEmpty)
              pw.Text('MESA: ${order.table.trim()}', style: pw.TextStyle(fontSize: bodySize, fontWeight: pw.FontWeight.bold)),
            if (order.isDelivery) ...[
              pw.Text('DATOS DE ENTREGA', style: pw.TextStyle(fontSize: bodySize, fontWeight: pw.FontWeight.bold)),
              if (order.customerName.trim().isNotEmpty) pw.Text('Cliente: ${order.customerName}', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
              if (order.customerPhone.trim().isNotEmpty) pw.Text('Tel: ${order.customerPhone}', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
              if (order.deliveryAddress.trim().isNotEmpty) pw.Text('Domicilio: ${order.deliveryAddress}', style: pw.TextStyle(fontSize: bodySize, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
            ],
            if (config.showFolio) pw.Text('Ficha: ${order.shortFolio}', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
            if (config.showWaiter && order.waiterName.trim().isNotEmpty)
              pw.Text('Mesero: ${order.waiterName}', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
            if (config.showDate)
              pw.Text(
                'Fecha: ${_dateTime(order.createdAt.toLocal())}',
                style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight),
              ),
            pw.Divider(),
            if (isPartial) ...[
              pw.Center(
                child: pw.Text(
                  scope == KomandaTicketPrintScope.tortas ? 'SOLO TORTAS' : 'SOLO TACOS',
                  style: pw.TextStyle(fontSize: itemSize, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 2),
            ],
            ..._itemWidgetsBySectionAndPlate(
              filteredItems,
              config,
              itemSize: itemSize,
              detailSize: detailSize,
              bodyWeight: bodyWeight,
            ),
            if (!isPartial) ...[
            pw.Divider(),
            if (order.isDelivery)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SUBTOTAL',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: bodySize),
                  ),
                  pw.Text(komandaMoney(order.itemsTotal), style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
                ],
              ),
            if (order.isDelivery && order.deliveryFee > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ENVÍO DOMICILIO', style: pw.TextStyle(fontSize: detailSize, fontWeight: bodyWeight)),
                  pw.Text(komandaMoney(order.deliveryFee), style: pw.TextStyle(fontSize: detailSize, fontWeight: bodyWeight)),
                ],
              ),
            if (config.showTip && order.tipAmount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PROPINA', style: pw.TextStyle(fontSize: detailSize, fontWeight: bodyWeight)),
                  pw.Text(komandaMoney(order.tipAmount), style: pw.TextStyle(fontSize: detailSize, fontWeight: bodyWeight)),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: bodySize),
                ),
                pw.Text(
                  komandaMoney(order.total + order.tipAmount),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: bodySize),
                ),
              ],
            ),
            // Comprobante del cliente: mostrar el efectivo recibido y el cambio,
            // incluso cuando el cambio sea cero. No se imprime en tickets parciales.
            if (order.isPaid) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RECIBÍ', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
                  pw.Text(komandaMoney(order.amountReceived), style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('CAMBIO', style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
                  pw.Text(komandaMoney(order.changeAmount), style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
                ],
              ),
            ],
            ],
            pw.SizedBox(height: 1.5),
            if (config.footer.trim().isNotEmpty)
              pw.Text(config.footer, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: bodySize, fontWeight: bodyWeight)),
            // Avance de papel al terminar el ticket de cliente.
            pw.SizedBox(height: 12 * PdfPageFormat.mm),
          ],
        ),
      ),
    );

    final suffix = scope == KomandaTicketPrintScope.tortas
        ? '_tortas'
        : scope == KomandaTicketPrintScope.tacos
            ? '_tacos'
            : '';
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'ticket_${order.shortFolio}$suffix.pdf',
    );
  }

  // El rollo de 80 mm necesita una altura acorde al contenido: una hoja
  // excesivamente larga genera espacio vacío al imprimir desde la PWA.
  // Se reserva margen para encabezado, totales, logo y líneas de detalle.
  static double _ticketHeightMm(List<KomandaOrderItem> items, KomandaTicketConfig config) {
    final detailLines = items.fold<int>(0, (sum, item) =>
        sum + _compactTicketDetails(item).length);
    final groups = KomandaOrderSections.byPlate(items).length;
    final estimated = 117.0 + items.length * 14.0 + detailLines * 8.0 + groups * 10.0 +
        (config.footer.trim().isEmpty ? 0.0 : 12.0) +
        (config.logoBase64.trim().isEmpty ? 0.0 : 12.0);
    return estimated.clamp(150.0, 1800.0).toDouble();
  }

  static List<KomandaOrderItem> _itemsForScope(
    List<KomandaOrderItem> items,
    KomandaTicketPrintScope scope,
  ) {
    switch (scope) {
      case KomandaTicketPrintScope.tortas:
        return KomandaOrderSections.itemsFor(items, KomandaOrderSection.tortas);
      case KomandaTicketPrintScope.tacos:
        return KomandaOrderSections.itemsFor(items, KomandaOrderSection.tacos);
      case KomandaTicketPrintScope.all:
        return items;
    }
  }

  static List<pw.Widget> _itemWidgetsBySectionAndPlate(
    List<KomandaOrderItem> items,
    KomandaTicketConfig config, {
    required double itemSize,
    required double detailSize,
    required pw.FontWeight bodyWeight,
  }) {
    final widgets = <pw.Widget>[];

    // El plato es el agrupador principal del ticket. Así "PLATO 1" se imprime
    // una sola vez aunque dentro tenga tacos, tortas o varios productos.
    final plates = KomandaOrderSections.byPlate(items);
    for (final group in plates.entries) {
      widgets.add(pw.SizedBox(height: 2));
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 1.2),
              bottom: pw.BorderSide(width: 1.2),
            ),
          ),
          child: pw.Text(
            (group.key.toLowerCase().startsWith('plato ') ? '${config.plateLabel} ${group.key.substring(6)}' : group.key).toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: itemSize + 2,
            ),
          ),
        ),
      );

      for (final item in group.value) {
        widgets.add(pw.SizedBox(height: 1.5));
        widgets.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${item.quantity} x ${item.name}',
                  style: pw.TextStyle(fontSize: itemSize, fontWeight: bodyWeight),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                komandaMoney(item.total),
                style: pw.TextStyle(fontSize: itemSize, fontWeight: bodyWeight),
              ),
            ],
          ),
        );

        if (config.showItemSpecifications && item.specifications.isNotEmpty) {
          final lines = _compactTicketDetails(item);
          if (lines.isNotEmpty) {
            final isPackage = item.specifications.any(
              (spec) => spec.contains(' · ') || spec.startsWith('Paquete · '),
            );
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: lines.map((line) {
                    final hasValue = line.value.trim().isNotEmpty;
                    final normalIngredientLine = !isPackage && !hasValue;
                    return pw.RichText(
                      text: pw.TextSpan(children: [
                        pw.TextSpan(
                          text: hasValue ? '${line.label}: ' : line.label,
                          style: pw.TextStyle(
                            fontSize: normalIngredientLine ? detailSize + 1.5 : detailSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (hasValue)
                          pw.TextSpan(
                            text: line.value,
                            style: pw.TextStyle(
                              fontSize: detailSize,
                              fontWeight: isPackage ? bodyWeight : pw.FontWeight.bold,
                            ),
                          ),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            );
          }
        }
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        pw.Center(
          child: pw.Text(
            'Sin productos en esta sección',
            style: pw.TextStyle(fontSize: itemSize, fontWeight: bodyWeight),
          ),
        ),
      );
    }

    return widgets;
  }

  static int _plateNumber(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return int.tryParse(match?.group(1) ?? '') ?? 9999;
  }

  static String _dateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> printCashClose(
    KomandaCashClose close,
    KomandaTicketConfig config,
  ) async {
    final doc = pw.Document();
    pw.MemoryImage? logo;
    try {
      if (config.logoBase64.trim().isNotEmpty) {
        logo = pw.MemoryImage(Uint8List.fromList(base64Decode(config.logoBase64)));
      }
    } catch (_) {}
    String money(num v) => komandaMoney(v);
    final total = close.cashTotal + close.cardTotal + close.transferTotal + close.tipsTotal;
    final shift = close.openedAt.hour < 15 ? 'Mañana' : 'Tarde';
    pw.Widget row(String label, String value, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.fromLTRB(9, 8, 9, 22),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        if (logo != null) pw.Center(child: pw.Image(logo, height: 52, fit: pw.BoxFit.contain)),
        pw.Text(config.businessName.trim().isEmpty ? 'Mi restaurante' : config.businessName.trim(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        if (config.address.trim().isNotEmpty) pw.Text(config.address, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
        if (config.phone.trim().isNotEmpty) pw.Text(config.phone, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
        pw.Divider(),
        pw.Text('CORTE DE CAJA', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.Text('$shift · ${_dateTime(close.closedAt.toLocal())}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
        pw.Divider(),
        row('Tickets cobrados', '${close.paidOrders}'),
        row('Efectivo', money(close.cashTotal)),
        row('Tarjeta', money(close.cardTotal)),
        row('Transferencia', money(close.transferTotal)),
        row('Propinas', money(close.tipsTotal)),
        pw.Divider(),
        row('TOTAL', money(total), bold: true),
        pw.SizedBox(height: 6),
        row('Fondo inicial', money(close.openingCash)),
        row('Efectivo generado', money(close.cashTotal)),
        row('Efectivo esperado', money(close.expectedTotal)),
        row('Efectivo contado', money(close.countedCash)),
        row('Diferencia', money(close.difference), bold: true),
        if (close.notes.trim().isNotEmpty) ...[pw.Divider(), pw.Text('Notas:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)), pw.Text(close.notes, style: const pw.TextStyle(fontSize: 10))],
        pw.SizedBox(height: 12),
        pw.Text('Corte generado por Komanda', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: 'corte-${close.id}.pdf');
  }

  static Future<void> printPerformanceSummary({
    required DateTime from, required DateTime to, required double total,
    required int tickets, required double average, required int pieces,
    required List<String> dayNames, required List<double> dayTotals,
    required List<int> dayTickets, required List<int> dayPieces,
  }) async {
    final document = pw.Document();
    final order = List<int>.generate(dayTotals.length, (i) => i)..sort((a,b) => dayTotals[b].compareTo(dayTotals[a]));
    String money(num v) => komandaMoney(v);
    String date(DateTime d) => '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year}';
    document.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(28), build: (_) => [
      pw.Text('REPORTE DE RENDIMIENTO', style: pw.TextStyle(fontSize:22,fontWeight:pw.FontWeight.bold)),
      pw.Text('Periodo: ${date(from)} al ${date(to)}'), pw.SizedBox(height:14),
      pw.Text('Ventas: ${money(total)}',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)), pw.Text('Tickets: $tickets'), pw.Text('Ticket promedio: ${money(average)}'), pw.Text('Piezas vendidas: $pieces'), pw.SizedBox(height:18),
      ...order.map((i)=>pw.Padding(padding:const pw.EdgeInsets.symmetric(vertical:5),child:pw.Row(children:[pw.SizedBox(width:24,child:pw.Text('${order.indexOf(i)+1}')),pw.Expanded(flex:2,child:pw.Text(dayNames[i])),pw.Expanded(flex:3,child:pw.Text('${dayTickets[i]} tickets · ${dayPieces[i]} pzas')),pw.Text(money(dayTotals[i]),style:pw.TextStyle(fontWeight:pw.FontWeight.bold))])))
    ]));
    await Printing.layoutPdf(onLayout: (_) async => document.save(), name:'rendimiento-${date(from)}-${date(to)}.pdf');
  }

}
