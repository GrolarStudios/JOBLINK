import 'package:flutter/material.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/utils/komanda_order_sections.dart';
import '../../../domain/entities/komanda_order.dart';
import 'komanda_item_detail_view.dart';

/// Resumen del paso de confirmación: plato -> categoría real -> productos.
/// No altera la agrupación por estaciones utilizada para imprimir cocina.
class KomandaConfirmationCategoriesView extends StatelessWidget {
  final List<KomandaOrderItem> items;

  const KomandaConfirmationCategoriesView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final plates = KomandaOrderSections.byPlate(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plate in plates.entries) ...[
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.restaurant_rounded, color: KomandaTheme.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(plate.key, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: KomandaTheme.text))),
            ]),
          ),
          ..._categoryCards(plate.value),
        ],
      ],
    );
  }

  List<Widget> _categoryCards(List<KomandaOrderItem> plateItems) {
    final categories = <String, List<KomandaOrderItem>>{};
    for (final item in plateItems) {
      final name = item.category.trim().isEmpty ? 'Otros' : item.category.trim();
      final key = categories.keys.where((k) => k.toLowerCase() == name.toLowerCase()).firstOrNull ?? name;
      categories.putIfAbsent(key, () => <KomandaOrderItem>[]).add(item);
    }
    return [
      for (final entry in categories.entries)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE4E9F1)),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Icon(Icons.restaurant_menu_rounded, color: KomandaTheme.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KomandaTheme.text))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(16)),
                child: Text('${entry.value.fold<int>(0, (sum, item) => sum + item.quantity)} productos', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KomandaTheme.primary)),
              ),
            ]),
            const SizedBox(height: 8),
            for (var i = 0; i < entry.value.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              KomandaItemDetailView(item: entry.value[i], showPrice: true),
            ],
          ]),
        ),
    ];
  }
}
