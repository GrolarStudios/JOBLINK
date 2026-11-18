import 'package:flutter/material.dart';

class ProviderStatusBanner extends StatelessWidget {
  final bool isClosed;
  final String folio;

  const ProviderStatusBanner({
    super.key,
    required this.isClosed,
    required this.folio,
  });

  @override
  Widget build(BuildContext context) {
    final color = isClosed ? Colors.red : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        isClosed ? 'Subasta $folio finalizada.' : 'Subasta $folio activa.',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
