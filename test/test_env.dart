/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

import 'dart:io';

import 'package:blackhole/Services/db/app_db.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boots the pieces of the app the API and database layers expect:
///
/// * a Flutter binding (drift_flutter and path_provider need one),
/// * a temporary directory standing in for path_provider's plugin,
/// * real networking — the test binding installs an [HttpOverrides] that
///   answers every request with 400, which would make the live API tests
///   below report failures that have nothing to do with the endpoints.
Future<Directory> bootTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  final Directory dir = Directory.systemTemp.createTempSync('blackhole_test');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async => dir.path,
  );

  await AppDb.init(basePath: dir.path);
  return dir;
}

/// Marks a test as depending on a third party service. Set `LIVE_API=0` to
/// skip them (offline machine, CI without egress).
final bool skipLive = Platform.environment['LIVE_API'] == '0';
