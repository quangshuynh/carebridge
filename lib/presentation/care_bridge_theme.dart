import 'package:flutter/material.dart';

/// The board's small, high-contrast palette. Choice colors live with each
/// choice's visual in the domain data.
abstract final class CareBridgeColors {
  static const background = Color(0xFFF5F7F4);
  static const surface = Colors.white;
  static const brand = Color(0xFF245D58);
  static const ink = Color(0xFF102B29);
  static const outline = Color(0xFF173A37);
  static const idleVisual = Color(0xFFE1ECEA);
}

ThemeData buildCareBridgeTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: CareBridgeColors.brand,
    surface: CareBridgeColors.background,
  ),
  scaffoldBackgroundColor: CareBridgeColors.background,
  useMaterial3: true,
);
