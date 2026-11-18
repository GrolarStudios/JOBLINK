import 'package:flutter/material.dart';

import '../../../utils/colors/gs_colors.dart';

class AuctionTableHelpers {
  const AuctionTableHelpers._();

  static String formatShortDateTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';

    if (raw.isEmpty ||
        raw == '0000-00-00' ||
        raw == '0000-00-00 00:00:00' ||
        raw == '0000-00-00T00:00:00') {
      return 'Sin fecha';
    }

    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    final date = DateTime.tryParse(normalized);

    if (date == null) return raw;

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = (date.year % 100).toString().padLeft(2, '0');

    final hasTime = raw.contains(':') &&
        !(date.hour == 0 && date.minute == 0 && date.second == 0);

    if (!hasTime) return '$day $month $year';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year $hour:$minute';
  }

  static DateTime? parseDate(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.trim().isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static double parseMoney(dynamic value) {
    if (value == null) return 0;

    final cleanValue = value
        .toString()
        .replaceAll(r'$', '')
        .replaceAll(',', '')
        .trim();

    if (cleanValue.isEmpty) return 0;

    return double.tryParse(cleanValue) ?? 0;
  }

  static String formatMoney(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final number = parts.first;
    final decimals = parts.length > 1 ? parts.last : '00';

    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      final reverseIndex = number.length - i;
      buffer.write(number[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }

    return '\$${buffer.toString()}.$decimals';
  }

  static String getStatus(Map<String, dynamic> row) {
    final raw = row['estatus'] ?? row['status'];

    if (raw != null && raw.toString().trim().isNotEmpty) {
      return raw.toString();
    }

    final activo = row['activo'];

    if (activo is bool) return activo ? 'Activa' : 'Inactiva';

    if (activo != null && activo.toString().trim().isNotEmpty) {
      final value = activo.toString().trim().toLowerCase();
      if (value == 'true') return 'Activa';
      if (value == 'false') return 'Inactiva';
      return activo.toString();
    }

    return 'Activa';
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'activa':
      case 'activo':
      case 'active':
        return Colors.green;
      case 'programada':
      case 'scheduled':
        return Colors.orange;
      case 'finalizada':
      case 'finalizado':
      case 'finished':
        return Colors.red;
      case 'inactiva':
      case 'inactivo':
        return Colors.grey;
      default:
        return GSColors.primaryLight;
    }
  }

  static bool isReadOnlyAuction(Map<String, dynamic> row) {
    final status = getStatus(row).toLowerCase().trim();

    if (status == 'finalizada' ||
        status == 'finalizado' ||
        status == 'finished' ||
        status == 'cerrada' ||
        status == 'closed') {
      return true;
    }

    final activo = row['activo'];
    if (activo is bool) return !activo;

    if (activo != null) {
      final value = activo.toString().toLowerCase().trim();
      if (value == 'false') return true;
    }

    return false;
  }
}