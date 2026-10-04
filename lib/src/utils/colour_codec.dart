import 'package:flutter/material.dart';

abstract final class ColourCodec {
  static String toHex(Color color, {bool includeAlpha = true}) {
    final a = (color.a * 255.0).round().clamp(0, 255);
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    final aHex = a.toRadixString(16).padLeft(2, '0').toUpperCase();
    final rHex = r.toRadixString(16).padLeft(2, '0').toUpperCase();
    final gHex = g.toRadixString(16).padLeft(2, '0').toUpperCase();
    final bHex = b.toRadixString(16).padLeft(2, '0').toUpperCase();
    return includeAlpha ? '#$aHex$rHex$gHex$bHex' : '#$rHex$gHex$bHex';
  }

  /// Reads `#RRGGBB` or `#AARRGGBB`; throws [FormatException] otherwise.
  static Color fromHex(String value) {
    final parsed = tryParseHex(value);
    if (parsed == null) {
      throw FormatException('Invalid color hex value: $value');
    }
    return parsed;
  }

  /// Reads a typed or pasted colour: `RGB`, `RRGGBB` or `AARRGGBB`, with or
  /// without `#` or `0x`, surrounding spaces ignored. Null when it is not
  /// one.
  static Color? tryParseHex(String value) {
    var s = value.trim();
    if (s.startsWith('#')) {
      s = s.substring(1);
    } else if (s.toLowerCase().startsWith('0x')) {
      s = s.substring(2);
    }
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return null;
    switch (s.length) {
      case 3:
        final expanded = s.split('').map((c) => '$c$c').join();
        return Color(int.parse('FF$expanded', radix: 16));
      case 6:
        return Color(int.parse('FF$s', radix: 16));
      case 8:
        return Color(int.parse(s, radix: 16));
    }
    return null;
  }

  /// 0–255 channel value.
  static int channel(double unit) => (unit * 255.0).round().clamp(0, 255);
}
