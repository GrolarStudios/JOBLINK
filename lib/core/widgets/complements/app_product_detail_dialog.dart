import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shared_sucursales_hover_cell.dart';

class AppProductDetailDialog extends StatelessWidget {
  final String title;
  final double width;
  final List<Widget> infoRows;
  final Widget child;
  final List<Widget> actions;

  const AppProductDetailDialog({
    super.key,
    required this.title,
    required this.infoRows,
    required this.child,
    required this.actions,
    this.width = 900,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppProductDialogTitle(title: title),
              const SizedBox(height: 14),
              AppProductInfoPanel(rows: infoRows),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }
}

class AppProductDialogTitle extends StatelessWidget {
  final String title;

  const AppProductDialogTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
      ),
    );
  }
}

class AppProductInfoPanel extends StatelessWidget {
  final List<Widget> rows;

  const AppProductInfoPanel({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class AppProductInfoRow extends StatelessWidget {
  final String label;
  final Widget value;
  final double labelWidth;
  final EdgeInsets padding;

  const AppProductInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 155,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
  });

  factory AppProductInfoRow.text({
    Key? key,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF111827),
    FontWeight valueWeight = FontWeight.w900,
    double labelWidth = 155,
  }) {
    return AppProductInfoRow(
      key: key,
      label: label,
      labelWidth: labelWidth,
      value: SizedBox(
        height: AppProductDialogSizes.valueHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: valueWeight,
              color: valueColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class AppProductDialogSizes {
  const AppProductDialogSizes._();

  static const double valueWidth = 170;
  static const double valueHeight = 34;
  static const double valueRadius = 8;
}

class AppProductValueBadge extends StatelessWidget {
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final double width;
  final double height;

  const AppProductValueBadge({
    super.key,
    required this.value,
    this.backgroundColor = const Color(0xFFEFF6FF),
    this.foregroundColor = const Color(0xFF1D4ED8),
    this.width = AppProductDialogSizes.valueWidth,
    this.height = AppProductDialogSizes.valueHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
          border: Border.all(color: foregroundColor.withOpacity(0.16)),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class AppProductQuantityInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double width;
  final double height;

  const AppProductQuantityInput({
    super.key,
    required this.controller,
    required this.enabled,
    this.onChanged,
    this.onSubmitted,
    this.width = AppProductDialogSizes.valueWidth,
    this.height = AppProductDialogSizes.valueHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        height: height,
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFE7E6E6),
            hintText: 'Cantidad',
            hintStyle: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
              borderSide: const BorderSide(color: Color(0xFFD9E2F3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
              borderSide: const BorderSide(color: Color(0xFFD9E2F3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
              borderSide: const BorderSide(
                color: Color(0xFF111827),
                width: 1.4,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onTap: () {
            if (controller.text.isNotEmpty) {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          },
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      ),
    );
  }
}

class AppProductSucursalesHoverValue extends StatelessWidget {
  final List<Map<String, dynamic>> sucursalesDetalle;
  final double width;
  final double height;

  const AppProductSucursalesHoverValue({
    super.key,
    required this.sucursalesDetalle,
    this.width = AppProductDialogSizes.valueWidth,
    this.height = AppProductDialogSizes.valueHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppProductDialogSizes.valueRadius),
          child: SizedBox.expand(
            child: SharedSucursalesHoverCell(
              row: {
                'sucursalesDetalle': sucursalesDetalle,
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AppProductDialogButtonStyles {
  const AppProductDialogButtonStyles._();

  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF111827),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: const BorderSide(
      color: Color(0xFFCBD5E1),
      width: 1.2,
    ),
    elevation: 0,
    shadowColor: Colors.transparent,
  );
}
