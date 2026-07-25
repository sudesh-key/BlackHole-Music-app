/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Drift-backed replacement for Hive.
//
// Design notes:
// * The app was written against Hive's synchronous Box API (346 call sites,
//   many inside build methods). To keep that surface, every box keeps its
//   full contents in an in-memory cache (exactly what Hive did): reads are
//   synchronous from the cache, writes update the cache immediately and are
//   persisted to SQLite asynchronously.
// * Box names are case-insensitive, matching Hive's behaviour
//   ('Favorite Songs' == 'favorite songs').
// * Keys can be String or int (encoded with an 's:'/'i:' prefix), values are
//   JSON-normalized (Map/List/String/num/bool/null).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blackhole/Services/db/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Drop-in alias so existing `Box` type annotations keep working.
typedef Box = AppBox;

class AppDb {
  AppDb._();

  static AppDatabase? _db;
  static final Map<String, AppBox> _boxes = {};
  static String? _basePath;
  static String? _subDir;

  static AppDatabase get database {
    final AppDatabase? db = _db;
    if (db == null) {
      throw StateError('AppDb.init() must be called before accessing the DB');
    }
    return db;
  }

  /// [basePath] overrides the documents directory (used from background
  /// isolates where path_provider is unavailable). [subDir] mirrors the old
  /// `Hive.initFlutter(subDir)` directory layout so the database lives next
  /// to the legacy .hive files.
  static Future<void> init({String? basePath, String? subDir}) async {
    if (_db != null) return;
    _basePath = basePath;
    _subDir = subDir;
    _db = AppDatabase.open(databasePath: databasePath);
  }

  static Future<String> databasePath() async {
    final String docs =
        _basePath ?? (await getApplicationDocumentsDirectory()).path;
    final String dir = _subDir == null ? docs : '$docs/$_subDir';
    await Directory(dir).create(recursive: true);
    return '$dir/blackhole.sqlite';
  }

  /// Directory holding the database (and, historically, the Hive boxes).
  static Future<String> storageDir() async {
    return File(await databasePath()).parent.path;
  }

  static String _canonical(String name) => name.toLowerCase();

  static bool isBoxOpen(String name) => _boxes.containsKey(_canonical(name));

  /// Synchronous access, mirroring `Hive.box`. Unlike Hive this does not
  /// throw when the box was never opened: it returns an empty box and loads
  /// its contents in the background (listeners fire once data arrives).
  static AppBox box(String name) {
    final String canonical = _canonical(name);
    final AppBox? existing = _boxes[canonical];
    if (existing != null) return existing;
    Logger.root
        .warning('Box "$name" accessed before being opened; lazy-loading');
    final AppBox lazy = AppBox._(canonical);
    _boxes[canonical] = lazy;
    unawaited(lazy._load());
    unawaited(database.registerBox(canonical));
    return lazy;
  }

  static Future<AppBox> openBox(String name) async {
    final String canonical = _canonical(name);
    final AppBox? existing = _boxes[canonical];
    if (existing != null) {
      await existing._load();
      return existing;
    }
    final AppBox box = AppBox._(canonical);
    _boxes[canonical] = box;
    await box._load();
    await database.registerBox(canonical);
    return box;
  }

  static Future<bool> boxExists(String name) async {
    final String canonical = _canonical(name);
    if (_boxes.containsKey(canonical)) return true;
    return database.containsBox(canonical);
  }

  static void removeFromRegistry(String name) {
    _boxes.remove(_canonical(name));
  }
}

class AppBox {
  AppBox._(this.name);

  /// Canonical (lowercase) box name.
  final String name;

  final Map<dynamic, dynamic> _cache = {};
  late final _BoxListenable _listenable = _BoxListenable(this);
  Future<void>? _loadFuture;

  Future<void> _load() => _loadFuture ??= _doLoad();

  Future<void> _doLoad() async {
    try {
      final rows = await AppDb.database.entriesForBox(name);
      for (final row in rows) {
        _cache[_decodeKey(row.key)] = jsonDecode(row.value);
      }
      if (rows.isNotEmpty) _listenable._notify();
    } catch (e, st) {
      Logger.root.severe('Failed to load box $name', e, st);
    }
  }

  static String _encodeKey(dynamic key) => key is int ? 'i:$key' : 's:$key';

  static dynamic _decodeKey(String key) => key.startsWith('i:')
      ? (int.tryParse(key.substring(2)) ?? key.substring(2))
      : key.substring(2);

  /// Makes any Hive-era value JSON-representable (string keys, no DateTime).
  static dynamic _jsonSafe(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map) {
      return value
          .map((key, val) => MapEntry(key.toString(), _jsonSafe(val)));
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }
    return value.toString();
  }

  // ─── Reads (synchronous, from cache) ──────────────────────────────────

  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _cache.containsKey(key) ? _cache[key] : defaultValue;

  bool containsKey(dynamic key) => _cache.containsKey(key);

  Iterable<dynamic> get keys => _cache.keys;

  Iterable<dynamic> get values => _cache.values;

  Map<dynamic, dynamic> toMap() => Map<dynamic, dynamic>.of(_cache);

  int get length => _cache.length;

  bool get isEmpty => _cache.isEmpty;

  bool get isNotEmpty => _cache.isNotEmpty;

  // ─── Writes (cache-first, persisted asynchronously) ───────────────────

  Future<void> put(dynamic key, dynamic value) async {
    final dynamic normalized = _jsonSafe(value);
    _cache[key] = normalized;
    _listenable._notify();
    try {
      await AppDb.database
          .putEntry(name, _encodeKey(key), jsonEncode(normalized));
    } catch (e, st) {
      Logger.root.severe('Failed to persist $name/$key', e, st);
    }
  }

  Future<void> putAll(Map<dynamic, dynamic> entries) async {
    final Map<String, String> encoded = {};
    entries.forEach((key, value) {
      final dynamic normalized = _jsonSafe(value);
      _cache[key] = normalized;
      encoded[_encodeKey(key)] = jsonEncode(normalized);
    });
    _listenable._notify();
    try {
      await AppDb.database.putEntries(name, encoded);
    } catch (e, st) {
      Logger.root.severe('Failed to persist batch into $name', e, st);
    }
  }

  Future<void> delete(dynamic key) async {
    _cache.remove(key);
    _listenable._notify();
    try {
      await AppDb.database.deleteEntry(name, _encodeKey(key));
    } catch (e, st) {
      Logger.root.severe('Failed to delete $name/$key', e, st);
    }
  }

  Future<void> deleteAll(Iterable<dynamic> keysToDelete) async {
    for (final key in List.of(keysToDelete)) {
      await delete(key);
    }
  }

  Future<void> clear() async {
    _cache.clear();
    _listenable._notify();
    await AppDb.database.clearBox(name);
  }

  Future<void> deleteFromDisk() async {
    _cache.clear();
    _listenable._notify();
    await AppDb.database.unregisterBox(name);
    AppDb.removeFromRegistry(name);
  }

  Future<void> close() async {
    // Writes are persisted eagerly; nothing to flush.
  }

  Future<void> flush() async {}

  // ─── Listeners (Hive's box.listenable() replacement) ──────────────────

  ValueListenable<AppBox> listenable({List<dynamic>? keys}) => _listenable;

  // ─── Backup / migration helpers ───────────────────────────────────────

  /// Serializable snapshot ({encodedKey: value}).
  Map<String, dynamic> exportData() => _cache.map(
        (key, value) => MapEntry(_encodeKey(key), value),
      );

  /// Restores a snapshot produced by [exportData] (encoded keys) or a raw
  /// legacy Hive `box.toMap()` (plain keys).
  Future<void> importData(
    Map<dynamic, dynamic> data, {
    bool encodedKeys = false,
  }) async {
    final Map<dynamic, dynamic> decoded = encodedKeys
        ? data.map((key, value) => MapEntry(_decodeKey(key.toString()), value))
        : data;
    await putAll(decoded);
  }
}

class _BoxListenable extends ChangeNotifier
    implements ValueListenable<AppBox> {
  _BoxListenable(this._box);

  final AppBox _box;

  @override
  AppBox get value => _box;

  void _notify() => notifyListeners();
}
