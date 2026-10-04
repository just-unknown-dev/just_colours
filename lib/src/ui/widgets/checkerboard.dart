import 'package:flutter/material.dart';

/// The grey squares shown behind a colour so its see-through part shows.
class Checkerboard extends StatelessWidget {
  const Checkerboard({super.key, this.cell = 5, this.child});

  final double cell;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: CheckerboardPainter(
        cell: cell,
        light: dark ? const Color(0xFF5C5C5C) : const Color(0xFFFFFFFF),
        dark: dark ? const Color(0xFF404040) : const Color(0xFFD4D4D4),
      ),
      child: child,
    );
  }
}

class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter({
    required this.cell,
    required this.light,
    required this.dark,
  });

  final double cell;
  final Color light;
  final Color dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    final paint = Paint()..color = dark;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var y = 0; y < rows; y++) {
      for (var x = (y.isOdd ? 1 : 0); x < cols; x += 2) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CheckerboardPainter old) =>
      old.cell != cell || old.light != light || old.dark != dark;
}
