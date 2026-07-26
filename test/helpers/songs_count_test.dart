/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Values come back out of the database as Map<String, dynamic>, so anything
// writing into `playlistDetails` has to cope with that type. Recording a name
// for the first time used to throw, which silently aborted playlist imports.

import 'package:blackhole/Helpers/songs_count.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

void main() {
  setUpAll(bootTestEnv);

  group('addSongsCount', () {
    test('records a playlist seen for the first time', () async {
      final Box settings = await AppDb.openBox('settings');
      await settings.put('playlistDetails', {
        'Existing Playlist': {'count': 1, 'imagesList': []},
      });

      addSongsCount('Brand New Playlist', 59, [
        {'image': 'https://example.com/1.jpg'},
      ]);

      final Map details = settings.get('playlistDetails') as Map;
      expect(details['Brand New Playlist'], isNotNull);
      expect(details['Brand New Playlist']['count'], 59);
      expect(details['Brand New Playlist']['imagesList'], hasLength(1));
      // The playlist that was already there is left alone.
      expect(details['Existing Playlist']['count'], 1);
    });

    test('updates a playlist that is already recorded', () async {
      final Box settings = await AppDb.openBox('settings');
      await settings.put('playlistDetails', {
        'Starred Songs': {'count': 68, 'imagesList': []},
      });

      addSongsCount('Starred Songs', 81, []);

      final Map details = settings.get('playlistDetails') as Map;
      expect(details['Starred Songs']['count'], 81);
    });

    test('works when no playlistDetails have been stored yet', () async {
      final Box settings = await AppDb.openBox('settings');
      await settings.delete('playlistDetails');

      addSongsCount('First Playlist', 3, []);

      final Map details = settings.get('playlistDetails') as Map;
      expect(details['First Playlist']['count'], 3);
    });
  });
}
