import 'package:flutter/material.dart';

/// Sizes, colours and text styles the picker draws with, all taken from the
/// ambient [Theme] so the picker looks like the app it sits in.
@immutable
class PickerLook {
  const PickerLook._({
    required this.scheme,
    required this.label,
    required this.value,
    required this.caption,
  });

  factory PickerLook.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    return PickerLook._(
      scheme: scheme,
      label: base.copyWith(fontSize: 12, color: scheme.onSurface),
      value: base.copyWith(
        fontSize: 12,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      caption: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  final ColorScheme scheme;

  /// Button and menu text.
  final TextStyle label;

  /// Numbers and codes in fields.
  final TextStyle value;

  /// Small headings over a group: "Recent", "Palette".
  final TextStyle caption;

  static const double radius = 6;
  static const double fieldHeight = 28;
  static const double gap = 8;
  static const double smallGap = 4;
  static const double swatchSize = 20;

  Color get border => scheme.outlineVariant;
  Color get fieldFill => scheme.surfaceContainerHighest;
  Color get accent => scheme.primary;
  Color get muted => scheme.onSurfaceVariant;
  Color get focusRing => scheme.primary;

  BoxDecoration fieldDecoration({bool focused = false}) => BoxDecoration(
    color: fieldFill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: focused ? focusRing : border,
      width: focused ? 1.5 : 1,
    ),
  );

  /// Black or white, whichever reads on [background].
  static Color readableOn(Color background) {
    // Seen over the page, a see-through colour reads as the page does.
    if (background.a < 0.5) return Colors.black;
    return background.computeLuminance() > 0.42 ? Colors.black : Colors.white;
  }
}
