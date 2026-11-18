import 'package:flutter/material.dart';
import '../utils/colors/gs_colors.dart';
import '../utils/colors/gs_text_theme.dart';
import '../utils/colors/gs_card_theme.dart';
import '../utils/colors/gs_appbar_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: GSColors.primaryLight,
        onPrimary: GSColors.onPrimaryLight,
        secondary: GSColors.secondaryLight,
        onSecondary: GSColors.onSecondaryLight,
        background: GSColors.backgroundLight,
        onBackground: GSColors.onBackgroundLight,
        surface: GSColors.surfaceLight,
        onSurface: GSColors.onSurfaceLight,
        error: GSColors.errorLight,
        onError: GSColors.onErrorLight,
      ),
      primarySwatch: GSColors.primarySwatchLight,
      scaffoldBackgroundColor: GSColors.backgroundLight,
      appBarTheme: GSAppBarTheme.light,
      cardTheme: GSCardTheme.light,
      textTheme: GSTextTheme.light,
      iconTheme: const IconThemeData(color: GSColors.iconLight),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: GSColors.primaryDark,
        onPrimary: GSColors.onPrimaryDark,
        secondary: GSColors.secondaryDark,
        onSecondary: GSColors.onSecondaryDark,
        background: GSColors.backgroundDark,
        onBackground: GSColors.onBackgroundDark,
        surface: GSColors.surfaceDark,
        onSurface: GSColors.onSurfaceDark,
        error: GSColors.errorDark,
        onError: GSColors.onErrorDark,
      ),
      primarySwatch: GSColors.primarySwatchDark,
      scaffoldBackgroundColor: GSColors.backgroundDark,
      appBarTheme: GSAppBarTheme.dark,
      cardTheme: GSCardTheme.dark,
      textTheme: GSTextTheme.dark,
      iconTheme: const IconThemeData(color: GSColors.iconDark),
    );
  }
}
