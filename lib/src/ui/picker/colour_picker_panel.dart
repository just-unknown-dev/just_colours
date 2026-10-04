import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../library/colour_library.dart';
import '../../models/colour_selection.dart';
import '../../models/gradient_config.dart';
import '../widgets/picker_look.dart';
import '../widgets/segmented.dart';
import '../widgets/swatch.dart';
import 'eyedropper.dart';
import 'gradient_editor.dart';
import 'solid_colour_editor.dart';
import 'swatch_shelf.dart';

/// What the picker lets the user choose.
enum ColourDialogView {
  /// A solid colour or a gradient, with a switch between them.
  both,

  /// A solid colour only.
  colourOnly,

  /// A gradient only.
  gradientOnly,
}

/// Puts what an app needs round the picker — a [Theme], say — when it
/// opens in a popover or dialog.
typedef PickerWrapper = Widget Function(BuildContext context, Widget picker);

class _ApplyIntent extends Intent {
  const _ApplyIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

/// The colour picker itself, without the window round it: what
/// [JustColourDialog] and [ColourPopover] show.
///
/// What is shown is what comes back: in Solid mode a colour, in Gradient
/// mode a gradient. Every change goes to [onChanged] as it happens, so the
/// caller can show it live; [onApply] and [onCancel] end the edit. Escape
/// cancels, Enter applies.
class ColourPickerPanel extends StatefulWidget {
  const ColourPickerPanel({
    super.key,
    required this.initialSelection,
    required this.onApply,
    required this.onCancel,
    this.onChanged,
    this.view = ColourDialogView.both,
    this.library,
    this.sampler,
    this.showTint = false,
    this.title,
  });

  final ColourSelection initialSelection;
  final ValueChanged<ColourSelection> onApply;
  final VoidCallback onCancel;
  final ValueChanged<ColourSelection>? onChanged;
  final ColourDialogView view;

  /// Recent colours and saved palettes and gradients;
  /// [ColourLibrary.session] when null.
  final ColourLibrary? library;

  /// Reads a colour off the screen; the eyedropper shows only with one.
  final ColourSampler? sampler;

  /// Whether to offer a tint over gradients. Only for callers that draw
  /// [ColourSelection.tint].
  final bool showTint;

  /// What is being picked, shown at the top: "Fill", "Outline".
  final String? title;

  /// [selection] as [view] allows it: a gradient-only picker always gives
  /// a gradient, a colour-only one never does.
  static ColourSelection normalize(
    ColourSelection selection,
    ColourDialogView view,
  ) {
    switch (view) {
      case ColourDialogView.colourOnly:
        return selection.copyWith(useGradient: false);
      case ColourDialogView.gradientOnly:
        return selection.copyWith(useGradient: true);
      case ColourDialogView.both:
        return selection;
    }
  }

  @override
  State<ColourPickerPanel> createState() => ColourPickerPanelState();
}

/// The picker's state; [apply] ends the edit as the Apply button does.
class ColourPickerPanelState extends State<ColourPickerPanel> {
  late final ColourSelection _initial = ColourPickerPanel.normalize(
    widget.initialSelection,
    widget.view,
  );
  late ColourSelection _sel = _initial;

  /// Whether the gradient is one somebody made, rather than the stand-in a
  /// colour comes with. A stand-in is replaced by one built from the colour
  /// the first time Gradient is picked.
  late bool _gradientIsReal =
      _initial.useGradient || widget.view == ColourDialogView.gradientOnly;

  int _stop = 0;
  bool _editingTint = false;

  ColourLibrary get _library => widget.library ?? ColourLibrary.session;

  bool get _canGradient => widget.view != ColourDialogView.colourOnly;

  void _update(ColourSelection next) {
    if (next == _sel) return;
    setState(() => _sel = next);
    widget.onChanged?.call(next);
  }

  void _setGradient(GradientConfig g) {
    _gradientIsReal = true;
    _update(_sel.copyWith(gradient: g));
  }

  void _setMode(bool gradient) {
    var next = _sel.copyWith(useGradient: gradient);
    if (gradient && !_gradientIsReal) {
      _gradientIsReal = true;
      next = next.copyWith(gradient: _gradientFrom(_sel.color, _sel.gradient));
      _stop = 0;
    }
    _editingTint = false;
    _update(next);
  }

  /// A first gradient for [colour]: from it to a darker neighbour.
  static GradientConfig _gradientFrom(Color colour, GradientConfig shape) {
    final hsv = HSVColor.fromColor(colour);
    final end = hsv
        .withHue((hsv.hue + 40) % 360)
        .withValue((hsv.value * 0.7).clamp(0.15, 1.0))
        .toColor();
    return shape.copyWith(colors: [colour, end], clearStops: true);
  }

  void _makeGradient(List<Color> colours) {
    _stop = 0;
    _editingTint = false;
    _gradientIsReal = true;
    _update(
      _sel.copyWith(
        useGradient: true,
        gradient: _sel.gradient.copyWith(colors: colours, clearStops: true),
      ),
    );
  }

  /// The colour the editor and swatches work on now.
  Color get _target {
    if (!_sel.useGradient) return _sel.color;
    if (_editingTint) return _sel.tint;
    final stops = _sel.gradient.stopList;
    return stops[_stop.clamp(0, stops.length - 1)].color;
  }

  void _setTarget(Color c) {
    if (!_sel.useGradient) {
      _update(_sel.copyWith(color: c));
    } else if (_editingTint) {
      _update(_sel.copyWith(tint: c));
    } else {
      final stops = [..._sel.gradient.stopList];
      final i = _stop.clamp(0, stops.length - 1);
      stops[i] = stops[i].copyWith(color: c);
      _setGradient(_sel.gradient.withStopList(stops));
    }
  }

  /// Gives the choice to [ColourPickerPanel.onApply], as Apply does.
  void apply() {
    final result = ColourPickerPanel.normalize(_sel, widget.view);
    _library.addRecentColours(
      result.useGradient
          ? [
              for (final s in result.gradient.stopList) s.color,
              if (widget.showTint && result.hasTint) result.tint,
            ]
          : [result.color],
    );
    widget.onApply(result);
  }

  void _revert() {
    _stop = 0;
    _editingTint = false;
    _update(_initial);
  }

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final showSwitch = widget.view == ColourDialogView.both;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _CancelIntent(),
        SingleActivator(LogicalKeyboardKey.enter): _ApplyIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _ApplyIntent(),
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            _ApplyIntent(),
      },
      child: Actions(
        actions: {
          _ApplyIntent: CallbackAction<_ApplyIntent>(onInvoke: (_) {
            apply();
            return null;
          }),
          _CancelIntent: CallbackAction<_CancelIntent>(onInvoke: (_) {
            widget.onCancel();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    if (widget.title != null) ...[
                      Flexible(
                        child: Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: look.label.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: PickerLook.gap),
                    ],
                    if (showSwitch)
                      PickerSegmented<bool>(
                        semanticLabel: 'Fill kind',
                        selected: _sel.useGradient,
                        onChanged: _setMode,
                        segments: const [
                          PickerSegment(false, 'Solid'),
                          PickerSegment(true, 'Gradient'),
                        ],
                      ),
                    const Spacer(),
                    CompareSwatch(
                      before: _initial,
                      after: _sel,
                      showTint: widget.showTint,
                      onRevert: _revert,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_sel.useGradient)
                        GradientEditor(
                          gradient: _sel.gradient,
                          onChanged: _setGradient,
                          selectedStop: _stop,
                          onSelectStop: (i) => setState(() {
                            _stop = i;
                            _editingTint = false;
                          }),
                          tint: _sel.tint,
                          onTintChanged: (c) =>
                              _update(_sel.copyWith(tint: c)),
                          editingTint: _editingTint,
                          onEditTint: () =>
                              setState(() => _editingTint = true),
                          showTint: widget.showTint,
                          sampler: widget.sampler,
                        )
                      else
                        SolidColourEditor(
                          color: _sel.color,
                          sampler: widget.sampler,
                          onChanged: (c) => _update(_sel.copyWith(color: c)),
                        ),
                      const SizedBox(height: 12),
                      SwatchShelf(
                        library: _library,
                        colour: _target,
                        onPickColour: _setTarget,
                        gradientMode: _sel.useGradient,
                        gradient: _sel.gradient,
                        onPickGradient: (g) {
                          _stop = 0;
                          _editingTint = false;
                          _setGradient(g);
                        },
                        onMakeGradient: _canGradient ? _makeGradient : null,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: PickerLook.gap),
                    FilledButton(
                      onPressed: apply,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
