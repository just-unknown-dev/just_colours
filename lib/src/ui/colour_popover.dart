import 'package:flutter/material.dart';

import '../library/colour_library.dart';
import '../models/colour_selection.dart';
import 'picker/colour_picker_panel.dart';
import 'picker/eyedropper.dart';

/// The colour picker as a panel beside what opened it, the way design
/// tools show one: it sits next to the field, keeps the field in view,
/// and goes away on a click elsewhere.
///
/// A click outside applies — like clicking Apply — and Escape cancels.
abstract final class ColourPopover {
  /// Opens the picker beside [context]'s widget, or beside [anchor] (in
  /// global coordinates) when given. The choice comes back when it closes;
  /// null when cancelled.
  ///
  /// Each change goes to [onChanged] as it happens, to show it live. Use
  /// [builder] to put the panel inside what the app needs round it — a
  /// [Theme], say; themes over [context] are carried over already.
  static Future<ColourSelection?> show(
    BuildContext context, {
    ColourSelection initialSelection = const ColourSelection(
      color: Colors.white,
    ),
    ColourDialogView view = ColourDialogView.both,
    Rect? anchor,
    ColourLibrary? library,
    ColourSampler? sampler,
    ValueChanged<ColourSelection>? onChanged,
    bool showTint = false,
    String? title,
    double width = 340,
    PickerWrapper? builder,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlayBox =
        navigator.overlay!.context.findRenderObject()! as RenderBox;
    Rect global;
    if (anchor != null) {
      global = anchor;
    } else {
      final box = context.findRenderObject()! as RenderBox;
      global = box.localToGlobal(Offset.zero) & box.size;
    }
    final local = Rect.fromPoints(
      overlayBox.globalToLocal(global.topLeft),
      overlayBox.globalToLocal(global.bottomRight),
    );

    final panelKey = GlobalKey<ColourPickerPanelState>();
    return navigator.push(
      _PopoverRoute(
        anchor: local,
        width: width,
        themes: InheritedTheme.capture(
          from: context,
          to: navigator.context,
        ),
        builder: builder,
        onOutsideTap: () => panelKey.currentState?.apply(),
        panel: (route) => ColourPickerPanel(
          key: panelKey,
          initialSelection: initialSelection,
          view: view,
          library: library,
          sampler: sampler,
          onChanged: onChanged,
          showTint: showTint,
          title: title,
          onApply: (s) {
            if (route.isActive) navigator.pop(s);
          },
          onCancel: () {
            if (route.isActive) navigator.pop();
          },
        ),
      ),
    );
  }
}

class _PopoverRoute extends PopupRoute<ColourSelection> {
  _PopoverRoute({
    required this.anchor,
    required this.width,
    required this.themes,
    required this.panel,
    required this.onOutsideTap,
    this.builder,
  });

  final Rect anchor;
  final double width;
  final CapturedThemes themes;
  final Widget Function(_PopoverRoute route) panel;
  final VoidCallback onOutsideTap;
  final PickerWrapper? builder;

  @override
  Color? get barrierColor => null;

  // Outside clicks apply, so the barrier must not close the picker itself.
  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 130);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 90);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    // Built below [builder], so a theme it puts round the panel colours
    // the panel's own surface too.
    Widget body = Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Material(
          elevation: 12,
          color: scheme.surfaceContainer,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: panel(this),
        );
      },
    );
    if (builder != null) body = builder!(context, body);
    return themes.wrap(
      Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOutsideTap,
              onSecondaryTap: onOutsideTap,
            ),
          ),
          CustomSingleChildLayout(
            delegate: _PopoverLayout(
              anchor: anchor,
              width: width,
              margin: EdgeInsets.fromLTRB(
                8 + padding.left,
                8 + padding.top,
                8 + padding.right,
                8 + padding.bottom,
              ),
            ),
            child: body,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.97, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}

/// Puts the panel beside the anchor — on the side with more room, so a
/// field near the right edge opens it to the left — or else below or
/// above it, and always inside the screen.
class _PopoverLayout extends SingleChildLayoutDelegate {
  _PopoverLayout({
    required this.anchor,
    required this.width,
    required this.margin,
  });

  final Rect anchor;
  final double width;
  final EdgeInsets margin;

  static const double _gap = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = (constraints.maxWidth - margin.horizontal).clamp(
      0.0,
      double.infinity,
    );
    final maxH = (constraints.maxHeight - margin.vertical).clamp(
      0.0,
      double.infinity,
    );
    return BoxConstraints(
      minWidth: width.clamp(0.0, maxW),
      maxWidth: width.clamp(0.0, maxW),
      maxHeight: maxH,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    double clampX(double x) => x
        .clamp(margin.left, size.width - margin.right - child.width)
        .toDouble();
    double clampY(double y) => y
        .clamp(margin.top, size.height - margin.bottom - child.height)
        .toDouble();

    final leftX = anchor.left - _gap - child.width;
    final rightX = anchor.right + _gap;
    final fitsLeft = leftX >= margin.left;
    final fitsRight = rightX + child.width <= size.width - margin.right;
    final preferLeft = anchor.center.dx > size.width / 2;
    final besideY = clampY(anchor.top - 12);

    if (preferLeft && fitsLeft) return Offset(leftX, besideY);
    if (fitsRight) return Offset(rightX, besideY);
    if (fitsLeft) return Offset(leftX, besideY);

    final below = anchor.bottom + _gap;
    final fitsBelow = below + child.height <= size.height - margin.bottom;
    final y = fitsBelow ? below : clampY(anchor.top - _gap - child.height);
    return Offset(clampX(anchor.left), y);
  }

  @override
  bool shouldRelayout(_PopoverLayout old) =>
      old.anchor != anchor || old.width != width || old.margin != margin;
}
