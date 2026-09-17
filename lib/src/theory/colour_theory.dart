import 'package:flutter/material.dart';

abstract final class ColourTheory {
  static Color complementary(Color color) {
    return _shiftHue(color, 180);
  }

  static List<Color> analogous(Color color, {double spread = 30}) {
    return [_shiftHue(color, -spread), color, _shiftHue(color, spread)];
  }

  static List<Color> triadic(Color color) {
    return [color, _shiftHue(color, 120), _shiftHue(color, 240)];
  }

  static List<Color> tetradic(Color color) {
    return [
      color,
      _shiftHue(color, 90),
      _shiftHue(color, 180),
      _shiftHue(color, 270),
    ];
  }

  static List<Color> splitComplementary(Color color, {double spread = 30}) {
    return [
      color,
      _shiftHue(color, 180 - spread),
      _shiftHue(color, 180 + spread),
    ];
  }

  static List<Color> monochromatic(Color color, {int count = 5}) {
    final hsv = HSVColor.fromColor(color);
    final items = <Color>[];
    if (count <= 1) {
      return [color];
    }
    for (var i = 0; i < count; i++) {
      final t = i / (count - 1);
      final value = 0.2 + (0.75 * t);
      final saturation = (hsv.saturation * (1 - (0.45 * t))).clamp(0.15, 1.0);
      items.add(
        hsv.withValue(value.clamp(0, 1)).withSaturation(saturation).toColor(),
      );
    }
    return items;
  }

  static List<Color> fullHarmonySet(Color color) {
    return [
      ...analogous(color),
      complementary(color),
      ...triadic(color),
      ...splitComplementary(color),
      ...monochromatic(color),
    ];
  }

  static Color _shiftHue(Color color, double deltaDegrees) {
    final hsv = HSVColor.fromColor(color);
    final shifted = (hsv.hue + deltaDegrees) % 360;
    return hsv.withHue(shifted < 0 ? shifted + 360 : shifted).toColor();
  }
}
