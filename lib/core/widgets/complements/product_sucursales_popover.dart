import 'package:flutter/material.dart';

class ProductSucursalesPopover extends StatelessWidget {
  final Map<String, dynamic> row;
  final List<Map<String, dynamic>>? sucursales;
  final String title;
  final bool compact;

  const ProductSucursalesPopover({
    super.key,
    required this.row,
    this.sucursales,
    this.title = 'Sucursales',
    this.compact = false,
  });

  num _toNum(dynamic value) {
    if (value == null) return 0;
    final clean = value.toString().replaceAll(r'$', '').replaceAll(',', '').trim();
    return num.tryParse(clean) ?? 0;
  }

  String _formatNumber(num value) {
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

  List<Map<String, dynamic>> _resolveSucursales() {
    final direct = sucursales;
    if (direct != null) return direct;

    final candidates = [
      row['sucursalesDetalle'],
      row['sucursales'],
      row['existenciasSucursales'],
      row['sucursalesExistencia'],
      row['branches'],
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

  String _nameFrom(Map<String, dynamic> item) {
    return (item['nombre'] ??
            item['sucursal'] ??
            item['Sucursal'] ??
            item['almacen'] ??
            item['Almacen'] ??
            item['name'] ??
            'Sucursal')
        .toString();
  }

  num _existenciaFrom(Map<String, dynamic> item) {
    return _toNum(item['existencia'] ??
        item['Existencia'] ??
        item['cantidad'] ??
        item['stock'] ??
        item['total'] ??
        0);
  }

  num _totalSucursales(List<Map<String, dynamic>> items) {
    return items.fold<num>(0, (total, item) => total + _existenciaFrom(item));
  }

  Future<void> _openDialog(BuildContext context, List<Map<String, dynamic>> items) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Text('🏬', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: items.isEmpty
                ? const Text('Este producto no tiene detalle de sucursales.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total sucursales',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              _formatNumber(_totalSucursales(items)),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: SingleChildScrollView(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.4),
                                1: FlexColumnWidth(1),
                              },
                              border: TableBorder.all(color: const Color(0xFFE5E7EB)),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                  children: [
                                    _SucTableCell('Sucursal', isHeader: true),
                                    _SucTableCell('Existencia', isHeader: true, alignRight: true),
                                  ],
                                ),
                                ...items.map((item) {
                                  return TableRow(
                                    children: [
                                      _SucTableCell(_nameFrom(item)),
                                      _SucTableCell(
                                        _formatNumber(_existenciaFrom(item)),
                                        alignRight: true,
                                        isBold: true,
                                      ),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolveSucursales();
    final total = _formatNumber(_totalSucursales(items));

    return InkWell(
      onTap: () => _openDialog(context, items),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏬', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              compact ? total : 'Ver sucursales · $total',
              style: const TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SucTableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool alignRight;
  final bool isBold;

  const _SucTableCell(
    this.text, {
    this.isHeader = false,
    this.alignRight = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader || isBold ? FontWeight.w900 : FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}
