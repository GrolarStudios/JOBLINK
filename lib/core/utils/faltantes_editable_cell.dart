import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/utils/colors/gs_colors.dart';

class FaltantesEditableCell extends StatelessWidget {
  final Map<String, dynamic> row;
  final String field;
  final String hint;
  final bool enabled;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const FaltantesEditableCell({
    super.key,
    required this.row,
    required this.field,
    required this.hint,
    required this.enabled,
    required this.keyboardType,
    required this.inputFormatters,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final original = (row['${field}Original'] ?? '').toString().trim();
    final current = controller.text.trim();
    final hasText = current.isNotEmpty;

    final wasTouched = row['${field}Touched'] == true;
    final wasPrefilled = row['${field}WasPrefilled'] == true;
    final wasEdited = hasText && wasTouched && current != original;

    String? statusText() {
      if (!hasText) return null;
      if (wasEdited) return 'Modificado';
      if (wasPrefilled && current == original) return 'Sugerido';
      return null;
    }

    Color fillColor() {
      if (!enabled) return Colors.grey.shade100;
      if (wasEdited) return const Color(0xFFFFF8E1);
      if (wasPrefilled && current == original) return Colors.grey.shade200;
      return Colors.white;
    }

    Color borderColor() {
      if (wasEdited) return Colors.orange;
      if (wasPrefilled && current == original) return Colors.grey.shade500;
      return GSColors.primaryLight.withOpacity(0.18);
    }

    return SizedBox(
      width: 170,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              color: wasEdited ? Colors.orange.shade900 : GSColors.onSurfaceLight,
              fontWeight: wasEdited ? FontWeight.w700 : FontWeight.w500,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              isDense: false,
              filled: true,
              fillColor: fillColor(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              border: _border(borderColor(), wasEdited),
              enabledBorder: _border(borderColor(), wasEdited),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: wasEdited ? Colors.orange : GSColors.primaryLight,
                  width: 1.8,
                ),
              ),
            ),
            onTap: onTap,
            onChanged: onChanged,
          ),
          if (statusText() != null) ...[
            const SizedBox(height: 4),
            Text(
              statusText()!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: wasEdited ? Colors.orange.shade800 : Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, bool wasEdited) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color,
        width: wasEdited ? 1.6 : 1,
      ),
    );
  }
}
