import 'package:flutter/material.dart';

import 'picker_look.dart';

/// One choice of a [PickerSegmented].
class PickerSegment<T> {
  const PickerSegment(this.value, this.label, {this.icon, this.tooltip});

  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;
}

/// A row of choices, one picked: a compact segmented control.
class PickerSegmented<T> extends StatelessWidget {
  const PickerSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.semanticLabel,
  });

  final List<PickerSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Whether the segments share the whole width.
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final children = [
      for (final s in segments)
        _segment(context, look, s, expand: expand),
    ];
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        height: PickerLook.fieldHeight,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: look.fieldFill,
          borderRadius: BorderRadius.circular(PickerLook.radius),
          border: Border.all(color: look.border),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    PickerLook look,
    PickerSegment<T> s, {
    required bool expand,
  }) {
    final on = s.value == selected;
    final fg = on ? look.scheme.onPrimary : look.scheme.onSurfaceVariant;
    Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: expand ? 4 : 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? look.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(PickerLook.radius - 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.icon != null) ...[
            Icon(s.icon, size: 14, color: fg),
            if (s.label.isNotEmpty) const SizedBox(width: 5),
          ],
          if (s.label.isNotEmpty)
            Flexible(
              child: Text(
                s.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: look.label.copyWith(
                  color: fg,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
    body = Semantics(
      button: true,
      selected: on,
      label: s.label.isEmpty ? s.tooltip : s.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(PickerLook.radius - 2),
        onTap: on ? null : () => onChanged(s.value),
        child: body,
      ),
    );
    if (s.tooltip != null) body = Tooltip(message: s.tooltip, child: body);
    return expand ? Expanded(child: body) : body;
  }
}
