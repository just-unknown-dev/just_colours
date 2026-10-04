import 'package:flutter/foundation.dart';

import 'gradient_config.dart';

/// A saved gradient with a name.
@immutable
class NamedGradient {
  final String id;
  final String name;
  final GradientConfig gradient;

  const NamedGradient({
    required this.id,
    required this.name,
    required this.gradient,
  });

  NamedGradient copyWith({String? id, String? name, GradientConfig? gradient}) {
    return NamedGradient(
      id: id ?? this.id,
      name: name ?? this.name,
      gradient: gradient ?? this.gradient,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gradient': gradient.toJson(),
  };

  factory NamedGradient.fromJson(Map<String, dynamic> json) {
    final raw = json['gradient'];
    return NamedGradient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Gradient',
      gradient: raw is Map<String, dynamic>
          ? GradientConfig.fromJson(raw)
          : const GradientConfig(),
    );
  }
}
