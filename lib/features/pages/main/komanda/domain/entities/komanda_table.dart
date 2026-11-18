class KomandaTable {
  final String id;
  final String name;
  final int capacity;
  final bool active;
  const KomandaTable({required this.id, required this.name, this.capacity = 4, this.active = true});
}
