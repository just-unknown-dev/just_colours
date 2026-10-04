import 'package:flutter/material.dart';

/// A named set of colours that go with a base colour.
@immutable
class ColourHarmony {
  /// Shown in the picker, e.g. "Triadic".
  final String name;

  /// The base colour and the colours that go with it: the base first,
  /// except in shades, where it sits between darker and lighter.
  final List<Color> colors;

  const ColourHarmony(this.name, this.colors);
}

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

  /// Darker to lighter versions of [color] at the same hue: [count] steps,
  /// the colour itself in the middle.
  static List<Color> shades(Color color, {int count = 7}) {
    final hsl = HSLColor.fromColor(color);
    if (count <= 1) return [color];
    final mid = (count - 1) / 2;
    return [
      for (var i = 0; i < count; i++)
        i == mid
            ? color
            : hsl
                  .withLightness(
                    i < mid
                        ? hsl.lightness * (0.25 + 0.75 * i / mid)
                        : hsl.lightness +
                              (1 - hsl.lightness) * 0.85 * (i - mid) / mid,
                  )
                  .toColor(),
    ];
  }

  /// Every harmony of [color], each with a name.
  static List<ColourHarmony> harmonies(Color color) {
    return [
      ColourHarmony('Complementary', [color, complementary(color)]),
      ColourHarmony('Analogous', [
        color,
        _shiftHue(color, -30),
        _shiftHue(color, 30),
      ]),
      ColourHarmony('Triadic', triadic(color)),
      ColourHarmony('Split complementary', splitComplementary(color)),
      ColourHarmony('Tetradic', tetradic(color)),
      ColourHarmony('Shades', shades(color)),
    ];
  }

  /// Every harmony of [color] in one list, each colour once.
  static List<Color> fullHarmonySet(Color color) {
    final seen = <int>{};
    return [
      for (final h in harmonies(color))
        for (final c in h.colors)
          if (seen.add(c.toARGB32())) c,
    ];
  }

  static Color _shiftHue(Color color, double deltaDegrees) {
    final hsv = HSVColor.fromColor(color);
    final shifted = (hsv.hue + deltaDegrees) % 360;
    return hsv.withHue(shifted < 0 ? shifted + 360 : shifted).toColor();
  }
}
