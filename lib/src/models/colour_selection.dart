import 'package:flutter/material.dart';

import 'gradient_config.dart';

class ColourSelection {
  final Color color;
  final GradientConfig gradient;
  final bool useGradient;

  const ColourSelection({
    required this.color,
    this.gradient = const GradientConfig(),
    this.useGradient = false,
  });

  ColourSelection copyWith({
    Color? color,
    GradientConfig? gradient,
    bool? useGradient,
  }) {
    return ColourSelection(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      useGradient: useGradient ?? this.useGradient,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'gradient': gradient.toJson(),
      'useGradient': useGradient,
    };
  }

  factory ColourSelection.fromJson(Map<String, dynamic> json) {
    return ColourSelection(
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      gradient: GradientConfig.fromJson(
        (json['gradient'] as Map<String, dynamic>?) ?? const {},
      ),
      useGradient: json['useGradient'] as bool? ?? false,
    );
  }
}
