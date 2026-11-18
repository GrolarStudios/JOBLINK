import 'package:flutter/material.dart';

import '../../../../../../core/utils/colors/gs_colors.dart';

class FaltantesPreciosBanner extends StatelessWidget {
  final String folio;
  final String providerName;
  final String estatus;
  final int productos;

  const FaltantesPreciosBanner({
    super.key,
    required this.folio,
    required this.providerName,
    required this.estatus,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GSColors.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GSColors.primaryLight.withOpacity(0.14),
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        children: [
          _HeaderChip(
            icon: Icons.confirmation_number_rounded,
            label: 'Folio',
            value: folio,
          ),
          _HeaderChip(
            icon: Icons.storefront_rounded,
            label: 'Proveedor',
            value: providerName,
          ),
          _HeaderChip(
            icon: Icons.info_outline_rounded,
            label: 'Estatus',
            value: estatus,
          ),
          _HeaderChip(
            icon: Icons.inventory_2_rounded,
            label: 'Productos',
            value: '$productos',
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GSColors.primaryLight.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: GSColors.primaryLight),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: GSColors.onSurfaceLight,
                fontSize: 13,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
