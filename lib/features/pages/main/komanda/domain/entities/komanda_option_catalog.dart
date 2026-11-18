class KomandaOptionCatalogValue {
  final String id;
  final String label;
  final bool active;
  final int sortOrder;
  final double extraPrice;
  final String complementId;
  final String linkedProductId;
  final int defaultQuantity;

  const KomandaOptionCatalogValue({
    required this.id,
    required this.label,
    this.active = true,
    this.sortOrder = 0,
    this.extraPrice = 0,
    this.complementId = '',
    this.linkedProductId = '',
    this.defaultQuantity = 1,
  });
}

class KomandaOptionCatalog {
  final String id;
  final String name;
  final String slug;
  final bool active;
  final int sortOrder;
  final List<KomandaOptionCatalogValue> values;

  const KomandaOptionCatalog({
    required this.id,
    required this.name,
    this.slug = '',
    this.active = true,
    this.sortOrder = 0,
    this.values = const [],
  });
}
