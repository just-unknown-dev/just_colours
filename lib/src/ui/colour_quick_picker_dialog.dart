import 'package:flutter/material.dart';

import '../models/colour_palette.dart';
import '../presets/colour_presets.dart';
import '../utils/colour_codec.dart';
import 'widgets/colour_wheel.dart';

class ColourQuickPickerDialog extends StatefulWidget {
  final Color initialColor;
  final String title;
  final List<ColourPalette>? palettes;

  const ColourQuickPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Pick Color',
    this.palettes,
  });

  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = 'Pick Color',
    List<ColourPalette>? palettes,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (_) => ColourQuickPickerDialog(
        initialColor: initialColor,
        title: title,
        palettes: palettes,
      ),
    );
  }

  @override
  State<ColourQuickPickerDialog> createState() =>
      _ColourQuickPickerDialogState();
}

class _ColourQuickPickerDialogState extends State<ColourQuickPickerDialog> {
  static const double _dialogWidth = 360;

  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = _normalizeForInteractiveWheel(
      HSVColor.fromColor(widget.initialColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _hsv.toColor();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: _dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ColourWheel(
                hue: _hsv.hue,
                onChanged: (h) => setState(() {
                  _hsv = _normalizeForInteractiveWheel(_hsv.withHue(h));
                }),
              ),
            ),
            const SizedBox(height: 12),
            _buildSlider(
              label: 'Saturation',
              value: _hsv.saturation,
              onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
            ),
            _buildSlider(
              label: 'Value',
              value: _hsv.value,
              onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
            ),
            _buildSlider(
              label: 'Opacity',
              value: _hsv.alpha,
              onChanged: (v) => setState(() => _hsv = _hsv.withAlpha(v)),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _choosePalette,
              child: const Text('Choose Palette'),
            ),
            const SizedBox(height: 12),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: current,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(
                ColourCodec.toHex(current),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: current.computeLuminance() > 0.45
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_hsv.toColor()),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  HSVColor _normalizeForInteractiveWheel(HSVColor hsv) {
    // If saturation is zero, hue changes are visually invisible (white/gray).
    // Keep wheel interactions vivid by defaulting to max saturation.
    if (hsv.saturation == 0) {
      return hsv.withSaturation(1);
    }
    return hsv;
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(value: value.clamp(0, 1), onChanged: onChanged),
        ),
      ],
    );
  }

  Future<void> _choosePalette() async {
    final merged = _mergedPalettes();
    if (merged.isEmpty) return;

    final selected = await showModalBottomSheet<ColourPalette>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: merged.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final palette = merged[index];
              return ListTile(
                title: Text(palette.name),
                subtitle: palette.description == null
                    ? null
                    : Text(palette.description!),
                trailing: SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: palette.colors
                        .take(4)
                        .map(
                          (c) => Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(palette),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null || selected.colors.isEmpty) return;
    setState(() => _hsv = HSVColor.fromColor(selected.colors.first));
  }

  List<ColourPalette> _mergedPalettes() {
    return [...ColourPresets.palettes, ...(widget.palettes ?? const [])];
  }
}
