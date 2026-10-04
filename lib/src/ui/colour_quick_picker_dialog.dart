import 'package:flutter/material.dart';

import '../library/colour_library.dart';
import '../models/colour_palette.dart';
import '../models/colour_selection.dart';
import 'just_colour_dialog.dart';

/// A dialog for one solid colour: [JustColourDialog] with gradients left
/// out, giving back a [Color].
class ColourQuickPickerDialog extends StatelessWidget {
  final Color initialColor;
  final String title;

  /// Offered besides the built-in palettes.
  final List<ColourPalette>? palettes;

  const ColourQuickPickerDialog({
    super.key,
    required this.initialColor,
    this.title = 'Pick Color',
    this.palettes,
  });

  static Future<Color?> show(
    BuildContext context, {
    required Color initialColor,
    String title = 'Pick Color',
    List<ColourPalette>? palettes,
  }) async {
    final picked = await JustColourDialog.show(
      context,
      initialSelection: ColourSelection(color: initialColor),
      view: ColourDialogView.colourOnly,
      library: _libraryFor(palettes),
      title: title,
    );
    return picked?.color;
  }

  static ColourLibrary? _libraryFor(List<ColourPalette>? palettes) {
    if (palettes == null || palettes.isEmpty) return null;
    return ColourLibrary(
      palettes: palettes,
      recentColours: ColourLibrary.session.recentColours,
      canSaveCollections: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return JustColourDialog(
      initialSelection: ColourSelection(color: initialColor),
      view: ColourDialogView.colourOnly,
      library: _libraryFor(palettes),
      title: title,
    );
  }
}
