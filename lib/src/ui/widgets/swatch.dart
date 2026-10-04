import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../models/colour_selection.dart';
import '../../models/gradient_config.dart';
import '../../utils/colour_codec.dart';
import 'checkerboard.dart';
import 'picker_look.dart';

/// Paints [selection] exactly as it will be drawn: the solid colour, or the
/// gradient with its tint multiplied in.
class SelectionPaint extends StatelessWidget {
  const SelectionPaint({
    super.key,
    required this.selection,
    this.showTint = true,
    this.child,
  });

  final ColourSelection selection;
  final bool showTint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (!selection.useGradient) {
      return Checkerboard(
        child: ColoredBox(
          color: selection.color,
          child: child ?? const SizedBox.expand(),
        ),
      );
    }
    return Checkerboard(
      child: GradientPaint(
        gradient: selection.gradient,
        tint: showTint && selection.hasTint ? selection.tint : null,
        child: child,
      ),
    );
  }
}

/// [gradient] filling the box, [tint] multiplied over it.
class GradientPaint extends StatelessWidget {
  const GradientPaint({super.key, required this.gradient, this.tint, this.child});

  final GradientConfig gradient;
  final Color? tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Widget paint = DecoratedBox(
      decoration: BoxDecoration(gradient: gradient.toGradient()),
      child: const SizedBox.expand(),
    );
    if (tint != null) {
      paint = ColorFiltered(
        colorFilter: ColorFilter.mode(tint!, BlendMode.modulate),
        child: paint,
      );
    }
    return Stack(fit: StackFit.passthrough, children: [paint, ?child]);
  }
}

/// A small square of colour to click.
class ColourSwatchTile extends StatelessWidget {
  const ColourSwatchTile({
    super.key,
    required this.color,
    this.onTap,
    this.onSecondaryTapUp,
    this.selected = false,
    this.size = PickerLook.swatchSize,
    this.tooltip,
  });

  final Color color;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final bool selected;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return _SwatchFrame(
      size: Size.square(size),
      selected: selected,
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      tooltip: tooltip ?? ColourCodec.toHex(color, includeAlpha: color.a < 1),
      semanticLabel: 'Colour ${ColourCodec.toHex(color)}',
      look: look,
      child: Checkerboard(cell: 4, child: ColoredBox(color: color)),
    );
  }
}

/// A small strip of gradient to click.
class GradientSwatchTile extends StatelessWidget {
  const GradientSwatchTile({
    super.key,
    required this.gradient,
    this.onTap,
    this.onSecondaryTapUp,
    this.selected = false,
    this.size = const Size(40, PickerLook.swatchSize),
    this.tooltip,
  });

  final GradientConfig gradient;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final bool selected;
  final Size size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return _SwatchFrame(
      size: size,
      selected: selected,
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      tooltip: tooltip,
      semanticLabel: tooltip ?? '${gradient.type.name} gradient',
      look: look,
      child: Checkerboard(cell: 4, child: GradientPaint(gradient: gradient)),
    );
  }
}

class _SwatchFrame extends StatelessWidget {
  const _SwatchFrame({
    required this.size,
    required this.selected,
    required this.onTap,
    required this.onSecondaryTapUp,
    required this.tooltip,
    required this.semanticLabel,
    required this.look,
    required this.child,
  });

  final Size size;
  final bool selected;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final String? tooltip;
  final String semanticLabel;
  final PickerLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    Widget tile = Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: selected ? look.accent : look.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(selected ? 2 : 3),
        child: child,
      ),
    );
    tile = Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          onSecondaryTapUp: onSecondaryTapUp,
          // A long press stands in for a right click on touch screens.
          onLongPress: onSecondaryTapUp == null
              ? null
              : () {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final at = box.localToGlobal(box.size.center(Offset.zero));
                  onSecondaryTapUp!(
                    TapUpDetails(
                      kind: PointerDeviceKind.touch,
                      globalPosition: at,
                      localPosition: box.size.center(Offset.zero),
                    ),
                  );
                },
          child: tile,
        ),
      ),
    );
    if (tooltip != null) {
      tile = Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: tile,
      );
    }
    return tile;
  }
}

/// What there was and what there is now, side by side. Clicking the old
/// half puts it back.
class CompareSwatch extends StatelessWidget {
  const CompareSwatch({
    super.key,
    required this.before,
    required this.after,
    required this.onRevert,
    this.showTint = true,
  });

  final ColourSelection before;
  final ColourSelection after;
  final VoidCallback onRevert;
  final bool showTint;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final changed = before != after;
    return Container(
      width: 64,
      height: PickerLook.fieldHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PickerLook.radius),
        border: Border.all(color: look.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PickerLook.radius - 1),
        child: Row(
          children: [
            Expanded(
              child: Tooltip(
                message: changed ? 'Before — click to go back' : 'Before',
                child: Semantics(
                  button: true,
                  label: 'Revert to the colour before',
                  child: MouseRegion(
                    cursor: changed
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    child: GestureDetector(
                      onTap: changed ? onRevert : null,
                      child: SelectionPaint(
                        selection: before,
                        showTint: showTint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Tooltip(
                message: 'Now',
                child: SelectionPaint(selection: after, showTint: showTint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
