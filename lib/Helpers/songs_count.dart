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

import 'package:blackhole/Services/db/app_db.dart';

void addSongsCount(String playlistName, int len, List images) {
  final Map playlistDetails =
      AppDb.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  // Index assignment rather than addEntries: values read back from the
  // database are Map<String, dynamic>, whose addEntries rejects the
  // List<MapEntry<dynamic, dynamic>> a literal infers here. That threw for
  // every playlist name being recorded for the first time, which aborted
  // playlist imports with an uncaught type error and no message.
  final Map details = (playlistDetails[playlistName] as Map?) ?? {};
  details['count'] = len;
  details['imagesList'] = images;
  playlistDetails[playlistName] = details;
  AppDb.box('settings').put('playlistDetails', playlistDetails);
}
