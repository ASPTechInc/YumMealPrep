import 'package:flutter/material.dart';

/// The colours used across YumMealPrep.
///
/// Material 3 derives the full light and dark palettes from [seed], so most
/// widgets take their colours from `Theme.of(context).colorScheme` instead
/// of from here.
abstract final class AppColours {
  static const Color seed = Color(0xFF00897B);

  // Meal type accents, used for calendar markers, chips and category cards.
  static const Color appetisers = Color(0xFF43A047);
  static const Color breakfast = Color(0xFFFFB300);
  static const Color lunch = Color(0xFF1E88E5);
  static const Color dinner = Color(0xFF3949AB);
  static const Color dessert = Color(0xFFFB8C00);
  static const Color smoothies = Color(0xFFD81B60);
}

/// A [Color] built from a hex string such as `#B1A582` or `FFB1A582`.
class HexColour extends Color {
  HexColour(String hexColor) : super(_getColourFromHex(hexColor));

  static int _getColourFromHex(String hexColour) {
    var hex = hexColour.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return int.parse(hex, radix: 16);
  }
}
