import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/gradient_config.dart';
import 'checkerboard.dart';
import 'picker_look.dart';

/// The gradient laid out flat with a handle for each colour.
///
/// Click the bar to add a colour there, drag a handle to move it, drag it
/// well off the bar — or press Delete — to take it away. The arrow keys
/// move the picked handle, Shift ten times as far.
class GradientStopBar extends StatefulWidget {
  const GradientStopBar({
    super.key,
    required this.gradient,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
    this.minStops = 2,
  });

  final GradientConfig gradient;

  /// The picked handle, or null when none is.
  final int? selected;
  final ValueChanged<int> onSelect;

  /// The new stops in order, and which of them is picked now.
  final void Function(List<GradientStop> stops, int selected) onChanged;
  final int minStops;

  @override
  State<GradientStopBar> createState() => _GradientStopBarState();
}

class _GradientStopBarState extends State<GradientStopBar> {
  static const double _handle = 16;
  static const double _trackHeight = 16;
  static const double _tearOff = 28;

  final FocusNode _focus = FocusNode(debugLabel: 'GradientStopBar');
  bool _highlight = false;

  int? _dragging;
  bool _removing = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<GradientStop> get _stops => widget.gradient.stopList;

  double _toOffset(double dx, double width) =>
      ((dx - _handle / 2) / (width - _handle)).clamp(0.0, 1.0);

  double _toX(double offset, double width) =>
      _handle / 2 + offset * (width - _handle);

  int? _hit(double dx, double width) {
    int? best;
    var bestDistance = _handle / 2 + 3;
    final stops = _stops;
    // Later handles are drawn on top, so they win a tie.
    for (var i = stops.length - 1; i >= 0; i--) {
      final d = (dx - _toX(stops[i].offset, width)).abs();
      if (d < bestDistance) {
        bestDistance = d;
        best = i;
      }
    }
    return best;
  }

  /// [stops] sorted, and where the stop that was at [index] ended up.
  (List<GradientStop>, int) _sorted(List<GradientStop> stops, int index) {
    final tagged = [for (var i = 0; i < stops.length; i++) (i, stops[i])];
    tagged.sort((a, b) {
      final byOffset = a.$2.offset.compareTo(b.$2.offset);
      return byOffset != 0 ? byOffset : a.$1.compareTo(b.$1);
    });
    return (
      [for (final t in tagged) t.$2],
      tagged.indexWhere((t) => t.$1 == index),
    );
  }

  void _move(int index, double offset) {
    final stops = [..._stops];
    stops[index] = stops[index].copyWith(offset: offset);
    final (sorted, at) = _sorted(stops, index);
    _dragging = at;
    widget.onChanged(sorted, at);
  }

  void _remove(int index) {
    final stops = [..._stops];
    if (stops.length <= widget.minStops) return;
    stops.removeAt(index);
    widget.onChanged(stops, index.clamp(0, stops.length - 1));
  }

  void _onDown(Offset local, double width) {
    _focus.requestFocus();
    final hit = _hit(local.dx, width);
    if (hit != null) {
      _dragging = hit;
      widget.onSelect(hit);
      return;
    }
    // A click on the bar adds the colour the gradient already shows there,
    // so adding changes nothing until it is moved or recoloured.
    final t = _toOffset(local.dx, width);
    final stops = [..._stops, GradientStop(widget.gradient.colorAt(t), t)];
    final (sorted, at) = _sorted(stops, stops.length - 1);
    _dragging = at;
    widget.onChanged(sorted, at);
  }

  void _onUpdate(Offset local, double width) {
    final i = _dragging;
    if (i == null) return;
    final removing =
        _stops.length > widget.minStops &&
        (local.dy < -_tearOff || local.dy > _trackHeight + _tearOff);
    if (removing != _removing) setState(() => _removing = removing);
    if (!removing) _move(i, _toOffset(local.dx, width));
  }

  void _onEnd() {
    final i = _dragging;
    if (i != null && _removing) _remove(i);
    setState(() {
      _dragging = null;
      _removing = false;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final i = widget.selected;
    if (i == null || i >= _stops.length) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      _remove(i);
      return KeyEventResult.handled;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.1 : 0.01;
    double? delta;
    if (key == LogicalKeyboardKey.arrowLeft) delta = -step;
    if (key == LogicalKeyboardKey.arrowRight) delta = step;
    if (delta == null) return KeyEventResult.ignored;
    _move(i, (_stops[i].offset + delta).clamp(0.0, 1.0));
    _dragging = null;
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final stops = _stops;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label:
          'Gradient colours: ${stops.length}. Click to add, drag to move, '
          'Delete to remove.',
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        onFocusChange: (on) => setState(
          () => _highlight =
              on &&
              FocusManager.instance.highlightMode ==
                  FocusHighlightMode.traditional,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            return MouseRegion(
              cursor: _removing
                  ? SystemMouseCursors.disappearing
                  : SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => _onDown(d.localPosition, width),
                onPanUpdate: (d) => _onUpdate(d.localPosition, width),
                onPanEnd: (_) => _onEnd(),
                onPanCancel: _onEnd,
                child: CustomPaint(
                  size: Size(width, _handle + 4),
                  painter: _StopBarPainter(
                    stops: stops,
                    selected: widget.selected,
                    removing: _removing ? _dragging : null,
                    handle: _handle,
                    trackHeight: _trackHeight,
                    accent: look.accent,
                    outline: _highlight ? look.focusRing : look.border,
                    checker: CheckerboardPainter(
                      cell: 4,
                      light: dark ? const Color(0xFF5C5C5C) : Colors.white,
                      dark: dark
                          ? const Color(0xFF404040)
                          : const Color(0xFFD4D4D4),
                    ),
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

class _StopBarPainter extends CustomPainter {
  _StopBarPainter({
    required this.stops,
    required this.selected,
    required this.removing,
    required this.handle,
    required this.trackHeight,
    required this.accent,
    required this.outline,
    required this.checker,
  });

  final List<GradientStop> stops;
  final int? selected;
  final int? removing;
  final double handle;
  final double trackHeight;
  final Color accent;
  final Color outline;
  final CheckerboardPainter checker;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        handle / 2,
        cy - trackHeight / 2,
        size.width - handle,
        trackHeight,
      ),
      const Radius.circular(4),
    );
    canvas.save();
    canvas.clipRRect(track);
    canvas.translate(track.left, track.top);
    checker.paint(canvas, track.outerRect.size);
    canvas.restore();
    final shown = [
      for (var i = 0; i < stops.length; i++)
        if (i != removing) stops[i],
    ];
    canvas.drawRRect(
      track,
      Paint()
        ..shader = LinearGradient(
          colors: shown.length == 1
              ? [shown.first.color, shown.first.color]
              : [for (final s in shown) s.color],
          stops: shown.length == 1
              ? null
              : [for (final s in shown) s.offset],
        ).createShader(track.outerRect),
    );
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = outline,
    );

    final order = [
      for (var i = 0; i < stops.length; i++)
        if (i != selected) i,
      ?selected,
    ];
    for (final i in order) {
      if (i >= stops.length) continue;
      final s = stops[i];
      final x = handle / 2 + s.offset * (size.width - handle);
      final on = i == selected;
      final faded = i == removing;
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, cy),
          width: on ? handle : handle - 3,
          height: on ? handle + 4 : handle + 1,
        ),
        const Radius.circular(4),
      );
      final alpha = faded ? 0.35 : 1.0;
      canvas.drawRRect(
        r.inflate(1),
        Paint()..color = Colors.black.withValues(alpha: 0.45 * alpha),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = (on ? accent : Colors.white).withValues(alpha: alpha),
      );
      canvas.drawRRect(
        r.deflate(2.5),
        Paint()..color = s.color.withValues(alpha: s.color.a * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_StopBarPainter old) => true;
}
