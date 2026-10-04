import 'dart:math' as math;

import 'package:flutter/material.dart';

enum GradientType { linear, radial, sweep }

/// One colour of a gradient and where along it the colour sits, from 0
/// (the start) to 1 (the end).
@immutable
class GradientStop {
  final Color color;
  final double offset;

  const GradientStop(this.color, this.offset);

  GradientStop copyWith({Color? color, double? offset}) =>
      GradientStop(color ?? this.color, offset ?? this.offset);

  @override
  bool operator ==(Object other) =>
      other is GradientStop &&
      other.color.toARGB32() == color.toARGB32() &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(color.toARGB32(), offset);

  @override
  String toString() => 'GradientStop(${color.toARGB32()}, $offset)';
}

/// A gradient in a form that saves to JSON and edits easily.
///
/// [colors] and [stops] follow Flutter's gradients: when [stops] is null the
/// colours are spread evenly; when set it has one offset per colour.
@immutable
class GradientConfig {
  final GradientType type;
  final List<Color> colors;
  final List<double>? stops;

  /// Direction of a linear gradient in degrees: 0 runs left to right, 90
  /// top to bottom.
  final double angle;

  /// Centre of a radial or sweep gradient, in alignment units.
  final Alignment center;

  /// Radius of a radial gradient, as a fraction of the shorter side.
  final double radius;

  /// Where a sweep gradient starts and ends, in degrees clockwise from the
  /// right. A full turn by default.
  final double startAngle;
  final double endAngle;

  final TileMode tileMode;

  static const List<Color> defaultColors = [
    Color(0xFFF5746F),
    Color(0xFF2E4EA8),
  ];

  const GradientConfig({
    this.type = GradientType.linear,
    this.colors = defaultColors,
    this.stops,
    this.angle = 0,
    this.center = Alignment.center,
    this.radius = 0.5,
    this.startAngle = 0,
    this.endAngle = 360,
    this.tileMode = TileMode.clamp,
  });

  /// A gradient through [stops], sorted by offset.
  factory GradientConfig.fromStops(
    List<GradientStop> stops, {
    GradientType type = GradientType.linear,
    double angle = 0,
    Alignment center = Alignment.center,
    double radius = 0.5,
    double startAngle = 0,
    double endAngle = 360,
    TileMode tileMode = TileMode.clamp,
  }) {
    final sorted = [...stops]..sort((a, b) => a.offset.compareTo(b.offset));
    return GradientConfig(
      type: type,
      colors: [for (final s in sorted) s.color],
      stops: [for (final s in sorted) s.offset.clamp(0.0, 1.0)],
      angle: angle,
      center: center,
      radius: radius,
      startAngle: startAngle,
      endAngle: endAngle,
      tileMode: tileMode,
    );
  }

  /// A copy with the given values changed.
  ///
  /// [stops] that no longer match the number of [colors] are dropped, so
  /// the colours spread evenly instead of breaking the gradient. Pass
  /// [clearStops] to drop them on purpose.
  GradientConfig copyWith({
    GradientType? type,
    List<Color>? colors,
    List<double>? stops,
    bool clearStops = false,
    double? angle,
    Alignment? center,
    double? radius,
    double? startAngle,
    double? endAngle,
    TileMode? tileMode,
  }) {
    final nextColors = colors ?? this.colors;
    var nextStops = clearStops ? null : (stops ?? this.stops);
    if (nextStops != null && nextStops.length != nextColors.length) {
      nextStops = null;
    }
    return GradientConfig(
      type: type ?? this.type,
      colors: nextColors,
      stops: nextStops,
      angle: angle ?? this.angle,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      startAngle: startAngle ?? this.startAngle,
      endAngle: endAngle ?? this.endAngle,
      tileMode: tileMode ?? this.tileMode,
    );
  }

  /// The colours with their offsets; evenly spread where [stops] is unset.
  List<GradientStop> get stopList {
    final cs = colors.isEmpty ? defaultColors : colors;
    final explicit = stops != null && stops!.length == cs.length;
    return [
      for (var i = 0; i < cs.length; i++)
        GradientStop(
          cs[i],
          explicit ? stops![i] : (cs.length == 1 ? 0 : i / (cs.length - 1)),
        ),
    ];
  }

  /// This gradient through [list] instead, sorted by offset.
  GradientConfig withStopList(List<GradientStop> list) {
    final sorted = [...list]..sort((a, b) => a.offset.compareTo(b.offset));
    return copyWith(
      colors: [for (final s in sorted) s.color],
      stops: [for (final s in sorted) s.offset.clamp(0.0, 1.0)],
    );
  }

  /// The same colours, end to start.
  GradientConfig reversed() => withStopList([
    for (final s in stopList.reversed) GradientStop(s.color, 1 - s.offset),
  ]);

  /// The same colours spread evenly.
  GradientConfig evenlySpaced() => copyWith(clearStops: true);

  /// The colour the gradient shows at [t], 0 to 1 along it.
  Color colorAt(double t) {
    final list = stopList;
    if (list.length == 1) return list.first.color;
    if (t <= list.first.offset) return list.first.color;
    if (t >= list.last.offset) return list.last.color;
    for (var i = 0; i < list.length - 1; i++) {
      final a = list[i];
      final b = list[i + 1];
      if (t >= a.offset && t <= b.offset) {
        final span = b.offset - a.offset;
        final f = span <= 0 ? 0.0 : (t - a.offset) / span;
        return Color.lerp(a.color, b.color, f)!;
      }
    }
    return list.last.color;
  }

  /// [angle] wrapped into 0 up to 360.
  double get normalizedAngle => _wrapDegrees(angle);

  /// Start and end of a linear gradient for [angle].
  (Alignment, Alignment) get linearEnds {
    final radians = angle * math.pi / 180;
    final end = Alignment(math.cos(radians), math.sin(radians));
    return (Alignment(-end.x, -end.y), end);
  }

  Gradient toGradient() {
    // Flutter needs two colours and one stop per colour; a gradient read
    // from a hand-edited file may have neither.
    final cs = colors.isEmpty
        ? defaultColors
        : (colors.length == 1 ? [colors.first, colors.first] : colors);
    final st = stops != null && stops!.length == cs.length ? stops : null;
    switch (type) {
      case GradientType.linear:
        final (begin, end) = linearEnds;
        return LinearGradient(
          begin: begin,
          end: end,
          colors: cs,
          stops: st,
          tileMode: tileMode,
        );
      case GradientType.radial:
        return RadialGradient(
          center: center,
          radius: radius,
          colors: cs,
          stops: st,
          tileMode: tileMode,
        );
      case GradientType.sweep:
        final start = startAngle * math.pi / 180;
        var end = endAngle * math.pi / 180;
        if (end <= start) end = start + 0.001;
        return SweepGradient(
          center: center,
          colors: cs,
          stops: st,
          startAngle: start,
          endAngle: end,
          tileMode: tileMode,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'stops': stops,
      'angle': angle,
      'centerX': center.x,
      'centerY': center.y,
      'radius': radius,
      'startAngle': startAngle,
      'endAngle': endAngle,
      'tileMode': tileMode.index,
    };
  }

  factory GradientConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    GradientType? parsedType;
    for (final value in GradientType.values) {
      if (value.name == typeName) {
        parsedType = value;
        break;
      }
    }

    final rawColors = (json['colors'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<num>()
        .map((e) => Color(e.toInt()))
        .toList();

    final tileIndex = (json['tileMode'] as num?)?.toInt() ?? 0;
    final safeTileIndex = tileIndex < 0 || tileIndex >= TileMode.values.length
        ? 0
        : tileIndex;

    final colors = rawColors.isEmpty ? defaultColors : rawColors;
    var stops = (json['stops'] as List<dynamic>?)
        ?.whereType<num>()
        .map((e) => e.toDouble())
        .toList();
    if (stops != null && stops.length != colors.length) stops = null;

    return GradientConfig(
      type: parsedType ?? GradientType.linear,
      colors: colors,
      stops: stops,
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      center: Alignment(
        (json['centerX'] as num?)?.toDouble() ?? 0,
        (json['centerY'] as num?)?.toDouble() ?? 0,
      ),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.5,
      startAngle: (json['startAngle'] as num?)?.toDouble() ?? 0,
      endAngle: (json['endAngle'] as num?)?.toDouble() ?? 360,
      tileMode: TileMode.values[safeTileIndex],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GradientConfig) return false;
    if (other.type != type ||
        other.angle != angle ||
        other.center != center ||
        other.radius != radius ||
        other.startAngle != startAngle ||
        other.endAngle != endAngle ||
        other.tileMode != tileMode ||
        other.colors.length != colors.length) {
      return false;
    }
    for (var i = 0; i < colors.length; i++) {
      if (other.colors[i].toARGB32() != colors[i].toARGB32()) return false;
    }
    final a = stops;
    final b = other.stops;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    type,
    Object.hashAll(colors.map((c) => c.toARGB32())),
    stops == null ? null : Object.hashAll(stops!),
    angle,
    center,
    radius,
    startAngle,
    endAngle,
    tileMode,
  );

  static double _wrapDegrees(double degrees) {
    final wrapped = degrees % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }
}
