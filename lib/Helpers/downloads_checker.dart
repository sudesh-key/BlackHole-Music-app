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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:logging/logging.dart';

Future<void> downloadChecker() async {
  // Opened rather than read straight away: `AppDb.box` hands back an empty box
  // while it loads, which would leave stale entries (a restored backup brings
  // paths from the device the backup came from) in place.
  final Box box = await AppDb.openBox('downloads');
  final List songs = box.values.toList();
  final List<String> keys = await compute(checkPaths, songs);
  if (keys.isNotEmpty) {
    Logger.root.info('Removing ${keys.length} downloads with missing files');
    await box.deleteAll(keys);
  }
}

Future<List<String>> checkPaths(List songs) async {
  final List<String> res = [];
  for (final song in songs) {
    final bool value = await File(song['path'].toString()).exists();
    if (!value) res.add(song['id'].toString());
  }
  return res;
}
