import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'models/app_table_column_config.dart';

typedef TableTopBarBuilder = Widget Function(ValueChanged<String> onSearchChanged);

class AppFrozenColumnsTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<AppTableColumnConfig> columns;
  final int fixedColumnCount;
  final int rowsPerPage;
  final int currentPage;
  final TableTopBarBuilder? topBarBuilder;
  final bool enableHorizontalScroll;

  /// Limita cuántas columnas del área con scroll se ven en pantalla.
  /// Ejemplo: 25 proveedores visibles y el resto aparece al mover scroll.
  /// Solo aplica cuando enableHorizontalScroll = true.
  final int? maxScrollableColumnCount;

  const AppFrozenColumnsTable({
    super.key,
    required this.data,
    required this.columns,
    required this.fixedColumnCount,
    required this.rowsPerPage,
    this.currentPage = 0,
    this.topBarBuilder,
    this.enableHorizontalScroll = true,
    this.maxScrollableColumnCount,
  });

  @override
  State<AppFrozenColumnsTable> createState() => _AppFrozenColumnsTableState();
}

class _AppFrozenColumnsTableState extends State<AppFrozenColumnsTable> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerController = ScrollController();
  final ScrollController _bodyController = ScrollController();

  static const double _rowHeight = 36;
  static const double _headerHeight = 42;

  String? _hoveredRowKey;
  String? _sortColumn;
  bool _sortAscending = true;
  bool _syncingHorizontalScroll = false;

  List<AppTableColumnConfig> get _fixedColumns {
    final safeCount = widget.fixedColumnCount.clamp(0, widget.columns.length);
    return widget.columns.take(safeCount).toList();
  }

  List<AppTableColumnConfig> get _scrollColumns {
    final safeCount = widget.fixedColumnCount.clamp(0, widget.columns.length);
    return widget.columns.skip(safeCount).toList();
  }

  List<Map<String, dynamic>> get _sortedData {
    final data = List<Map<String, dynamic>>.from(widget.data);

    if (_sortColumn == null) return data;

    data.sort((a, b) {
      final aValue = a[_sortColumn];
      final bValue = b[_sortColumn];

      final aNum = _toComparableNumber(aValue);
      final bNum = _toComparableNumber(bValue);

      int result;

      if (aNum != null && bNum != null) {
        result = aNum.compareTo(bNum);
      } else {
        result = _cleanText(aValue).compareTo(_cleanText(bValue));
      }

      return _sortAscending ? result : -result;
    });

    return data;
  }

  int get totalPages {
    if (_sortedData.isEmpty) return 1;
    return (_sortedData.length / widget.rowsPerPage).ceil();
  }

  List<Map<String, dynamic>> get _pagedData {
    final data = _sortedData;
    final safePage = widget.currentPage.clamp(0, totalPages - 1);
    final start = safePage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, data.length);

    if (start >= data.length) return [];

    return data.sublist(start, end);
  }

  num? _toComparableNumber(dynamic value) {
    if (value == null) return null;

    final cleaned = value
        .toString()
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .replaceAll('%', '')
        .trim();

    return num.tryParse(cleaned);
  }

  String _cleanText(dynamic value) {
    return (value ?? '').toString().toLowerCase().trim();
  }

  void _toggleSort(AppTableColumnConfig column) {
    setState(() {
      if (_sortColumn != column.key) {
        _sortColumn = column.key;
        _sortAscending = true;
      } else if (_sortAscending) {
        _sortAscending = false;
      } else {
        _sortColumn = null;
        _sortAscending = true;
      }
    });
  }

  IconData _sortIconFor(AppTableColumnConfig column) {
    if (_sortColumn != column.key) {
      return Icons.unfold_more_rounded;
    }

    return _sortAscending
        ? Icons.keyboard_arrow_up_rounded
        : Icons.keyboard_arrow_down_rounded;
  }

  @override
  void initState() {
    super.initState();
    _headerController.addListener(_syncHeaderToBody);
    _bodyController.addListener(_syncBodyToHeader);
  }

  @override
  void dispose() {
    _headerController.removeListener(_syncHeaderToBody);
    _bodyController.removeListener(_syncBodyToHeader);
    _verticalController.dispose();
    _headerController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _syncHeaderToBody() {
    if (_syncingHorizontalScroll ||
        !_headerController.hasClients ||
        !_bodyController.hasClients) {
      return;
    }

    _syncingHorizontalScroll = true;
    final max = _bodyController.position.maxScrollExtent;
    final offset = _headerController.offset.clamp(0.0, max);
    _bodyController.jumpTo(offset);
    _syncingHorizontalScroll = false;
  }

  void _syncBodyToHeader() {
    if (_syncingHorizontalScroll ||
        !_headerController.hasClients ||
        !_bodyController.hasClients) {
      return;
    }

    _syncingHorizontalScroll = true;
    final max = _headerController.position.maxScrollExtent;
    final offset = _bodyController.offset.clamp(0.0, max);
    _headerController.jumpTo(offset);
    _syncingHorizontalScroll = false;
  }


  void _handleHorizontalPointerSignal({
    required PointerSignalEvent pointerSignal,
    required ScrollController controller,
  }) {
    if (pointerSignal is! PointerScrollEvent || !controller.hasClients) {
      return;
    }

    final delta = pointerSignal.scrollDelta.dx.abs() > 0
        ? pointerSignal.scrollDelta.dx
        : pointerSignal.scrollDelta.dy;

    if (delta == 0) return;

    final nextOffset = (controller.offset + delta).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );

    if (nextOffset != controller.offset) {
      controller.jumpTo(nextOffset);
    }
  }

  double _widthFor(AppTableColumnConfig column) {
    if (column.width != null) return column.width!;
    return 140;
  }

  double _columnsWidth(List<AppTableColumnConfig> columns) {
    return columns.fold<double>(
      0,
          (total, column) => total + _widthFor(column),
    );
  }

  String _rowKey(Map<String, dynamic> row, int index) {
    return (row['id'] ??
        row['productId'] ??
        row['clave'] ??
        row['pk'] ??
        row['nombre'] ??
        index)
        .toString();
  }

  Widget _cellShell({
    required double width,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: child,
    );
  }

  Widget _buildHeaderRow(
      List<AppTableColumnConfig> columns, {
        required bool fixed,
        required double Function(AppTableColumnConfig column, bool fixed) widthFor,
      }) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(
          right: fixed
              ? const BorderSide(color: Color(0xFFCBD5E1), width: 1.4)
              : BorderSide.none,
          bottom: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          return _cellShell(
            width: widthFor(column, fixed),
            borderColor: const Color(0xFFCBD5E1),
            child: column.headerBuilder != null
                ? column.headerBuilder!()
                : InkWell(
              onTap: () => _toggleSort(column),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        column.header,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Icon(
                      _sortIconFor(column),
                      size: 14,
                      color: _sortColumn == column.key
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow({
    required BuildContext context,
    required Map<String, dynamic> row,
    required String rowKey,
    required int index,
    required List<AppTableColumnConfig> columns,
    required bool fixed,
    required double Function(AppTableColumnConfig column, bool fixed) widthFor,
  }) {
    final hovered = _hoveredRowKey == rowKey;

    final baseColor = hovered
        ? const Color(0xFFEFF6FF)
        : index.isEven
        ? Colors.white
        : const Color(0xFFF8FAFC);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowKey = rowKey),
      onExit: (_) => setState(() {
        if (_hoveredRowKey == rowKey) {
          _hoveredRowKey = null;
        }
      }),
      child: Container(
        height: _rowHeight,
        decoration: BoxDecoration(
          color: baseColor,
          border: Border(
            right: fixed
                ? const BorderSide(color: Color(0xFFE2E8F0), width: 1.4)
                : BorderSide.none,
            bottom: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: columns.map((column) {
            return _cellShell(
              width: widthFor(column, fixed),
              borderColor: const Color(0xFFE2E8F0),
              child: column.customCellBuilder != null
                  ? Center(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontSize: 10, height: 1.15),
                  child: column.customCellBuilder!(context, row),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Align(
                  alignment: column.key == 'nombre'
                      ? Alignment.centerLeft
                      : Alignment.center,
                  child: Text(
                    (row[column.key] ?? '-').toString(),
                    maxLines: column.maxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: column.key == 'nombre'
                        ? TextAlign.left
                        : TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final rows = _pagedData;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _columnsWidth(widget.columns);

        if (!widget.enableHorizontalScroll) {
          final columns = widget.columns;
          final originalWidth = _columnsWidth(columns);
          final safeOriginalWidth = originalWidth <= 0 ? availableWidth : originalWidth;
          final scale = availableWidth / safeOriginalWidth;

          double fitWidthFor(AppTableColumnConfig column, bool fixed) {
            final base = _widthFor(column);
            return base * scale;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.topBarBuilder != null) ...[
                widget.topBarBuilder!((_) {}),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: availableWidth,
                          child: _buildHeaderRow(
                            columns,
                            fixed: false,
                            widthFor: fitWidthFor,
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _verticalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _verticalController,
                              child: SizedBox(
                                width: availableWidth,
                                child: Column(
                                  children: List.generate(rows.length, (index) {
                                    final row = rows[index];
                                    final key = _rowKey(row, index);

                                    return _buildDataRow(
                                      context: context,
                                      row: row,
                                      rowKey: key,
                                      index: index,
                                      columns: columns,
                                      fixed: false,
                                      widthFor: fitWidthFor,
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final fixedColumns = _fixedColumns;
        final scrollColumns = _scrollColumns;

        final fixedWidth = _columnsWidth(fixedColumns);
        final originalScrollWidth = _columnsWidth(scrollColumns);
        final totalOriginalWidth = fixedWidth + originalScrollWidth;

        final shouldLimitScrollViewport =
            widget.maxScrollableColumnCount != null &&
                widget.maxScrollableColumnCount! > 0 &&
                scrollColumns.length > widget.maxScrollableColumnCount!;

        final shouldExpand = totalOriginalWidth < availableWidth &&
            !shouldLimitScrollViewport;

        final extraWidth = shouldExpand ? availableWidth - totalOriginalWidth : 0.0;

        final visibleColumnsCount = fixedColumns.length + scrollColumns.length;

        final extraPerColumn =
        shouldExpand && visibleColumnsCount > 0 ? extraWidth / visibleColumnsCount : 0.0;

        double effectiveWidthFor(AppTableColumnConfig column, bool fixed) {
          final base = _widthFor(column);
          if (!shouldExpand) return base;
          return base + extraPerColumn;
        }

        final effectiveFixedWidth = fixedColumns.fold<double>(
          0,
              (total, column) => total + effectiveWidthFor(column, true),
        );

        final effectiveScrollWidth = scrollColumns.fold<double>(
          0,
              (total, column) => total + effectiveWidthFor(column, false),
        );

        final availableScrollViewportWidth =
        (availableWidth - effectiveFixedWidth).clamp(0.0, availableWidth);

        final limitedScrollViewportWidth = shouldLimitScrollViewport
            ? scrollColumns
            .take(widget.maxScrollableColumnCount!)
            .fold<double>(
          0,
              (total, column) => total + effectiveWidthFor(column, false),
        )
            : availableScrollViewportWidth;

        final scrollViewportWidth = availableScrollViewportWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.topBarBuilder != null) ...[
              widget.topBarBuilder!((_) {}),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: effectiveFixedWidth,
                            child: _buildHeaderRow(
                              fixedColumns,
                              fixed: true,
                              widthFor: effectiveWidthFor,
                            ),
                          ),
                          if (scrollColumns.isNotEmpty)
                            SizedBox(
                              width: scrollViewportWidth,
                              child: Scrollbar(
                                controller: _headerController,
                                thumbVisibility: true,
                                notificationPredicate: (_) => true,
                                child: Listener(
                                  onPointerSignal: (pointerSignal) {
                                    _handleHorizontalPointerSignal(
                                      pointerSignal: pointerSignal,
                                      controller: _headerController,
                                    );
                                  },
                                  child: SingleChildScrollView(
                                    controller: _headerController,
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: effectiveScrollWidth,
                                      child: _buildHeaderRow(
                                        scrollColumns,
                                        fixed: false,
                                        widthFor: effectiveWidthFor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _verticalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: effectiveFixedWidth,
                                  child: Column(
                                    children: List.generate(rows.length, (index) {
                                      final row = rows[index];
                                      final key = _rowKey(row, index);

                                      return _buildDataRow(
                                        context: context,
                                        row: row,
                                        rowKey: key,
                                        index: index,
                                        columns: fixedColumns,
                                        fixed: true,
                                        widthFor: effectiveWidthFor,
                                      );
                                    }),
                                  ),
                                ),
                                if (scrollColumns.isNotEmpty)
                                  SizedBox(
                                    width: scrollViewportWidth,
                                    child: Scrollbar(
                                      controller: _bodyController,
                                      thumbVisibility: true,
                                      notificationPredicate: (_) => true,
                                      child: SingleChildScrollView(
                                        controller: _bodyController,
                                        scrollDirection: Axis.horizontal,
                                        physics: const NeverScrollableScrollPhysics(),
                                        child: SizedBox(
                                          width: effectiveScrollWidth,
                                          child: Column(
                                            children: List.generate(rows.length, (index) {
                                              final row = rows[index];
                                              final key = _rowKey(row, index);

                                              return _buildDataRow(
                                                context: context,
                                                row: row,
                                                rowKey: key,
                                                index: index,
                                                columns: scrollColumns,
                                                fixed: false,
                                                widthFor: effectiveWidthFor,
                                              );
                                            }),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
