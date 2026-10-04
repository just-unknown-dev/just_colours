import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/gradient_config.dart';
import 'checkerboard.dart';
import 'picker_look.dart';
import 'swatch.dart';

/// The gradient as it will look, with handles to shape it by hand: the
/// direction of a linear one, the centre and size of a radial one, the
/// centre, start and end of a sweep. Shift snaps angles to 15°.
class GradientCanvas extends StatefulWidget {
  const GradientCanvas({
    super.key,
    required this.gradient,
    required this.onChanged,
    this.tint,
    this.height = 88,
  });

  final GradientConfig gradient;
  final ValueChanged<GradientConfig> onChanged;
  final Color? tint;
  final double height;

  @override
  State<GradientCanvas> createState() => _GradientCanvasState();
}

enum _Handle { begin, end, center, radius, start, finish }

class _GradientCanvasState extends State<GradientCanvas> {
  _Handle? _active;
  _Handle? _hover;

  GradientConfig get _g => widget.gradient;

  Offset _alignToPoint(Alignment a, Size s) =>
      Offset(s.width / 2 + a.x * s.width / 2, s.height / 2 + a.y * s.height / 2);

  Alignment _pointToAlign(Offset p, Size s) => Alignment(
    ((p.dx - s.width / 2) / (s.width / 2)).clamp(-1.0, 1.0),
    ((p.dy - s.height / 2) / (s.height / 2)).clamp(-1.0, 1.0),
  );

  double _sweepRing(Size s) => math.min(s.width, s.height) * 0.36;

  Map<_Handle, Offset> _handles(Size s) {
    switch (_g.type) {
      case GradientType.linear:
        final (begin, end) = _g.linearEnds;
        return {
          _Handle.begin: _alignToPoint(_inset(begin), s),
          _Handle.end: _alignToPoint(_inset(end), s),
        };
      case GradientType.radial:
        final c = _alignToPoint(_g.center, s);
        final r = _g.radius * math.min(s.width, s.height);
        return {
          _Handle.center: c,
          _Handle.radius: c + Offset(r, 0),
        };
      case GradientType.sweep:
        final c = _alignToPoint(_g.center, s);
        final ring = _sweepRing(s);
        Offset at(double deg) {
          final rad = deg * math.pi / 180;
          return c + Offset(math.cos(rad), math.sin(rad)) * ring;
        }

        return {
          _Handle.center: c,
          _Handle.start: at(_g.startAngle),
          _Handle.finish: at(_g.endAngle),
        };
    }
  }

  /// Linear ends drawn a little inside the box, so their handles stay
  /// whole at the edges. Scaled evenly, so a handle stays on the line the
  /// gradient runs along.
  Alignment _inset(Alignment a) => Alignment(a.x * 0.82, a.y * 0.82);

  _Handle? _hit(Offset p, Size s) {
    _Handle? best;
    var bestDistance = 14.0;
    _handles(s).forEach((h, at) {
      final d = (at - p).distance;
      // The centre sits under the others; let them win where they meet.
      final bias = h == _Handle.center ? 2.0 : 0.0;
      if (d + bias < bestDistance) {
        bestDistance = d + bias;
        best = h;
      }
    });
    return best;
  }

  double _snap(double degrees) {
    if (!HardwareKeyboard.instance.isShiftPressed) return degrees;
    return (degrees / 15).round() * 15.0;
  }

  double _degrees(Offset from, Offset to) {
    final d = math.atan2(to.dy - from.dy, to.dx - from.dx) * 180 / math.pi;
    return d < 0 ? d + 360 : d;
  }

  void _drag(Offset p, Size s) {
    final h = _active;
    if (h == null) return;
    final center = Offset(s.width / 2, s.height / 2);
    switch (h) {
      case _Handle.end:
      case _Handle.begin:
        // Direction is taken in the box's own units, the way the gradient
        // itself is laid out.
        final a = Offset(
          (p.dx - center.dx) / (s.width / 2),
          (p.dy - center.dy) / (s.height / 2),
        );
        var deg = _degrees(Offset.zero, a);
        if (h == _Handle.begin) deg = (deg + 180) % 360;
        widget.onChanged(_g.copyWith(angle: _snap(deg) % 360));
      case _Handle.center:
        widget.onChanged(_g.copyWith(center: _pointToAlign(p, s)));
      case _Handle.radius:
        final c = _alignToPoint(_g.center, s);
        final r = (p - c).distance / math.min(s.width, s.height);
        widget.onChanged(_g.copyWith(radius: r.clamp(0.02, 2.0)));
      case _Handle.start:
      case _Handle.finish:
        final c = _alignToPoint(_g.center, s);
        final deg = _snap(_degrees(c, p));
        if (h == _Handle.start) {
          widget.onChanged(_g.copyWith(startAngle: deg));
        } else {
          widget.onChanged(_g.copyWith(endAngle: deg == 0 ? 360 : deg));
        }
    }
  }

  void _down(Offset p, Size s) {
    final hit = _hit(p, s);
    if (hit != null) {
      setState(() => _active = hit);
      return;
    }
    // A press away from the handles grabs the one it most likely means:
    // the end of a linear gradient, the centre of the others.
    setState(
      () => _active = _g.type == GradientType.linear
          ? _Handle.end
          : _Handle.center,
    );
    _drag(p, s);
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, widget.height);
        return Semantics(
          label: 'Gradient preview. Drag the handles to shape it.',
          child: MouseRegion(
            cursor: _active != null || _hover != null
                ? SystemMouseCursors.grab
                : SystemMouseCursors.precise,
            onHover: (e) {
              final h = _hit(e.localPosition, size);
              if (h != _hover) setState(() => _hover = h);
            },
            onExit: (_) => setState(() => _hover = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => _down(d.localPosition, size),
              onPanUpdate: (d) => _drag(d.localPosition, size),
              onPanEnd: (_) => setState(() => _active = null),
              onPanCancel: () => setState(() => _active = null),
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PickerLook.radius),
                  border: Border.all(color: look.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PickerLook.radius - 1),
                  child: Checkerboard(
                    child: GradientPaint(
                      gradient: _g,
                      tint: widget.tint,
                      child: CustomPaint(
                        size: size,
                        painter: _HandlePainter(
                          type: _g.type,
                          handles: _handles(size),
                          active: _active ?? _hover,
                          ring: _g.type == GradientType.radial
                              ? _g.radius * math.min(size.width, size.height)
                              : _sweepRing(size),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HandlePainter extends CustomPainter {
  _HandlePainter({
    required this.type,
    required this.handles,
    required this.active,
    required this.ring,
  });

  final GradientType type;
  final Map<_Handle, Offset> handles;
  final _Handle? active;
  final double ring;

  static final Paint _shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _line = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _faintLine = Paint()
    ..color = Colors.white70
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case GradientType.linear:
        final a = handles[_Handle.begin]!;
        final b = handles[_Handle.end]!;
        canvas.drawLine(a, b, _shadow);
        canvas.drawLine(a, b, _line);
        _dot(canvas, a, _Handle.begin, hollow: true);
        _arrow(canvas, a, b);
        _dot(canvas, b, _Handle.end);
      case GradientType.radial:
        final c = handles[_Handle.center]!;
        canvas.drawCircle(c, ring, _shadow);
        canvas.drawCircle(c, ring, _line);
        _dot(canvas, c, _Handle.center);
        _dot(canvas, handles[_Handle.radius]!, _Handle.radius, hollow: true);
      case GradientType.sweep:
        final c = handles[_Handle.center]!;
        final s = handles[_Handle.start]!;
        final f = handles[_Handle.finish]!;
        canvas.drawCircle(c, ring, _shadow);
        canvas.drawCircle(c, ring, _faintLine);
        canvas.drawLine(c, s, _shadow);
        canvas.drawLine(c, s, _line);
        _dot(canvas, c, _Handle.center);
        _dot(canvas, f, _Handle.finish, hollow: true);
        _dot(canvas, s, _Handle.start);
    }
  }

  void _arrow(Canvas canvas, Offset from, Offset to) {
    final d = to - from;
    if (d.distance < 1) return;
    final u = d / d.distance;
    final n = Offset(-u.dy, u.dx);
    final tip = to - u * 9;
    final path = Path()
      ..moveTo(tip.dx + u.dx * 5, tip.dy + u.dy * 5)
      ..lineTo(tip.dx - u.dx * 3 + n.dx * 5, tip.dy - u.dy * 3 + n.dy * 5)
      ..lineTo(tip.dx - u.dx * 3 - n.dx * 5, tip.dy - u.dy * 3 - n.dy * 5)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  void _dot(Canvas canvas, Offset at, _Handle h, {bool hollow = false}) {
    final big = h == active;
    final r = big ? 7.0 : 5.5;
    canvas.drawCircle(at, r + 1.5, Paint()..color = Colors.black54);
    canvas.drawCircle(at, r, Paint()..color = Colors.white);
    if (hollow) {
      canvas.drawCircle(at, r - 2.5, Paint()..color = Colors.black54);
    }
  }

  @override
  bool shouldRepaint(_HandlePainter old) => true;
}
