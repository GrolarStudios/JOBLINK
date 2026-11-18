import 'package:flutter/material.dart';
import 'gs_colors.dart';

class GSCardTheme {
  GSCardTheme._();

  static final light = CardThemeData(
    color: GSColors.surfaceLight,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: GSColors.cardShadowLight,
  );

  static final dark = CardThemeData(
    color: GSColors.surfaceDark,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: GSColors.cardShadowDark,
  );
}
