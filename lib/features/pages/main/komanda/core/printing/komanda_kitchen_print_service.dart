import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/komanda_order.dart';
import '../../domain/entities/komanda_ticket_config.dart';
import '../utils/komanda_item_detail_formatter.dart';
import '../utils/komanda_order_sections.dart';

/// Ticket de preparación independiente del comprobante de cliente.
/// No incluye importes ni instrucciones para abrir el cajón.
class KomandaKitchenPrintService {
  const KomandaKitchenPrintService._();
  static bool _printing = false;

  // Solo estas categorías se imprimen en el ticket general de cocina.
  static const _allowedCategories = <String>{
    'consome', 'especial', 'lonche', 'lonches', 'paquete', 'paquetes', 'quesabirria', 'taco', 'tacos', 'ordenes',
  };

  static String _normalizeCategory(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool _isKitchenItem(KomandaOrderItem item) {
    final category = _normalizeCategory(item.category);
    return _allowedCategories.contains(category) ||
        _allowedCategories.any((allowed) => category.startsWith('$allowed '));
  }


  static Future<bool> printOrder(
    KomandaOrder order,
    KomandaTicketConfig config, {
    String restaurantId = '',
  }) async {
    if (_printing) return false;
    _printing = true;
    try {
      final doc = pw.Document();
      final kitchenItems = restaurantId.trim() == '3'
          ? order.items.where(_isKitchenItem).toList()
          : order.items.toList();
      // No ocultar el ticket cuando una categoría antigua o nueva no coincide.
      // La impresión debe seguir disponible para cualquier pedido con productos.
      final printableItems = kitchenItems.isEmpty ? order.items.toList() : kitchenItems;
      if (printableItems.isEmpty) return false;
      final groups = KomandaOrderSections.byPlate(printableItems).entries.toList();
      final lines = printableItems.length * 3 +
          printableItems.fold<int>(0, (n, item) =>
              n + KomandaItemDetailFormatter.lines(item.specifications).length);
      final height = (115.0 + 350.0 + 12.0 + lines * 9 + groups.length * 13)
          .clamp(120.0, 1600.0).toDouble();
      final big = pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold);
      final body = pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold);
      final heading = order.isDelivery
          ? 'DIRECCIÓN'
          : order.isTakeaway ? 'LLEVAR' : 'COCINA';

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, height * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.fromLTRB(6, 0, 6, 4),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Avance inicial de 35 cm (350 mm) antes de imprimir contenido.
            pw.SizedBox(height: 350 * PdfPageFormat.mm),
            pw.Center(child: pw.Text(heading, style: big)),
            if (!order.isDelivery && !order.isTakeaway && order.table.trim().isNotEmpty)
              pw.Center(child: pw.Text('MESA: ${order.table.trim()}', style: big)),
            if (order.kitchenName.trim().isNotEmpty)
              pw.Center(child: pw.Text(order.kitchenName.trim().toUpperCase(), style: big)),
            if (order.isDelivery && order.deliveryAddress.trim().isNotEmpty)
              pw.Text(order.deliveryAddress, style: body),
            pw.Divider(),
            ...[
              for (var i = 0; i < groups.length; i++) ...[
                pw.Text(order.isDelivery ? 'DIRECCIÓN' :
                    order.isTakeaway ? 'LLEVAR' : 'PLATO ${i + 1}', style: big),
                for (final item in groups[i].value) ...[
                  pw.Text('${item.quantity} x ${item.name}', style: body),
                  for (final detail in KomandaItemDetailFormatter.lines(item.specifications))
                    pw.Text(
                      detail.value.trim().isEmpty ? detail.label :
                      '${detail.label}: ${detail.value}',
                      style: body,
                    ),
                ],
                pw.SizedBox(height: 5),
              ],
            ],
            // Avance final para que el cortador no alcance el texto.
            pw.SizedBox(height: 12 * PdfPageFormat.mm),
          ],
        ),
      ));
      return await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name: 'cocina_${order.shortFolio}.pdf',
      );
    } catch (_) {
      return false;
    } finally {
      _printing = false;
    }
  }
}
