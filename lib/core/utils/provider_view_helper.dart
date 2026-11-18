import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProviderViewHelper {
  ProviderViewHelper._();

  static String getStatusByDate(DateTime inicio, DateTime fin) {
    final now = DateTime.now();

    if (now.isBefore(inicio)) return 'Programada';
    if (now.isAfter(fin)) return 'Finalizada';
    return 'Activa';
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'Activa':
        return Colors.green;
      case 'Programada':
        return Colors.orange;
      case 'Finalizada':
      default:
        return Colors.red;
    }
  }

  static String formatDateTime(String value) {
    if (value.trim().isEmpty ||
        value == '0000-00-00' ||
        value == '0000-00-00 00:00:00') {
      return 'Sin fecha';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Sin fecha';
    }

    final bool mostrarHora =
    !(date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0);

    final formatter = DateFormat(
      mostrarHora
          ? 'd MMMM yyyy HH:mm'
          : 'd MMMM yyyy',
      'es_MX',
    );

    final formatted = formatter.format(date);
    final parts = formatted.split(' ');

    if (parts.length < 3) return formatted;

    final mes = parts[1];

    final mesCapitalizado =
    mes.isNotEmpty
        ? mes[0].toUpperCase() + mes.substring(1)
        : mes;

    if (mostrarHora && parts.length >= 4) {
      return '${parts[0]} $mesCapitalizado ${parts[2]} ${parts[3]}';
    }

    return '${parts[0]} $mesCapitalizado ${parts[2]}';
  }

  static String formatDateTimeLabel(DateTime? value) {
    if (value == null) return 'Seleccionar';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  static List<Map<String, dynamic>> mapAuctions(List<Map<String, dynamic>> remoteAuctions) {
    final mapped = remoteAuctions.map((e) {
      final row = Map<String, dynamic>.from(e);

      final productos = List<Map<String, dynamic>>.from(
        ((row['productos'] ?? []) as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      final inicio = DateTime.tryParse(row['fechaInicio']?.toString() ?? '');
      final fin = DateTime.tryParse(row['fechaTermino']?.toString() ?? '');

      return {
        ...row,
        'productos': productos,
        'ver': 'Ver',
        'editar': 'Editar',
        'estatus': inicio != null && fin != null
            ? getStatusByDate(inicio, fin)
            : 'Sin estatus',
        'productosCount': productos.length,
      };
    }).toList();

    mapped.sort((a, b) {
      final aDate = DateTime.tryParse(a['fechaInicio']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['fechaInicio']?.toString() ?? '');

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return mapped;
  }
}
