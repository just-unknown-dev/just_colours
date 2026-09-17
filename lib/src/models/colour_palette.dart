import 'package:flutter/material.dart';

class ColourPalette {
  final String id;
  final String name;
  final List<Color> colors;
  final String? description;

  const ColourPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.description,
  });

  ColourPalette copyWith({
    String? id,
    String? name,
    List<Color>? colors,
    String? description,
  }) {
    return ColourPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      colors: colors ?? this.colors,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colors': colors.map((c) => c.toARGB32()).toList(),
      'description': description,
    };
  }

  factory ColourPalette.fromJson(Map<String, dynamic> json) {
    return ColourPalette(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      colors: (json['colors'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Color((e as num).toInt()))
          .toList(),
      description: json['description'] as String?,
    );
  }
}
