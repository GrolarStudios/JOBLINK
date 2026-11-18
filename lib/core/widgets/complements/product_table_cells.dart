import 'package:flutter/material.dart';

import '../../utils/colors/gs_colors.dart';

class ProductTableCells {
  ProductTableCells._();

  static Widget almacenCell(Map<String, dynamic> row) {
    return SizedBox(
      width: 92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        child: Text(
          row['almacen']?.toString() ?? '0',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  static Widget descriptionCell(Map<String, dynamic> row) {
    return SizedBox(
      width: 360,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          row['desc']?.toString() ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  static Widget sucTotalBox({
    required GlobalKey cellKey,
    required String value,
  }) {
    return SizedBox(
      width: 92,
      child: Container(
        key: cellKey,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GSColors.primaryLight.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GSColors.primaryLight.withOpacity(0.12)),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: GSColors.primaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
