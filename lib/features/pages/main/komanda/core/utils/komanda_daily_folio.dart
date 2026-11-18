import '../../domain/entities/komanda_order.dart';

/// Fecha de operación en zona Centro de México (UTC-6, sin horario de verano).
/// El backend debe asignar el folio definitivo de manera atómica.
DateTime komandaMexicoDate(DateTime value) =>
    value.toUtc().subtract(const Duration(hours: 6));

String komandaNextDailyFolio(Iterable<KomandaOrder> orders, DateTime now) {
  final today = komandaMexicoDate(now);
  var maximum = 0;
  for (final order in orders) {
    final date = komandaMexicoDate(order.createdAt);
    if (date.year != today.year || date.month != today.month || date.day != today.day) continue;
    final raw = order.folio.trim().replaceFirst(RegExp(r'^#'), '');
    final value = int.tryParse(raw);
    if (value != null && value > maximum) maximum = value;
  }
  return '${maximum + 1}';
}
