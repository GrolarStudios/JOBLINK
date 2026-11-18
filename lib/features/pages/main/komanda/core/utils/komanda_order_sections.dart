import '../../domain/entities/komanda_order.dart';

enum KomandaOrderSection { tortas, tacos }

extension KomandaOrderSectionX on KomandaOrderSection {
  String get label {
    switch (this) {
      case KomandaOrderSection.tortas:
        return 'Tortas';
      case KomandaOrderSection.tacos:
        return 'Tacos';
    }
  }
}

class KomandaOrderSections {
  const KomandaOrderSections._();

  static KomandaOrderSection sectionFor(KomandaOrderItem item) {
    final category = item.category.trim().toLowerCase();
    final name = item.name.trim().toLowerCase();
    final specs = item.specifications.join(' ').trim().toLowerCase();

    // La categoría real del producto manda primero. Esto evita clasificar
    // por coincidencias accidentales en el nombre o en las especificaciones.
    // "Mini" se usa en este menú para Tortas minis.
    if (category.contains('taco')) return KomandaOrderSection.tacos;
    if (category.contains('torta') ||
        category == 'mini' ||
        category.contains('torta mini') ||
        category.contains('mini torta') ||
        category.contains('blando')) {
      return KomandaOrderSection.tortas;
    }

    // Compatibilidad con pedidos viejos que no traían categoría desde API.
    // Taco tiene prioridad para que "Taco dorado" nunca termine en Tortas.
    final searchable = '$name $specs';
    if (searchable.contains('taco')) return KomandaOrderSection.tacos;
    if (searchable.contains('torta') ||
        searchable.contains('mini') ||
        searchable.contains('blando') ||
        searchable.contains('kilo') ||
        searchable.contains('manita') ||
        searchable.contains('riñon') ||
        searchable.contains('riñón') ||
        specs.contains('peso:')) {
      return KomandaOrderSection.tortas;
    }

    // El sistema actual solo tiene dos estaciones de impresión/cocina.
    return KomandaOrderSection.tacos;
  }

  static List<KomandaOrderItem> itemsFor(
    List<KomandaOrderItem> items,
    KomandaOrderSection section,
  ) {
    return items.where((item) => sectionFor(item) == section).toList();
  }

  static String plateOf(KomandaOrderItem item) {
    for (final specification in item.specifications) {
      final value = specification.trim();
      if (value.toLowerCase().startsWith('plato ')) return value;
    }
    return 'Sin plato';
  }

  static Map<String, List<KomandaOrderItem>> byPlate(
    List<KomandaOrderItem> items,
  ) {
    final map = <String, List<KomandaOrderItem>>{};
    for (final item in items) {
      final plate = plateOf(item);
      map.putIfAbsent(plate, () => <KomandaOrderItem>[]).add(item);
    }

    final keys = map.keys.toList()
      ..sort((a, b) => plateNumber(a).compareTo(plateNumber(b)));
    return <String, List<KomandaOrderItem>>{
      for (final key in keys) key: map[key]!,
    };
  }

  static int plateNumber(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return int.tryParse(match?.group(1) ?? '') ?? 9999;
  }

  static String compactSummary(List<KomandaOrderItem> items) {
    final parts = <String>[];
    for (final section in KomandaOrderSection.values) {
      final sectionItems = itemsFor(items, section);
      if (sectionItems.isEmpty) continue;
      final plates = byPlate(sectionItems).keys.toList();
      final plateText = plates.where((p) => p != 'Sin plato').join(', ');
      parts.add(plateText.isEmpty ? section.label : '${section.label}: $plateText');
    }
    return parts.join(' · ');
  }
}
