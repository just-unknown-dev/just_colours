import 'package:flutter/material.dart';

import '../../models/gradient_config.dart';
import '../widgets/gradient_canvas.dart';
import '../widgets/gradient_stop_bar.dart';
import '../widgets/number_field.dart';
import '../widgets/picker_buttons.dart';
import '../widgets/picker_look.dart';
import '../widgets/segmented.dart';
import '../widgets/swatch.dart';
import 'eyedropper.dart';
import 'solid_colour_editor.dart';

/// Edits a gradient in place: its kind, its shape by hand on the preview,
/// its colours on the stop bar, the picked colour — or the tint — in the
/// colour editor below.
class GradientEditor extends StatelessWidget {
  const GradientEditor({
    super.key,
    required this.gradient,
    required this.onChanged,
    required this.selectedStop,
    required this.onSelectStop,
    required this.tint,
    required this.onTintChanged,
    required this.editingTint,
    required this.onEditTint,
    this.showTint = false,
    this.sampler,
  });

  final GradientConfig gradient;
  final ValueChanged<GradientConfig> onChanged;

  /// The colour on the stop bar being edited.
  final int selectedStop;
  final ValueChanged<int> onSelectStop;

  final Color tint;
  final ValueChanged<Color> onTintChanged;

  /// Whether the colour editor is on the tint rather than a stop.
  final bool editingTint;
  final VoidCallback onEditTint;

  /// Whether to offer the tint at all.
  final bool showTint;
  final ColourSampler? sampler;

  static const _types = [
    PickerSegment(GradientType.linear, 'Linear', tooltip: 'Along a line'),
    PickerSegment(GradientType.radial, 'Radial', tooltip: 'Out from a point'),
    PickerSegment(GradientType.sweep, 'Sweep', tooltip: 'Round a point'),
  ];

  static const _edges = {
    TileMode.clamp: 'Extend',
    TileMode.repeated: 'Repeat',
    TileMode.mirror: 'Mirror',
    TileMode.decal: 'Clear',
  };

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final stops = gradient.stopList;
    final index = selectedStop.clamp(0, stops.length - 1);
    final stop = stops[index];
    final tinted = showTint && tint.toARGB32() != 0xFFFFFFFF;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: PickerSegmented<GradientType>(
                expand: true,
                segments: _types,
                selected: gradient.type,
                semanticLabel: 'Gradient kind',
                onChanged: (t) => onChanged(gradient.copyWith(type: t)),
              ),
            ),
            const SizedBox(width: PickerLook.gap),
            PickerMenuButton(
              maxWidth: 96,
              label: _edges[gradient.tileMode]!,
              tooltip: 'Past the ends of the gradient',
              menuChildren: [
                for (final e in _edges.entries)
                  pickerMenuItem(
                    context,
                    e.value,
                    checked: e.key == gradient.tileMode,
                    onPressed: () =>
                        onChanged(gradient.copyWith(tileMode: e.key)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: PickerLook.gap),
        GradientCanvas(
          gradient: gradient,
          tint: tinted ? tint : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: PickerLook.gap),
        GradientStopBar(
          gradient: gradient,
          selected: editingTint ? null : index,
          onSelect: onSelectStop,
          onChanged: (list, at) {
            onChanged(gradient.withStopList(list));
            onSelectStop(at);
          },
        ),
        const SizedBox(height: PickerLook.smallGap),
        Row(
          children: [
            if (editingTint)
              Expanded(
                child: Text(
                  'Tint — multiplied over the gradient',
                  style: look.caption,
                ),
              )
            else ...[
              Text('Colour ${index + 1} of ${stops.length}', style: look.caption),
              const SizedBox(width: PickerLook.gap),
              SizedBox(
                width: 66,
                child: PickerNumberField(
                  prefix: 'at',
                  suffix: '%',
                  value: (stop.offset * 100).roundToDouble(),
                  min: 0,
                  max: 100,
                  semanticLabel: 'Position of colour ${index + 1}',
                  onChanged: (v) {
                    final list = [...stops];
                    list[index] = stop.copyWith(offset: v / 100);
                    final moved = list[index];
                    final next = gradient.withStopList(list);
                    onChanged(next);
                    onSelectStop(next.stopList.indexOf(moved));
                  },
                ),
              ),
              PickerIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove this colour',
                onPressed: stops.length <= 2
                    ? null
                    : () {
                        final list = [...stops]..removeAt(index);
                        onChanged(gradient.withStopList(list));
                        onSelectStop(index.clamp(0, list.length - 1));
                      },
              ),
              const Spacer(),
            ],
            PickerIconButton(
              icon: Icons.swap_horiz_rounded,
              tooltip: 'Reverse',
              onPressed: () {
                onChanged(gradient.reversed());
                onSelectStop(stops.length - 1 - index);
              },
            ),
            PickerIconButton(
              icon: Icons.horizontal_distribute_rounded,
              tooltip: 'Space evenly',
              onPressed: () => onChanged(gradient.evenlySpaced()),
            ),
          ],
        ),
        const SizedBox(height: PickerLook.gap),
        SolidColourEditor(
          color: editingTint ? tint : stop.color,
          boxHeight: 112,
          sampler: sampler,
          onChanged: (c) {
            if (editingTint) {
              onTintChanged(c);
              return;
            }
            final list = [...stops];
            list[index] = stop.copyWith(color: c);
            onChanged(gradient.withStopList(list));
          },
        ),
        const SizedBox(height: PickerLook.gap),
        Row(children: _shapeFields()),
        if (showTint) ...[
          const SizedBox(height: PickerLook.gap),
          _TintRow(
            tint: tint,
            selected: editingTint,
            onSelect: onEditTint,
            onReset: () => onTintChanged(const Color(0xFFFFFFFF)),
          ),
        ],
      ],
    );
  }

  List<Widget> _shapeFields() {
    Widget field(
      String prefix,
      String suffix,
      double value,
      double min,
      double max,
      ValueChanged<double> onChanged, {
      bool wrap = false,
      required String label,
    }) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: PickerNumberField(
          prefix: prefix,
          suffix: suffix,
          value: value,
          min: min,
          max: max,
          wrap: wrap,
          semanticLabel: label,
          onChanged: onChanged,
        ),
      ),
    );

    double pct(double align) => ((align + 1) / 2 * 100).roundToDouble();
    double align(double pct) => pct / 100 * 2 - 1;

    final g = gradient;
    final centre = [
      field('X', '%', pct(g.center.x), 0, 100, label: 'Centre across', (v) {
        onChanged(g.copyWith(center: Alignment(align(v), g.center.y)));
      }),
      field('Y', '%', pct(g.center.y), 0, 100, label: 'Centre down', (v) {
        onChanged(g.copyWith(center: Alignment(g.center.x, align(v))));
      }),
    ];
    switch (g.type) {
      case GradientType.linear:
        return [
          field(
            'Angle',
            '°',
            g.normalizedAngle.roundToDouble(),
            0,
            360,
            wrap: true,
            label: 'Angle',
            (v) => onChanged(g.copyWith(angle: v % 360)),
          ),
        ];
      case GradientType.radial:
        return [
          ...centre,
          field(
            'Size',
            '%',
            (g.radius * 100).roundToDouble(),
            1,
            200,
            label: 'Size',
            (v) => onChanged(g.copyWith(radius: v / 100)),
          ),
        ];
      case GradientType.sweep:
        return [
          ...centre,
          field(
            'From',
            '°',
            g.startAngle.roundToDouble(),
            0,
            360,
            label: 'Start angle',
            (v) => onChanged(g.copyWith(startAngle: v)),
          ),
          field(
            'To',
            '°',
            g.endAngle.roundToDouble(),
            0,
            360,
            label: 'End angle',
            (v) => onChanged(g.copyWith(endAngle: v)),
          ),
        ];
    }
  }
}

class _TintRow extends StatelessWidget {
  const _TintRow({
    required this.tint,
    required this.selected,
    required this.onSelect,
    required this.onReset,
  });

  final Color tint;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final plain = tint.toARGB32() == 0xFFFFFFFF;
    return Tooltip(
      message: 'Multiplied over the gradient. White leaves it as it is.',
      child: Row(
        children: [
          ColourSwatchTile(
            color: tint,
            selected: selected,
            onTap: onSelect,
            tooltip: 'Edit the tint',
          ),
          const SizedBox(width: PickerLook.gap),
          InkWell(
            onTap: onSelect,
            child: Text(
              plain ? 'Tint: none' : 'Tint',
              style: look.label.copyWith(
                color: selected ? look.accent : look.label.color,
              ),
            ),
          ),
          const Spacer(),
          if (!plain)
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: look.label,
              ),
              child: const Text('No tint'),
            ),
        ],
      ),
    );
  }
}
