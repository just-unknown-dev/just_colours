import 'package:flutter/material.dart';

import 'picker_look.dart';
import 'step_keys.dart';

/// The square of every saturation (left to right) and brightness (bottom
/// to top) of one hue.
class SaturationValueBox extends StatefulWidget {
  const SaturationValueBox({
    super.key,
    required this.hsv,
    required this.onChanged,
    this.height = 150,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  final double height;

  @override
  State<SaturationValueBox> createState() => _SaturationValueBoxState();
}

class _SaturationValueBoxState extends State<SaturationValueBox> {
  final FocusNode _focus = FocusNode(debugLabel: 'SaturationValueBox');
  bool _highlight = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _fromPointer(Offset local, Size size) {
    final s = (local.dx / size.width).clamp(0.0, 1.0);
    final v = (1 - local.dy / size.height).clamp(0.0, 1.0);
    widget.onChanged(widget.hsv.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final hsv = widget.hsv;
    String pct(double v) => '${(v * 100).round()}%';
    return Semantics(
      label: 'Saturation and brightness',
      value:
          'saturation ${pct(hsv.saturation)}, brightness ${pct(hsv.value)}',
      child: FocusableActionDetector(
        focusNode: _focus,
        shortcuts: stepShortcuts,
        actions: {
          StepIntent: CallbackAction<StepIntent>(
            onInvoke: (i) {
              widget.onChanged(
                hsv
                    .withSaturation(
                      (hsv.saturation + i.dx * 0.01).clamp(0.0, 1.0),
                    )
                    .withValue((hsv.value + i.dy * 0.01).clamp(0.0, 1.0)),
              );
              return null;
            },
          ),
        },
        onShowFocusHighlight: (on) => setState(() => _highlight = on),
        mouseCursor: SystemMouseCursors.precise,
        child: LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, widget.height);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) {
                _focus.requestFocus();
                _fromPointer(d.localPosition, size);
              },
              onPanUpdate: (d) => _fromPointer(d.localPosition, size),
              child: CustomPaint(
                size: size,
                painter: _SvPainter(
                  hsv: hsv,
                  outline: _highlight ? look.focusRing : look.border,
                  outlineWidth: _highlight ? 2 : 1,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SvPainter extends CustomPainter {
  _SvPainter({
    required this.hsv,
    required this.outline,
    required this.outlineWidth,
  });

  final HSVColor hsv;
  final Color outline;
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(PickerLook.radius),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.drawRRect(
      rrect.deflate(outlineWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth
        ..color = outline,
    );

    final c = Offset(
      hsv.saturation * size.width,
      (1 - hsv.value) * size.height,
    );
    canvas.drawCircle(
      c,
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
    canvas.drawCircle(c, 5, Paint()..color = hsv.withAlpha(1).toColor());
  }

  @override
  bool shouldRepaint(_SvPainter old) =>
      old.hsv != hsv ||
      old.outline != outline ||
      old.outlineWidth != outlineWidth;
}
