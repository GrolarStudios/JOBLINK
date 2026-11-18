class KomandaProductOption {
  final String id;
  final String label;
  final double extraPrice;
  final String complementId;
  final String linkedProductId;
  final int defaultQuantity;
  final KomandaProduct? linkedProduct;

  const KomandaProductOption({
    required this.id,
    required this.label,
    this.extraPrice = 0,
    this.complementId = '',
    this.linkedProductId = '',
    this.defaultQuantity = 1,
    this.linkedProduct,
  });
}

class KomandaProductOptionGroup {
  final String id;
  final String name;
  final List<String> options;
  final List<KomandaProductOption> optionDetails;
  final bool multiple;
  final bool required;
  final int minSelections;
  final int? maxSelections;
  final bool allowRepeats;
  final String catalogId;
  final String catalogName;

  const KomandaProductOptionGroup({
    required this.id,
    required this.name,
    this.options = const [],
    this.optionDetails = const [],
    this.multiple = false,
    this.required = false,
    this.minSelections = 0,
    this.maxSelections,
    this.allowRepeats = false,
    this.catalogId = '',
    this.catalogName = '',
  });

  List<String> get labels => optionDetails.isNotEmpty
      ? optionDetails.map((e) => e.label).toList()
      : options;
}

class KomandaProduct {
  final String id;
  final String name;
  final String printName;
  final String category;
  final double price;
  final bool available;
  final String productKind;
  final String pricingMode;
  final String description;
  final List<KomandaProductOptionGroup> optionGroups;

  const KomandaProduct({
    required this.id,
    required this.name,
    String? printName,
    required this.category,
    required this.price,
    required this.available,
    this.productKind = 'simple',
    this.pricingMode = 'fixed',
    this.description = '',
    this.optionGroups = const [],
  }) : printName = printName ?? name;

  static const String packageGroupPrefix = '__KOMANDA_PACKAGE__';

  bool get isPackage => productKind == 'package' || optionGroups.any(
        (group) => group.name.startsWith(packageGroupPrefix),
      );

  String get packagePricingMode {
    if (pricingMode.isNotEmpty) return pricingMode;
    final groups = optionGroups.where(
      (group) => group.name.startsWith(packageGroupPrefix),
    );
    if (groups.isEmpty) return '';
    final parts = groups.first.name.split(':');
    return parts.length > 1 ? parts.last : 'fixed';
  }

  List<KomandaProductOptionGroup> get selectableOptionGroups => isPackage
      ? const []
      : optionGroups
          .where((group) => !group.name.startsWith(packageGroupPrefix))
          .toList();

  List<KomandaProductOptionGroup> get packageGroups => isPackage
      ? optionGroups.where((g) => !g.name.startsWith(packageGroupPrefix)).toList()
      : const [];

  List<String> get packageItemLabels {
    if (productKind == 'package') {
      return packageGroups.map((group) {
        final qty = group.maxSelections ?? group.minSelections;
        return qty > 1 ? '$qty × ${group.name}' : group.name;
      }).toList();
    }
    final groups = optionGroups.where(
      (group) => group.name.startsWith(packageGroupPrefix),
    );
    if (groups.isEmpty) return const [];
    return groups.first.options.map((value) {
      final parts = value.split('|');
      if (parts.length > 3) {
        final qty = int.tryParse(parts[3]) ?? 1;
        return qty > 1 ? '$qty × ${parts[1]}' : parts[1];
      }
      return parts.length > 1 ? parts[1] : value;
    }).toList();
  }

  bool get hasOptions => selectableOptionGroups.isNotEmpty;

  KomandaProduct copyWith({
    String? id,
    String? name,
    String? printName,
    String? category,
    double? price,
    bool? available,
    String? productKind,
    String? pricingMode,
    String? description,
    List<KomandaProductOptionGroup>? optionGroups,
  }) {
    return KomandaProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      printName: printName ?? this.printName,
      category: category ?? this.category,
      price: price ?? this.price,
      available: available ?? this.available,
      productKind: productKind ?? this.productKind,
      pricingMode: pricingMode ?? this.pricingMode,
      description: description ?? this.description,
      optionGroups: optionGroups ?? this.optionGroups,
    );
  }
}
