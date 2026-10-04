import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Nudges a control by whole steps: arrows one, with Shift ten.
class StepIntent extends Intent {
  const StepIntent(this.dx, this.dy);

  /// Steps right (positive) or left.
  final int dx;

  /// Steps up (positive) or down.
  final int dy;
}

/// Arrow keys as [StepIntent]s.
const Map<ShortcutActivator, Intent> stepShortcuts = {
  SingleActivator(LogicalKeyboardKey.arrowRight): StepIntent(1, 0),
  SingleActivator(LogicalKeyboardKey.arrowLeft): StepIntent(-1, 0),
  SingleActivator(LogicalKeyboardKey.arrowUp): StepIntent(0, 1),
  SingleActivator(LogicalKeyboardKey.arrowDown): StepIntent(0, -1),
  SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): StepIntent(
    10,
    0,
  ),
  SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): StepIntent(
    -10,
    0,
  ),
  SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): StepIntent(0, 10),
  SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): StepIntent(
    0,
    -10,
  ),
};
