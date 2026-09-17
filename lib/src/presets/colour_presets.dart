import 'package:flutter/material.dart';

import '../models/colour_palette.dart';
import '../models/gradient_config.dart';

abstract final class ColourPresets {
  static final List<ColourPalette> palettes = [
    const ColourPalette(
      id: 'sunset',
      name: 'Sunset Ember',
      colors: [
        Color(0xFF2A1A5E),
        Color(0xFFF04D5C),
        Color(0xFFF59A58),
        Color(0xFFFFD394),
      ],
      description: 'Warm cinematic shades for fantasy and adventure UI.',
    ),
    const ColourPalette(
      id: 'forest',
      name: 'Forest Signal',
      colors: [
        Color(0xFF0F3D3E),
        Color(0xFF2C666E),
        Color(0xFF90D1CA),
        Color(0xFFEFEFEF),
      ],
      description: 'Natural greens and calm neutrals.',
    ),
    const ColourPalette(
      id: 'arcade',
      name: 'Arcade Pop',
      colors: [
        Color(0xFF121212),
        Color(0xFF00E5FF),
        Color(0xFFFFEA00),
        Color(0xFFFF3D81),
      ],
      description: 'High contrast retro-electronic palette.',
    ),
  ];

  static final List<GradientConfig> gradients = [
    const GradientConfig(
      type: GradientType.linear,
      angle: 45,
      colors: [Color(0xFFF5746F), Color(0xFFF8B056)],
    ),
    const GradientConfig(
      type: GradientType.radial,
      radius: 0.8,
      colors: [Color(0xFF1D2671), Color(0xFFC33764)],
    ),
    const GradientConfig(
      type: GradientType.sweep,
      colors: [
        Color(0xFFFF595E),
        Color(0xFFFFCA3A),
        Color(0xFF8AC926),
        Color(0xFF1982C4),
        Color(0xFF6A4C93),
        Color(0xFFFF595E),
      ],
    ),
  ];
}
