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

/// Colors and stroke widths the board draws with, in standard or high
/// contrast. High contrast keeps each choice's own background color, so
/// choices stay distinguishable, and makes text, icons, and every border
/// black and heavier. Selection keeps its non-color cues in both.
@immutable
class CareBridgePalette extends ThemeExtension<CareBridgePalette> {
  const CareBridgePalette({
    required this.isHighContrast,
    required this.background,
    required this.surface,
    required this.selectedSurface,
    required this.onSelectedSurface,
    required this.ink,
    required this.outline,
    required this.idleBorder,
    required this.idleBorderWidth,
    required this.selectedBorderWidth,
    required this.confirmationBorder,
    required this.confirmationBorderWidth,
    required this.idleVisual,
    required this.focus,
  });

  static const standard = CareBridgePalette(
    isHighContrast: false,
    background: CareBridgeColors.background,
    surface: CareBridgeColors.surface,
    selectedSurface: CareBridgeColors.brand,
    onSelectedSurface: CareBridgeColors.surface,
    ink: CareBridgeColors.ink,
    outline: CareBridgeColors.outline,
    idleBorder: Color(0x33173A37),
    idleBorderWidth: 2,
    selectedBorderWidth: 6,
    confirmationBorder: CareBridgeColors.brand,
    confirmationBorderWidth: 2,
    idleVisual: CareBridgeColors.idleVisual,
    focus: CareBridgeColors.brand,
  );

  static const highContrast = CareBridgePalette(
    isHighContrast: true,
    background: Colors.white,
    surface: Colors.white,
    selectedSurface: Colors.black,
    onSelectedSurface: Colors.white,
    ink: Colors.black,
    outline: Colors.black,
    idleBorder: Colors.black,
    idleBorderWidth: 3,
    selectedBorderWidth: 8,
    confirmationBorder: Colors.black,
    confirmationBorderWidth: 3,
    idleVisual: Colors.white,
    focus: Colors.black,
  );

  final bool isHighContrast;
  final Color background;

  /// The confirmation area before anything is selected.
  final Color surface;

  /// The confirmation area once a choice is selected, and its text.
  final Color selectedSurface;
  final Color onSelectedSurface;

  /// Text, and icons drawn on light surfaces.
  final Color ink;

  /// Icons, the selected border, and the selected badge.
  final Color outline;
  final Color idleBorder;
  final double idleBorderWidth;
  final double selectedBorderWidth;
  final Color confirmationBorder;
  final double confirmationBorderWidth;
  final Color idleVisual;

  /// The keyboard and switch-access focus ring.
  final Color focus;

  static CareBridgePalette of(BuildContext context) =>
      Theme.of(context).extension<CareBridgePalette>() ?? standard;

  @override
  CareBridgePalette copyWith() => this;

  // Contrast changes at once instead of fading through weaker in-between
  // colors.
  @override
  CareBridgePalette lerp(CareBridgePalette? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

ThemeData buildCareBridgeTheme({bool highContrast = false}) {
  final palette = highContrast
      ? CareBridgePalette.highContrast
      : CareBridgePalette.standard;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: CareBridgeColors.brand,
      surface: palette.background,
      contrastLevel: highContrast ? 1 : 0,
    ),
    scaffoldBackgroundColor: palette.background,
    extensions: [palette],
    useMaterial3: true,
  );
}
