import 'package:flutter/material.dart';

import 'picker_look.dart';

/// A small square button with an icon and a tooltip.
class PickerIconButton extends StatelessWidget {
  const PickerIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = PickerLook.fieldHeight,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(PickerLook.radius),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: 16,
              color: enabled
                  ? look.scheme.onSurfaceVariant
                  : look.scheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// A field-sized button that opens [menuChildren]: the label of what is
/// chosen and a chevron.
class PickerMenuButton extends StatelessWidget {
  const PickerMenuButton({
    super.key,
    required this.label,
    required this.menuChildren,
    this.tooltip,
    this.maxWidth = 140,
  });

  final String label;
  final List<Widget> menuChildren;
  final String? tooltip;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return MenuAnchor(
      menuChildren: menuChildren,
      builder: (context, controller, _) {
        Widget button = InkWell(
          borderRadius: BorderRadius.circular(PickerLook.radius),
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            height: PickerLook.fieldHeight,
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.only(left: 8, right: 4),
            decoration: look.fieldDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: look.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.expand_more_rounded, size: 14, color: look.muted),
              ],
            ),
          ),
        );
        if (tooltip != null) {
          button = Tooltip(message: tooltip, child: button);
        }
        return button;
      },
    );
  }
}

/// A menu entry with a tick in front when [checked].
Widget pickerMenuItem(
  BuildContext context,
  String label, {
  required VoidCallback? onPressed,
  bool checked = false,
  IconData? icon,
}) {
  final look = PickerLook.of(context);
  return MenuItemButton(
    onPressed: onPressed,
    leadingIcon: Icon(
      icon ?? Icons.check_rounded,
      size: 14,
      color: icon != null
          ? look.muted
          : (checked ? look.accent : Colors.transparent),
    ),
    child: Text(label, style: look.label),
  );
}
