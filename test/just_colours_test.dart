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

  group('GradientConfig', () {
    const red = Color(0xFFFF0000);
    const green = Color(0xFF00FF00);
    const blue = Color(0xFF0000FF);

    test('copyWith drops stops that no longer match the colours', () {
      const g = GradientConfig(colors: [red, green, blue], stops: [0, .2, 1]);
      final two = g.copyWith(colors: [red, blue]);
      expect(two.stops, isNull);
      expect(() => two.toGradient(), returnsNormally);
      expect(g.copyWith(clearStops: true).stops, isNull);
      expect(g.copyWith(angle: 10).stops, [0, .2, 1]);
    });

    test('stopList spreads unset stops evenly', () {
      const g = GradientConfig(colors: [red, green, blue]);
      expect(g.stopList.map((s) => s.offset), [0, .5, 1]);
    });

    test('withStopList sorts by offset and keeps every colour', () {
      const g = GradientConfig(colors: [red, blue]);
      final next = g.withStopList(const [
        GradientStop(blue, 1),
        GradientStop(green, .3),
        GradientStop(red, 0),
      ]);
      expect(next.colors, [red, green, blue]);
      expect(next.stops, [0, .3, 1]);
    });

    test('reversed keeps all colours, mirrored', () {
      final g = const GradientConfig(
        colors: [red, green, blue, red, green, blue],
      ).reversed();
      expect(g.colors.length, 6);
      expect(g.colors.first, blue);
      expect(g.stops!.first, 0);
      expect(g.stops!.last, 1);
    });

    test('colorAt blends between neighbours', () {
      const g = GradientConfig(colors: [Colors.black, Colors.white]);
      final mid = g.colorAt(.5);
      expect(mid.r, closeTo(.5, .01));
      expect(g.colorAt(-1), Colors.black);
      expect(g.colorAt(2), Colors.white);
    });

    test('one colour or none still makes a gradient', () {
      expect(
        () => const GradientConfig(colors: [red]).toGradient(),
        returnsNormally,
      );
      expect(() => const GradientConfig(colors: []).toGradient(), returnsNormally);
    });

    test('sweep angles survive json; old json reads a full turn', () {
      const g = GradientConfig(
        type: GradientType.sweep,
        startAngle: 30,
        endAngle: 200,
      );
      final back = GradientConfig.fromJson(g.toJson());
      expect(back, g);
      final old = GradientConfig.fromJson({'type': 'sweep'});
      expect(old.startAngle, 0);
      expect(old.endAngle, 360);
    });

    test('json with mismatched stops reads without them', () {
      final g = GradientConfig.fromJson({
        'colors': [0xFFFF0000, 0xFF0000FF],
        'stops': [0, .5, 1],
      });
      expect(g.stops, isNull);
    });

    test('normalizedAngle wraps', () {
      expect(const GradientConfig(angle: -90).normalizedAngle, 270);
      expect(const GradientConfig(angle: 450).normalizedAngle, 90);
    });
  });

  group('ColourSelection', () {
    test('tint survives json; old json has no tint', () {
      const s = ColourSelection(
        color: Color(0xFF112233),
        useGradient: true,
        tint: Color(0xFF808080),
      );
      expect(ColourSelection.fromJson(s.toJson()), s);
      final old = ColourSelection.fromJson({'color': 0xFF112233});
      expect(old.hasTint, isFalse);
    });
  });

  group('ColourCodec.tryParseHex', () {
    test('reads short, long and alpha codes', () {
      expect(ColourCodec.tryParseHex('#f00'), const Color(0xFFFF0000));
      expect(ColourCodec.tryParseHex('00ff00'), const Color(0xFF00FF00));
      expect(ColourCodec.tryParseHex(' 0x800000FF '), const Color(0x800000FF));
    });

    test('refuses what is not a colour', () {
      expect(ColourCodec.tryParseHex('#12345'), isNull);
      expect(ColourCodec.tryParseHex('zzzzzz'), isNull);
      expect(ColourCodec.tryParseHex(''), isNull);
    });
  });

  group('ColourTheory.harmonies', () {
    test('each is named and holds the base colour', () {
      const base = Color(0xFFFF0044);
      final all = ColourTheory.harmonies(base);
      expect(all.map((h) => h.name), contains('Triadic'));
      for (final h in all) {
        expect(h.colors, contains(base), reason: h.name);
      }
    });

    test('fullHarmonySet has each colour once', () {
      final set = ColourTheory.fullHarmonySet(const Color(0xFFFF0044));
      final codes = set.map((c) => c.toARGB32()).toList();
      expect(codes.toSet().length, codes.length);
    });
  });

  group('ColourLibrary', () {
    test('recent colours are unique, newest first, capped', () {
      final lib = ColourLibrary(recentLimit: 3);
      lib.addRecentColours(const [Color(0xFF000001)]);
      lib.addRecentColours(const [Color(0xFF000002), Color(0xFF000003)]);
      lib.addRecentColours(const [Color(0xFF000001)]);
      lib.addRecentColours(const [Color(0xFF000004)]);
      expect(lib.recentColours.map((c) => c.toARGB32() & 0xF), [4, 1, 2]);
    });

    test('recents and collections tell their changes apart', () {
      final lib = ColourLibrary();
      var recents = 0;
      var collections = 0;
      lib.recentsChanged.addListener(() => recents++);
      lib.collectionsChanged.addListener(() => collections++);
      lib.addRecentColours(const [Colors.red]);
      lib.savePalette(const ColourPalette(id: '', name: 'A', colors: []));
      expect(recents, 1);
      expect(collections, 1);
    });

    test('collections survive json and get ids', () {
      final lib = ColourLibrary();
      final p = lib.savePalette(
        const ColourPalette(id: '', name: 'Mine', colors: [Colors.red]),
      );
      lib.saveGradient(
        const NamedGradient(id: '', name: 'G', gradient: GradientConfig()),
      );
      expect(p.id, isNotEmpty);
      final other = ColourLibrary()..loadCollections(lib.collectionsToJson());
      expect(other.palettes.single.name, 'Mine');
      expect(other.gradients.single.gradient, const GradientConfig());
      expect(lib.unusedPaletteName(), 'Palette 1');
    });
  });
}
