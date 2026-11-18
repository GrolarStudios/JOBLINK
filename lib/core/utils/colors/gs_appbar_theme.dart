import 'package:flutter/material.dart';
import 'gs_colors.dart';

class GSAppBarTheme {
  GSAppBarTheme._();

  static const light = AppBarTheme(
    color: GSColors.primaryLight,
    iconTheme: IconThemeData(color: GSColors.appBarIconLight),
    elevation: 4.0,
  );

  static const dark = AppBarTheme(
    color: GSColors.primaryDark,
    iconTheme: IconThemeData(color: GSColors.appBarIconDark),
    elevation: 4.0,
  );
}
