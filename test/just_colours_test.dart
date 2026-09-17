import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:just_colours/just_colours.dart';

void main() {
  test('complementary color keeps alpha and changes hue', () {
    const color = Color(0xFF00AACC);
    final complementary = ColourTheory.complementary(color);

    final compA = (complementary.a * 255.0).round();
    final baseA = (color.a * 255.0).round();
    expect(compA, baseA);
    expect(complementary.toARGB32(), isNot(color.toARGB32()));
  });

  test('gradient config json roundtrip', () {
    const config = GradientConfig(
      type: GradientType.radial,
      colors: [Color(0xFF123456), Color(0xFFABCDEF)],
      angle: 32,
      radius: 0.75,
    );

    final encoded = config.toJson();
    final decoded = GradientConfig.fromJson(encoded);

    expect(decoded.type, GradientType.radial);
    expect(decoded.colors.length, 2);
    expect(decoded.colors.first.toARGB32(), const Color(0xFF123456).toARGB32());
    expect(decoded.radius, closeTo(0.75, 0.0001));
  });
}
