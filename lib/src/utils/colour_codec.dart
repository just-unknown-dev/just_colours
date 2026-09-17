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

  static Color fromHex(String value) {
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length == 6) {
      return Color(int.parse('FF$normalized', radix: 16));
    }
    if (normalized.length == 8) {
      return Color(int.parse(normalized, radix: 16));
    }
    throw FormatException('Invalid color hex value: $value');
  }
}
