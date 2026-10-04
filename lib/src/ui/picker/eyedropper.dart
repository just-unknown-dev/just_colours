import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reads the colour drawn at [globalPosition] on screen, or null where it
/// cannot: what the app gives the picker to make its eyedropper work.
typedef ColourSampler = Future<Color?> Function(Offset globalPosition);

/// Lets the user click anywhere to pick the colour there with [sampler].
/// Escape or a right click gives up. Null when nothing was picked.
Future<Color?> pickColourFromScreen(
  BuildContext context,
  ColourSampler sampler,
) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final done = Completer<Color?>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => EyedropperLayer(
      onPick: (at) async {
        if (done.isCompleted) return;
        Color? picked;
        try {
          picked = await sampler(at);
        } catch (_) {
          picked = null;
        }
        if (!done.isCompleted) done.complete(picked);
      },
      onCancel: () {
        if (!done.isCompleted) done.complete(null);
      },
    ),
  );
  overlay.insert(entry);
  return done.future.whenComplete(entry.remove);
}

/// What covers the screen while a colour is being picked off it: a
/// crosshair, a hint, and a click that picks. Escape or a right click gives
/// up.
class EyedropperLayer extends StatefulWidget {
  const EyedropperLayer({
    super.key,
    required this.onPick,
    required this.onCancel,
  });

  final ValueChanged<Offset> onPick;
  final VoidCallback onCancel;

  @override
  State<EyedropperLayer> createState() => _EyedropperLayerState();
}

class _EyedropperLayerState extends State<EyedropperLayer> {
  final FocusNode _focus = FocusNode(debugLabel: 'Eyedropper');

  /// What had the keys before, to have them back after: autofocus alone
  /// would not take them from a picker that already has them.
  FocusNode? _before;

  @override
  void initState() {
    super.initState();
    _before = FocusManager.instance.primaryFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    final before = _before;
    if (before != null && before.context != null) {
      scheduleMicrotask(() {
        if (before.context?.mounted ?? false) before.requestFocus();
      });
    }
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => widget.onPick(d.globalPosition),
          onSecondaryTap: widget.onCancel,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                color: scheme.inverseSurface,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.colorize_rounded,
                        size: 16,
                        color: scheme.onInverseSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Click to pick a colour · Esc to cancel',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
