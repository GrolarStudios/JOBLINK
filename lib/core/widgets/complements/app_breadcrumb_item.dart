import 'package:flutter/material.dart';

class AppBreadcrumbItem {
  final String label;
  final String? routeName;
  final Object? arguments;
  final VoidCallback? onTap;

  const AppBreadcrumbItem({
    required this.label,
    this.routeName,
    this.arguments,
    this.onTap,
  });
}