/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Live checks against the plain YouTube surface: the scraped home feed, search,
// and stream resolution through youtube_explode_dart.

import 'package:blackhole/Services/youtube_services.dart';
import 'package:blackhole/Services/yt_music.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../test_env.dart';

void main() {
  late YouTubeServices yt;

  setUpAll(() async {
    await bootTestEnv();
    yt = YouTubeServices.instance;
  });

  group('YouTube', () {
    test('music home feed parses into head and body', () async {
      final Map<String, List> home = await yt.getMusicHome();

      expect(home['body'], isNotNull);
      expect(home['body'], isNotEmpty,
          reason: 'home feed is empty — the loader would spin forever');

      final Map firstShelf = (home['body'] as List).first as Map;
      expect(firstShelf['title'].toString(), isNotEmpty);
      expect(firstShelf['playlists'] ?? firstShelf['items'], isNotNull);
    });

    test('search returns videos with the fields the tiles read', () async {
      final List<Map> results = await yt.fetchSearchResults('kesariya');

      expect(results, isNotEmpty, reason: 'search parsed to nothing');
      final List items = results.first['items'] as List;
      expect(items, isNotEmpty);

      final Map first = items.first as Map;
      expect(first['id'].toString(), isNotEmpty);
      expect(first['title'].toString(), isNotEmpty);
      expect(first['image'].toString(), startsWith('http'));
    });

    test('search suggestions come back', () async {
      final List suggestions = await yt.getSearchSuggestions(query: 'kesar');

      expect(suggestions, isNotEmpty);
    });

    test('a video id resolves to a playable audio stream', () async {
      final List<Map> results = await yt.fetchSearchResults('kesariya');
      final String id =
          (results.first['items'] as List).first['id'].toString();

      final Map? data = await yt.formatVideoFromId(id: id);

      expect(data, isNotNull, reason: 'no stream resolved for $id');
      expect(data!['url'].toString(), startsWith('http'));
      expect(data['duration'], isNotNull);

      final http.Response probe = await http.get(
        Uri.parse(data['url'].toString()),
        headers: {'range': 'bytes=0-1'},
      );
      expect(
        probe.statusCode,
        anyOf(200, 206),
        reason: 'googlevideo rejected the resolved url',
      );
    });

    test('refreshLink returns a fresh url for an expired one', () async {
      final List<Map> results = await yt.fetchSearchResults('kesariya');
      final String id =
          (results.first['items'] as List).first['id'].toString();

      final Map? refreshed = await yt.refreshLink(id);

      expect(refreshed, isNotNull);
      expect(refreshed!['url'].toString(), startsWith('http'));
      expect(refreshed['expire_at'].toString(), isNotEmpty);
    });

    test('home feed playlists open through YouTube Music', () async {
      // Taken from the live home feed rather than hardcoded: YouTube retires
      // playlist ids often enough that a fixed one turns into a false alarm.
      // youtube_home.dart hands these ids to YouTubePlaylist, which resolves
      // them with YtMusicService — youtube_explode cannot enumerate the `RD`
      // mixes that dominate this feed.
      final Map<String, List> home = await yt.getMusicHome();
      final Map shelf = (home['body'] as List)
          .cast<Map>()
          .firstWhere((Map s) => (s['playlists'] as List?)?.isNotEmpty ?? false);
      final String playlistId =
          (shelf['playlists'] as List).first['playlistId'].toString();

      final Map details = await YtMusicService().getPlaylistDetails(playlistId);

      expect(details['songs'] as List, isNotEmpty,
          reason: 'home feed playlist $playlistId parsed to zero songs');
    });
  }, skip: skipLive);
}
