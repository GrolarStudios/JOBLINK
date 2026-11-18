import 'package:flutter/material.dart';

class GlobalSucursalesPopover extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool compact;

  const GlobalSucursalesPopover({
    super.key,
    required this.row,
    this.compact = true,
  });

  static num toNum(dynamic value) {
    if (value == null) return 0;
    final clean = value.toString().replaceAll(r'$', '').replaceAll(',', '').trim();
    return num.tryParse(clean) ?? 0;
  }

  static String formatNumber(num value) {
    final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = fixed.split('.');
    final integer = parts[0];
    final decimal = parts.length > 1 ? '.${parts[1]}' : '';
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      final positionFromEnd = integer.length - i;
      buffer.write(integer[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) buffer.write(',');
    }

    return '${buffer.toString()}$decimal';
  }

  List<Map<String, dynamic>> get _sucursales {
    final candidates = [
      row['sucursalesDetalle'],
      row['sucursales'],
      row['existenciasSucursal'],
      row['existenciasSucursales'],
      row['detalleSucursales'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    return [];
  }

  num get totalExistencia {
    if (_sucursales.isEmpty) {
      return toNum(row['suc'] ?? row['sucursalesTotal'] ?? row['existenciaSucursales']);
    }

    return _sucursales.fold<num>(
      0,
      (total, item) => total + toNum(
        item['existencia'] ?? item['cantidad'] ?? item['stock'] ?? item['total'],
      ),
    );
  }

  String _sucursalName(Map<String, dynamic> item) {
    return (item['nombre'] ??
            item['sucursal'] ??
            item['almacen'] ??
            item['name'] ??
            item['id'] ??
            'Sucursal')
        .toString();
  }

  Widget _buildPopoverContent() {
    final sucursales = _sucursales;

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 360),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏬', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Existencia por sucursal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Total sucursales: ${formatNumber(totalExistencia)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (sucursales.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Sin detalle de sucursales.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.4),
                      1: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          _SucHeaderCell('Sucursal'),
                          _SucHeaderCell('Exist.'),
                        ],
                      ),
                      ...sucursales.map((item) {
                        final existencia = toNum(
                          item['existencia'] ?? item['cantidad'] ?? item['stock'] ?? item['total'],
                        );

                        return TableRow(
                          children: [
                            _SucBodyCell(_sucursalName(item)),
                            _SucBodyCell(formatNumber(existencia), isBold: true),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = formatNumber(totalExistencia);

    return Tooltip(
      richMessage: WidgetSpan(child: _buildPopoverContent()),
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      preferBelow: false,
      child: Container(
        constraints: BoxConstraints(minWidth: compact ? 74 : 110),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏬', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SucHeaderCell extends StatelessWidget {
  final String text;
  const _SucHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

class _SucBodyCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _SucBodyCell(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          color: const Color(0xFF111827),
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }
}
