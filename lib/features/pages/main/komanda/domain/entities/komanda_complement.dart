class KomandaComplement {
  final String id;
  final String type;
  final String name;
  final double extraPrice;
  final bool active;

  const KomandaComplement({
    required this.id,
    required this.type,
    required this.name,
    this.extraPrice = 0,
    this.active = true,
  });
}
