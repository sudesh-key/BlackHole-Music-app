/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Home page shelves carry "mini objects": songs with an id and little else,
// whose details are fetched separately. A lookup that fails used to leave an
// empty map in the shelf, which draws as a titleless placeholder card, and
// cached that blank under the key "null".

import 'package:blackhole/Helpers/format.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

void main() {
  setUpAll(bootTestEnv);

  group('formatSongsInList', () {
    test('drops a mini object whose details cannot be fetched', () async {
      final Box cache = await AppDb.openBox('cache');
      await cache.delete('null');

      final List shelf = [
        {'id': 'not-a-real-song-id', 'type': 'song', 'mini_obj': true},
      ];

      final List result = await FormatResponse.formatSongsInList(shelf);

      expect(result, isEmpty, reason: 'a blank was left in the shelf');
      expect(cache.containsKey('null'), isFalse,
          reason: 'a failed lookup was cached under the key "null"');
    });

    test('leaves a song that is not a mini object alone', () async {
      final List shelf = [
        {'id': 'abc', 'type': 'album', 'title': 'An album', 'image': 'x'},
      ];

      final List result = await FormatResponse.formatSongsInList(shelf);

      expect(result, hasLength(1));
      expect(result.first['title'], 'An album');
    });
  });
}
