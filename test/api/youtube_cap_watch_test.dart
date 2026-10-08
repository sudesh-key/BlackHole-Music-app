/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// A watch on the two things that would let youtube playback work properly
// again. Both tests assert today's broken state, so they fail the moment it
// improves — that failure is the signal to revisit, not a regression.
//
// Background: youtube moved media delivery to SABR (the player response now
// carries `serverAbrStreamingUrl`, no HLS manifest and no progressive formats).
// The plain urls the app still uses are the legacy path, and youtube serves
// only about the first megabyte of them, so a track stops roughly a minute in.
// See YouTubeAudioSource.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../test_env.dart';

/// The version this limitation was measured against.
const String pinnedExplodeVersion = '3.1.0';

/// Bytes youtube will serve from a stream url without an attestation token.
const int readablePrefix = 1024 * 1024;

void main() {
  setUpAll(bootTestEnv);

  group('youtube playback cap', () {
    test('streams are still cut off after the first megabyte', () async {
      final manifest = await YoutubeExplode().videos.streamsClient.getManifest(
        VideoId('Vug4YLiIsaU'),
        ytClients: [YoutubeApiClient.android],
      );
      final audio = manifest.audioOnly
          .where((e) => e.audioCodec.contains('mp4'))
          .toList()
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
      final stream = audio.last;
      expect(stream.size.totalBytes, greaterThan(readablePrefix),
          reason: 'pick a longer track; this one fits inside the cap');

      final response = await http.get(
        stream.url,
        headers: {'range': 'bytes=$readablePrefix-${readablePrefix + 65535}'},
      );

      expect(
        response.statusCode,
        403,
        reason: 'youtube now serves past the first megabyte — the chunked '
            'source and its caveats in YouTubeAudioSource can likely go',
      );
    });

    test('youtube_explode_dart has not published a newer release', () async {
      final response = await http
          .get(Uri.https('pub.dev', '/api/packages/youtube_explode_dart'));
      final Map data = jsonDecode(response.body) as Map;
      final String latest = data['latest']['version'].toString();

      expect(
        latest,
        pinnedExplodeVersion,
        reason: 'a new youtube_explode_dart is out — check its changelog for '
            'SABR or proof-of-origin token support, which is what youtube '
            'playback is waiting on',
      );
    });
  }, skip: skipLive);
}
