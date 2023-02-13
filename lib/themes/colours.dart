import 'package:flutter/material.dart';

class AppColours {
  static   HexColour primaryColour = HexColour("#B1A582");
  static final MaterialColor dark = _factoryColor(0xff3a3a3a);

  static MaterialColor _factoryColor(int color) {
    return MaterialColor(color, <int, Color>{
      50: Color(color),
      100: Color(color),
      200: Color(color),
      300: Color(color),
      400: Color(color),
      500: Color(color),
      600: Color(color),
      700: Color(color),
      800: Color(color),
      900: Color(color),
    });
  }
}

class HexColour extends Color {
  static int _getColourFromHex(String hexColour) {
    hexColour = hexColour.toUpperCase().replaceAll("#", "");
    if (hexColour.length == 6) {
      hexColour = "FF$hexColour";
    }
    return int.parse(hexColour, radix: 16);
  }

  HexColour(final String hexColor) : super(_getColourFromHex(hexColor));
}
