import 'dart:math' as math;

import 'package:flutter/material.dart';

class ColourWheel extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;
  final double size;

  const ColourWheel({
    super.key,
    required this.hue,
    required this.onChanged,
    this.size = 180,
  }) : assert(size > 0, 'size must be greater than zero');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Colour wheel',
      child: GestureDetector(
        onPanDown: (details) => _updateHue(details.localPosition),
        onPanUpdate: (details) => _updateHue(details.localPosition),
        child: CustomPaint(
          size: Size.square(size),
          painter: _ColourWheelPainter(hue: hue),
        ),
      ),
    );
  }

  void _updateHue(Offset local) {
    final center = Offset(size / 2, size / 2);
    final vector = local - center;
    if (vector.distance > size / 2) {
      return;
    }
    final angle = math.atan2(vector.dy, vector.dx);
    final deg = ((angle * 180 / math.pi) + 360) % 360;
    onChanged(deg);
  }
}

class _ColourWheelPainter extends CustomPainter {
  final double hue;

  const _ColourWheelPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const stroke = 20.0;

    final ringRect = Rect.fromCircle(
      center: center,
      radius: radius - stroke / 2,
    );
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: List<Color>.generate(13, (index) {
          final h = index * 30.0;
          return HSVColor.fromAHSV(1, h, 1, 1).toColor();
        }),
      ).createShader(ringRect);

    canvas.drawCircle(center, radius - stroke / 2, ringPaint);

    final thumbAngle = hue * math.pi / 180;
    final thumbOffset = Offset(
      center.dx + math.cos(thumbAngle) * (radius - stroke / 2),
      center.dy + math.sin(thumbAngle) * (radius - stroke / 2),
    );

    canvas.drawCircle(thumbOffset, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      thumbOffset,
      6,
      Paint()..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
    );

    canvas.drawCircle(
      center,
      radius - stroke - 2,
      Paint()..color = HSVColor.fromAHSV(1, hue, 0.35, 1).toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _ColourWheelPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}
