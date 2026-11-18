class KomandaCategory {
  final String id;
  final String name;
  final String printPrefix;
  final bool active;
  const KomandaCategory({
    required this.id,
    required this.name,
    this.printPrefix = '',
    this.active = true,
  });
}
