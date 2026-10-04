import 'package:flutter/material.dart';

import '../../library/colour_library.dart';
import '../../models/colour_palette.dart';
import '../../models/gradient_config.dart';
import '../../models/named_gradient.dart';
import '../../presets/colour_presets.dart';
import '../../theory/colour_theory.dart';
import '../widgets/picker_buttons.dart';
import '../widgets/picker_look.dart';
import '../widgets/segmented.dart';
import '../widgets/swatch.dart';

enum _Shelf { gradients, recent, palette, harmony }

/// Ready colours to click, on tabs: saved gradients, recent colours, a
/// palette, and the harmonies of the colour being edited.
class SwatchShelf extends StatefulWidget {
  const SwatchShelf({
    super.key,
    required this.library,
    required this.colour,
    required this.onPickColour,
    required this.gradientMode,
    required this.gradient,
    required this.onPickGradient,
    required this.onMakeGradient,
  });

  final ColourLibrary library;

  /// The colour being edited: harmonies are worked out from it, and a
  /// swatch of it shows as picked.
  final Color colour;
  final ValueChanged<Color> onPickColour;

  /// Whether a gradient is being edited, which adds the gradients tab.
  final bool gradientMode;
  final GradientConfig gradient;
  final ValueChanged<GradientConfig> onPickGradient;

  /// Turns a palette or harmony into a gradient through its colours. The
  /// buttons for it are hidden when null.
  final ValueChanged<List<Color>>? onMakeGradient;

  @override
  State<SwatchShelf> createState() => _SwatchShelfState();
}

class _SwatchShelfState extends State<SwatchShelf> {
  // Kept for the run, so the shelf opens where it was left.
  static _Shelf _solidTab = _Shelf.recent;
  static _Shelf _gradientTab = _Shelf.gradients;
  static String _harmony = 'Triadic';

  ColourLibrary get _lib => widget.library;

  _Shelf get _tab => widget.gradientMode ? _gradientTab : _solidTab;
  set _tab(_Shelf t) {
    if (widget.gradientMode) {
      _gradientTab = t;
    } else {
      _solidTab = t;
    }
  }

  List<ColourPalette> get _allPalettes => [
    ...ColourPresets.palettes,
    ..._lib.palettes,
  ];

  ColourPalette get _palette {
    final all = _allPalettes;
    return all.firstWhere(
      (p) => p.id == _lib.selectedPaletteId,
      orElse: () => all.first,
    );
  }

  bool _isMine(ColourPalette p) => _lib.palettes.any((m) => m.id == p.id);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _lib,
      builder: (context, _) {
        final tab = !widget.gradientMode && _tab == _Shelf.gradients
            ? _Shelf.recent
            : _tab;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PickerSegmented<_Shelf>(
              expand: true,
              semanticLabel: 'Swatches',
              selected: tab,
              onChanged: (t) => setState(() => _tab = t),
              segments: [
                if (widget.gradientMode)
                  const PickerSegment(_Shelf.gradients, 'Gradients'),
                const PickerSegment(_Shelf.recent, 'Recent'),
                const PickerSegment(_Shelf.palette, 'Palette'),
                const PickerSegment(_Shelf.harmony, 'Harmony'),
              ],
            ),
            const SizedBox(height: PickerLook.gap),
            ConstrainedBox(
              // Two rows of swatches, so a short tab does not make the
              // picker jump in height as tabs change.
              constraints: const BoxConstraints(minHeight: 44),
              child: switch (tab) {
                _Shelf.gradients => _gradients(context),
                _Shelf.recent => _recent(context),
                _Shelf.palette => _paletteTab(context),
                _Shelf.harmony => _harmonyTab(context),
              },
            ),
          ],
        );
      },
    );
  }

  bool _same(Color a, Color b) => a.toARGB32() == b.toARGB32();

  Widget _colourWrap(
    List<Color> colours, {
    List<Widget> trailing = const [],
    void Function(int index, Offset at)? onMenu,
  }) {
    return Wrap(
      spacing: PickerLook.smallGap,
      runSpacing: PickerLook.smallGap,
      children: [
        for (var i = 0; i < colours.length; i++)
          ColourSwatchTile(
            color: colours[i],
            selected: _same(colours[i], widget.colour),
            onTap: () => widget.onPickColour(colours[i]),
            onSecondaryTapUp: onMenu == null
                ? null
                : (d) => onMenu(i, d.globalPosition),
          ),
        ...trailing,
      ],
    );
  }

  Widget _empty(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, style: PickerLook.of(context).caption),
  );

  Widget _recent(BuildContext context) {
    final recent = _lib.recentColours;
    if (recent.isEmpty) {
      return _empty(context, 'Colours you apply show up here.');
    }
    return _colourWrap(
      recent,
      onMenu: (i, at) => _menuAt<void>(context, at, [
        PopupMenuItem(
          onTap: () => _lib.removeRecentColour(recent[i]),
          child: const Text('Remove from recent'),
        ),
        PopupMenuItem(
          onTap: _lib.clearRecentColours,
          child: const Text('Clear recent colours'),
        ),
      ]),
    );
  }

  Widget _paletteTab(BuildContext context) {
    final palette = _palette;
    final mine = _isMine(palette);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PickerMenuButton(
              label: palette.name,
              maxWidth: 190,
              tooltip: palette.description ?? 'Choose a palette',
              menuChildren: _paletteMenu(context, palette, mine),
            ),
            const Spacer(),
            if (widget.onMakeGradient case final make?)
              _ToGradientButton(
                tooltip: 'Make a gradient of this palette',
                onPressed: palette.colors.length < 2
                    ? null
                    : () => make(palette.colors),
              ),
          ],
        ),
        const SizedBox(height: PickerLook.smallGap + 2),
        _colourWrap(
          palette.colors,
          trailing: [
            if (mine && _lib.canSaveCollections)
              _AddTile(
                icon: Icons.add_rounded,
                tooltip: 'Add this colour to the palette',
                onTap: () {
                  if (palette.colors.any((c) => _same(c, widget.colour))) {
                    return;
                  }
                  _lib.savePalette(
                    palette.copyWith(
                      colors: [...palette.colors, widget.colour],
                    ),
                  );
                },
              ),
          ],
          onMenu: mine && _lib.canSaveCollections
              ? (i, at) => _menuAt<void>(context, at, [
                  PopupMenuItem(
                    onTap: () => _lib.savePalette(
                      palette.copyWith(
                        colors: [...palette.colors]..removeAt(i),
                      ),
                    ),
                    child: const Text('Remove from palette'),
                  ),
                ])
              : null,
        ),
      ],
    );
  }

  List<Widget> _paletteMenu(
    BuildContext context,
    ColourPalette current,
    bool mine,
  ) {
    return [
      for (final p in ColourPresets.palettes)
        pickerMenuItem(
          context,
          p.name,
          checked: p.id == current.id,
          onPressed: () => _lib.selectedPaletteId = p.id,
        ),
      if (_lib.palettes.isNotEmpty) const Divider(height: 8),
      for (final p in _lib.palettes)
        pickerMenuItem(
          context,
          p.name,
          checked: p.id == current.id,
          onPressed: () => _lib.selectedPaletteId = p.id,
        ),
      if (_lib.canSaveCollections) ...[
        const Divider(height: 8),
        pickerMenuItem(
          context,
          'New palette with this colour',
          icon: Icons.add_rounded,
          onPressed: () {
            final made = _lib.savePalette(
              ColourPalette(
                id: '',
                name: _lib.unusedPaletteName(),
                colors: [widget.colour],
              ),
            );
            _lib.selectedPaletteId = made.id;
          },
        ),
        if (mine) ...[
          pickerMenuItem(
            context,
            'Rename palette…',
            icon: Icons.edit_outlined,
            onPressed: () async {
              final name = await _askName(context, 'Rename palette', current.name);
              if (name != null) _lib.savePalette(current.copyWith(name: name));
            },
          ),
          pickerMenuItem(
            context,
            'Delete palette',
            icon: Icons.delete_outline_rounded,
            onPressed: () async {
              final ok = await _confirm(
                context,
                'Delete "${current.name}"?',
                'Its colours are not used anywhere else in the picker.',
              );
              if (ok) _lib.deletePalette(current.id);
            },
          ),
        ],
      ],
    ];
  }

  Widget _harmonyTab(BuildContext context) {
    final all = ColourTheory.harmonies(widget.colour);
    final harmony = all.firstWhere(
      (h) => h.name == _harmony,
      orElse: () => all.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PickerMenuButton(
              label: harmony.name,
              maxWidth: 200,
              tooltip: 'Colours that go with this one',
              menuChildren: [
                for (final h in all)
                  pickerMenuItem(
                    context,
                    h.name,
                    checked: h.name == harmony.name,
                    onPressed: () => setState(() => _harmony = h.name),
                  ),
              ],
            ),
            const Spacer(),
            if (widget.onMakeGradient case final make?)
              _ToGradientButton(
                tooltip: 'Make a gradient of these colours',
                onPressed: () => make(harmony.colors),
              ),
          ],
        ),
        const SizedBox(height: PickerLook.smallGap + 2),
        _colourWrap(harmony.colors),
      ],
    );
  }

  Widget _gradients(BuildContext context) {
    final mine = _lib.gradients;
    return Wrap(
      spacing: PickerLook.smallGap,
      runSpacing: PickerLook.smallGap,
      children: [
        for (final g in ColourPresets.gradients)
          GradientSwatchTile(
            gradient: g,
            selected: g == widget.gradient,
            onTap: () => widget.onPickGradient(g),
            tooltip: 'Built-in ${g.type.name} gradient',
          ),
        for (final g in mine)
          GradientSwatchTile(
            gradient: g.gradient,
            selected: g.gradient == widget.gradient,
            tooltip: g.name,
            onTap: () => widget.onPickGradient(g.gradient),
            onSecondaryTapUp: _lib.canSaveCollections
                ? (d) => _gradientMenu(context, g, d.globalPosition)
                : null,
          ),
        if (_lib.canSaveCollections)
          _AddTile(
            icon: Icons.bookmark_add_outlined,
            tooltip: 'Save this gradient',
            width: 40,
            onTap: () {
              if (mine.any((g) => g.gradient == widget.gradient)) return;
              _lib.saveGradient(
                NamedGradient(
                  id: '',
                  name: _lib.unusedGradientName(),
                  gradient: widget.gradient,
                ),
              );
            },
          ),
      ],
    );
  }

  void _gradientMenu(BuildContext context, NamedGradient g, Offset at) {
    _menuAt<void>(context, at, [
      PopupMenuItem(
        onTap: () async {
          // The menu closes first; ask once it has.
          await Future<void>.delayed(Duration.zero);
          if (!context.mounted) return;
          final name = await _askName(context, 'Rename gradient', g.name);
          if (name != null) _lib.saveGradient(g.copyWith(name: name));
        },
        child: const Text('Rename…'),
      ),
      PopupMenuItem(
        onTap: () => _lib.saveGradient(g.copyWith(gradient: widget.gradient)),
        child: const Text('Replace with the current gradient'),
      ),
      PopupMenuItem(
        onTap: () => _lib.deleteGradient(g.id),
        child: const Text('Delete'),
      ),
    ]);
  }

  Future<T?> _menuAt<T>(
    BuildContext context,
    Offset at,
    List<PopupMenuEntry<T>> items,
  ) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final local = overlay?.globalToLocal(at) ?? at;
    final size = overlay?.size ?? Size.zero;
    return showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        local.dx,
        local.dy,
        size.width - local.dx,
        size.height - local.dy,
      ),
      items: items,
    );
  }
}

Future<String?> _askName(BuildContext context, String title, String current) {
  final text = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (context) {
      void done() {
        final name = text.text.trim();
        Navigator.of(context).pop(name.isEmpty ? null : name);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (_) => done(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: done, child: const Text('Rename')),
        ],
      );
    },
  ).whenComplete(text.dispose);
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A swatch-sized button: add, save, clear.
class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.width = PickerLook.swatchSize,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: width,
            height: PickerLook.swatchSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: look.border),
            ),
            child: Icon(icon, size: 14, color: look.muted),
          ),
        ),
      ),
    );
  }
}

/// Turns the colours shown into a gradient.
class _ToGradientButton extends StatelessWidget {
  const _ToGradientButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final look = PickerLook.of(context);
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: look.scheme.onSurfaceVariant,
          textStyle: look.label,
          minimumSize: const Size(0, PickerLook.fieldHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: const Icon(Icons.gradient_rounded, size: 14),
        label: const Text('To gradient'),
      ),
    );
  }
}
