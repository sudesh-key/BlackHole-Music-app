/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// The Drift shim replaced Hive while keeping Hive's synchronous Box surface.
// These tests pin the behaviour the rest of the app (and backup/restore)
// depends on: key encoding, case-insensitive box names and export/import.

import 'package:blackhole/Services/db/app_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

void main() {
  setUpAll(bootTestEnv);

  group('AppBox', () {
    test('stores and reads back string and int keys', () async {
      final Box box = await AppDb.openBox('kv_types');

      await box.put('name', 'BlackHole');
      await box.put(7, {'nested': true});

      expect(box.get('name'), 'BlackHole');
      expect(box.get(7), {'nested': true});
      expect(box.get('missing', defaultValue: 'fallback'), 'fallback');
      expect(box.containsKey('name'), isTrue);
      expect(box.containsKey(7), isTrue);
      expect(box.length, 2);
    });

    test('normalises values that JSON cannot hold', () async {
      final Box box = await AppDb.openBox('kv_normalise');

      await box.put('date', DateTime.utc(2026, 7, 25));
      await box.put('mixedKeys', {1: 'one', 'two': 2});

      expect(box.get('date'), isA<String>());
      expect((box.get('mixedKeys') as Map).keys, everyElement(isA<String>()));
    });

    test('delete, deleteAll and clear', () async {
      final Box box = await AppDb.openBox('kv_delete');
      await box.putAll({'a': 1, 'b': 2, 'c': 3});

      await box.delete('a');
      expect(box.containsKey('a'), isFalse);

      await box.deleteAll(['b', 'c']);
      expect(box.isEmpty, isTrue);

      await box.putAll({'x': 1});
      await box.clear();
      expect(box.isEmpty, isTrue);
    });

    test('box names are case insensitive, matching Hive', () async {
      final Box upper = await AppDb.openBox('Favorite Songs');
      await upper.put('song1', {'id': 'song1'});

      final Box lower = await AppDb.openBox('favorite songs');
      expect(lower.get('song1'), {'id': 'song1'});
      expect(identical(upper, lower), isTrue);
    });

    test('exportData encodes key types so a backup round trips', () async {
      final Box source = await AppDb.openBox('kv_export');
      await source.putAll({'stringKey': 'v1', 42: 'v2'});

      final Map<String, dynamic> exported = source.exportData();
      expect(exported.keys, containsAll(['s:stringKey', 'i:42']));

      final Box target = await AppDb.openBox('kv_export_target');
      await target.importData(exported, encodedKeys: true);

      expect(target.get('stringKey'), 'v1');
      expect(target.get(42), 'v2');
    });

    test('importData accepts a raw legacy Hive map', () async {
      final Box box = await AppDb.openBox('kv_legacy');

      // What `hive.Box.toMap()` hands back: plain, unprefixed keys.
      await box.importData({'Favorite': {'id': 'x'}, 3: 'third'});

      expect(box.get('Favorite'), {'id': 'x'});
      expect(box.get(3), 'third');
    });

    test('boxExists reflects registration', () async {
      expect(await AppDb.boxExists('never_created_box'), isFalse);
      await AppDb.openBox('created_box');
      expect(await AppDb.boxExists('created_box'), isTrue);
    });

    test('listenable fires when the box changes', () async {
      final Box box = await AppDb.openBox('kv_listen');
      int notifications = 0;
      box.listenable().addListener(() => notifications++);

      await box.put('k', 'v');
      await box.delete('k');

      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('writes notify listeners off the caller stack, never inline',
        () async {
      // Screens call put() from initState (addSongsCount does). Hive notified
      // after its async disk write, so listeners were never marked dirty from
      // inside a build; notifying inline throws "setState() called during
      // build" for every mounted ValueListenableBuilder on the box.
      final Box box = await AppDb.openBox('kv_notify_timing');
      bool notified = false;
      box.listenable().addListener(() => notified = true);

      final Future<void> write = box.put('playlistDetails', {'Liked': 4});
      expect(notified, isFalse,
          reason: 'listeners were notified inside the caller stack');
      // The cache is still updated synchronously, so readers see it at once.
      expect(box.get('playlistDetails'), {'Liked': 4});

      await write;
      expect(notified, isTrue, reason: 'the notification never arrived');
    });

    test('delete and clear notify off the caller stack too', () async {
      final Box box = await AppDb.openBox('kv_notify_timing_2');
      await box.putAll({'a': 1, 'b': 2});

      bool notified = false;
      box.listenable().addListener(() => notified = true);

      final Future<void> removal = box.delete('a');
      expect(notified, isFalse);
      await removal;
      expect(notified, isTrue);

      notified = false;
      final Future<void> wipe = box.clear();
      expect(notified, isFalse);
      await wipe;
      expect(notified, isTrue);
    });

    test('data survives a reopen of the same box', () async {
      final Box box = await AppDb.openBox('kv_persist');
      await box.put('persisted', [1, 2, 3]);

      // Forces a fresh read through the database rather than the cache.
      final rows = await AppDb.database.entriesForBox('kv_persist');
      expect(rows, isNotEmpty);
      expect(rows.first.key, 's:persisted');
    });
  });
}
