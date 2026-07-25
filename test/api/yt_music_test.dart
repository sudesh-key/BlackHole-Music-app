/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Live checks against YouTube Music's InnerTube endpoints. These parsers break
// whenever YouTube reshapes a renderer, so the assertions deliberately reach
// into the fields the UI actually reads.

import 'package:blackhole/Services/yt_music.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

void main() {
  late YtMusicService ytm;

  setUpAll(() async {
    await bootTestEnv();
    ytm = YtMusicService();
    await ytm.init();
  });

  group('YouTube Music', () {
    test('init obtains a visitor id and context', () async {
      expect(ytm.headers, isNotNull);
      expect(ytm.context, isNotNull);
      expect(ytm.headers!['X-Goog-Visitor-Id'], isNotNull);
    });

    test('unfiltered search returns grouped sections', () async {
      final List<Map> results = await ytm.search('arijit singh');

      expect(results, isNotEmpty, reason: 'search returned no sections');
      for (final Map section in results) {
        expect(section['title'], isNotNull);
        expect(section['items'], isA<List>());
        expect(section['items'] as List, isNotEmpty,
            reason: 'section "${section['title']}" is empty');
      }
    });

    // search.dart opens a tile using its 'id' and branches on its 'type', so a
    // null id or a mislabelled type makes the row unopenable.
    // YouTube omits the leading "Video • " on rows returned by the videos
    // filter and gives them no browse page type, so they land on the song
    // path. Both are played the same way and carry the same kind of id, so
    // that row is allowed either label.
    const Map<String, List<String>> expectedType = {
      'songs': ['song'],
      'videos': ['video', 'song'],
      'albums': ['album', 'single'],
      'playlists': ['playlist'],
      'artists': ['artist'],
    };

    for (final MapEntry<String, List<String>> entry in expectedType.entries) {
      test('search filtered by ${entry.key} yields openable rows', () async {
        final List<Map> results =
            await ytm.search('arijit singh', filter: entry.key);

        expect(results, isNotEmpty,
            reason: 'no results for filter "${entry.key}"');
        final List items = results.first['items'] as List;
        expect(items, isNotEmpty);

        final Map first = items.first as Map;
        expect(first['id'], isNotNull,
            reason: '${entry.key} row has no id, it cannot be opened');
        expect(first['id'].toString(), isNot('null'));
        expect(first['id'].toString(), isNotEmpty);
        expect(
          entry.value,
          contains(first['type'].toString().toLowerCase()),
          reason: '${entry.key} row was typed as "${first['type']}"',
        );
        expect(first['title'].toString(), isNotEmpty);
        expect(first['image'].toString(), startsWith('http'));
      });
    }

    test('searchSongs maps onto SongItem', () async {
      final songs = await ytm.searchSongs('kesariya');

      expect(songs, isNotEmpty);
      final song = songs.first;
      expect(song.id, isNotEmpty);
      expect(song.title, isNotEmpty);
      expect(song.artists, isNotEmpty);
      expect(song.image, startsWith('http'));
      expect(song.duration.inSeconds, greaterThan(0));
    });

    test('search suggestions come back for a partial query', () async {
      final List<String> suggestions =
          await ytm.getSearchSuggestions(query: 'kesar');

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.trim(), isNotEmpty);
    });

    test('playlist details carry a header and songs', () async {
      final List<Map> found =
          await ytm.search('bollywood hits', filter: 'playlists');
      final String id = (found.first['items'] as List).first['id'].toString();

      final Map details = await ytm.getPlaylistDetails(id);

      // youtube_playlist.dart reads 'name' and takes `images.last`.
      expect(details['name'].toString(), isNotEmpty,
          reason: 'playlist $id has no name');
      expect(details['images'] as List, isNotEmpty,
          reason: 'playlist $id has no header art');
      expect((details['images'] as List).last.toString(), startsWith('http'));
      expect(details['songs'], isA<List>());
      expect(details['songs'] as List, isNotEmpty,
          reason: 'playlist $id parsed to zero songs');
      expect(
        (details['songs'] as List).first['id'].toString(),
        isNotEmpty,
      );
    });

    test('album details carry a header and songs', () async {
      final List<Map> found = await ytm.search('brahmastra', filter: 'albums');
      final String id = (found.first['items'] as List).first['id'].toString();

      final Map details = await ytm.getAlbumDetails(id);

      expect(details['name'].toString(), isNotEmpty,
          reason: 'album $id has no name');
      expect(details['images'] as List, isNotEmpty,
          reason: 'album $id has no header art');
      expect(details['songs'] as List, isNotEmpty,
          reason: 'album $id parsed to zero songs');
    });

    test('artist details carry sections', () async {
      final List<Map> found =
          await ytm.search('arijit singh', filter: 'artists');
      final String id = (found.first['items'] as List).first['id'].toString();

      final Map<String, dynamic> details = await ytm.getArtistDetails(id);

      expect(details['name'].toString(), isNotEmpty);
      expect(details['songs'], isA<List>());
      expect(details['songs'] as List, isNotEmpty,
          reason: 'artist $id has no songs');
    });

    test('song data resolves a playable url', () async {
      final songs = await ytm.searchSongs('kesariya');
      final Map data = await ytm.getSongData(videoId: songs.first.id);

      expect(data['id'].toString(), songs.first.id);
      expect(data['url'], isNotNull, reason: 'no stream url resolved');
      expect(data['url'].toString(), startsWith('http'));
      expect(data['duration'], isNotNull);
    });

    test('watch playlist yields related video ids for autoplay', () async {
      final songs = await ytm.searchSongs('kesariya');
      final List<String> related =
          await ytm.getWatchPlaylist(videoId: songs.first.id, limit: 5);

      expect(related, isNotEmpty, reason: 'autoplay would stall here');
      expect(related.first, isNotEmpty);
    });
  }, skip: skipLive);
}
