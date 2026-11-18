import 'package:flutter/material.dart';
import '../../utils/colors/gs_colors.dart';

class AppPageCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry outerPadding;
  final EdgeInsetsGeometry innerPadding;

  const AppPageCard({
    super.key,
    required this.child,
    this.outerPadding = const EdgeInsets.all(16),
    this.innerPadding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: outerPadding,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: GSColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: GSColors.cardShadowLight,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: innerPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}
