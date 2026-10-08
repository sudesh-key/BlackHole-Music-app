/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

/// googlevideo will not serve a whole file in one request any more: a plain
/// GET, and any open ended `Range: bytes=N-`, come back 403 — and that open
/// ended range is the first thing both ExoPlayer and AVPlayer ask for, so a
/// track loads into the player and then never starts. Bounded ranges are still
/// answered, so the audio is pulled in chunks and handed to the player through
/// just_audio's proxy.
///
/// This does not buy back a whole track. YouTube also caps how much audio an
/// unattested client may pull — about a megabyte, after which every range is
/// refused whether or not the url is resolved again — so playback still stops
/// there, roughly a minute in at 128 kbps or three at 49 kbps.
class YouTubeAudioSource extends StreamAudioSource {
  YouTubeAudioSource({required this.uri, required this.sourceLength})
      : contentType = uri.queryParameters['mime'] ?? 'audio/mp4';

  static const int maxChunkSize = 512 * 1024;

  final Uri uri;
  final int sourceLength;
  final String contentType;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final int from = start ?? 0;
    final int until = end ?? sourceLength;
    return StreamAudioResponse(
      sourceLength: sourceLength,
      contentLength: until - from,
      offset: from,
      stream: _read(from, until),
      contentType: contentType,
    );
  }

  Stream<List<int>> _read(int from, int until) async* {
    int position = from;
    while (position < until) {
      final int last = min(position + maxChunkSize, until) - 1;
      final http.Response response = await http.get(
        uri,
        headers: {'range': 'bytes=$position-$last'},
      );
      if (response.statusCode != 206 && response.statusCode != 200) {
        throw Exception(
          'googlevideo refused bytes=$position-$last with '
          '${response.statusCode}',
        );
      }
      yield response.bodyBytes;
      position = last + 1;
    }
  }
}
