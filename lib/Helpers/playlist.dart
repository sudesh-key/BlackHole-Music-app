/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/format.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/songs_count.dart' as songs_count;
import 'package:blackhole/Services/db/app_db.dart';
import 'package:logging/logging.dart';

/// Some playlists hold raw JioSaavn API responses instead of formatted songs:
/// the flat fields the app reads (`artist`, `album`, `url`, `genre`) sit under
/// `more_info` there, so those entries render as "Unknown" with a null artist
/// and have no playable url. Rewrites them through the normal formatter and
/// saves the result, so a playlist is repaired the first time it is opened.
Future<List> repairRawPlaylistSongs(String name, List songs) async {
  final List<Map> raw = songs
      .whereType<Map>()
      .where((Map song) => song['url'] == null && song['more_info'] is Map)
      .toList();
  if (raw.isEmpty) return songs;

  Logger.root.info('Repairing ${raw.length} unformatted songs in "$name"');
  final Box playlistBox = await AppDb.openBox(name);
  final Map<String, dynamic> repaired = {};
  for (final Map song in raw) {
    final Map formatted = await FormatResponse.formatSingleSongResponse(song);
    if (formatted.containsKey('Error')) continue;
    if (song['dateAdded'] != null) formatted['dateAdded'] = song['dateAdded'];
    repaired[formatted['id'].toString()] = formatted;
  }
  if (repaired.isEmpty) return songs;

  await playlistBox.putAll(repaired);
  return playlistBox.values.toList();
}

bool checkPlaylist(String name, String key) {
  if (name != 'Favorite Songs') {
    AppDb.openBox(name).then((value) {
      return AppDb.box(name).containsKey(key);
    });
  }
  return AppDb.box(name).containsKey(key);
}

Future<void> removeLiked(String key) async {
  final Box likedBox = AppDb.box('Favorite Songs');
  likedBox.delete(key);
  // setState(() {});
}

Future<void> addMapToPlaylist(String name, Map info) async {
  if (name != 'Favorite Songs') await AppDb.openBox(name);
  final Box playlistBox = AppDb.box(name);
  final List songs = playlistBox.values.toList();
  info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
  songs_count.addSongsCount(
    name,
    playlistBox.values.length + 1,
    songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
  );
  playlistBox.put(info['id'].toString(), info);
}

Future<void> addItemToPlaylist(String name, MediaItem mediaItem) async {
  if (name != 'Favorite Songs') await AppDb.openBox(name);
  final Box playlistBox = AppDb.box(name);
  final Map info = MediaItemConverter.mediaItemToMap(mediaItem);
  info.addEntries([MapEntry('dateAdded', DateTime.now().toString())]);
  final List songs = playlistBox.values.toList();
  songs_count.addSongsCount(
    name,
    playlistBox.values.length + 1,
    songs.length >= 4 ? songs.sublist(0, 4) : songs.sublist(0, songs.length),
  );
  playlistBox.put(mediaItem.id, info);
}

Future<void> addPlaylist(String inputName, List data) async {
  final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
  String name = inputName.replaceAll(avoid, '').replaceAll('  ', ' ');

  final List playlistNames =
      AppDb.box('settings').get('playlistNames', defaultValue: []) as List;

  if (name.trim() == '') {
    name = 'Playlist ${playlistNames.length}';
  }
  while (playlistNames.contains(name)) {
    // ignore: use_string_buffers
    name += ' (1)';
  }

  await AppDb.openBox(name);
  final Box playlistBox = AppDb.box(name);

  songs_count.addSongsCount(
    name,
    data.length,
    data.length >= 4 ? data.sublist(0, 4) : data.sublist(0, data.length),
  );
  final Map result = {for (final v in data) v['id'].toString(): v};
  playlistBox.putAll(result);

  playlistNames.add(name);
  AppDb.box('settings').put('playlistNames', playlistNames);
}
