import 'package:flutter/material.dart';

class ProviderDetalleHelper {
  ProviderDetalleHelper._();

  static num toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;

    return num.tryParse(
          value.toString().replaceAll('\$', '').replaceAll(',', '').trim(),
        ) ??
        0;
  }

  static String formatMoney(dynamic value) {
    final number = toNum(value);
    return '\$${number.toStringAsFixed(2)}';
  }

  static String formatNumber(dynamic value) {
    final number = toNum(value);
    return number % 1 == 0
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
  }

  static String getStatusByDate(DateTime inicio, DateTime fin) {
    final now = DateTime.now();

    if (now.isBefore(inicio)) return 'Programada';
    if (now.isAfter(fin)) return 'Finalizada';
    return 'Activa';
  }

  static String getProductUniqueId(Map<String, dynamic> product) {
    return (product['productId'] ?? product['clave'] ?? product['id']).toString();
  }

  static Map<String, num> providerPricesFromRow(Map<String, dynamic> row) {
    final raw = row['providerPrices'];

    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, toNum(value)));
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), toNum(value)));
    }

    return {};
  }

  static Map<String, String> providerObservationsFromRow(
    Map<String, dynamic> row,
  ) {
    final raw = row['providerObservaciones'];

    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(key, value.toString()));
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
    }

    return {};
  }

  static bool hasQuoted(Map<String, dynamic> row) {
    final providerPrices = providerPricesFromRow(row);
    final providerObservaciones = providerObservationsFromRow(row);

    final hasPrice = providerPrices.values.any((value) => toNum(value) > 0);
    final hasObs =
        providerObservaciones.values.any((value) => value.trim().isNotEmpty);

    return hasPrice || hasObs;
  }

  static List<String> extractProvidersFromProducts(
    List<Map<String, dynamic>> rows,
  ) {
    final providers = <String>{};

    for (final row in rows) {
      providers.addAll(providerPricesFromRow(row).keys);
      providers.addAll(providerObservationsFromRow(row).keys);
    }

    return providers.where((e) => e.trim().isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static num? bestPriceForRow(Map<String, dynamic> row) {
    final prices = providerPricesFromRow(row)
        .values
        .map(toNum)
        .where((value) => value > 0)
        .toList();

    if (prices.isEmpty) return null;

    prices.sort();
    return prices.first;
  }

  static List<String> winnerProvidersForRow(Map<String, dynamic> row) {
    final providerPrices = providerPricesFromRow(row);
    final best = bestPriceForRow(row);
    if (best == null) return [];

    return providerPrices.entries
        .where((entry) => toNum(entry.value) > 0 && toNum(entry.value) == best)
        .map((entry) => entry.key)
        .toList();
  }

  static bool isBestPrice(Map<String, dynamic> row, String providerKey) {
    return winnerProvidersForRow(row).contains(providerKey);
  }

  static List<Map<String, dynamic>> buildLocalRows(Map<String, dynamic> subasta) {
    final rows = <Map<String, dynamic>>[];
    final rawProducts = subasta['productos'];

    if (rawProducts is! List) return rows;

    for (final raw in rawProducts) {
      final product = Map<String, dynamic>.from(raw as Map);
      final productUniqueId = getProductUniqueId(product);
      final providerData = normalizeProviderData(product['providerData']);

      final providerPrices = <String, num>{};
      final providerObservaciones = <String, String>{};

      providerData.forEach((provider, data) {
        final item = Map<String, dynamic>.from(data);

        final precioCaja = toNum(item['precioCaja']);
        final precioPieza = toNum(item['precioPieza']);
        final piezasPorCaja = toNum(item['piezasPorCaja']);

        providerPrices[provider] = precioPieza > 0
            ? precioPieza
            : (precioCaja > 0 && piezasPorCaja > 0 ? precioCaja / piezasPorCaja : 0);

        providerObservaciones[provider] = item['observacion']?.toString() ?? '';
      });

      num pzaCaja = toNum(product['pzaCaja']);
      num precioCaja = toNum(product['precioCaja']);
      num precioPieza = toNum(product['precioPieza']);

      if (providerData.isNotEmpty) {
        final firstProviderData = Map<String, dynamic>.from(providerData.values.first);

        if (pzaCaja <= 0) pzaCaja = toNum(firstProviderData['piezasPorCaja']);
        if (precioCaja <= 0) precioCaja = toNum(firstProviderData['precioCaja']);
        if (precioPieza <= 0) precioPieza = toNum(firstProviderData['precioPieza']);
      }

      rows.add({
        'id': productUniqueId,
        'subastaId': subasta['id'],
        'nombre': (product['desc'] ?? product['nombre'] ?? 'Producto').toString(),
        'cantidad': toNum(product['pedXCjs'] ?? product['cantidad']),
        'pzaCaja': pzaCaja,
        'precioCaja': precioCaja,
        'precioPieza': precioPieza,
        'providerObservaciones': providerObservaciones,
        'providerPrices': providerPrices,
      });
    }

    return rows;
  }

  static Map<String, dynamic> normalizeProviderData(dynamic rawProviderData) {
    if (rawProviderData is Map<String, dynamic>) {
      return rawProviderData;
    }

    if (rawProviderData is Map) {
      return rawProviderData.map(
        (key, value) => MapEntry(
          key.toString(),
          value is Map<String, dynamic>
              ? value
              : value is Map
                  ? Map<String, dynamic>.from(value)
                  : <String, dynamic>{},
        ),
      );
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> buildTableData({
    required List<Map<String, dynamic>> filteredRows,
    required List<String> providers,
  }) {
    return filteredRows.map((row) {
      final newRow = Map<String, dynamic>.from(row);
      final providerPrices = providerPricesFromRow(row);

      newRow['nombre'] = row['nombre'];
      newRow['cantidadFormatted'] = formatNumber(row['cantidad']);
      newRow['pzaCajaFormatted'] = formatNumber(row['pzaCaja']);
      newRow['precioCajaFormatted'] =
          toNum(row['precioCaja']) > 0 ? formatMoney(row['precioCaja']) : '-';
      newRow['precioPiezaFormatted'] =
          toNum(row['precioPieza']) > 0 ? formatMoney(row['precioPieza']) : '-';

      for (final provider in providers) {
        newRow[provider] = providerPrices[provider] ?? '';
      }

      return newRow;
    }).toList();
  }

  static List<Map<String, dynamic>> buildProductsForPersistence({
    required Map<String, dynamic> subasta,
    required List<Map<String, dynamic>> rows,
  }) {
    final rawProducts = subasta['productos'];
    final byId = <String, Map<String, dynamic>>{};

    if (rawProducts is List) {
      for (final raw in rawProducts) {
        final product = Map<String, dynamic>.from(raw as Map);
        final productUniqueId = getProductUniqueId(product);
        byId[productUniqueId] = product;
      }
    }

    for (final row in rows) {
      final id = row['id'].toString();
      final existing = Map<String, dynamic>.from(byId[id] ?? {'productId': id});
      final providerPrices = providerPricesFromRow(row);
      final providerObservaciones = providerObservationsFromRow(row);
      final providerData = <String, dynamic>{};

      for (final provider in providerPrices.keys) {
        final precioPieza = toNum(providerPrices[provider]);
        final observacion = providerObservaciones[provider] ?? '';
        final piezasCaja = toNum(row['pzaCaja']);
        final precioCaja = piezasCaja > 0 ? precioPieza * piezasCaja : 0;

        providerData[provider] = {
          'precioCaja': formatNumber(precioCaja),
          'precioPieza': formatNumber(precioPieza),
          'piezasPorCaja': formatNumber(piezasCaja),
          'observacion': observacion,
        };
      }

      existing['desc'] = existing['desc'] ?? row['nombre'];
      existing['nombre'] = row['nombre'];
      existing['pedXCjs'] = formatNumber(row['cantidad']);
      existing['providerData'] = providerData;
      existing['pzaCaja'] = toNum(row['pzaCaja']);
      byId[id] = existing;
    }

    return byId.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
