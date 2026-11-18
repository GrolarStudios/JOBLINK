import 'package:flutter/material.dart';

import '../../../core/komanda_theme.dart';
import '../../../core/utils/komanda_order_sections.dart';
import '../../../domain/entities/komanda_order.dart';
import 'komanda_item_detail_view.dart';

class KomandaOrderSectionsView extends StatelessWidget {
  final List<KomandaOrderItem> items;
  final bool showPrice;
  final bool compact;

  const KomandaOrderSectionsView({
    super.key,
    required this.items,
    this.showPrice = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (final section in KomandaOrderSection.values) {
      final sectionItems = KomandaOrderSections.itemsFor(items, section);
      if (sectionItems.isEmpty) continue;
      final plates = KomandaOrderSections.byPlate(sectionItems);

      children.add(
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: children.isEmpty ? 0 : 10, bottom: 6),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: KomandaTheme.purple.withOpacity(.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KomandaTheme.purple.withOpacity(.12)),
          ),
          child: Row(
            children: [
              Icon(
                section == KomandaOrderSection.tortas
                    ? Icons.lunch_dining_rounded
                    : Icons.restaurant_rounded,
                color: KomandaTheme.purple,
                size: compact ? 16 : 19,
              ),
              const SizedBox(width: 7),
              Text(
                section.label,
                style: TextStyle(
                  color: KomandaTheme.purple,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );

      for (final entry in plates.entries) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              left: compact ? 4 : 6,
              top: 2,
              bottom: 4,
            ),
            child: Text(
              entry.key,
              style: TextStyle(
                color: KomandaTheme.text,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );

        if (compact) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 5),
              child: Text(
                entry.value
                    .map((item) => '${item.quantity}× ${item.name}')
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KomandaTheme.softText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        } else {
          for (final item in entry.value) {
            children.add(KomandaItemDetailView(item: item, showPrice: showPrice));
            children.add(const Divider(height: 1));
          }
        }
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
