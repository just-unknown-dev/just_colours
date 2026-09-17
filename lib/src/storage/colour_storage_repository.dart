import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_database/just_database.dart';
import 'package:just_storage/just_storage.dart';

import '../models/colour_palette.dart';
import '../models/colour_selection.dart';
import '../models/gradient_config.dart';

class ColourStorageRepository {
  static const String _selectionKey = 'just_colours.current_selection';
  static const String _pinnedRecentColorsKey =
      'just_colours.pinned_recent_colors';
  static const String _pinnedRecentGradientsKey =
      'just_colours.pinned_recent_gradients';

  final JustStandardStorage _storage;
  final JustDatabase _database;
  final String _databaseName;

  ColourStorageRepository._({
    required JustStandardStorage storage,
    required JustDatabase database,
    required String databaseName,
  }) : _storage = storage,
       _database = database,
       _databaseName = databaseName;

  static Future<ColourStorageRepository> create({
    String databaseName = 'just_colours_db',
    DatabaseMode databaseMode = DatabaseMode.standard,
    bool persistDatabase = true,
  }) async {
    final storage = await JustStorage.standard();
    final database = await DatabaseManager.open(
      databaseName,
      mode: databaseMode,
      persist: persistDatabase,
    );

    final repo = ColourStorageRepository._(
      storage: storage,
      database: database,
      databaseName: databaseName,
    );
    await repo._ensureSchema();
    return repo;
  }

  Future<void> _ensureSchema() async {
    await _createTable(
      'CREATE TABLE colour_palettes ('
      'id TEXT PRIMARY KEY, '
      'name TEXT, '
      'description TEXT, '
      'colors_json TEXT, '
      'created_at INTEGER'
      ')',
    );

    await _createTable(
      'CREATE TABLE colour_gradients ('
      'id TEXT PRIMARY KEY, '
      'name TEXT, '
      'config_json TEXT, '
      'created_at INTEGER'
      ')',
    );

    await _createTable(
      'CREATE TABLE colour_history ('
      'id TEXT PRIMARY KEY, '
      'selection_json TEXT, '
      'created_at INTEGER'
      ')',
    );
  }

  Future<void> _createTable(String sql) async {
    final result = await _database.execute(sql);
    if (!result.success) {
      final msg = (result.errorMessage ?? '').toLowerCase();
      if (!msg.contains('exists')) {
        throw StateError('Failed creating table: ${result.errorMessage}');
      }
    }
  }

  Future<void> saveCurrentSelection(ColourSelection selection) {
    return _storage.writeJson<ColourSelection>(
      _selectionKey,
      selection,
      (value) => value.toJson(),
    );
  }

  Future<ColourSelection?> loadCurrentSelection() {
    return _storage.readJson<ColourSelection>(
      _selectionKey,
      ColourSelection.fromJson,
    );
  }

  Future<List<int>> loadPinnedRecentColors() async {
    final raw = await _storage.readJson<Map<String, dynamic>>(
      _pinnedRecentColorsKey,
      (value) => value,
    );
    return (raw?['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<num>()
        .map((v) => v.toInt())
        .toList();
  }

  Future<void> savePinnedRecentColors(List<int> colors) {
    return _storage.writeJson<Map<String, dynamic>>(_pinnedRecentColorsKey, {
      'items': colors,
    }, (value) => value);
  }

  Future<List<String>> loadPinnedRecentGradients() async {
    final raw = await _storage.readJson<Map<String, dynamic>>(
      _pinnedRecentGradientsKey,
      (value) => value,
    );
    return (raw?['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList();
  }

  Future<void> savePinnedRecentGradients(List<String> gradients) {
    return _storage.writeJson<Map<String, dynamic>>(_pinnedRecentGradientsKey, {
      'items': gradients,
    }, (value) => value);
  }

  Future<void> savePalette(ColourPalette palette) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = palette.toJson();
    final colorsJson = (payload['colors'] as List<dynamic>).join(',');
    final id = palette.id.isEmpty ? _id('palette') : palette.id;

    await _database.execute(
      "DELETE FROM colour_palettes WHERE id = '${_escape(id)}'",
    );

    await _database.execute(
      'INSERT INTO colour_palettes '
      "(id, name, description, colors_json, created_at) VALUES ('${_escape(id)}', '${_escape(palette.name)}', "
      "'${_escape(palette.description ?? '')}', '${_escape(colorsJson)}', $now)",
    );
  }

  Future<List<ColourPalette>> listPalettes() async {
    final result = await _database.query(
      'SELECT id, name, description, colors_json '
      'FROM colour_palettes ORDER BY created_at DESC',
    );
    if (!result.success) {
      return const [];
    }

    return result.rows.map((row) {
      final colors = (row['colors_json'] as String? ?? '')
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.tryParse(e) ?? 0xFFFFFFFF)
          .toList();
      return ColourPalette(
        id: row['id'] as String? ?? '',
        name: row['name'] as String? ?? 'Untitled',
        description: (row['description'] as String?)?.trim().isEmpty ?? true
            ? null
            : row['description'] as String?,
        colors: colors.map((c) => Color(c)).toList(),
      );
    }).toList();
  }

  Future<void> saveGradient(String name, GradientConfig config) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _id('gradient');
    final payload = jsonEncode(config.toJson());

    await _database.execute(
      'INSERT INTO colour_gradients '
      "(id, name, config_json, created_at) VALUES ('${_escape(id)}', '${_escape(name)}', '${_escape(payload)}', $now)",
    );
  }

  Future<List<(String, GradientConfig)>> listGradients() async {
    final result = await _database.query(
      'SELECT name, config_json FROM colour_gradients ORDER BY created_at DESC',
    );
    if (!result.success) {
      return const [];
    }

    return result.rows
        .map((row) {
          final name = row['name'] as String? ?? 'Gradient';
          final raw = row['config_json'] as String? ?? '{}';
          return (name, _parseGradient(raw));
        })
        .where((entry) => entry.$2 != null)
        .map((entry) => (entry.$1, entry.$2!))
        .toList();
  }

  Future<void> appendHistory(ColourSelection selection) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _id('history');
    final raw = jsonEncode(selection.toJson());

    await _database.execute(
      'INSERT INTO colour_history '
      "(id, selection_json, created_at) VALUES ('${_escape(id)}', '${_escape(raw)}', $now)",
    );
  }

  Future<List<ColourSelection>> listHistory({int limit = 40}) async {
    final result = await _database.query(
      'SELECT selection_json FROM colour_history '
      'ORDER BY created_at DESC LIMIT $limit',
    );
    if (!result.success) {
      return const [];
    }

    return result.rows
        .map((e) => e['selection_json'] as String? ?? '{}')
        .map(_parseSelection)
        .whereType<ColourSelection>()
        .toList();
  }

  Future<void> close() => DatabaseManager.close(_databaseName);

  static String _escape(String input) => input.replaceAll("'", "''");

  static String _id(String prefix) {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${prefix}_$micros$random';
  }

  static GradientConfig? _parseGradient(String raw) {
    final json = _decodePseudoJson(raw);
    if (json == null) return null;
    return GradientConfig.fromJson(json);
  }

  static ColourSelection? _parseSelection(String raw) {
    final json = _decodePseudoJson(raw);
    if (json == null) return null;
    return ColourSelection.fromJson(json);
  }

  static Map<String, dynamic>? _decodePseudoJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
