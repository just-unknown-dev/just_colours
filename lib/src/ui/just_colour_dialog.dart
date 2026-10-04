import 'package:flutter/material.dart';

import '../library/colour_library.dart';
import '../models/colour_selection.dart';
import '../storage/colour_storage_repository.dart';
import 'picker/colour_picker_panel.dart';
import 'picker/eyedropper.dart';

export 'picker/colour_picker_panel.dart' show ColourDialogView;

/// The colour picker in a dialog in the middle of the screen. See
/// [ColourPopover] for one that opens beside a field.
class JustColourDialog extends StatefulWidget {
  final ColourSelection initialSelection;

  /// Keeps recent colours, palettes and gradients on this device, and the
  /// last choice. Superseded by [library]; used when that is null.
  final ColourStorageRepository? repository;
  final ColourDialogView view;
  final ColourLibrary? library;
  final ColourSampler? sampler;
  final ValueChanged<ColourSelection>? onChanged;
  final bool showTint;
  final String? title;

  const JustColourDialog({
    super.key,
    required this.initialSelection,
    this.repository,
    this.view = ColourDialogView.both,
    this.library,
    this.sampler,
    this.onChanged,
    this.showTint = false,
    this.title,
  });

  /// Opens the picker and gives back the choice; null when cancelled.
  /// Each change goes to [onChanged] as it happens.
  static Future<ColourSelection?> show(
    BuildContext context, {
    ColourSelection initialSelection = const ColourSelection(
      color: Colors.white,
    ),
    ColourStorageRepository? repository,
    ColourDialogView view = ColourDialogView.both,
    ColourLibrary? library,
    ColourSampler? sampler,
    ValueChanged<ColourSelection>? onChanged,
    bool showTint = false,
    String? title,
    PickerWrapper? builder,
  }) {
    return showDialog<ColourSelection>(
      context: context,
      builder: (context) {
        final dialog = JustColourDialog(
          initialSelection: initialSelection,
          repository: repository,
          view: view,
          library: library,
          sampler: sampler,
          onChanged: onChanged,
          showTint: showTint,
          title: title,
        );
        return builder == null ? dialog : builder(context, dialog);
      },
    );
  }

  @override
  State<JustColourDialog> createState() => _JustColourDialogState();
}

class _JustColourDialogState extends State<JustColourDialog> {
  ColourLibrary? _loaded;

  @override
  void initState() {
    super.initState();
    final repo = widget.repository;
    if (widget.library == null && repo != null) {
      repo.loadLibrary().then((lib) {
        if (mounted) setState(() => _loaded = lib);
      });
    }
  }

  Future<void> _apply(ColourSelection result) async {
    final repo = widget.repository;
    if (repo != null) {
      await repo.saveCurrentSelection(result);
      await repo.appendHistory(result);
    }
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 820),
        child: ColourPickerPanel(
          // A library loaded late starts the panel afresh with it.
          key: ValueKey(_loaded),
          initialSelection: widget.initialSelection,
          view: widget.view,
          library: widget.library ?? _loaded,
          sampler: widget.sampler,
          onChanged: widget.onChanged,
          showTint: widget.showTint,
          title: widget.title,
          onApply: _apply,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
