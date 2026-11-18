import 'package:flutter/material.dart';

class AppTableInputController {
  final TextEditingController bulkController;
  final FocusNode bulkFocusNode;
  final FocusNode? endFocusNode;
  final String Function(Map<String, dynamic> row) rowIdBuilder;

  final Map<String, FocusNode> _rowFocusNodes = {};

  AppTableInputController({
    required this.bulkController,
    required this.bulkFocusNode,
    required this.rowIdBuilder,
    this.endFocusNode,
  });

  void init() {
    bulkFocusNode.addListener(_handleBulkFocus);
  }

  void dispose() {
    bulkFocusNode.removeListener(_handleBulkFocus);

    for (final node in _rowFocusNodes.values) {
      node.dispose();
    }

    _rowFocusNodes.clear();
  }

  void _handleBulkFocus() {
    if (!bulkFocusNode.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!bulkFocusNode.hasFocus) return;

      bulkController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: bulkController.text.length,
      );
    });
  }

  FocusNode focusNodeFor(String productId) {
    return _rowFocusNodes.putIfAbsent(productId, () => FocusNode());
  }

  void cleanup(List<Map<String, dynamic>> rows) {
    final validIds = rows
        .map(rowIdBuilder)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final keysToRemove =
    _rowFocusNodes.keys.where((key) => !validIds.contains(key)).toList();

    for (final key in keysToRemove) {
      _rowFocusNodes[key]?.dispose();
      _rowFocusNodes.remove(key);
    }
  }

  void moveFocusByRow({
    required List<Map<String, dynamic>> rows,
    required int currentIndex,
    required bool moveDown,
  }) {
    if (rows.isEmpty) return;

    final targetIndex = moveDown ? currentIndex + 1 : currentIndex - 1;

    if (targetIndex < 0 || targetIndex >= rows.length) return;

    final targetId = rowIdBuilder(rows[targetIndex]);
    if (targetId.trim().isEmpty) return;

    focusNodeFor(targetId).requestFocus();
  }

  void focusEnd() {
    endFocusNode?.requestFocus();
  }
}
