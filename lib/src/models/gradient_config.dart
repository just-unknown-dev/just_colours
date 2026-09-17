import 'dart:math' as math;

import 'package:flutter/material.dart';

enum GradientType { linear, radial, sweep }

class GradientConfig {
  final GradientType type;
  final List<Color> colors;
  final List<double>? stops;
  final double angle;
  final Alignment center;
  final double radius;
  final TileMode tileMode;

  const GradientConfig({
    this.type = GradientType.linear,
    this.colors = const [Color(0xFFF5746F), Color(0xFF2E4EA8)],
    this.stops,
    this.angle = 0,
    this.center = Alignment.center,
    this.radius = 0.5,
    this.tileMode = TileMode.clamp,
  });

  GradientConfig copyWith({
    GradientType? type,
    List<Color>? colors,
    List<double>? stops,
    double? angle,
    Alignment? center,
    double? radius,
    TileMode? tileMode,
  }) {
    return GradientConfig(
      type: type ?? this.type,
      colors: colors ?? this.colors,
      stops: stops ?? this.stops,
      angle: angle ?? this.angle,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      tileMode: tileMode ?? this.tileMode,
    );
  }

  Gradient toGradient() {
    switch (type) {
      case GradientType.linear:
        final radians = angle * math.pi / 180;
        final begin = Alignment(
          math.cos(radians + math.pi),
          math.sin(radians + math.pi),
        );
        final end = Alignment(math.cos(radians), math.sin(radians));
        return LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: stops,
          tileMode: tileMode,
        );
      case GradientType.radial:
        return RadialGradient(
          center: center,
          radius: radius,
          colors: colors,
          stops: stops,
          tileMode: tileMode,
        );
      case GradientType.sweep:
        return SweepGradient(
          center: center,
          colors: colors,
          stops: stops,
          startAngle: 0,
          endAngle: math.pi * 2,
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
        .map((e) => Color((e as num).toInt()))
        .toList();

    final tileIndex = (json['tileMode'] as num?)?.toInt() ?? 0;
    final safeTileIndex = tileIndex < 0 || tileIndex >= TileMode.values.length
        ? 0
        : tileIndex;

    return GradientConfig(
      type: parsedType ?? GradientType.linear,
      colors: rawColors.isEmpty
          ? const [Color(0xFFF5746F), Color(0xFF2E4EA8)]
          : rawColors,
      stops: (json['stops'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      angle: (json['angle'] as num?)?.toDouble() ?? 0,
      center: Alignment(
        (json['centerX'] as num?)?.toDouble() ?? 0,
        (json['centerY'] as num?)?.toDouble() ?? 0,
      ),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.5,
      tileMode: TileMode.values[safeTileIndex],
    );
  }
}
