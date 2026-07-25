/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Generic key-value storage: one row per (box, key) pair. Values are
/// JSON-encoded. This mirrors the schema-less Hive model the app was built
/// on while giving us a single, transactional SQLite database via Drift.
@DataClassName('KeyValueEntry')
class KeyValueEntries extends Table {
  TextColumn get box => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {box, key};
}

/// Tracks which boxes exist (needed for `boxExists` on empty boxes).
@DataClassName('BoxRegistryEntry')
class BoxRegistry extends Table {
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

@DriftDatabase(tables: [KeyValueEntries, BoxRegistry])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.open({
    required Future<String> Function() databasePath,
  }) {
    return AppDatabase(
      driftDatabase(
        name: 'blackhole',
        native: DriftNativeOptions(
          databasePath: databasePath,
          // The yt-link refresh isolate accesses the same database; sharing
          // one drift server across isolates avoids sqlite lock contention.
          shareAcrossIsolates: true,
        ),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  Future<List<KeyValueEntry>> entriesForBox(String boxName) =>
      (select(keyValueEntries)..where((t) => t.box.equals(boxName))).get();

  Future<void> putEntry(String boxName, String key, String value) =>
      into(keyValueEntries).insertOnConflictUpdate(
        KeyValueEntriesCompanion.insert(box: boxName, key: key, value: value),
      );

  Future<void> putEntries(String boxName, Map<String, String> values) =>
      batch((b) {
        b.insertAllOnConflictUpdate(
          keyValueEntries,
          values.entries
              .map(
                (e) => KeyValueEntriesCompanion.insert(
                  box: boxName,
                  key: e.key,
                  value: e.value,
                ),
              )
              .toList(),
        );
      });

  Future<void> deleteEntry(String boxName, String key) => (delete(
        keyValueEntries,
      )..where((t) => t.box.equals(boxName) & t.key.equals(key)))
          .go();

  Future<void> clearBox(String boxName) =>
      (delete(keyValueEntries)..where((t) => t.box.equals(boxName))).go();

  Future<void> registerBox(String boxName) => into(boxRegistry)
      .insertOnConflictUpdate(BoxRegistryCompanion.insert(name: boxName));

  Future<void> unregisterBox(String boxName) async {
    await clearBox(boxName);
    await (delete(boxRegistry)..where((t) => t.name.equals(boxName))).go();
  }

  Future<bool> containsBox(String boxName) async {
    final row = await (select(boxRegistry)
          ..where((t) => t.name.equals(boxName)))
        .getSingleOrNull();
    return row != null;
  }
}
