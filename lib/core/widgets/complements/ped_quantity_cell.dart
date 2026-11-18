import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/colors/gs_colors.dart';

class PedQuantityCell extends StatelessWidget {
  final Map<String, dynamic> row;
  final int rowIndex;
  final String productId;
  final FocusNode focusNode;
  final void Function({
  required int currentIndex,
  required bool moveDown,
  }) onMoveFocus;
  final VoidCallback? onLastSubmitted;
  final ValueChanged<String>? onSubmitted;

  const PedQuantityCell({
    super.key,
    required this.row,
    required this.rowIndex,
    required this.productId,
    required this.focusNode,
    required this.onMoveFocus,
    this.onLastSubmitted,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: row['pedXCjs']?.toString() ?? '',
    );

    final bool wasPrefilled = row['pedXCjsWasPrefilled'] == true;
    final bool wasTouched = row['pedXCjsTouched'] == true;
    final bool isSuggested = wasPrefilled && !wasTouched;

    return SizedBox(
      width: 90,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;

          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            onMoveFocus(
              currentIndex: rowIndex,
              moveDown: true,
            );
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            onMoveFocus(
              currentIndex: rowIndex,
              moveDown: false,
            );
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSuggested ? GSColors.grey600 : GSColors.secondary800,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isSuggested ? GSColors.grey300 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isSuggested ? GSColors.grey500 : GSColors.grey300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isSuggested ? GSColors.grey500 : GSColors.grey300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: GSColors.primaryLight,
                width: 1.6,
              ),
            ),
          ),
          onChanged: (value) {
            row['pedXCjs'] = value;
            row['pedXCjsTouched'] = true;

            final original = (row['pedXCjsOriginal'] ?? '').toString().trim();

            row['pedXCjsEdited'] = value.trim() != original;
          },
          onSubmitted: (value) {
            row['pedXCjs'] = value;
            row['pedXCjsTouched'] = true;

            onSubmitted?.call(value);
          },
        ),
      ),
    );
  }
}