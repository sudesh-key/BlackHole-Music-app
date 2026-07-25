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

import 'dart:async';
import 'dart:io';

import 'package:blackhole/Helpers/config.dart';
import 'package:blackhole/Helpers/handle_native.dart';
import 'package:blackhole/Helpers/import_export_playlist.dart';
import 'package:blackhole/Helpers/logging.dart';
import 'package:blackhole/Helpers/route_handler.dart';
import 'package:blackhole/Screens/Common/routes.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/constants/constants.dart';
import 'package:blackhole/constants/languagecodes.dart';
import 'package:blackhole/providers/audio_service_provider.dart';
import 'package:blackhole/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:blackhole/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:blackhole/Services/db/app_db.dart';
import 'package:blackhole/Services/db/hive_migration.dart';
// import 'package:home_widget/home_widget.dart';
import 'package:logging/logging.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:sizer/sizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Paint.enableDithering = true; No longer needed

  String? dbSubDir;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    dbSubDir = 'BlackHole/Database';
  } else if (Platform.isIOS) {
    dbSubDir = 'Database';
  }
  await AppDb.init(subDir: dbSubDir);
  // One-time import of pre-2.x Hive data into Drift.
  await migrateLegacyHiveData();
  for (final box in hiveBoxes) {
    await openAppDbBox(
      box['name'].toString(),
      limit: box['limit'] as bool? ?? false,
    );
  }
  if (Platform.isAndroid) {
    setOptimalDisplayMode();
  }
  await startService();
  runApp(MyApp());
}

Future<void> setOptimalDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  // final List<DisplayMode> supported = await FlutterDisplayMode.supported;
  // final DisplayMode active = await FlutterDisplayMode.active;

  // final List<DisplayMode> sameResolution = supported
  //     .where(
  //       (DisplayMode m) => m.width == active.width && m.height == active.height,
  //     )
  //     .toList()
  //   ..sort(
  //     (DisplayMode a, DisplayMode b) => b.refreshRate.compareTo(a.refreshRate),
  //   );

  // final DisplayMode mostOptimalMode =
  //     sameResolution.isNotEmpty ? sameResolution.first : active;

  // await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
}

Future<void> startService() async {
  await initializeLogging();
  try {
    MetadataGod.initialize();
  } catch (e) {
    Logger.root.severe('MetadataGod init failed (tag editing disabled): $e');
  }
  final audioHandlerHelper = AudioHandlerHelper();
  final AudioPlayerHandler audioHandler =
      await audioHandlerHelper.getAudioHandler();
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
  GetIt.I.registerSingleton<MyTheme>(MyTheme());
}

Future<void> openAppDbBox(String boxName, {bool limit = false}) async {
  final AppBox box = await AppDb.openBox(boxName);
  // clear box if it grows large
  if (limit && box.length > 500) {
    await box.clear();
  }
}

/// Called when Doing Background Work initiated from Widget
// @pragma('vm:entry-point')
// Future<void> backgroundCallback(Uri? data) async {
//   if (data?.host == 'controls') {
//     final audioHandler = await AudioHandlerHelper().getAudioHandler();
//     if (data?.path == '/play') {
//       audioHandler.play();
//     } else if (data?.path == '/pause') {
//       audioHandler.pause();
//     } else if (data?.path == '/skipNext') {
//       audioHandler.skipToNext();
//     } else if (data?.path == '/skipPrevious') {
//       audioHandler.skipToPrevious();
//     }

//     // await HomeWidget.saveWidgetData<String>(
//     //   'title',
//     //   audioHandler?.mediaItem.value?.title,
//     // );
//     // await HomeWidget.saveWidgetData<String>(
//     //   'subtitle',
//     //   audioHandler?.mediaItem.value?.displaySubtitle,
//     // );
//     // await HomeWidget.updateWidget(name: 'BlackHoleMusicWidget');
//   }
// }

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  // ignore: unreachable_from_main
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en', '');
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // HomeWidget.setAppGroupId('com.shadow.blackhole');
    // HomeWidget.registerBackgroundCallback(backgroundCallback);
    final String systemLangCode = Platform.localeName.substring(0, 2);
    final String? lang = AppDb.box('settings').get('lang') as String?;
    if (lang == null &&
        LanguageCodes.languageCodes.values.contains(systemLangCode)) {
      _locale = Locale(systemLangCode);
    } else {
      _locale = Locale(LanguageCodes.languageCodes[lang ?? 'English'] ?? 'en');
    }

    AppTheme.currentTheme.addListener(() {
      setState(() {});
    });

    if (Platform.isAndroid || Platform.isIOS) {
      void handleSharedMedia(List<SharedMediaFile> value) {
        if (value.isEmpty) return;
        for (final file in value) {
          // receive_sharing_intent >= 1.6 delivers shared text & urls through
          // the media stream with SharedMediaType.text / SharedMediaType.url.
          if (file.type == SharedMediaType.text ||
              file.type == SharedMediaType.url) {
            Logger.root.info('Received shared text/url: ${file.path}');
            handleSharedText(file.path, navigatorKey);
          } else if (file.path.endsWith('.json')) {
            final List playlistNames = AppDb.box('settings')
                    .get('playlistNames')
                    ?.toList() as List? ??
                ['Favorite Songs'];
            importFilePlaylist(
              null,
              playlistNames,
              path: file.path,
              pickFile: false,
            ).then(
              (value) => navigatorKey.currentState?.pushNamed('/playlists'),
            );
          }
        }
      }

      // For shared urls/text/files coming in while the app is in memory.
      _intentDataStreamSubscription =
          ReceiveSharingIntent.instance.getMediaStream().listen(
        handleSharedMedia,
        onError: (err) {
          Logger.root.severe('ERROR in getMediaStream', err);
        },
      );

      // For shared urls/text/files that launched the app.
      ReceiveSharingIntent.instance.getInitialMedia().then(
        (List<SharedMediaFile> value) {
          handleSharedMedia(value);
          ReceiveSharingIntent.instance.reset();
        },
        onError: (err) {
          Logger.root.severe('ERROR in getInitialMedia', err);
        },
      );
    }
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.themeMode == ThemeMode.system
            ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                ? Brightness.light
                : Brightness.dark
            : AppTheme.themeMode == ThemeMode.dark
                ? Brightness.light
                : Brightness.dark,
        systemNavigationBarIconBrightness:
            AppTheme.themeMode == ThemeMode.system
                ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark
                : AppTheme.themeMode == ThemeMode.dark
                    ? Brightness.light
                    : Brightness.dark,
      ),
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
                title: 'BlackHole',
                restorationScopeId: 'blackhole',
                debugShowCheckedModeBanner: false,
                themeMode: AppTheme.themeMode,
                theme: AppTheme.lightTheme(
                  context: context,
                ),
                darkTheme: AppTheme.darkTheme(
                  context: context,
                ),
                locale: _locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LanguageCodes.languageCodes.entries
                    .map((languageCode) => Locale(languageCode.value, ''))
                    .toList(),
                routes: namedRoutes,
                navigatorKey: navigatorKey,
                onGenerateRoute: (RouteSettings settings) {
                  if (settings.name == '/player') {
                    return PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => const PlayScreen(),
                    );
                  }
                  return HandleRoute.handleRoute(settings.name);
                },
          );
        },
      ),
    );
  }
}
