import 'package:flutter/material.dart';

import 'checkerboard.dart';
import 'picker_look.dart';
import 'step_keys.dart';

/// A thin track painted with [colors] and a thumb along it: the hue and
/// opacity sliders. [value] runs 0 to 1.
class ColourStrip extends StatefulWidget {
  const ColourStrip({
    super.key,
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.thumbColor,
    required this.semanticLabel,
    required this.semanticValue,
    this.checkerboard = false,
    this.step = 0.01,
    this.height = 14,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final List<Color> colors;
  final Color thumbColor;
  final String semanticLabel;
  final String Function(double value) semanticValue;

  /// Whether the track shows see-through colour over squares.
  final bool checkerboard;

  /// How far one arrow key moves the thumb.
  final double step;
  final double height;

  @override
  State<ColourStrip> createState() => _ColourStripState();
}

class _ColourStripState extends State<ColourStrip> {
  final FocusNode _focus = FocusNode(debugLabel: 'ColourStrip');
  bool _highlight = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _thumbRadius => widget.height / 2 + 2;

  void _fromPointer(Offset local, double width) {
    final inset = _thumbRadius;
    final t = ((local.dx - inset) / (width - inset * 2)).clamp(0.0, 1.0);
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final v = widget.value.clamp(0.0, 1.0);
    return Semantics(
      slider: true,
      label: widget.semanticLabel,
      value: widget.semanticValue(v),
      increasedValue: widget.semanticValue((v + widget.step).clamp(0, 1)),
      decreasedValue: widget.semanticValue((v - widget.step).clamp(0, 1)),
      onIncrease: () => widget.onChanged((v + widget.step).clamp(0.0, 1.0)),
      onDecrease: () => widget.onChanged((v - widget.step).clamp(0.0, 1.0)),
      child: FocusableActionDetector(
        focusNode: _focus,
        shortcuts: stepShortcuts,
        actions: {
          StepIntent: CallbackAction<StepIntent>(
            onInvoke: (i) {
              final d = i.dx != 0 ? i.dx : i.dy;
              widget.onChanged((v + d * widget.step).clamp(0.0, 1.0));
              return null;
            },
          ),
        },
        onShowFocusHighlight: (on) => setState(() => _highlight = on),
        mouseCursor: SystemMouseCursors.click,
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) {
                _focus.requestFocus();
                _fromPointer(d.localPosition, width);
              },
              onPanUpdate: (d) => _fromPointer(d.localPosition, width),
              child: SizedBox(
                height: _thumbRadius * 2,
                width: width,
                child: CustomPaint(
                  painter: _StripPainter(
                    value: v,
                    colors: widget.colors,
                    thumbColor: widget.thumbColor,
                    trackHeight: widget.height,
                    thumbRadius: _thumbRadius,
                    ring: _highlight ? look.focusRing : null,
                    checker: widget.checkerboard
                        ? CheckerboardPainter(
                            cell: 4,
                            light:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF5C5C5C)
                                : Colors.white,
                            dark:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF404040)
                                : const Color(0xFFD4D4D4),
                          )
                        : null,
                    outline: look.border,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({
    required this.value,
    required this.colors,
    required this.thumbColor,
    required this.trackHeight,
    required this.thumbRadius,
    required this.ring,
    required this.checker,
    required this.outline,
  });

  final double value;
  final List<Color> colors;
  final Color thumbColor;
  final double trackHeight;
  final double thumbRadius;
  final Color? ring;
  final CheckerboardPainter? checker;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - trackHeight / 2, size.width, trackHeight),
      Radius.circular(trackHeight / 2),
    );
    if (checker != null) {
      canvas.save();
      canvas.clipRRect(track);
      canvas.translate(track.left, track.top);
      checker!.paint(canvas, track.outerRect.size);
      canvas.restore();
    }
    canvas.drawRRect(
      track,
      Paint()
        ..shader = LinearGradient(colors: colors).createShader(track.outerRect),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = outline,
    );

    final x = thumbRadius + (size.width - thumbRadius * 2) * value;
    final c = Offset(x, cy);
    if (ring != null) {
      canvas.drawCircle(
        c,
        thumbRadius + 2.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ring!,
      );
    }
    canvas.drawCircle(
      c,
      thumbRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(c, thumbRadius - 1, Paint()..color = Colors.white);
    canvas.drawCircle(c, thumbRadius - 3, Paint()..color = thumbColor);
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.value != value ||
      old.thumbColor != thumbColor ||
      old.ring != ring ||
      old.outline != outline ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
