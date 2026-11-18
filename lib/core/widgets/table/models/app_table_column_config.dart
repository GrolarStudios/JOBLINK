// app_table_column_config.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TableTopBarBuilder = Widget Function(
    ValueChanged<String> onSearchChanged,
    );

class AppTableColumnConfig {
  final String header;
  final String key;

  final double? width;

  final Widget Function()? headerBuilder;

  /// Activa o desactiva filtro por columna
  final bool enableFilter;

  /// Activa o desactiva ordenamiento al tocar el header
  final bool enableSorting;

  final bool enableCellTap;

  final void Function(
      BuildContext context,
      Map<String, dynamic> rowData,
      )? onCellTap;

  final bool enableObservationIcon;
  final String? observationKey;

  final bool enableHoverEffect;
  final bool enableCustomCellColor;

  final Color? cellColor;
  final Color? hoverColor;
  final Color? textColor;

  final int maxLines;

  final bool enableInput;
  final bool inputEnabled;

  final String? inputHintText;

  final TextInputType? keyboardType;

  final List<TextInputFormatter>? inputFormatters;

  final bool Function(Map<String, dynamic> rowData)? inputVisibilityBuilder;

  final bool Function(Map<String, dynamic> rowData)? inputEnabledBuilder;

  final bool allowBulkApply;

  final void Function(
      BuildContext context,
      Map<String, dynamic> rowData,
      String value,
      )? onInputChanged;

  final void Function(
      BuildContext context,
      Map<String, dynamic> rowData,
      String value,
      )? onInputSubmitted;

  final Widget Function(
      BuildContext context,
      Map<String, dynamic> rowData,
      )? customCellBuilder;

  const AppTableColumnConfig({
    required this.header,
    required this.key,
    this.width,
    this.headerBuilder,

    /// Por defecto todas las columnas sí tienen filtro
    this.enableFilter = true,

    /// Por defecto todas las columnas sí se pueden ordenar
    this.enableSorting = true,

    this.enableCellTap = false,
    this.onCellTap,
    this.enableObservationIcon = false,
    this.observationKey,
    this.enableHoverEffect = false,
    this.enableCustomCellColor = false,
    this.cellColor,
    this.hoverColor,
    this.textColor,
    this.maxLines = 2,
    this.enableInput = false,
    this.inputEnabled = true,
    this.inputHintText,
    this.keyboardType,
    this.inputFormatters,
    this.inputVisibilityBuilder,
    this.inputEnabledBuilder,
    this.allowBulkApply = false,
    this.onInputChanged,
    this.onInputSubmitted,
    this.customCellBuilder,
  });
}