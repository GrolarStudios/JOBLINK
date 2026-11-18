import 'package:flutter/material.dart';
import 'gs_colors.dart';

class GSTextTheme {
  GSTextTheme._();

  static const light = TextTheme(
    bodyLarge: TextStyle(color: GSColors.bodyTextLight),
    bodyMedium: TextStyle(color: GSColors.bodyMediumLight),
    headlineSmall: TextStyle(
      color: GSColors.headlineLight,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(color: GSColors.titleMediumLight),
  );

  static const dark = TextTheme(
    bodyLarge: TextStyle(color: GSColors.bodyTextDark),
    bodyMedium: TextStyle(color: GSColors.bodyMediumDark),
    headlineSmall: TextStyle(
      color: GSColors.headlineDark,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(color: GSColors.titleMediumDark),
  );
}
