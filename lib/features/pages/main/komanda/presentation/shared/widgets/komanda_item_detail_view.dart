import 'package:flutter/material.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/utils/komanda_money.dart';
import '../../../core/utils/komanda_item_detail_formatter.dart';
import '../../../domain/entities/komanda_order.dart';

bool _hideDetailLabel(String label) {
  final value = label.trim().toLowerCase();
  return value == 'detalle' || value == 'detalles';
}

class KomandaItemDetailView extends StatelessWidget {
  final KomandaOrderItem item;
  final bool showPrice;
  final bool showQuantity;
  final EdgeInsetsGeometry padding;

  const KomandaItemDetailView({
    super.key,
    required this.item,
    this.showPrice = false,
    this.showQuantity = true,
    this.padding = const EdgeInsets.symmetric(vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    final lines = KomandaItemDetailFormatter.lines(item.specifications)
        .where((line) {
          final label = line.label.trim().toLowerCase();
          final value = line.value.trim().toLowerCase();
          if (label == 'plato') return false;
          if (RegExp(r'^plato\s+\d+$').hasMatch(value)) return false;
          final isChicharron = item.category.toLowerCase().contains('chicharr') ||
              item.name.toLowerCase().contains('chicharr');
          if (isChicharron && label.contains('importe carne')) return false;
          return true;
        })
        .toList();

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showQuantity) ...[
            Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EAFF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${item.quantity}×',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KomandaTheme.purple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: KomandaTheme.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (lines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'Sin especificaciones',
                      style: TextStyle(
                        color: KomandaTheme.softText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...lines.map(
                    (line) {
                      final normalized = line.label.trim().toLowerCase();
                      final isMeat = normalized == 'carnes' ||
                          normalized == 'carne' ||
                          normalized == 'tipo de carne' ||
                          normalized.startsWith('carne');
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (!_hideDetailLabel(line.label))
                                TextSpan(
                                  text: '${line.label}: ',
                                  style: const TextStyle(
                                    color: KomandaTheme.purple,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              TextSpan(
                                text: line.value,
                                style: TextStyle(
                                  color: KomandaTheme.text,
                                  fontWeight: isMeat || _hideDetailLabel(line.label)
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          if (showPrice) ...[
            const SizedBox(width: 8),
            Text(
              komandaMoney(item.total),
              style: const TextStyle(
                color: KomandaTheme.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
