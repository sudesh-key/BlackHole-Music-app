/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// Live checks for each lyrics provider. `getLyrics` walks Spotify → Saavn →
// Musixmatch → Google, so a provider dying silently is invisible in the app;
// these tests name the one that broke.

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_env.dart';

void main() {
  setUpAll(bootTestEnv);

  group('Lyrics', () {
    test('Saavn returns text lyrics for a song that advertises them',
        () async {
      final Map res = await SaavnAPI()
          .fetchSongSearchResults(searchQuery: 'tum hi ho', count: 10);
      final List songs = res['songs'] as List;

      final Map withLyrics = songs.cast<Map>().firstWhere(
            (Map s) => s['has_lyrics'].toString() == 'true',
            orElse: () => {},
          );
      expect(withLyrics, isNotEmpty,
          reason: 'no song in the results advertises lyrics');

      final String lyrics =
          await Lyrics.getSaavnLyrics(withLyrics['id'].toString());

      expect(lyrics.trim(), isNotEmpty);
      // A scraped error page would bring markup along with it.
      expect(lyrics, isNot(contains('<')));
    });

    test('Google fallback returns lyrics, not a consent page', () async {
      final String lyrics = await Lyrics.getGoogleLyrics(
        title: 'Shape of You',
        artist: 'Ed Sheeran',
      );

      // Google frequently drops the answer box; an empty result is an honest
      // "not found". Markup coming back is the failure we care about.
      expect(lyrics, isNot(contains('<')));
      if (lyrics.isEmpty) {
        markTestSkipped('Google served no lyrics answer box for this query');
      }
    });

    test('LRCLIB returns lyrics, timestamped when it has them', () async {
      final Map<String, String> res = await Lyrics.getLrcLibLyrics(
        title: 'Shape of You',
        artist: 'Ed Sheeran',
      );

      expect(res['lyrics']!.trim(), isNotEmpty);
      expect(res['type'], anyOf('lrc', 'text'));
      // Whether a track has synced lyrics is up to LRCLIB's contributors, but
      // claiming 'lrc' without timestamps would break the scrolling view.
      if (res['type'] == 'lrc') {
        expect(res['lyrics'], contains('['));
      }
    });

    test('LRCLIB also covers Indian catalogue', () async {
      final Map<String, String> res = await Lyrics.getLrcLibLyrics(
        title: 'Tum Hi Ho',
        artist: 'Arijit Singh',
      );

      expect(res['lyrics']!.trim(), isNotEmpty);
    });

    test('LRCLIB returns empty rather than throwing for nonsense', () async {
      final Map<String, String> res = await Lyrics.getLrcLibLyrics(
        title: 'zzzz not a real song zzzz',
        artist: 'nobody at all',
      );

      expect(res['lyrics'], '');
    });

    test('Musixmatch scraping is known to be blocked', () async {
      final String link =
          await Lyrics.getLyricsLink('Shape of You', 'Ed Sheeran');

      // Kept as a probe: Musixmatch serves a JS shell to scrapers, so this
      // provider contributes nothing today. If it ever starts working again
      // this test fails and we can promote it back up the chain.
      expect(link, isEmpty);
    });

    test('Spotify synced lyrics require credentials and degrade gracefully',
        () async {
      final Map<String, String> res =
          await Lyrics.getSpotifyLyrics('Shape of You', 'Ed Sheeran');

      // Without a signed in Spotify account this must return empty, not throw.
      expect(res['lyrics'], isNotNull);
      expect(res['source'], 'Spotify');
    });

    test('the full chain finds lyrics for a popular song', () async {
      final Map res = await SaavnAPI()
          .fetchSongSearchResults(searchQuery: 'tum hi ho', count: 1);
      final Map song = (res['songs'] as List).first as Map;

      final Map<String, String> lyrics = await Lyrics.getLyrics(
        id: song['id'].toString(),
        title: song['title'].toString(),
        artist: song['artist'].toString(),
        saavnHas: song['has_lyrics'].toString() == 'true',
      );

      expect(lyrics['lyrics']!.trim(), isNotEmpty,
          reason: 'every lyrics provider failed for "${song['title']}"');
      expect(lyrics['source'], isNotEmpty);
    });
  }, skip: skipLive);
}
