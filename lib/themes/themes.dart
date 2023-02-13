import 'package:flutter/material.dart';
import 'package:yummealprep/themes/colours.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(
          secondary: Colors.amber,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: AppColours.dark).copyWith(
          secondary: Colors.grey,
          brightness: Brightness.dark,
        ),
      );
}
