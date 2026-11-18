class KomandaDetailLine {
  final String label;
  final String value;

  const KomandaDetailLine(this.label, this.value);
}

class KomandaItemDetailFormatter {
  const KomandaItemDetailFormatter._();

  static List<KomandaDetailLine> lines(List<String> specifications) {
    final result = <KomandaDetailLine>[];
    final regular = <String, List<String>>{};

    // En los paquetes Nuevo pedido guarda las especificaciones así:
    //   Torta 1: Torta
    //   Torta 1 · Carne(s): Carne
    //   Taco sencillo 1 · Relleno: Papa
    // Detectamos primero los nombres de cada posición para poder agrupar
    // visualmente cada producto del paquete con sus propias opciones.
    final packageComponents = <String>[];
    for (final original in specifications) {
      final raw = original.trim();
      final separator = raw.indexOf(' · ');
      if (separator <= 0) continue;
      final component = raw.substring(0, separator).trim();
      if (component.isNotEmpty && !packageComponents.contains(component)) {
        packageComponents.add(component);
      }
    }

    final packageProduct = <String, String>{};
    final packageDetails = <String, Map<String, List<String>>>{};

    void addRegular(String rawLabel, String rawValue) {
      final label = _normalizeLabel(rawLabel);
      final values = regular.putIfAbsent(label, () => <String>[]);
      _appendValues(values, rawValue);
    }

    void addPackageDetail(
      String component,
      String rawLabel,
      String rawValue,
    ) {
      final label = _normalizeLabel(rawLabel);
      final details = packageDetails.putIfAbsent(
        component,
        () => <String, List<String>>{},
      );
      final values = details.putIfAbsent(label, () => <String>[]);
      _appendValues(values, rawValue);
    }

    for (final original in specifications) {
      final raw = original.trim();
      if (raw.isEmpty) continue;

      // El plato se presenta como encabezado grande en Cocina. Nunca debe
      // repetirse dentro del detalle del producto.
      if (RegExp(r'^plato\s+\d+$', caseSensitive: false).hasMatch(raw)) {
        continue;
      }

      // Compatibilidad con el formato anterior de paquetes.
      if (raw.startsWith('Paquete · ')) {
        final packageText = raw.substring('Paquete · '.length).trim();
        final arrow = packageText.indexOf('→');
        final component = (arrow >= 0
                ? packageText.substring(0, arrow)
                : packageText)
            .trim();
        final details = arrow >= 0 ? packageText.substring(arrow + 1).trim() : '';
        final parsed = _parseChunks(details);
        result.add(KomandaDetailLine(component, 'Incluido'));
        for (final line in parsed) {
          result.add(
            KomandaDetailLine(
              '${line.label} de $component',
              _sortMeatValue(line.label, line.value),
            ),
          );
        }
        continue;
      }

      final packageSeparator = raw.indexOf(' · ');
      if (packageSeparator > 0) {
        final component = raw.substring(0, packageSeparator).trim();
        final detailText = raw.substring(packageSeparator + 3).trim();
        for (final line in _parseChunks(detailText)) {
          addPackageDetail(component, line.label, line.value);
        }
        continue;
      }

      // "Torta 1: Torta" / "Taco sencillo 1: Taco Blando" identifica el
      // producto fijo de una posición del paquete.
      final colon = raw.indexOf(':');
      if (colon > 0) {
        final rawLabel = raw.substring(0, colon).trim();
        final rawValue = raw.substring(colon + 1).trim();
        if (packageComponents.contains(rawLabel)) {
          packageProduct[rawLabel] = rawValue;
          continue;
        }
      }

      for (final line in _parseChunks(raw)) {
        addRegular(line.label, line.value);
      }
    }

    // Detalle de un producto normal. Las carnes siempre se ordenan con la
    // opción literal "Carne" al principio cuando está presente.
    for (final entry in regular.entries) {
      result.add(
        KomandaDetailLine(
          entry.key,
          _sortedValues(entry.key, entry.value).join(', '),
        ),
      );
    }

    // En paquetes, cocina no necesita ver "Torta 1" / "Taco sencillo 1".
    // Se presenta un encabezado simple (Torta, Taco, Agua, etc.) y debajo
    // únicamente sus opciones. Si dos componentes tienen exactamente la misma
    // combinación, se agrupan, por ejemplo: "2× Taco".
    final blocks = <_PackageDetailBlock>[];
    for (final component in packageComponents) {
      final product = packageProduct[component];
      final details = packageDetails[component] ?? const <String, List<String>>{};
      final normalizedDetails = <String, List<String>>{};
      for (final entry in details.entries) {
        normalizedDetails[entry.key] = _sortedValues(entry.key, entry.value);
      }

      final title = _packageTitle(component, product);
      final signature = _packageSignature(title, normalizedDetails);
      final existingIndex = blocks.indexWhere((block) => block.signature == signature);
      if (existingIndex >= 0) {
        blocks[existingIndex] = blocks[existingIndex].copyWith(
          quantity: blocks[existingIndex].quantity + 1,
        );
      } else {
        blocks.add(
          _PackageDetailBlock(
            title: title,
            details: normalizedDetails,
            signature: signature,
          ),
        );
      }
    }

    for (final block in blocks) {
      final title = block.quantity > 1 ? '${block.quantity}× ${block.title}' : block.title;
      // "Detalle" se renderiza sin etiqueta en la UI, por lo que queda como
      // un encabezado limpio: Torta / Taco / 2× Taco.
      result.add(KomandaDetailLine('Detalle', title));
      for (final entry in block.details.entries) {
        result.add(KomandaDetailLine(entry.key, entry.value.join(', ')));
      }
    }

    return result;
  }


  static String _packageTitle(String component, String? product) {
    final raw = component.trim();
    final lower = raw.toLowerCase();
    if (lower.contains('torta')) return 'Torta';
    if (lower.contains('taco')) return 'Taco';
    if (lower.contains('agua')) return 'Agua';
    if (lower.contains('bebida')) return 'Bebida';

    final cleanComponent = raw
        .replaceFirst(RegExp(r'\s+\d+$'), '')
        .replaceAll(RegExp(r'\s+sencill[oa]$', caseSensitive: false), '')
        .trim();
    if (cleanComponent.isNotEmpty) return cleanComponent;

    final cleanProduct = (product ?? '').trim();
    return cleanProduct.isEmpty ? 'Incluido' : cleanProduct;
  }

  static String _packageSignature(
    String title,
    Map<String, List<String>> details,
  ) {
    final parts = <String>[title.toLowerCase()];
    for (final entry in details.entries) {
      parts.add('${entry.key.toLowerCase()}=${entry.value.map((e) => e.toLowerCase()).join('|')}');
    }
    return parts.join('||');
  }

  static String compact(List<String> specifications) {
    final detailLines = lines(specifications);
    if (detailLines.isEmpty) return 'Sin especificaciones';
    return detailLines.map((line) => '${line.label}: ${line.value}').join(' · ');
  }

  static List<KomandaDetailLine> _parseChunks(String text) {
    if (text.trim().isEmpty) return const [];
    final grouped = <String, List<String>>{};
    for (final rawChunk in text.split(RegExp(r'\s+[·•]\s+'))) {
      final chunk = rawChunk.trim();
      if (chunk.isEmpty) continue;
      final colon = chunk.indexOf(':');
      final label = colon > 0 ? _normalizeLabel(chunk.substring(0, colon)) : 'Detalle';
      final value = colon > 0 ? chunk.substring(colon + 1) : chunk;
      final values = grouped.putIfAbsent(label, () => <String>[]);
      _appendValues(values, value);
    }
    return grouped.entries
        .map(
          (entry) => KomandaDetailLine(
            entry.key,
            _sortedValues(entry.key, entry.value).join(', '),
          ),
        )
        .toList();
  }

  static void _appendValues(List<String> target, String rawValue) {
    for (final part in rawValue.split(',')) {
      final clean = part.trim();
      if (clean.isNotEmpty && !target.contains(clean)) target.add(clean);
    }
  }

  static List<String> _sortedValues(String label, List<String> values) {
    final result = List<String>.from(values);
    if (!_isMeatLabel(label)) return result;

    // Mantener el orden configurado por BD, únicamente promoviendo "Carne"
    // a la primera posición, tal como se requiere en cocina/tickets.
    result.sort((a, b) {
      final aIsCarne = a.trim().toLowerCase() == 'carne';
      final bIsCarne = b.trim().toLowerCase() == 'carne';
      if (aIsCarne == bIsCarne) return 0;
      return aIsCarne ? -1 : 1;
    });
    return result;
  }

  static String _sortMeatValue(String label, String value) {
    final values = <String>[];
    _appendValues(values, value);
    return _sortedValues(label, values).join(', ');
  }

  static bool _isMeatLabel(String label) {
    final lower = label.trim().toLowerCase();
    return lower == 'carne' ||
        lower == 'carnes' ||
        lower.startsWith('carne') ||
        lower.contains('tipo de carne');
  }

  static String _normalizeLabel(String value) {
    final text = value.trim();
    final lower = text.toLowerCase();
    if (lower.contains('sabor')) return 'Sabor';
    if (lower.contains('tipo de carne')) return 'Tipo de carne';
    if (lower.startsWith('carne')) return 'Carnes';
    if (lower.startsWith('relleno')) return 'Rellenos';
    return text.replaceAll('(s)', 's');
  }
}


class _PackageDetailBlock {
  final String title;
  final Map<String, List<String>> details;
  final String signature;
  final int quantity;

  const _PackageDetailBlock({
    required this.title,
    required this.details,
    required this.signature,
    this.quantity = 1,
  });

  _PackageDetailBlock copyWith({int? quantity}) {
    return _PackageDetailBlock(
      title: title,
      details: details,
      signature: signature,
      quantity: quantity ?? this.quantity,
    );
  }
}
