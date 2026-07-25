/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Live checks against JioSaavn's web endpoints. They talk to the real service,
// so a failure here means the endpoint (or our parsing of it) is broken, not
// that the device is misconfigured.

import 'package:blackhole/APIs/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../test_env.dart';

void main() {
  late SaavnAPI api;

  setUpAll(() async {
    await bootTestEnv();
    api = SaavnAPI();
  });

  group('JioSaavn', () {
    test('home page data has the usual shelves', () async {
      final Map home = await api.fetchHomePageData();

      expect(home, isNotEmpty, reason: 'homepage formatted to nothing');
      expect(home['collections'], isA<List>());
      expect((home['collections'] as List), isNotEmpty);
      // The home screen renders one section per advertised collection, so
      // every one of them has to carry items.
      for (final String key in (home['collections'] as List).cast<String>()) {
        expect(home[key], isA<List>(), reason: 'collection "$key" missing');
        expect(home[key] as List, isNotEmpty, reason: 'collection "$key" empty');
      }
      expect((home['collections'] as List), contains('new_trending'));
      expect((home['collections'] as List), contains('top_playlists'));
    });

    test('top searches return titles', () async {
      final List<String> top = await api.getTopSearches();

      expect(top, isNotEmpty);
      expect(top.first.trim(), isNotEmpty);
    });

    test('song search returns playable, well formed songs', () async {
      final Map res =
          await api.fetchSongSearchResults(searchQuery: 'kesariya', count: 5);

      expect(res['error'], '');
      final List songs = res['songs'] as List;
      expect(songs, isNotEmpty);
      expect(songs.length, lessThanOrEqualTo(5));

      final Map song = songs.first as Map;
      for (final String key in ['id', 'title', 'artist', 'image', 'url']) {
        expect(song[key], isNotNull, reason: '"$key" missing from song');
        expect(song[key].toString(), isNotEmpty, reason: '"$key" is blank');
      }
      expect(song['url'].toString(), startsWith('http'));
      expect(song['image'].toString(), startsWith('http'));
    });

    test('the decrypted media url actually streams', () async {
      final Map res =
          await api.fetchSongSearchResults(searchQuery: 'tum hi ho', count: 1);
      final Map song = (res['songs'] as List).first as Map;

      final http.Response head = await http.get(
        Uri.parse(song['url'].toString()),
        // One byte is enough to prove the CDN serves us the file.
        headers: {'range': 'bytes=0-1'},
      );

      expect(
        head.statusCode,
        anyOf(200, 206),
        reason: 'stream url rejected: ${song['url']}',
      );
    });

    test('combined search groups albums, playlists and artists', () async {
      final List<Map<String, dynamic>> results =
          await api.fetchSearchResults('arijit singh');

      expect(results, isNotEmpty);
      // Each entry is a {'title': …, 'items': [...]} section, ordered by the
      // position JioSaavn assigns.
      for (final Map<String, dynamic> section in results) {
        expect(section['title'].toString(), isNotEmpty);
        expect(section['items'], isA<List>());
        expect(section['items'] as List, isNotEmpty,
            reason: 'section "${section['title']}" is empty');
      }
      expect(
        results.map((Map<String, dynamic> s) => s['title']),
        contains('Albums'),
      );
    });

    test('album search then album songs', () async {
      final List<Map> albums =
          await api.fetchAlbums(searchQuery: 'brahmastra', type: 'album');
      expect(albums, isNotEmpty);
      expect(albums.first['id'].toString(), isNotEmpty);

      final Map songs = await api.fetchAlbumSongs(albums.first['id'].toString());
      expect(songs['songs'] as List, isNotEmpty);
      expect((songs['songs'] as List).first['url'].toString(),
          startsWith('http'));
    });

    test('playlist search then playlist songs', () async {
      final List<Map> playlists =
          await api.fetchAlbums(searchQuery: 'romantic', type: 'playlist');
      expect(playlists, isNotEmpty);

      final Map songs =
          await api.fetchPlaylistSongs(playlists.first['id'].toString());
      expect(songs['error'], '');
      expect(songs['songs'] as List, isNotEmpty);
    });

    test('artist search then artist details', () async {
      final List<Map> artists =
          await api.fetchAlbums(searchQuery: 'shreya ghoshal', type: 'artist');
      expect(artists, isNotEmpty);

      // artists.dart navigates with 'artistToken', so that is what must work.
      final String token = artists.first['artistToken'].toString();
      expect(token, isNot('null'), reason: 'artist token was not parsed');

      final Map<String, List> details =
          await api.fetchArtistSongs(artistToken: token);

      expect(details, isNotEmpty);
      expect(details['Top Songs'], isNotNull);
      expect(details['Top Songs'], isNotEmpty);

      // artists.dart shares this value; it must be a real link.
      expect(artists.first['perma_url'].toString(), startsWith('http'));
    });

    test('an unknown artist token degrades instead of throwing', () async {
      // JioSaavn answers a bad token with `{}` where lists are expected; the
      // screen should get an empty map rather than an uncaught TypeError.
      final Map<String, List> details =
          await api.fetchArtistSongs(artistToken: 'not-a-real-token');

      expect(details, isEmpty);
    });

    test('song details and recommendations for a known id', () async {
      final Map res =
          await api.fetchSongSearchResults(searchQuery: 'channa mereya', count: 1);
      final String id = (res['songs'] as List).first['id'].toString();

      final Map details = await api.fetchSongDetails(id);
      expect(details['id'].toString(), id);
      expect(details['title'].toString(), isNotEmpty);

      // Autoplay tops the queue up from here; an empty list stalls it.
      final List reco = await api.getReco(id);
      expect(reco, isNotEmpty, reason: 'no recommendations for $id');
      final Map first = reco.first as Map;
      expect(first['id'].toString(), isNotEmpty);
      expect(first['url'].toString(), startsWith('http'));
    });

    test('token lookup resolves a shared playlist link', () async {
      // The token SaavnUrlHandler pulls out of a shared jiosaavn.com link.
      final List<Map> playlists =
          await api.fetchAlbums(searchQuery: 'love', type: 'playlist');
      final String permaUrl = playlists.first['perma_url'].toString();
      expect(permaUrl, startsWith('http'),
          reason: 'perma_url was not mapped, sharing would post "null"');

      final Map res =
          await api.getSongFromToken(permaUrl.split('/').last, 'playlist');
      expect(res['list'], isA<List>());
      expect(res['list'] as List, isNotEmpty);
    });

    test('radio station can be created and returns songs', () async {
      final String? stationId = await api.createRadio(
        names: ['Arijit Singh'],
        stationType: 'artist',
        language: 'hindi',
      );
      expect(stationId, isNotNull);
      expect(stationId, isNotEmpty);

      final List songs =
          await api.getRadioSongs(stationId: stationId!, count: 3);
      expect(songs, isNotEmpty);
    });
  }, skip: skipLive);
}
