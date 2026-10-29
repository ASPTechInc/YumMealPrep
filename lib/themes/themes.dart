import 'package:flutter/material.dart';

import 'package:yummealprep/themes/colours.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colourScheme = ColorScheme.fromSeed(
      seedColor: AppColours.seed,
      brightness: brightness,
    );
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
