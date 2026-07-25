import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:get_it/get_it.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

SendPort? isolateSendPort;

Future<void> startBackgroundProcessing() async {
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  final receivePort = ReceivePort();
  await Isolate.spawn(_backgroundProcess, receivePort.sendPort);

  receivePort.listen((message) async {
    if (isolateSendPort == null) {
      Logger.root.info('setting isolateSendPort');
      isolateSendPort = message as SendPort;
      final appDocumentDirectoryPath =
          (await getApplicationDocumentsDirectory()).path;
      // Send docs path + root isolate token so the background isolate can
      // use platform channels (path_provider is called by drift_flutter).
      isolateSendPort?.send(
        [appDocumentDirectoryPath, RootIsolateToken.instance!],
      );
    } else {
      await audioHandler.customAction('refreshLink', {'newData': message});
    }
  });
}

// The function that will run in the background Isolate
Future<void> _backgroundProcess(SendPort sendPort) async {
  final isolateReceivePort = ReceivePort();
  sendPort.send(isolateReceivePort.sendPort);
  bool hiveInit = false;

  await for (final message in isolateReceivePort) {
    if (!hiveInit) {
      final List<dynamic> initData = message as List<dynamic>;
      final String path = initData[0] as String;
      final RootIsolateToken token = initData[1] as RootIsolateToken;
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      DartPluginRegistrant.ensureInitialized();
      String? subDir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        subDir = 'BlackHole/Database';
      } else if (Platform.isIOS) {
        subDir = 'Database';
      }
      // Connects to the main isolate's drift server (shareAcrossIsolates).
      await AppDb.init(basePath: path, subDir: subDir);
      await AppDb.openBox('ytlinkcache');
      await AppDb.openBox('settings');
      hiveInit = true;
      continue;
    }
    final newData =
        await YouTubeServices.instance.refreshLink(message.toString());
    sendPort.send(newData);
  }
}

void addIdToBackgroundProcessingIsolate(String id) {
  isolateSendPort?.send(id);
}
