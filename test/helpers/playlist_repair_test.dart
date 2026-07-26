/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Playlists written by older versions hold raw JioSaavn API responses rather
// than formatted songs, which is why they render as "Unknown" with a null
// artist and cannot play. The fixture below is a real record taken from such
// a playlist, trimmed to the fields the formatter reads.

import 'package:blackhole/Helpers/playlist.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

Map<String, dynamic> rawSaavnSong() => {
      'id': '0FtPxWaM',
      'title': 'Vaadaldi Varsi Re',
      'subtitle': 'Aditya Gadhvi, Aishwarya Majmudar - Vaadaldi Varsi Re',
      'type': 'song',
      'image':
          'https://c.saavncdn.com/638/Vaadaldi-Varsi-Re-Gujarati-2017-150x150.jpg',
      'language': 'gujarati',
      'year': '2017',
      'perma_url': 'https://www.jiosaavn.com/song/vaadaldi-varsi-re/QC4fYQxnVn4',
      'more_info': {
        'album': 'Vaadaldi Varsi Re',
        'album_id': '11295088',
        'duration': '195',
        'has_lyrics': 'false',
        'lyrics_snippet': '',
        'release_date': '2017-08-04',
        'music': 'Parth Bharat Thakkar',
        'encrypted_media_url':
            'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDybXt4vQEAHshzvXsUA3KwPb460HlAGLEFb/DoVoYVF8hYp36f4RWIpBw7tS9a8Gtq',
        'artistMap': {
          'primary_artists': [
            {'id': '698769', 'name': 'Aditya Gadhvi', 'role': 'primary_artists'},
            {
              'id': '502671',
              'name': 'Aishwarya Majmudar',
              'role': 'primary_artists',
            },
          ],
        },
      },
    };

void main() {
  setUpAll(bootTestEnv);

  group('repairRawPlaylistSongs', () {
    test('fills in the fields the UI reads and persists them', () async {
      const String name = 'Starred Songs Test';
      final Box box = await AppDb.openBox(name);
      final Map<String, dynamic> raw = rawSaavnSong();
      await box.put(raw['id'], raw);

      // What the screen saw before: no artist, no album, nothing playable.
      expect(box.get('0FtPxWaM')['artist'], isNull);
      expect(box.get('0FtPxWaM')['url'], isNull);

      final List repaired =
          await repairRawPlaylistSongs(name, box.values.toList());

      final Map song = repaired.firstWhere((s) => s['id'] == '0FtPxWaM') as Map;
      expect(song['artist'], 'Aditya Gadhvi, Aishwarya Majmudar');
      expect(song['title'], 'Vaadaldi Varsi Re');
      expect(song['album'], 'Vaadaldi Varsi Re');
      expect(song['genre'], 'Gujarati');
      expect(song['duration'], '195');
      expect(song['url'].toString(), startsWith('http'));
      expect(song['image'].toString(), startsWith('http'));

      // Saved, so the playlist is only repaired once.
      expect(box.get('0FtPxWaM')['artist'], 'Aditya Gadhvi, Aishwarya Majmudar');
    });

    test('keeps dateAdded so ordering survives the repair', () async {
      const String name = 'Starred Dates Test';
      final Box box = await AppDb.openBox(name);
      final Map<String, dynamic> raw = rawSaavnSong()
        ..['dateAdded'] = '2024-01-02 03:04:05.000';
      await box.put(raw['id'], raw);

      await repairRawPlaylistSongs(name, box.values.toList());

      expect(box.get('0FtPxWaM')['dateAdded'], '2024-01-02 03:04:05.000');
    });

    test('leaves already formatted songs untouched', () async {
      const String name = 'Formatted Test';
      final Box box = await AppDb.openBox(name);
      final Map<String, dynamic> formatted = {
        'id': 'abc123',
        'title': 'Mujhse Kaha Na Gaya',
        'artist': 'Palash Sen',
        'album': 'Phir Dhoom',
        'url': 'https://aac.saavncdn.com/456/example.mp4',
        'image': 'https://c.saavncdn.com/456/example.jpg',
      };
      await box.put('abc123', formatted);

      final List result =
          await repairRawPlaylistSongs(name, box.values.toList());

      expect(result.first, formatted);
    });
  });
}
