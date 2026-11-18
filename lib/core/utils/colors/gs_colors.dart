import 'package:flutter/material.dart';

class GSColors {
  GSColors._();

  // ================= BASE =================

  static const baseWhite = Color(0xFFFFFFFF);

  static const grey50 = Color(0xFFF4F7F8);
  static const grey100 = Color(0xFFEBF0F2);
  static const grey150 = Color(0xFFE8E8E8);
  static const grey200 = Color(0xFFCFD2D3);
  static const grey300 = Color(0xFFC1C5C8);
  static const grey400 = Color(0xFFA2A9AD);
  static const grey500 = Color(0xFF7B868C);
  static const grey600 = Color(0xFF5B6670);

  static const secondary700 = Color(0xFF323E48);
  static const secondary800 = Color(0xFF1E1E1E);

  static const primary100 = Color(0xFFEB0029);
  static const primary200 = Color(0xFFBD001F);
  static const primary300 = Color(0xFF8F0017);

  static const alert100 = Color(0xFFFD6120);
  static const warning100 = Color(0xFFF5BE64);
  static const positive100 = Color(0xFF6CC04A);

  // ================= LIGHT THEME =================

  static const primaryLight = primary100;
  static const onPrimaryLight = baseWhite;

  static const secondaryLight = secondary700;
  static const onSecondaryLight = baseWhite;

  static const backgroundLight = grey100;
  static const onBackgroundLight = secondary700;

  static const surfaceLight = baseWhite;
  static const onSurfaceLight = secondary700;

  static const errorLight = primary100;
  static const onErrorLight = baseWhite;

  static const appBarIconLight = secondary700;
  static const cardShadowLight = Color.fromRGBO(50, 62, 72, 0.12);

  static const bodyTextLight = secondary700;
  static const bodyMediumLight = grey600;
  static const headlineLight = secondary700;
  static const titleMediumLight = secondary700;

  static const iconLight = grey600;
  static const iconDisabledLight = grey400;
  static const iconInverseLight = baseWhite;

  static const borderLight = grey600;
  static const borderSubtleLight = grey150;
  static const borderDisabledLight = grey400;

  static const hoverLight = primary200;
  static const activeMenuLight = primary300;

  // ================= DARK THEME =================

  static const primaryDark = primary100;
  static const onPrimaryDark = baseWhite;

  static const secondaryDark = grey300;
  static const onSecondaryDark = secondary800;

  static const backgroundDark = secondary800;
  static const onBackgroundDark = baseWhite;

  static const surfaceDark = secondary700;
  static const onSurfaceDark = baseWhite;

  static const errorDark = primary100;
  static const onErrorDark = baseWhite;

  static const appBarIconDark = baseWhite;
  static const cardShadowDark = Color.fromRGBO(0, 0, 0, 0.45);

  static const bodyTextDark = baseWhite;
  static const bodyMediumDark = grey300;
  static const headlineDark = baseWhite;
  static const titleMediumDark = baseWhite;

  static const iconDark = baseWhite;
  static const iconDisabledDark = grey500;
  static const iconInverseDark = secondary700;

  static const borderDark = secondary700;
  static const borderSubtleDark = grey600;
  static const borderDisabledDark = grey500;

  static const hoverDark = primary200;
  static const activeMenuDark = primary300;

  // ================= STATUS COLORS =================

  static const error = primary100;
  static const alerta = alert100;
  static const aviso = warning100;
  static const positivo = positive100;

  // ================= OVERLAYS =================

  static const overlay = Color.fromRGBO(50, 62, 72, 0.70);
  static const overlayDark = Color.fromRGBO(0, 0, 0, 0.40);

  // ================= PRIMARY SWATCH =================

  static const primarySwatchLight = MaterialColor(
    0xFFEB0029,
    <int, Color>{
      50: Color(0xFFFFF1F3),
      100: Color(0xFFFFD9DF),
      200: Color(0xFFFFA8B6),
      300: Color(0xFFFF6B82),
      400: Color(0xFFFF3353),
      500: Color(0xFFEB0029),
      600: Color(0xFFBD001F),
      700: Color(0xFF8F0017),
      800: Color(0xFF650010),
      900: Color(0xFF3D000A),
    },
  );

  static const primarySwatchDark = primarySwatchLight;
}