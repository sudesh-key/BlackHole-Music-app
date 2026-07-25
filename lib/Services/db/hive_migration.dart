/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

// One-time import of the legacy Hive database into Drift.
//
// hive_ce is kept as a dependency solely for this reader; once you are
// confident all users have migrated, drop this file and the hive_ce entry
// from pubspec.yaml.

import 'dart:io';

import 'package:blackhole/Services/db/app_db.dart';
import 'package:hive_ce/hive.dart' as legacy;
import 'package:logging/logging.dart';

Future<void> migrateLegacyHiveData() async {
  try {
    final AppBox meta = await AppDb.openBox('_meta');
    if (meta.get('hiveImported') == true) return;

    final String dirPath = await AppDb.storageDir();
    final Directory dir = Directory(dirPath);
    final List<File> hiveFiles = dir.existsSync()
        ? dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.hive'))
            .toList()
        : <File>[];

    if (hiveFiles.isEmpty) {
      await meta.put('hiveImported', true);
      return;
    }

    Logger.root
        .info('Found ${hiveFiles.length} legacy Hive boxes, migrating...');
    legacy.Hive.init(dirPath);
    int migrated = 0;
    for (final File file in hiveFiles) {
      // Hive stored boxes as lowercase file names; AppDb box names are
      // case-insensitive too, so the file name is a valid box name.
      final String boxName =
          file.uri.pathSegments.last.replaceAll('.hive', '');
      try {
        final legacy.Box oldBox =
            await legacy.Hive.openBox(boxName, path: dirPath);
        final Map<dynamic, dynamic> data = oldBox.toMap();
        if (data.isNotEmpty) {
          final AppBox newBox = await AppDb.openBox(boxName);
          await newBox.importData(data);
        }
        await oldBox.close();
        migrated++;
        Logger.root.info('Migrated Hive box "$boxName" (${data.length} keys)');
      } catch (e, st) {
        Logger.root.severe('Failed to migrate Hive box "$boxName"', e, st);
      }
    }
    Logger.root.info('Hive migration finished ($migrated boxes)');
    await meta.put('hiveImported', true);
  } catch (e, st) {
    Logger.root.severe('Legacy Hive migration failed', e, st);
  }
}
