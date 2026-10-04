import 'dart:math';

import 'package:flutter/material.dart';

import '../models/colour_palette.dart';
import '../models/named_gradient.dart';

/// The colours the picker offers besides the ones it works out itself:
/// colours used lately, and palettes and gradients someone saved.
///
/// The picker reads it and changes it; where it is kept is up to whoever
/// made it. Recent colours and saved collections change apart —
/// [recentsChanged] and [collectionsChanged] — so they can be kept apart:
/// recents for one user, say, and palettes with a project.
class ColourLibrary extends ChangeNotifier {
  ColourLibrary({
    Iterable<Color> recentColours = const [],
    Iterable<ColourPalette> palettes = const [],
    Iterable<NamedGradient> gradients = const [],
    this.recentLimit = 24,
    this.canSaveCollections = true,
    String? selectedPaletteId,
  }) : _recent = [...recentColours.take(recentLimit)],
       _palettes = [...palettes],
       _gradients = [...gradients],
       _selectedPaletteId = selectedPaletteId;

  /// One library for the whole run of the app, kept nowhere: what the
  /// picker uses when it is given none, so recent colours still carry from
  /// one opening to the next.
  static final ColourLibrary session = ColourLibrary(
    canSaveCollections: false,
  );

  /// How many recent colours are kept.
  final int recentLimit;

  /// Whether palettes and gradients can be saved and changed. Off for a
  /// library that has nowhere to keep them.
  final bool canSaveCollections;

  final List<Color> _recent;
  final List<ColourPalette> _palettes;
  final List<NamedGradient> _gradients;
  String? _selectedPaletteId;

  // Counters, bumped on each change: a ChangeNotifier's own notify is
  // protected.
  final ValueNotifier<int> _recentsChanged = ValueNotifier(0);
  final ValueNotifier<int> _collectionsChanged = ValueNotifier(0);

  /// Fires when [recentColours] or [selectedPaletteId] change.
  Listenable get recentsChanged => _recentsChanged;

  /// Fires when [palettes] or [gradients] change.
  Listenable get collectionsChanged => _collectionsChanged;

  /// Newest first.
  List<Color> get recentColours => List.unmodifiable(_recent);
  List<ColourPalette> get palettes => List.unmodifiable(_palettes);
  List<NamedGradient> get gradients => List.unmodifiable(_gradients);

  /// The palette the picker showed last.
  String? get selectedPaletteId => _selectedPaletteId;
  set selectedPaletteId(String? id) {
    if (id == _selectedPaletteId) return;
    _selectedPaletteId = id;
    _recentChanged();
  }

  /// Puts [colours] at the front of the recent colours, once each.
  void addRecentColours(Iterable<Color> colours) {
    final incoming = <int>{};
    final front = <Color>[];
    for (final c in colours) {
      if (incoming.add(c.toARGB32())) front.add(c);
    }
    if (front.isEmpty) return;
    _recent.removeWhere((c) => incoming.contains(c.toARGB32()));
    _recent.insertAll(0, front);
    if (_recent.length > recentLimit) {
      _recent.removeRange(recentLimit, _recent.length);
    }
    _recentChanged();
  }

  void removeRecentColour(Color colour) {
    final before = _recent.length;
    _recent.removeWhere((c) => c.toARGB32() == colour.toARGB32());
    if (_recent.length != before) _recentChanged();
  }

  void clearRecentColours() {
    if (_recent.isEmpty) return;
    _recent.clear();
    _recentChanged();
  }

  /// Adds [palette], or replaces the one with its id. A palette without an
  /// id gets one. Returns the palette as kept.
  ColourPalette savePalette(ColourPalette palette) {
    final kept = palette.id.isEmpty
        ? palette.copyWith(id: newId('palette'))
        : palette;
    final at = _palettes.indexWhere((p) => p.id == kept.id);
    if (at >= 0) {
      _palettes[at] = kept;
    } else {
      _palettes.add(kept);
    }
    _collectionChanged();
    return kept;
  }

  void deletePalette(String id) {
    final before = _palettes.length;
    _palettes.removeWhere((p) => p.id == id);
    if (_palettes.length == before) return;
    if (_selectedPaletteId == id) _selectedPaletteId = null;
    _collectionChanged();
  }

  /// Adds [gradient], or replaces the one with its id. Returns it as kept.
  NamedGradient saveGradient(NamedGradient gradient) {
    final kept = gradient.id.isEmpty
        ? gradient.copyWith(id: newId('gradient'))
        : gradient;
    final at = _gradients.indexWhere((g) => g.id == kept.id);
    if (at >= 0) {
      _gradients[at] = kept;
    } else {
      _gradients.add(kept);
    }
    _collectionChanged();
    return kept;
  }

  void deleteGradient(String id) {
    final before = _gradients.length;
    _gradients.removeWhere((g) => g.id == id);
    if (_gradients.length != before) _collectionChanged();
  }

  /// A name not yet used by a palette, from [base]: "Palette 2" and on.
  String unusedPaletteName([String base = 'Palette']) =>
      _unusedName(base, _palettes.map((p) => p.name));

  /// A name not yet used by a gradient, from [base].
  String unusedGradientName([String base = 'Gradient']) =>
      _unusedName(base, _gradients.map((g) => g.name));

  /// Palettes and gradients, for saving.
  Map<String, dynamic> collectionsToJson() => {
    'version': 1,
    'palettes': [for (final p in _palettes) p.toJson()],
    'gradients': [for (final g in _gradients) g.toJson()],
  };

  /// Replaces the palettes and gradients with [json] from
  /// [collectionsToJson]. Does not count as a change to save.
  void loadCollections(Map<String, dynamic> json) {
    _palettes
      ..clear()
      ..addAll(
        (json['palettes'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ColourPalette.fromJson),
      );
    _gradients
      ..clear()
      ..addAll(
        (json['gradients'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NamedGradient.fromJson),
      );
    notifyListeners();
  }

  /// Recent colours and the last palette, for saving.
  Map<String, dynamic> recentsToJson() => {
    'version': 1,
    'colours': [for (final c in _recent) c.toARGB32()],
    'palette': _selectedPaletteId,
  };

  /// Replaces the recent colours with [json] from [recentsToJson]. Does not
  /// count as a change to save.
  void loadRecents(Map<String, dynamic> json) {
    _recent
      ..clear()
      ..addAll(
        (json['colours'] as List<dynamic>? ?? const [])
            .whereType<num>()
            .take(recentLimit)
            .map((v) => Color(v.toInt())),
      );
    _selectedPaletteId = json['palette'] as String?;
    notifyListeners();
  }

  void _recentChanged() {
    notifyListeners();
    _recentsChanged.value++;
  }

  void _collectionChanged() {
    notifyListeners();
    _collectionsChanged.value++;
  }

  @override
  void dispose() {
    _recentsChanged.dispose();
    _collectionsChanged.dispose();
    super.dispose();
  }

  /// A fresh id with [prefix].
  static String newId(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${micros.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}';
  }

  static final Random _random = Random();

  static String _unusedName(String base, Iterable<String> taken) {
    final names = taken.toSet();
    for (var i = 1; ; i++) {
      final name = '$base $i';
      if (!names.contains(name)) return name;
    }
  }
}
