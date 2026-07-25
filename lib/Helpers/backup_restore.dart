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

import 'dart:convert';
import 'dart:io';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:blackhole/l10n/app_localizations.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:hive_ce/hive.dart' as legacy;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> createBackup(
  BuildContext context,
  List items,
  Map<String, List> boxNameData, {
  String? path,
  String? fileName,
  bool showDialog = true,
}) async {
  if (Platform.isAndroid) {
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      await [
        Permission.storage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ].request();
    }
    status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
  final String savePath = path ??
      await Picker.selectFolder(
        context: context,
        message: AppLocalizations.of(context)!.selectBackLocation,
      );
  if (savePath.trim() != '') {
    try {
      final saveDir = Directory(savePath);
      final dirExists = await saveDir.exists();
      if (!dirExists) saveDir.create(recursive: true);
      final List<File> files = [];
      final List boxNames = [];

      for (int i = 0; i < items.length; i++) {
        boxNames.addAll(boxNameData[items[i]]!);
      }

      for (int i = 0; i < boxNames.length; i++) {
        final AppBox box = await AppDb.openBox(boxNames[i].toString());
        final File exportFile = File('$savePath/${boxNames[i]}.bhdb.json');
        try {
          await exportFile.writeAsString(jsonEncode(box.exportData()));
        } catch (e) {
          await [
            Permission.manageExternalStorage,
          ].request();
          await exportFile.writeAsString(jsonEncode(box.exportData()));
        }

        files.add(exportFile);
      }

      final now = DateTime.now();
      final String time =
          '${now.hour}${now.minute}_${now.day}${now.month}${now.year}';
      final zipFile =
          File('$savePath/${fileName ?? "BlackHole_Backup_$time"}.zip');

      if ((Platform.isIOS || Platform.isMacOS) && await zipFile.exists()) {
        await zipFile.delete();
      }

      await ZipFile.createFromFiles(
        sourceDir: saveDir,
        files: files,
        zipFile: zipFile,
      );
      for (int i = 0; i < files.length; i++) {
        files[i].delete();
      }
      if (showDialog) {
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.backupSuccess,
        );
      }
      return '';
    } catch (e) {
      Logger.root.severe('Error in creating backup', e);
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.failedCreateBackup}\nError: $e',
      );
      return e.toString();
    }
  } else {
    ShowSnackBar().showSnackBar(
      context,
      AppLocalizations.of(context)!.noFolderSelected,
    );
    return 'No Folder Selected';
  }
}

/// A backup box is either a JSON export written by this (Drift based) version
/// or a `.hive` box from the versions before it.
enum _BackupFormat { driftJson, legacyHive }

bool _isBackupFile(String path) {
  final String name = path.toLowerCase();
  return name.endsWith('.bhdb.json') || name.endsWith('.hive');
}

String _boxNameOf(String fileName) =>
    fileName.replaceAll('.bhdb.json', '').replaceAll('.hive', '');

/// Decided by the first byte — only a JSON export can start with `{` — so a
/// backup keeps restoring even if its extension was changed along the way.
/// The extension is the fallback for files that cannot be read.
Future<_BackupFormat> _detectBackupFormat(File file) async {
  try {
    final List<int> head = await file.openRead(0, 1).first;
    if (head.isNotEmpty) {
      return head.first == 0x7B // '{'
          ? _BackupFormat.driftJson
          : _BackupFormat.legacyHive;
    }
  } catch (e) {
    Logger.root.warning('Could not read the start of ${file.path}: $e');
  }
  return file.path.toLowerCase().endsWith('.bhdb.json')
      ? _BackupFormat.driftJson
      : _BackupFormat.legacyHive;
}

/// Reads one backup file with the reader its format needs and imports it.
/// An empty backup leaves the existing box untouched rather than clearing it.
Future<void> _restoreBackupFile(File file, Directory legacyDir) async {
  final String fileName = file.path.split('/').last;
  final String boxName = _boxNameOf(fileName);
  final _BackupFormat format = await _detectBackupFormat(file);

  Map data;
  legacy.Box? oldBox;
  if (format == _BackupFormat.driftJson) {
    data = jsonDecode(await file.readAsString()) as Map;
  } else {
    // Hive resolves a box to the lowercased `<name>.hive` file while backups
    // keep the original casing, so it is read through a lowercase copy: on a
    // case sensitive filesystem Hive would otherwise open a new, empty box.
    await file.copy('${legacyDir.path}/${boxName.toLowerCase()}.hive');
    oldBox = await legacy.Hive.openBox(boxName, path: legacyDir.path);
    data = oldBox.toMap();
  }
  Logger.root.info(
    'Restoring $boxName from ${format.name} backup, ${data.length} entries',
  );

  if (data.isEmpty) {
    Logger.root.warning('Backup for $boxName is empty, keeping existing data');
  } else {
    final AppBox box = await AppDb.openBox(boxName);
    await box.clear();
    await box.importData(
      data,
      encodedKeys: format == _BackupFormat.driftJson,
    );
  }
  await oldBox?.close();
}

Future<void> restore(
  BuildContext context,
) async {
  Logger.root.info('Prompting for restore file selection');
  final String savePath = await Picker.selectFile(
    context: context,
    // ext: ['zip'],
    message: AppLocalizations.of(context)!.selectBackFile,
  );
  Logger.root.info('Selected restore file path: $savePath');
  if (savePath == '') {
    Logger.root.severe('Error in restoring backup', 'No file selected');
    ShowSnackBar().showSnackBar(
      context,
      AppLocalizations.of(context)!.noFileSelected,
    );
    return;
  }

  final bool isZip = savePath.toLowerCase().endsWith('.zip');
  if (!isZip && !_isBackupFile(savePath)) {
    Logger.root.severe('Error in restoring backup', 'Unsupported file');
    ShowSnackBar().showSnackBar(
      context,
      '${AppLocalizations.of(context)!.failedImport}\nSelect a .zip backup, or a single .bhdb.json / .hive file.',
    );
    return;
  }

  final Directory tempDir = await getTemporaryDirectory();
  final Directory destinationDir = Directory('${tempDir.path}/restore');
  final Directory legacyDir = Directory('${tempDir.path}/restore_legacy');

  try {
    final List<File> backupFiles;
    if (isZip) {
      Logger.root.info('Extracting backup file');
      if (await destinationDir.exists()) {
        await destinationDir.delete(recursive: true);
      }
      await ZipFile.extractToDirectory(
        zipFile: File(savePath),
        destinationDir: destinationDir,
      );
      backupFiles = destinationDir
          .listSync()
          .whereType<File>()
          .where((File file) => _isBackupFile(file.path))
          .toList();
    } else {
      Logger.root.info('Single backup file is selected');
      backupFiles = [File(savePath)];
    }
    Logger.root.info('Found ${backupFiles.length} backup files');

    await legacyDir.create(recursive: true);
    legacy.Hive.init(legacyDir.path);
    for (final File file in backupFiles) {
      await _restoreBackupFile(file, legacyDir);
    }

    await legacyDir.delete(recursive: true);
    if (isZip) {
      await destinationDir.delete(recursive: true);
    }
    ShowSnackBar()
        .showSnackBar(context, AppLocalizations.of(context)!.importSuccess);
  } catch (e) {
    Logger.root.severe('Error in restoring backup', e);
    ShowSnackBar().showSnackBar(
      context,
      '${AppLocalizations.of(context)!.failedImport}\nError: $e',
    );
  }
}
