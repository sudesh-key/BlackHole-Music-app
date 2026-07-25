/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *  Copyright (c) 2021-2026, Ankit Sangwan
 */

/// Central place for third-party API credentials.
///
/// The bundled Spotify credentials from the original 2023 project are dead.
/// Create your own (free) app at https://developer.spotify.com/dashboard,
/// add `blackhole://spotify/auth` as the Redirect URI, and either paste the
/// values below or pass them at build time:
///
///   flutter build apk \
///     --dart-define=SPOTIFY_CLIENT_ID=xxx \
///     --dart-define=SPOTIFY_CLIENT_SECRET=yyy
class AppCredentials {
  static const String spotifyClientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    // TODO(user): replace with your own client ID if not using --dart-define.
    defaultValue: '08de4eaf71904d1b95254fab3015d711',
  );

  static const String spotifyClientSecret = String.fromEnvironment(
    'SPOTIFY_CLIENT_SECRET',
    // TODO(user): replace with your own client secret if not using --dart-define.
    defaultValue: '622b4fbad33947c59b95a6ae607de11d',
  );

  static const String spotifyRedirectUrl = 'blackhole://spotify/auth';
}
