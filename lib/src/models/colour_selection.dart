import 'package:flutter/material.dart';

import 'gradient_config.dart';

/// What the picker hands back: a solid [color], or a [gradient] when
/// [useGradient] is on.
@immutable
class ColourSelection {
  /// The solid colour. Kept while a gradient is chosen, so switching back
  /// finds it again.
  final Color color;
  final GradientConfig gradient;
  final bool useGradient;

  /// Multiplied over the gradient when [useGradient] is on. White leaves the
  /// gradient as it is.
  final Color tint;

  const ColourSelection({
    required this.color,
    this.gradient = const GradientConfig(),
    this.useGradient = false,
    this.tint = const Color(0xFFFFFFFF),
  });

  /// Whether [tint] changes anything.
  bool get hasTint => tint.toARGB32() != 0xFFFFFFFF;

  ColourSelection copyWith({
    Color? color,
    GradientConfig? gradient,
    bool? useGradient,
    Color? tint,
  }) {
    return ColourSelection(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      useGradient: useGradient ?? this.useGradient,
      tint: tint ?? this.tint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'gradient': gradient.toJson(),
      'useGradient': useGradient,
      'tint': tint.toARGB32(),
    };
  }

  factory ColourSelection.fromJson(Map<String, dynamic> json) {
    final rawGradient = json['gradient'];
    return ColourSelection(
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      gradient: rawGradient is Map<String, dynamic>
          ? GradientConfig.fromJson(rawGradient)
          : const GradientConfig(),
      useGradient: json['useGradient'] as bool? ?? false,
      tint: Color((json['tint'] as num?)?.toInt() ?? 0xFFFFFFFF),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ColourSelection &&
      other.color.toARGB32() == color.toARGB32() &&
      other.gradient == gradient &&
      other.useGradient == useGradient &&
      other.tint.toARGB32() == tint.toARGB32();

  @override
  int get hashCode =>
      Object.hash(color.toARGB32(), gradient, useGradient, tint.toARGB32());
}
