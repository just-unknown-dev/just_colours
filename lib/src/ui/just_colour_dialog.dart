import 'package:flutter/material.dart';

import '../models/colour_palette.dart';
import '../models/colour_selection.dart';
import '../models/gradient_config.dart';
import '../presets/colour_presets.dart';
import '../storage/colour_storage_repository.dart';
import '../theory/colour_theory.dart';
import 'colour_quick_picker_dialog.dart';

enum ColourDialogView { both, colourOnly, gradientOnly }

abstract final class _DialogUi {
  static const dialogInsetPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 24,
  );
  static const dialogInnerPadding = EdgeInsets.fromLTRB(18, 16, 18, 14);
  static const dialogMaxWidth = 580.0;
  static const dialogMaxHeight = 720.0;
  static const sectionGap = 12.0;
  static const inlineGap = 8.0;
  static const mediumGap = 10.0;
  static const smallGap = 6.0;
  static const largeGap = 14.0;
  static const recentSheetPadding = EdgeInsets.fromLTRB(16, 8, 16, 16);
  static const durationFast = Duration(milliseconds: 220);
  static const durationMedium = Duration(milliseconds: 260);
  static const durationSlow = Duration(milliseconds: 280);
  static const durationChipScale = Duration(milliseconds: 170);
  static const durationChipText = Duration(milliseconds: 180);
}

class JustColourDialog extends StatefulWidget {
  final ColourSelection initialSelection;
  final ColourStorageRepository? repository;
  final ColourDialogView view;

  const JustColourDialog({
    super.key,
    required this.initialSelection,
    this.repository,
    this.view = ColourDialogView.both,
  });

  static Future<ColourSelection?> show(
    BuildContext context, {
    ColourSelection initialSelection = const ColourSelection(
      color: Colors.white,
    ),
    ColourStorageRepository? repository,
    ColourDialogView view = ColourDialogView.both,
  }) {
    return showDialog<ColourSelection>(
      context: context,
      builder: (_) => JustColourDialog(
        initialSelection: initialSelection,
        repository: repository,
        view: view,
      ),
    );
  }

  @override
  State<JustColourDialog> createState() => _JustColourDialogState();
}

class _JustColourDialogState extends State<JustColourDialog> {
  late ColourSelection _selection;
  late GradientConfig _gradient;

  bool get _showsColour =>
      widget.view == ColourDialogView.both ||
      widget.view == ColourDialogView.colourOnly;

  bool get _showsGradient =>
      widget.view == ColourDialogView.both ||
      widget.view == ColourDialogView.gradientOnly;

  bool get _showsBoth => _showsColour && _showsGradient;

  @override
  void initState() {
    super.initState();
    _selection = _normalizeSelectionForView(widget.initialSelection);
    _gradient = widget.initialSelection.gradient;
  }

  ColourSelection _normalizeSelectionForView(ColourSelection selection) {
    switch (widget.view) {
      case ColourDialogView.colourOnly:
        return selection.copyWith(useGradient: false);
      case ColourDialogView.gradientOnly:
        return selection.copyWith(useGradient: true);
      case ColourDialogView.both:
        return selection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Dialog(
      insetPadding: _DialogUi.dialogInsetPadding,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _DialogUi.dialogMaxWidth,
          maxHeight: _DialogUi.dialogMaxHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.10),
                theme.colorScheme.surface,
                theme.colorScheme.surface,
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
          child: Padding(
            padding: _DialogUi.dialogInnerPadding,
            child: _showsBoth
                ? DefaultTabController(
                    length: 2,
                    child: _buildDialogBody(theme, accent),
                  )
                : _buildDialogBody(theme, accent),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogBody(ThemeData theme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DialogHeader(
          accent: accent,
          titleStyle: theme.textTheme.titleMedium,
          onClose: () => Navigator.of(context).pop(),
        ),
        Text(
          'Build a modern paint style with palettes and gradients',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: _DialogUi.sectionGap),
        if (_showsBoth)
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TabBar(
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Colour'),
                Tab(text: 'Gradient'),
              ],
            ),
          ),
        if (_showsBoth) const SizedBox(height: _DialogUi.sectionGap),
        Expanded(child: _buildBodyContent()),
        const SizedBox(height: _DialogUi.sectionGap),
        _DialogFooterActions(
          canUseRepository: widget.repository != null,
          onLoadSaved: _handleLoadCurrent,
          onOpenRecent: _openRecentPicker,
          onCancel: () => Navigator.of(context).pop(),
          onApply: _handleApply,
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    if (_showsBoth) {
      return TabBarView(
        children: [_buildColourTab(context), _buildGradientTab(context)],
      );
    }

    if (_showsColour) {
      return _buildColourTab(context);
    }

    return _buildGradientTab(context);
  }

  Widget _buildColourTab(BuildContext context) {
    final harmonies = ColourTheory.fullHarmonySet(
      _selection.color,
    ).take(8).toList();
    return _ColourTabContent(
      selection: _selection,
      harmonies: harmonies,
      showsGradientToggle: _showsGradient,
      canSavePalette: widget.repository != null,
      onOpenColorWheel: _pickBaseColor,
      onChoosePalette: _choosePalette,
      onUseGradientChanged: (v) =>
          setState(() => _selection = _selection.copyWith(useGradient: v)),
      onSelectHarmony: (color) =>
          setState(() => _selection = _selection.copyWith(color: color)),
      onSaveCurrentAsPalette: _saveCurrentAsPalette,
    );
  }

  Widget _buildGradientTab(BuildContext context) {
    final gradientColors = _gradient.colors.length >= 2
        ? _gradient.colors.take(2).toList()
        : [_selection.color, _selection.color.withValues(alpha: 0.8)];

    return _GradientTabContent(
      gradient: _gradient,
      gradientColors: gradientColors,
      animatedGradientControls: _buildAnimatedGradientControls(),
      canSaveGradient: widget.repository != null,
      onPickStartColor: () => _pickGradientColor(0),
      onPickEndColor: () => _pickGradientColor(1),
      onSwapStops: () {
        final colors = List<Color>.from(gradientColors.reversed);
        setState(() => _gradient = _gradient.copyWith(colors: colors));
      },
      onGradientTypeChanged: (type) =>
          setState(() => _gradient = _gradient.copyWith(type: type)),
      onGradientPresetSelected: (preset) => setState(() => _gradient = preset),
      isPresetSelected: _isPresetSelected,
      gradientTypeLabelBuilder: _gradientTypeLabel,
      onSaveCurrentGradient: _saveCurrentGradient,
    );
  }

  Widget _buildSliderRowModern({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _DialogUi.smallGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _gradientTypeLabel(GradientType type) {
    switch (type) {
      case GradientType.linear:
        return 'Linear';
      case GradientType.radial:
        return 'Radial';
      case GradientType.sweep:
        return 'Sweep';
    }
  }

  bool _isPresetSelected(GradientConfig preset) {
    if (_gradient.type != preset.type) return false;
    if ((_gradient.angle - preset.angle).abs() > 0.001) return false;
    if ((_gradient.radius - preset.radius).abs() > 0.001) return false;
    if ((_gradient.center.x - preset.center.x).abs() > 0.001) return false;
    if ((_gradient.center.y - preset.center.y).abs() > 0.001) return false;
    if (_gradient.tileMode != preset.tileMode) return false;
    if (_gradient.colors.length != preset.colors.length) return false;
    for (int i = 0; i < _gradient.colors.length; i++) {
      if (_gradient.colors[i].toARGB32() != preset.colors[i].toARGB32()) {
        return false;
      }
    }
    final s1 = _gradient.stops;
    final s2 = preset.stops;
    if (s1 == null && s2 == null) return true;
    if (s1 == null || s2 == null) return false;
    if (s1.length != s2.length) return false;
    for (int i = 0; i < s1.length; i++) {
      if ((s1[i] - s2[i]).abs() > 0.001) return false;
    }
    return true;
  }

  Widget _buildAnimatedGradientControls() {
    switch (_gradient.type) {
      case GradientType.linear:
        return KeyedSubtree(
          key: const ValueKey<GradientType>(GradientType.linear),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderRowModern(
                label: 'Angle',
                value: _gradient.angle,
                min: 0,
                max: 360,
                onChanged: (v) =>
                    setState(() => _gradient = _gradient.copyWith(angle: v)),
              ),
            ],
          ),
        );
      case GradientType.radial:
        return KeyedSubtree(
          key: const ValueKey<GradientType>(GradientType.radial),
          child: Column(
            children: [
              _buildSliderRowModern(
                label: 'Radius',
                value: _gradient.radius,
                min: 0.1,
                max: 1.5,
                onChanged: (v) =>
                    setState(() => _gradient = _gradient.copyWith(radius: v)),
              ),
              const SizedBox(height: _DialogUi.inlineGap),
              _buildSliderRowModern(
                label: 'Center X',
                value: _gradient.center.x,
                min: -1,
                max: 1,
                onChanged: (v) => setState(
                  () => _gradient = _gradient.copyWith(
                    center: Alignment(v, _gradient.center.y),
                  ),
                ),
              ),
              _buildSliderRowModern(
                label: 'Center Y',
                value: _gradient.center.y,
                min: -1,
                max: 1,
                onChanged: (v) => setState(
                  () => _gradient = _gradient.copyWith(
                    center: Alignment(_gradient.center.x, v),
                  ),
                ),
              ),
            ],
          ),
        );
      case GradientType.sweep:
        return KeyedSubtree(
          key: const ValueKey<GradientType>(GradientType.sweep),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderRowModern(
                label: 'Center X',
                value: _gradient.center.x,
                min: -1,
                max: 1,
                onChanged: (v) => setState(
                  () => _gradient = _gradient.copyWith(
                    center: Alignment(v, _gradient.center.y),
                  ),
                ),
              ),
              _buildSliderRowModern(
                label: 'Center Y',
                value: _gradient.center.y,
                min: -1,
                max: 1,
                onChanged: (v) => setState(
                  () => _gradient = _gradient.copyWith(
                    center: Alignment(_gradient.center.x, v),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _pickBaseColor() async {
    final picked = await ColourQuickPickerDialog.show(
      context,
      initialColor: _selection.color,
      title: 'Pick Base Color',
    );
    if (!mounted || picked == null) return;
    setState(() => _selection = _selection.copyWith(color: picked));
  }

  Future<void> _pickGradientColor(int index) async {
    final colors = List<Color>.from(_gradient.colors);
    while (colors.length <= index) {
      colors.add(_selection.color);
    }

    final picked = await ColourQuickPickerDialog.show(
      context,
      initialColor: colors[index],
      title: index == 0 ? 'Pick Start Color' : 'Pick End Color',
    );
    if (!mounted || picked == null) return;

    colors[index] = picked;
    setState(() => _gradient = _gradient.copyWith(colors: colors));
  }

  void _applyPalette(ColourPalette palette) {
    if (palette.colors.isEmpty) return;
    final gradientColors = palette.colors.length >= 2
        ? palette.colors.take(2).toList()
        : [palette.colors.first, _selection.color];

    setState(() {
      _selection = _selection.copyWith(color: palette.colors.first);
      _gradient = _gradient.copyWith(colors: gradientColors);
    });
  }

  Future<void> _choosePalette() async {
    final savedPalettes = widget.repository == null
        ? const <ColourPalette>[]
        : await widget.repository!.listPalettes();

    final merged = <ColourPalette>[...ColourPresets.palettes, ...savedPalettes];

    if (!mounted || merged.isEmpty) return;

    final selected = await showModalBottomSheet<ColourPalette>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: merged.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final palette = merged[index];
              return ListTile(
                title: Text(palette.name),
                subtitle: palette.description == null
                    ? null
                    : Text(palette.description!),
                trailing: SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: palette.colors
                        .take(4)
                        .map(
                          (c) => Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                onTap: () => Navigator.of(context).pop(palette),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    _applyPalette(selected);
  }

  Future<void> _saveCurrentAsPalette() async {
    final repo = widget.repository;
    if (repo == null) return;

    final palette = ColourPalette(
      id: '',
      name: 'Palette ${DateTime.now().toIso8601String()}',
      colors: [
        _selection.color,
        ...ColourTheory.analogous(_selection.color).take(2),
      ],
      description: 'Saved from colour dialog',
    );
    await repo.savePalette(palette);
  }

  Future<void> _saveCurrentGradient() async {
    final repo = widget.repository;
    if (repo == null) return;

    await repo.saveGradient(
      'Gradient ${DateTime.now().toIso8601String()}',
      _gradient,
    );
  }

  Future<void> _handleLoadCurrent() async {
    final repo = widget.repository;
    if (repo == null) return;
    final loaded = await repo.loadCurrentSelection();
    if (!mounted || loaded == null) return;

    setState(() {
      _selection = loaded;
      _gradient = loaded.gradient;
    });
  }

  Future<void> _openRecentPicker() async {
    final repo = widget.repository;
    if (repo == null) return;

    final history = await repo.listHistory(limit: 30);
    final savedGradients = await repo.listGradients();
    final pinnedColors = (await repo.loadPinnedRecentColors()).toSet();
    final pinnedGradients = (await repo.loadPinnedRecentGradients()).toSet();
    if (!mounted) return;

    final recentColors = <Color>[];
    final seenColors = <int>{};
    for (final entry in history) {
      final argb = entry.color.toARGB32();
      if (seenColors.add(argb)) {
        recentColors.add(entry.color);
      }
    }

    recentColors.sort((a, b) {
      final aPinned = pinnedColors.contains(a.toARGB32());
      final bPinned = pinnedColors.contains(b.toARGB32());
      if (aPinned == bPinned) return 0;
      return aPinned ? -1 : 1;
    });

    final orderedGradients = List<(String, GradientConfig)>.from(savedGradients)
      ..sort((a, b) {
        final aPinned = pinnedGradients.contains(_gradientRecentKey(a));
        final bPinned = pinnedGradients.contains(_gradientRecentKey(b));
        if (aPinned == bPinned) return 0;
        return aPinned ? -1 : 1;
      });

    if (recentColors.isEmpty && orderedGradients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recent colors or gradients yet.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _RecentSelectionsSheet(
        recentColors: recentColors,
        gradients: orderedGradients,
        pinnedColors: pinnedColors,
        pinnedGradients: pinnedGradients,
        gradientKeyBuilder: _gradientRecentKey,
        onSelectColor: (color) {
          setState(() => _selection = _selection.copyWith(color: color));
          Navigator.of(sheetContext).pop();
        },
        onSelectGradient: (gradient) {
          setState(() => _gradient = gradient);
          Navigator.of(sheetContext).pop();
        },
        onPinnedColorsChanged: (updated) =>
            repo.savePinnedRecentColors(updated.toList()),
        onPinnedGradientsChanged: (updated) =>
            repo.savePinnedRecentGradients(updated.toList()),
      ),
    );
  }

  String _gradientRecentKey((String, GradientConfig) entry) {
    return '${entry.$1}|${entry.$2.toJson()}';
  }

  Future<void> _handleApply() async {
    final result = _normalizeSelectionForView(
      _selection.copyWith(gradient: _gradient),
    );
    final repo = widget.repository;
    if (repo != null) {
      await repo.saveCurrentSelection(result);
      await repo.appendHistory(result);
    }
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }
}

class _DialogHeader extends StatelessWidget {
  final Color accent;
  final TextStyle? titleStyle;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.accent,
    required this.titleStyle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.gradient_rounded, color: accent, size: 18),
        const SizedBox(width: _DialogUi.inlineGap),
        Text(
          'Colour Studio',
          style: titleStyle?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _DialogFooterActions extends StatelessWidget {
  final bool canUseRepository;
  final Future<void> Function() onLoadSaved;
  final Future<void> Function() onOpenRecent;
  final VoidCallback onCancel;
  final Future<void> Function() onApply;

  const _DialogFooterActions({
    required this.canUseRepository,
    required this.onLoadSaved,
    required this.onOpenRecent,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: canUseRepository ? onLoadSaved : null,
          icon: const Icon(Icons.history_rounded),
          label: const Text('Load Saved'),
        ),
        const SizedBox(width: _DialogUi.inlineGap),
        TextButton.icon(
          onPressed: canUseRepository ? onOpenRecent : null,
          icon: const Icon(Icons.auto_awesome_mosaic_rounded),
          label: const Text('Recent'),
        ),
        const Spacer(),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        const SizedBox(width: _DialogUi.inlineGap),
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _GradientPreviewCard extends StatelessWidget {
  final GradientConfig gradient;
  final int stopCount;
  final Color borderColor;

  const _GradientPreviewCard({
    required this.gradient,
    required this.stopCount,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade300, Colors.white],
                ),
              ),
            ),
            AnimatedContainer(
              duration: _DialogUi.durationSlow,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(gradient: gradient.toGradient()),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: AnimatedSwitcher(
                duration: _DialogUi.durationFast,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.15),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey<String>('${gradient.type.name}-$stopCount'),
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${gradient.type.name.toUpperCase()} • $stopCount stops',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSelectionsSheet extends StatefulWidget {
  final List<Color> recentColors;
  final List<(String, GradientConfig)> gradients;
  final Set<int> pinnedColors;
  final Set<String> pinnedGradients;
  final String Function((String, GradientConfig)) gradientKeyBuilder;
  final ValueChanged<Color> onSelectColor;
  final ValueChanged<GradientConfig> onSelectGradient;
  final Future<void> Function(Set<int>) onPinnedColorsChanged;
  final Future<void> Function(Set<String>) onPinnedGradientsChanged;

  const _RecentSelectionsSheet({
    required this.recentColors,
    required this.gradients,
    required this.pinnedColors,
    required this.pinnedGradients,
    required this.gradientKeyBuilder,
    required this.onSelectColor,
    required this.onSelectGradient,
    required this.onPinnedColorsChanged,
    required this.onPinnedGradientsChanged,
  });

  @override
  State<_RecentSelectionsSheet> createState() => _RecentSelectionsSheetState();
}

class _RecentSelectionsSheetState extends State<_RecentSelectionsSheet> {
  late final Set<int> _localPinnedColors;
  late final Set<String> _localPinnedGradients;

  @override
  void initState() {
    super.initState();
    _localPinnedColors = {...widget.pinnedColors};
    _localPinnedGradients = {...widget.pinnedGradients};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: _DialogUi.recentSheetPadding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Colors & Gradients',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (widget.recentColors.isNotEmpty) ...[
                const SizedBox(height: _DialogUi.sectionGap),
                Text('Colors', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: _DialogUi.inlineGap),
                Wrap(
                  spacing: _DialogUi.inlineGap,
                  runSpacing: _DialogUi.inlineGap,
                  children: widget.recentColors
                      .map(
                        (color) => Stack(
                          children: [
                            GestureDetector(
                              onTap: () => widget.onSelectColor(color),
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 6, top: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleColorPin(color.toARGB32()),
                                child: Icon(
                                  _localPinnedColors.contains(color.toARGB32())
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
              if (widget.gradients.isNotEmpty) ...[
                const SizedBox(height: _DialogUi.largeGap),
                Text(
                  'Gradients',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: _DialogUi.inlineGap),
                Wrap(
                  spacing: _DialogUi.inlineGap,
                  runSpacing: _DialogUi.inlineGap,
                  children: widget.gradients
                      .map(
                        (entry) => Stack(
                          children: [
                            GestureDetector(
                              onTap: () => widget.onSelectGradient(entry.$2),
                              child: Container(
                                width: 92,
                                height: 44,
                                margin: const EdgeInsets.only(right: 6, top: 4),
                                decoration: BoxDecoration(
                                  gradient: entry.$2.toGradient(),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black26),
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  entry.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () => _toggleGradientPin(entry),
                                child: Icon(
                                  _localPinnedGradients.contains(
                                        widget.gradientKeyBuilder(entry),
                                      )
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleColorPin(int colorKey) async {
    setState(() {
      if (!_localPinnedColors.add(colorKey)) {
        _localPinnedColors.remove(colorKey);
      }
    });
    await widget.onPinnedColorsChanged(_localPinnedColors);
  }

  Future<void> _toggleGradientPin((String, GradientConfig) entry) async {
    final key = widget.gradientKeyBuilder(entry);
    setState(() {
      if (!_localPinnedGradients.add(key)) {
        _localPinnedGradients.remove(key);
      }
    });
    await widget.onPinnedGradientsChanged(_localPinnedGradients);
  }
}

class _ColourTabContent extends StatelessWidget {
  final ColourSelection selection;
  final List<Color> harmonies;
  final bool showsGradientToggle;
  final bool canSavePalette;
  final Future<void> Function() onOpenColorWheel;
  final Future<void> Function() onChoosePalette;
  final ValueChanged<bool> onUseGradientChanged;
  final ValueChanged<Color> onSelectHarmony;
  final Future<void> Function() onSaveCurrentAsPalette;

  const _ColourTabContent({
    required this.selection,
    required this.harmonies,
    required this.showsGradientToggle,
    required this.canSavePalette,
    required this.onOpenColorWheel,
    required this.onChoosePalette,
    required this.onUseGradientChanged,
    required this.onSelectHarmony,
    required this.onSaveCurrentAsPalette,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewCard(selection: selection),
          const SizedBox(height: _DialogUi.sectionGap),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onOpenColorWheel,
                  child: const Text('Open Color Wheel'),
                ),
              ),
              const SizedBox(width: _DialogUi.inlineGap),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onChoosePalette,
                  child: const Text('Choose Palette'),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DialogUi.mediumGap),
          if (showsGradientToggle)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use Gradient in result'),
              value: selection.useGradient,
              onChanged: onUseGradientChanged,
            ),
          const SizedBox(height: _DialogUi.inlineGap),
          Text(
            'Color Theory Suggestions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          Wrap(
            spacing: _DialogUi.inlineGap,
            runSpacing: _DialogUi.inlineGap,
            children: harmonies
                .map(
                  (c) => InkWell(
                    onTap: () => onSelectHarmony(c),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (canSavePalette) ...[
            const SizedBox(height: _DialogUi.sectionGap),
            FilledButton.tonal(
              onPressed: onSaveCurrentAsPalette,
              child: const Text('Save Current As Palette'),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientTabContent extends StatelessWidget {
  final GradientConfig gradient;
  final List<Color> gradientColors;
  final Widget animatedGradientControls;
  final bool canSaveGradient;
  final VoidCallback onPickStartColor;
  final VoidCallback onPickEndColor;
  final VoidCallback onSwapStops;
  final ValueChanged<GradientType> onGradientTypeChanged;
  final ValueChanged<GradientConfig> onGradientPresetSelected;
  final bool Function(GradientConfig) isPresetSelected;
  final String Function(GradientType) gradientTypeLabelBuilder;
  final Future<void> Function() onSaveCurrentGradient;

  const _GradientTabContent({
    required this.gradient,
    required this.gradientColors,
    required this.animatedGradientControls,
    required this.canSaveGradient,
    required this.onPickStartColor,
    required this.onPickEndColor,
    required this.onSwapStops,
    required this.onGradientTypeChanged,
    required this.onGradientPresetSelected,
    required this.isPresetSelected,
    required this.gradientTypeLabelBuilder,
    required this.onSaveCurrentGradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradientPreviewCard(
            gradient: gradient,
            stopCount: gradientColors.length,
            borderColor: theme.dividerColor,
          ),
          const SizedBox(height: _DialogUi.sectionGap),
          Text(
            'Gradient Mode',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          Row(
            children: GradientType.values
                .map(
                  (type) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: _DialogUi.inlineGap,
                      ),
                      child: _AnimatedTypeChip(
                        label: gradientTypeLabelBuilder(type),
                        selected: gradient.type == type,
                        colorScheme: theme.colorScheme,
                        onTap: () => onGradientTypeChanged(type),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: _DialogUi.mediumGap),
          Text(
            'Stops',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickStartColor,
                  icon: _StopDot(color: gradientColors[0]),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: _DialogUi.inlineGap),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickEndColor,
                  icon: _StopDot(color: gradientColors[1]),
                  label: const Text('End'),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          OutlinedButton.icon(
            onPressed: onSwapStops,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Swap Stops'),
          ),
          const SizedBox(height: _DialogUi.mediumGap),
          AnimatedSwitcher(
            duration: _DialogUi.durationMedium,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: animatedGradientControls,
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          Text(
            'Presets',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _DialogUi.inlineGap),
          Wrap(
            spacing: _DialogUi.inlineGap,
            runSpacing: _DialogUi.inlineGap,
            children: List.generate(
              ColourPresets.gradients.length.clamp(0, 8),
              (index) {
                final preset = ColourPresets.gradients[index];
                return _AnimatedPresetSwatch(
                  gradient: preset,
                  selected: isPresetSelected(preset),
                  colorScheme: theme.colorScheme,
                  onTap: () => onGradientPresetSelected(preset),
                );
              },
            ),
          ),
          if (canSaveGradient) ...[
            const SizedBox(height: _DialogUi.inlineGap),
            FilledButton.tonalIcon(
              onPressed: onSaveCurrentGradient,
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text('Save Gradient Preset'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ColourSelection selection;

  const _PreviewCard({required this.selection});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: selection.useGradient ? null : selection.color,
        gradient: selection.useGradient
            ? selection.gradient.toGradient()
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      alignment: Alignment.center,
      child: Text(
        selection.useGradient ? 'Gradient Preview' : 'Color Preview',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StopDot extends StatelessWidget {
  final Color color;

  const _StopDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}

class _AnimatedTypeChip extends StatefulWidget {
  const _AnimatedTypeChip({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  State<_AnimatedTypeChip> createState() => _AnimatedTypeChipState();
}

class _AnimatedTypeChipState extends State<_AnimatedTypeChip> {
  bool _focused = false;
  int _pulseVersion = 0;

  void _handleTap() {
    setState(() => _pulseVersion++);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBg = widget.colorScheme.primary.withValues(alpha: 0.16);
    final selectedBorder = widget.colorScheme.primary.withValues(alpha: 0.45);

    return AnimatedScale(
      scale: widget.selected ? 1.0 : 0.98,
      duration: _DialogUi.durationChipScale,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: _DialogUi.durationFast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.selected
              ? selectedBg
              : widget.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.28,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused
                ? widget.colorScheme.primary.withValues(alpha: 0.85)
                : widget.selected
                ? selectedBorder
                : widget.colorScheme.outline.withValues(alpha: 0.22),
            width: _focused ? 2 : 1,
          ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: widget.colorScheme.primary.withValues(alpha: 0.24),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: FocusableActionDetector(
            onShowFocusHighlight: (focused) {
              if (focused != _focused) setState(() => _focused = focused);
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _handleTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(_pulseVersion),
                      tween: Tween(begin: 0, end: 1),
                      duration: _DialogUi.durationSlow,
                      builder: (context, value, _) {
                        final opacity = (1 - value) * 0.30;
                        return IgnorePointer(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: 0.35 + (value * 1.5),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: widget.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: _DialogUi.durationChipText,
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(
                              color: widget.selected
                                  ? widget.colorScheme.primary
                                  : widget.colorScheme.onSurfaceVariant,
                              fontWeight: widget.selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                        child: Text(widget.label),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedPresetSwatch extends StatefulWidget {
  const _AnimatedPresetSwatch({
    required this.gradient,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final GradientConfig gradient;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  State<_AnimatedPresetSwatch> createState() => _AnimatedPresetSwatchState();
}

class _AnimatedPresetSwatchState extends State<_AnimatedPresetSwatch> {
  bool _focused = false;
  int _pulseVersion = 0;

  void _handleTap() {
    setState(() => _pulseVersion++);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.selected ? 1.04 : 1.0,
      duration: _DialogUi.durationChipText,
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: _DialogUi.durationFast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: widget.colorScheme.primary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: FocusableActionDetector(
            onShowFocusHighlight: (focused) {
              if (focused != _focused) setState(() => _focused = focused);
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _handleTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(_pulseVersion),
                      tween: Tween(begin: 0, end: 1),
                      duration: _DialogUi.durationSlow,
                      builder: (context, value, _) {
                        final opacity = (1 - value) * 0.26;
                        return IgnorePointer(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: 0.25 + (value * 1.7),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: widget.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: widget.gradient.toGradient(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _focused
                            ? widget.colorScheme.primary
                            : widget.selected
                            ? widget.colorScheme.primary.withValues(alpha: 0.70)
                            : Colors.black26,
                        width: _focused ? 2 : (widget.selected ? 2 : 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
