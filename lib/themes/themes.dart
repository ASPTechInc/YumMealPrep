import 'package:flutter/material.dart';

import 'package:yummealprep/themes/colours.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    var colourScheme = ColorScheme.fromSeed(
      seedColor: AppColours.seed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      // The seeded neutrals carry a teal tint, so take the dark surfaces from
      // a monochrome scheme to get plain greys while keeping teal accents.
      final neutral = ColorScheme.fromSeed(
        seedColor: AppColours.seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
      );
      colourScheme = colourScheme.copyWith(
        surface: neutral.surface,
        surfaceDim: neutral.surfaceDim,
        surfaceBright: neutral.surfaceBright,
        surfaceContainerLowest: neutral.surfaceContainerLowest,
        surfaceContainerLow: neutral.surfaceContainerLow,
        surfaceContainer: neutral.surfaceContainer,
        surfaceContainerHigh: neutral.surfaceContainerHigh,
        surfaceContainerHighest: neutral.surfaceContainerHighest,
        onSurface: neutral.onSurface,
        onSurfaceVariant: neutral.onSurfaceVariant,
        outline: neutral.outline,
        outlineVariant: neutral.outlineVariant,
        inverseSurface: neutral.inverseSurface,
        onInverseSurface: neutral.onInverseSurface,
        surfaceTint: Colors.transparent,
      );
    }
    return ThemeData(
      colorScheme: colourScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
