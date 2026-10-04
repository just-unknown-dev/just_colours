import 'package:flutter/material.dart';

import '../widgets/colour_strip.dart';
import '../widgets/number_field.dart';
import '../widgets/picker_look.dart';
import '../widgets/saturation_value_box.dart';
import 'eyedropper.dart';

/// How the colour's numbers are shown under the square.
enum ColourFormat { hex, rgb, hsl, hsv }

/// Edits one colour in place: the saturation/brightness square, hue and
/// opacity strips, its numbers in any [ColourFormat], and an eyedropper
/// when there is a [sampler].
class SolidColourEditor extends StatefulWidget {
  const SolidColourEditor({
    super.key,
    required this.color,
    required this.onChanged,
    this.sampler,
    this.boxHeight = 150,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final ColourSampler? sampler;
  final double boxHeight;

  @override
  State<SolidColourEditor> createState() => _SolidColourEditorState();
}

class _SolidColourEditorState extends State<SolidColourEditor> {
  /// Kept for the whole run, so the picker opens on the numbers last used.
  static ColourFormat _lastFormat = ColourFormat.hex;

  late HSVColor _hsv = HSVColor.fromColor(widget.color);
  ColourFormat _format = _lastFormat;

  @override
  void didUpdateWidget(SolidColourEditor old) {
    super.didUpdateWidget(old);
    if (widget.color.toARGB32() != _hsv.toColor().toARGB32()) {
      _hsv = _keepHue(HSVColor.fromColor(widget.color));
    }
  }

  /// A grey or black has no hue of its own; keep the one there was, so the
  /// square does not jump to red when the colour passes through grey.
  HSVColor _keepHue(HSVColor next) {
    if (next.saturation == 0 || next.value == 0) {
      next = next.withHue(_hsv.hue);
    }
    if (next.value == 0) next = next.withSaturation(_hsv.saturation);
    return next;
  }

  void _setHsv(HSVColor hsv) {
    setState(() => _hsv = hsv);
    widget.onChanged(hsv.toColor());
  }

  void _setColor(Color c, {double? hue}) {
    var next = _keepHue(HSVColor.fromColor(c));
    if (hue != null) next = next.withHue(hue % 360);
    _setHsv(next);
  }

  // The pick layer hangs off this widget rather than being put in the
  // overlay on its own, so whatever the app put round the picker — a
  // claim on the keys, a theme — is round it too.
  final OverlayPortalController _picking = OverlayPortalController();

  void _startPicking() => _picking.show();

  Future<void> _pickAt(Offset at) async {
    _picking.hide();
    final sampler = widget.sampler;
    if (sampler == null) return;
    Color? picked;
    try {
      picked = await sampler(at);
    } catch (_) {
      picked = null;
    }
    if (!mounted || picked == null) return;
    _setColor(picked);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final opaque = _hsv.withAlpha(1).toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SaturationValueBox(
          hsv: _hsv,
          height: widget.boxHeight,
          onChanged: _setHsv,
        ),
        const SizedBox(height: PickerLook.gap),
        Row(
          children: [
            if (widget.sampler != null) ...[
              OverlayPortal(
                controller: _picking,
                overlayLocation: OverlayChildLocation.rootOverlay,
                overlayChildBuilder: (_) => EyedropperLayer(
                  onPick: _pickAt,
                  onCancel: _picking.hide,
                ),
                child: _EyedropperButton(onPressed: _startPicking),
              ),
              const SizedBox(width: PickerLook.gap),
            ],
            Expanded(
              child: Column(
                children: [
                  ColourStrip(
                    value: _hsv.hue / 360,
                    step: 1 / 360,
                    colors: [
                      for (var h = 0; h <= 360; h += 60)
                        HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                    ],
                    thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                    semanticLabel: 'Hue',
                    semanticValue: (v) => '${(v * 360).round()} degrees',
                    onChanged: (v) => _setHsv(_hsv.withHue(v * 360 % 360)),
                  ),
                  const SizedBox(height: 2),
                  ColourStrip(
                    value: _hsv.alpha,
                    checkerboard: true,
                    colors: [opaque.withValues(alpha: 0), opaque],
                    thumbColor: color,
                    semanticLabel: 'Opacity',
                    semanticValue: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => _setHsv(_hsv.withAlpha(v)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PickerLook.gap),
        Row(
          children: [
            _FormatMenu(
              format: _format,
              onChanged: (f) => setState(() => _format = _lastFormat = f),
            ),
            const SizedBox(width: PickerLook.smallGap),
            ..._channelFields(color),
            const SizedBox(width: PickerLook.smallGap),
            SizedBox(
              width: 58,
              child: PickerNumberField(
                value: (_hsv.alpha * 100).roundToDouble(),
                min: 0,
                max: 100,
                suffix: '%',
                semanticLabel: 'Opacity',
                onChanged: (v) => _setHsv(_hsv.withAlpha(v / 100)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _channelFields(Color color) {
    Widget field(
      String prefix,
      double value,
      double max,
      ValueChanged<double> onChanged, {
      String? suffix,
      bool wrap = false,
      String? label,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 3),
        child: PickerNumberField(
          prefix: prefix,
          suffix: suffix,
          value: value,
          min: 0,
          max: max,
          wrap: wrap,
          semanticLabel: label ?? prefix,
          onChanged: onChanged,
        ),
      ),
    );

    switch (_format) {
      case ColourFormat.hex:
        return [
          Expanded(
            child: PickerHexField(color: color, onChanged: _setColor),
          ),
        ];
      case ColourFormat.rgb:
        int ch(double unit) => (unit * 255).round();
        return [
          field('R', ch(color.r).toDouble(), 255, label: 'Red', (v) {
            _setColor(color.withValues(red: v / 255));
          }),
          field('G', ch(color.g).toDouble(), 255, label: 'Green', (v) {
            _setColor(color.withValues(green: v / 255));
          }),
          field('B', ch(color.b).toDouble(), 255, label: 'Blue', (v) {
            _setColor(color.withValues(blue: v / 255));
          }),
        ];
      case ColourFormat.hsl:
        final hsl = HSLColor.fromColor(color);
        // A grey's hue reads as 0; show the hue the square is on.
        final hue = hsl.saturation == 0 ? _hsv.hue : hsl.hue;
        return [
          field('H', hue.roundToDouble(), 360, suffix: '°', wrap: true,
              label: 'Hue', (v) {
            _setHsv(_hsv.withHue(v % 360));
          }),
          field('S', (hsl.saturation * 100).roundToDouble(), 100,
              label: 'Saturation', (v) {
            _setColor(hsl.withHue(hue).withSaturation(v / 100).toColor(),
                hue: hue);
          }),
          field('L', (hsl.lightness * 100).roundToDouble(), 100,
              label: 'Lightness', (v) {
            _setColor(hsl.withHue(hue).withLightness(v / 100).toColor(),
                hue: hue);
          }),
        ];
      case ColourFormat.hsv:
        return [
          field('H', _hsv.hue.roundToDouble(), 360, suffix: '°', wrap: true,
              label: 'Hue', (v) {
            _setHsv(_hsv.withHue(v % 360));
          }),
          field('S', (_hsv.saturation * 100).roundToDouble(), 100,
              label: 'Saturation', (v) {
            _setHsv(_hsv.withSaturation(v / 100));
          }),
          field('V', (_hsv.value * 100).roundToDouble(), 100,
              label: 'Brightness', (v) {
            _setHsv(_hsv.withValue(v / 100));
          }),
        ];
    }
  }
}

class _EyedropperButton extends StatelessWidget {
  const _EyedropperButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return Tooltip(
      message: 'Pick a colour from the screen',
      child: Semantics(
        button: true,
        label: 'Eyedropper',
        excludeSemantics: true,
        child: Material(
          color: look.fieldFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PickerLook.radius),
            side: BorderSide(color: look.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(PickerLook.radius),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 34,
              child: Icon(
                Icons.colorize_rounded,
                size: 16,
                color: look.scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatMenu extends StatelessWidget {
  const _FormatMenu({required this.format, required this.onChanged});

  final ColourFormat format;
  final ValueChanged<ColourFormat> onChanged;

  static const _labels = {
    ColourFormat.hex: 'Hex',
    ColourFormat.rgb: 'RGB',
    ColourFormat.hsl: 'HSL',
    ColourFormat.hsv: 'HSV',
  };

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return MenuAnchor(
      menuChildren: [
        for (final f in ColourFormat.values)
          MenuItemButton(
            onPressed: () => onChanged(f),
            leadingIcon: Icon(
              Icons.check_rounded,
              size: 14,
              color: f == format ? look.accent : Colors.transparent,
            ),
            child: Text(_labels[f]!, style: look.label),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: 'Show the colour as',
        child: InkWell(
          borderRadius: BorderRadius.circular(PickerLook.radius),
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: PickerLook.fieldHeight,
            padding: const EdgeInsets.only(left: 8, right: 4),
            decoration: look.fieldDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(_labels[format]!, style: look.label),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: look.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
