import 'package:flutter/material.dart';
import '../../utils/colors/gs_colors.dart';

class AppTableActionsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const AppTableActionsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderRadius = 14,
  });

  /// 🔥 CAMBIA ESTOS COLORES Y SE MODIFICA EN LAS 3 PÁGINAS
  static const Color backgroundColor = Color(0xFFF1F5F9);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: GSColors.cardShadowLight,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}