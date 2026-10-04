import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/colour_codec.dart';
import 'picker_look.dart';

/// A small box for one number, with an optional letter in front ("R") and
/// unit behind ("%"). Typing applies as soon as it reads as a number; the
/// arrow keys step it, Shift ten steps.
class PickerNumberField extends StatefulWidget {
  const PickerNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.prefix,
    this.suffix,
    this.decimals = 0,
    this.step = 1,
    this.wrap = false,
    this.semanticLabel,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String? prefix;
  final String? suffix;
  final int decimals;
  final double step;

  /// Whether stepping past one end comes round to the other: angles.
  final bool wrap;
  final String? semanticLabel;

  @override
  State<PickerNumberField> createState() => _PickerNumberFieldState();
}

class _PickerNumberFieldState extends State<PickerNumberField> {
  late final TextEditingController _text = TextEditingController(
    text: _format(widget.value),
  );
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey)
    ..addListener(_onFocus);

  String _format(double v) => v.toStringAsFixed(widget.decimals);

  @override
  void didUpdateWidget(PickerNumberField old) {
    super.didUpdateWidget(old);
    // While typing, the box shows what was typed; the value it gives back
    // must not rewrite it under the caret.
    if (!_focus.hasFocus) {
      final shown = _format(widget.value);
      if (_text.text != shown) _text.text = shown;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _text.text.length,
      );
    } else {
      _text.text = _format(widget.value);
    }
  }

  double _fit(double v) {
    if (!widget.wrap) return v.clamp(widget.min, widget.max);
    final span = widget.max - widget.min;
    var w = (v - widget.min) % span;
    if (w < 0) w += span;
    return widget.min + w;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!up && !down) return KeyEventResult.ignored;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final current = double.tryParse(_text.text) ?? widget.value;
    final next = _fit(current + (up ? 1 : -1) * widget.step * (shift ? 10 : 1));
    _text.text = _format(next);
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
    widget.onChanged(next);
    return KeyEventResult.handled;
  }

  void _onTyped(String s) {
    final v = double.tryParse(s.trim());
    if (v == null) return;
    widget.onChanged(v.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return _FieldShell(
      focus: _focus,
      prefix: widget.prefix,
      suffix: widget.suffix,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        style: look.value,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
        decoration: InputDecoration.collapsed(
          hintText: '',
          hintStyle: look.value,
        ).copyWith(semanticCounterText: widget.semanticLabel),
        onChanged: _onTyped,
        onSubmitted: (_) => _text.text = _format(widget.value),
      ),
    );
  }
}

/// The box for a colour code: `RRGGBB` after a `#`. Takes any code
/// [ColourCodec.tryParseHex] reads, pasted with alpha or without; one that
/// carries no alpha keeps the alpha there was.
class PickerHexField extends StatefulWidget {
  const PickerHexField({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<PickerHexField> createState() => _PickerHexFieldState();
}

class _PickerHexFieldState extends State<PickerHexField> {
  late final TextEditingController _text = TextEditingController(
    text: _format(widget.color),
  );
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);
  bool _invalid = false;

  static String _format(Color c) =>
      ColourCodec.toHex(c, includeAlpha: false).substring(1);

  @override
  void didUpdateWidget(PickerHexField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus) {
      final shown = _format(widget.color);
      if (_text.text != shown) _text.text = shown;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _text.text.length,
      );
    } else {
      setState(() => _invalid = false);
      _text.text = _format(widget.color);
    }
  }

  Color? _read(String s) {
    final parsed = ColourCodec.tryParseHex(s);
    if (parsed == null) return null;
    final digits = s.trim().replaceFirst('#', '').replaceFirst(
      RegExp('^0[xX]'),
      '',
    );
    // Six or three digits say nothing about alpha: keep the one there was.
    return digits.length == 8 ? parsed : parsed.withValues(alpha: widget.color.a);
  }

  void _onTyped(String s) {
    final c = _read(s);
    setState(() => _invalid = c == null && s.trim().isNotEmpty);
    if (c != null) widget.onChanged(c);
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return _FieldShell(
      focus: _focus,
      prefix: '#',
      error: _invalid,
      child: TextField(
        controller: _text,
        focusNode: _focus,
        style: look.value.copyWith(letterSpacing: 0.6),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-FxX#]')),
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: const InputDecoration.collapsed(
          hintText: 'RRGGBB',
        ).copyWith(semanticCounterText: 'Hex colour'),
        onChanged: _onTyped,
        onSubmitted: (_) {
          setState(() => _invalid = false);
          _text.text = _format(widget.color);
        },
      ),
    );
  }
}

/// The outline every field shares: fill, border, focus ring, the letter in
/// front and unit behind.
class _FieldShell extends StatefulWidget {
  const _FieldShell({
    required this.focus,
    required this.child,
    this.prefix,
    this.suffix,
    this.error = false,
  });

  final FocusNode focus;
  final Widget child;
  final String? prefix;
  final String? suffix;
  final bool error;

  @override
  State<_FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends State<_FieldShell> {
  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_changed);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final focused = widget.focus.hasFocus;
    var deco = look.fieldDecoration(focused: focused);
    if (widget.error) {
      deco = deco.copyWith(border: Border.all(color: look.scheme.error));
    }
    return GestureDetector(
      onTap: widget.focus.requestFocus,
      child: Container(
        height: PickerLook.fieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: deco,
        child: Row(
          children: [
            if (widget.prefix != null) ...[
              Text(widget.prefix!, style: look.caption),
              const SizedBox(width: 4),
            ],
            Expanded(child: Center(child: widget.child)),
            if (widget.suffix != null) ...[
              const SizedBox(width: 2),
              Text(widget.suffix!, style: look.caption),
            ],
          ],
        ),
      ),
    );
  }
}
