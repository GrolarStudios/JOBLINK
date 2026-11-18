import 'package:flutter/material.dart';

class FaltantesPreciosHelper {
  FaltantesPreciosHelper._();

  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();

    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    final cleaned = value.toString().replaceAll(',', '').replaceAll('\$', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  static String formatMoney(num? value) {
    if (value == null) return '';
    return value.toStringAsFixed(2);
  }

  static String getStatus(Map<String, dynamic>? subasta) {
    final explicit = (subasta?['estatus'] ?? '').toString().trim();
    if (explicit.isNotEmpty) return explicit;

    final inicio = DateTime.tryParse((subasta?['fechaInicio'] ?? '').toString());
    final fin = DateTime.tryParse((subasta?['fechaTermino'] ?? '').toString());

    if (inicio == null || fin == null) return 'Sin estatus';

    final now = DateTime.now();
    if (now.isBefore(inicio)) return 'Programada';
    if (now.isAfter(fin)) return 'Finalizada';
    return 'Activa';
  }

  static bool isAuctionClosed(Map<String, dynamic>? subasta) {
    final status = getStatus(subasta).toLowerCase().trim();

    return status == 'finalizada' ||
        status == 'finished' ||
        status == 'closed' ||
        status == 'finished_window';
  }

  static String productUniqueId(Map<String, dynamic> product) {
    return (product['productId'] ?? product['clave'] ?? product['id']).toString();
  }

  static Map<String, Map<String, dynamic>> castProviderDataMap(dynamic value) {
    if (value is Map<String, Map<String, dynamic>>) return value;

    if (value is Map<String, dynamic>) {
      return value.map((key, val) {
        if (val is Map<String, dynamic>) {
          return MapEntry(key, Map<String, dynamic>.from(val));
        }

        if (val is Map) {
          return MapEntry(
            key,
            Map<String, dynamic>.from(val.cast<String, dynamic>()),
          );
        }

        return MapEntry(key, emptyProviderData());
      });
    }

    if (value is Map) {
      return value.map((key, val) {
        final k = key.toString();

        if (val is Map<String, dynamic>) {
          return MapEntry(k, Map<String, dynamic>.from(val));
        }

        if (val is Map) {
          return MapEntry(
            k,
            Map<String, dynamic>.from(val.cast<String, dynamic>()),
          );
        }

        return MapEntry(k, emptyProviderData());
      });
    }

    return <String, Map<String, dynamic>>{};
  }

  static Map<String, dynamic> emptyProviderData() {
    return {
      'observacion': '',
      'precioCaja': '',
      'precioPieza': '',
      'piezasPorCaja': '',
    };
  }

  static List<Map<String, dynamic>> buildRows({
    required Map<String, dynamic> subasta,
    required String providerName,
  }) {
    final result = <Map<String, dynamic>>[];
    final rawProducts = subasta['productos'];

    if (rawProducts is! List) return result;

    for (final raw in rawProducts) {
      final product = Map<String, dynamic>.from(raw as Map);
      final rowId = productUniqueId(product);

      final providerData = castProviderDataMap(product['providerData']);
      final currentProviderData = providerData[providerName] ?? <String, dynamic>{};

      final currentObservation = (currentProviderData['observacion'] ?? '').toString();
      final currentPrecioCaja = parseDouble(currentProviderData['precioCaja']);
      final currentPrecioPieza = parseDouble(currentProviderData['precioPieza']);
      final currentPiezasPorCaja = parseInt(currentProviderData['piezasPorCaja']);

      String? source;
      double precioCaja = 0;
      double precioPieza = 0;
      int piezasPorCaja = currentPiezasPorCaja;

      if (currentPrecioCaja > 0) {
        precioCaja = currentPrecioCaja;
        source = 'caja';
      }

      if (currentPrecioPieza > 0) {
        precioPieza = currentPrecioPieza;
        source ??= 'pieza';
      }

      if (precioCaja <= 0 && precioPieza > 0 && piezasPorCaja > 0) {
        precioCaja = precioPieza * piezasPorCaja;
      }

      if (precioPieza <= 0 && precioCaja > 0 && piezasPorCaja > 0) {
        precioPieza = precioCaja / piezasPorCaja;
      }

      final precioCajaText = precioCaja > 0 ? formatMoney(precioCaja) : '';
      final precioPiezaText = precioPieza > 0 ? formatMoney(precioPieza) : '';
      final piezasPorCajaText = piezasPorCaja > 0 ? piezasPorCaja.toString() : '';

      result.add({
        'id': rowId,
        'subastaId': subasta['id'],
        'clave': (product['clave'] ?? '').toString(),
        'producto': (product['desc'] ?? product['producto'] ?? '').toString(),
        'cajasFaltantes': parseInt(product['pedXCjs']).toString(),
        'precioCaja': precioCajaText,
        'precioPieza': precioPiezaText,
        'piezasPorCaja': piezasPorCajaText,
        'observaciones': currentObservation,
        '_priceSource': source,
        '_rawProduct': product,
        'precioCajaOriginal': precioCajaText,
        'precioPiezaOriginal': precioPiezaText,
        'piezasPorCajaOriginal': piezasPorCajaText,
        'precioCajaEdited': false,
        'precioPiezaEdited': false,
        'piezasPorCajaEdited': false,
        'precioCajaTouched': false,
        'precioPiezaTouched': false,
        'piezasPorCajaTouched': false,
        'precioCajaWasPrefilled': precioCajaText.trim().isNotEmpty,
        'precioPiezaWasPrefilled': precioPiezaText.trim().isNotEmpty,
        'piezasPorCajaWasPrefilled': piezasPorCajaText.trim().isNotEmpty,
      });
    }

    return result;
  }

  static bool hasCapturedData(Map<String, dynamic> row) {
    final precioCaja = (row['precioCaja'] ?? '').toString().trim();
    final precioPieza = (row['precioPieza'] ?? '').toString().trim();
    final piezasPorCaja = (row['piezasPorCaja'] ?? '').toString().trim();
    final observaciones = (row['observaciones'] ?? '').toString().trim();

    return precioCaja.isNotEmpty ||
        precioPieza.isNotEmpty ||
        piezasPorCaja.isNotEmpty ||
        observaciones.isNotEmpty;
  }

  static List<Map<String, dynamic>> filterRows({
    required List<Map<String, dynamic>> rows,
    required String query,
  }) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return List<Map<String, dynamic>>.from(rows);

    return rows.where((row) {
      return row.entries.any((entry) {
        if (entry.key.startsWith('_')) return false;
        if (entry.key == 'cajasFaltantes') return false;
        if (entry.key.endsWith('Original')) return false;
        if (entry.key.endsWith('Edited')) return false;
        if (entry.key.endsWith('Touched')) return false;
        if (entry.key.endsWith('WasPrefilled')) return false;

        return entry.value.toString().toLowerCase().contains(q);
      });
    }).toList();
  }

  static List<Map<String, dynamic>> buildUpdatedProducts({
    required Map<String, dynamic> subasta,
    required List<Map<String, dynamic>> rows,
    required String providerName,
  }) {
    final rawProducts = subasta['productos'];
    final updatedProducts = <Map<String, dynamic>>[];

    if (rawProducts is! List) return updatedProducts;

    for (final raw in rawProducts) {
      final product = Map<String, dynamic>.from(raw as Map);
      final productUniqueId = productUniqueIdFromProduct(product);

      final row = rows.firstWhere(
        (item) => item['id'].toString() == productUniqueId,
        orElse: () => <String, dynamic>{},
      );

      if (row.isEmpty) {
        updatedProducts.add(product);
        continue;
      }

      final providerData = castProviderDataMap(product['providerData']);

      final precioCajaText = (row['precioCaja'] ?? '').toString().trim();
      final piezasPorCajaText = (row['piezasPorCaja'] ?? '').toString().trim();
      final precioPiezaText = (row['precioPieza'] ?? '').toString().trim();
      final observaciones = (row['observaciones'] ?? '').toString().trim();

      if (!hasCapturedData(row)) {
        providerData.remove(providerName);
      } else {
        providerData[providerName] = {
          'observacion': observaciones,
          'precioCaja': precioCajaText,
          'precioPieza': precioPiezaText,
          'piezasPorCaja': piezasPorCajaText,
        };
      }

      product['providerData'] = providerData;

      product.remove('providerObservaciones');
      product.remove('providerPrices');
      product.remove('providerPrecioCaja');
      product.remove('providerPrecioPieza');
      product.remove('providerPiezasPorCaja');

      updatedProducts.add(product);
    }

    return updatedProducts;
  }

  static String productUniqueIdFromProduct(Map<String, dynamic> product) {
    return (product['productId'] ?? product['clave'] ?? product['id']).toString();
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'activa':
        return Colors.green;
      case 'programada':
        return Colors.orange;
      case 'finalizada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
