import 'package:flutter/material.dart';

import '../../utils/colors/gs_colors.dart';

/// Widget global compartido para mostrar sucursales con la MISMA funcionalidad
/// de hover que ya tenía la tabla:
/// - Al pasar el mouse abre un overlay flotante.
/// - El overlay se queda abierto si el mouse entra al pop.
/// - Se cierra al salir del cell y del overlay.
/// - Sirve en tablas y también dentro de otros pops/dialogs.
class SharedSucursalesHoverCell extends StatefulWidget {
  final Map<String, dynamic> row;
  final Widget? child;
  final double overlayWidth;
  final double overlayMaxHeight;

  const SharedSucursalesHoverCell({
    super.key,
    required this.row,
    this.child,
    this.overlayWidth = 300,
    this.overlayMaxHeight = 320,
  });

  @override
  State<SharedSucursalesHoverCell> createState() => _SharedSucursalesHoverCellState();
}

class _SharedSucursalesHoverCellState extends State<SharedSucursalesHoverCell> {
  final GlobalKey _targetKey = GlobalKey();

  OverlayEntry? _hoverOverlayEntry;
  bool _isPointerInsideCell = false;
  bool _isPointerInsideOverlay = false;

  @override
  void dispose() {
    _removeHoverOverlay();
    super.dispose();
  }

  void _removeHoverOverlay() {
    _hoverOverlayEntry?.remove();
    _hoverOverlayEntry = null;
  }

  void _scheduleOverlayClose() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      if (!_isPointerInsideCell && !_isPointerInsideOverlay) {
        _removeHoverOverlay();
      }
    });
  }

  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;

    final clean = value
        .toString()
        .replaceAll(r'$', '')
        .replaceAll(',', '')
        .trim();

    return num.tryParse(clean) ?? 0;
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> _sucursalesFromRow(Map<String, dynamic> row) {
    final raw = row['sucursalesDetalle'] ?? row['sucursales'] ?? [];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  num _totalExistencia(Map<String, dynamic> row) {
    final totalFromRow = row['totalExistencia'];

    if (totalFromRow != null && totalFromRow.toString().trim().isNotEmpty) {
      return _toNum(totalFromRow);
    }

    final sucursales = _sucursalesFromRow(row);

    return sucursales.fold<num>(
      0,
          (total, item) => total + _toNum(item['existencia']),
    );
  }

  String _productName(Map<String, dynamic> row) {
    final candidates = [
      row['desc'],
      row['nombre'],
      row['descripcion'],
      row['articulo'],
      row['clave'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return 'Producto';
  }

  void _showHoverSucursalesOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = _targetKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    _removeHoverOverlay();

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    final sucursales = _sucursalesFromRow(widget.row);
    final totalExistencia = _totalExistencia(widget.row);
    final productName = _productName(widget.row);

    final overlayWidth = widget.overlayWidth;
    final overlayMaxHeight = widget.overlayMaxHeight;
    const screenMargin = 12.0;
    const overlayGap = 4.0;

    final left = (targetPosition.dx + overlayWidth > screenSize.width - screenMargin)
        ? screenSize.width - overlayWidth - screenMargin
        : targetPosition.dx;

    final safeLeft = left < screenMargin ? screenMargin : left;

    final spaceBelow = screenSize.height - (targetPosition.dy + targetSize.height);
    final spaceAbove = targetPosition.dy;
    final shouldOpenUp = spaceBelow < overlayMaxHeight + overlayGap + screenMargin &&
        spaceAbove > spaceBelow;

    final rawTop = shouldOpenUp
        ? targetPosition.dy - overlayMaxHeight - overlayGap
        : targetPosition.dy + targetSize.height + overlayGap;

    final maxSafeTop = screenSize.height - overlayMaxHeight - screenMargin;
    final safeTop = rawTop.clamp(screenMargin, maxSafeTop < screenMargin ? screenMargin : maxSafeTop);

    _hoverOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop.toDouble(),
              child: MouseRegion(
                onEnter: (_) {
                  _isPointerInsideOverlay = true;
                },
                onExit: (_) {
                  _isPointerInsideOverlay = false;
                  _scheduleOverlayClose();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: overlayWidth,
                    constraints: BoxConstraints(maxHeight: widget.overlayMaxHeight),
                    decoration: BoxDecoration(
                      color: GSColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: GSColors.cardShadowLight,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: GSColors.primaryLight.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: const BoxDecoration(
                            color: GSColors.primaryLight,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: GSColors.onPrimaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: GSColors.primaryLight.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _formatNumber(totalExistencia),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: GSColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: sucursales.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: Text(
                              'Sin sucursales disponibles',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                              : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            itemCount: sucursales.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: GSColors.primaryLight.withOpacity(0.08),
                            ),
                            itemBuilder: (_, index) {
                              final sucursal = sucursales[index];
                              final nombre = (sucursal['nombre'] ?? '-').toString();
                              final existencia = _toNum(sucursal['existencia']);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 7,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: existencia > 0
                                            ? GSColors.secondaryLight.withOpacity(0.12)
                                            : Colors.grey.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _formatNumber(existencia),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: existencia > 0
                                              ? GSColors.secondaryLight
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_hoverOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final totalExistencia = _totalExistencia(widget.row);

    return MouseRegion(
      key: _targetKey,
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        _isPointerInsideCell = true;
        _showHoverSucursalesOverlay();
      },
      onExit: (_) {
        _isPointerInsideCell = false;
        _scheduleOverlayClose();
      },
      child: widget.child ??
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: GSColors.primaryLight.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: GSColors.primaryLight.withOpacity(0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 14,
                  color: GSColors.primaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatNumber(totalExistencia),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GSColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
