/// Formato monetario uniforme de Komanda: $120,231,329.00
String komandaMoney(num value) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${negative ? '-\$' : '\$'}$integer.${parts[1]}';
}
