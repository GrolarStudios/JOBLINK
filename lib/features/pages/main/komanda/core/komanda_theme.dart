import 'package:flutter/material.dart';

class KomandaTheme {
  const KomandaTheme._();

  // Colores base
  static const Color bg = Color(0xFFF5F7FB);

  static const Color text = Color(0xFF172238);
  static const Color softText = Color(0xFF65728A);

  static const Color border = Color(0xFFE1E7F0);

  static const Color purple = Color(0xFFEA6B0A);
  static const Color purple2 = Color(0xFFC55300);

  static const Color green = Color(0xFF18B85A);
  static const Color orange = Color(0xFFFF7A00);
  static const Color red = Color(0xFFFF2D55);
  static const Color blue = Color(0xFF2684FF);

  // Compatibilidad
  static const Color primary = purple;
  static const Color primaryDark = purple2;

  static const Color success = green;
  static const Color warning = orange;
  static const Color danger = red;
  static const Color info = blue;

  static const Color accent = purple;

  /// Color de fondo para tarjetas
  static const Color card = Colors.white;

  /// Decoración estándar para tarjetas
  static BoxDecoration cardDecoration({
    double radius = 20,
  }) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: border,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140F254A),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    );
  }

  /// Gradiente principal
  static BoxDecoration purpleGradient({
    double radius = 16,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          purple,
          purple2,
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24EA6B0A),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    );
  }
}