# BlackHole Modernization — What Changed & How to Build

Refactored from the 2023 codebase (Flutter 3.x-era, AGP 7) to **Flutter 3.32+ / Dart 3.8+**, all platforms.

## Dependency changes (pubspec.yaml)

| Old | New | Code impact |
|---|---|---|
| `audiotagger` (dead git fork) | removed → `metadata_god ^1.1.0` everywhere | tag read/write in `download.dart`, `downloads.dart`; offline embedded-tag lyrics replaced by sidecar `.lrc`/`.txt` lookup in `lyrics.dart` |
| `persistent_bottom_nav_bar` (git fork) | removed → own widget `lib/CustomWidgets/persistent_tab_view.dart` | same API surface (`PersistentTabController`, `jumpToTab`), per-tab Navigators + `NavigatorPopHandler` back handling |
| `hive` / `hive_flutter` (unmaintained) | `hive_ce` / `hive_ce_flutter` | import swap only; on-disk data format is compatible |
| `on_audio_query` | `on_audio_query_forked ^2.9.1` | AGP 8 compatible, identical API |
| `lint` | `flutter_lints ^6` | analysis_options updated |
| `youtube_explode_dart` 2.0.4 | **^3.1.0** | new JS-challenge solvers fix broken stream extraction; `getManifest` now passes multi-client fallback (`androidVr`, `android`, `ios`, `tv`) |
| `flutter_lyric` 2.x | **^3.0.7** | migrated `LyricsReader`/`UINetease` → `LyricView` + `LyricController` in `audioplayer.dart` |
| `share_plus` 7 → 13 | `Share.share` → `SharePlus.instance.share(ShareParams(...))` (9 call sites) |
| `receive_sharing_intent` 1.4 → 1.8 | text+media streams unified in `main.dart` (`ReceiveSharingIntent.instance`) |
| `connectivity_plus` 5 → 7 | stream now emits `List<ConnectivityResult>` (`audio_service.dart`) |
| `app_links` 3 → 7 | `allUriLinkStream` → `uriLinkStream` (3 files) |
| `just_audio` 0.9 → 0.10 | added `errorStream` listener; `ConcatenatingAudioSource` is deprecated-but-working (TODO: migrate to the new playlist API later) |
| `sizer` 2 → 3 | `SizerUtil.setScreenSize` → `Sizer(builder:)` wrapper in `main.dart` |
| `carousel_slider` 4 → 5, `uuid` 3 → 4, `file_picker` 6 → 11, `permission_handler` 11 → 12, `device_info_plus` 9 → 12, `package_info_plus` 5 → 9, `get_it` 7 → 9, `flutter_archive` → 6.0.4, `marquee` → 2.3, `material_design_icons_flutter` → 7 | no source changes needed |
| added `http ^1.5.0` explicitly (was transitive) | |

## Flutter API migrations
- `withOpacity()` → `withValues(alpha:)` (55 sites)
- `CardTheme` → `CardThemeData` in `app_theme.dart`
- l10n: synthetic `flutter_gen` package removed → generated into `lib/l10n/` (`l10n.yaml`), 57 imports updated to `package:blackhole/l10n/app_localizations.dart`

## Android build system
- AGP **8.7.3**, Gradle **8.10.2**, Kotlin **2.1.0**, declarative `plugins {}` DSL
- `compileSdk 35`, `targetSdk 35`, `minSdk 23`, Java 17, `namespace` in build.gradle
- Manifest: `package` attr removed; added `READ_MEDIA_AUDIO`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; legacy storage perms capped with `maxSdkVersion`; audio service marked `foregroundServiceType="mediaPlayback"`
- Release build falls back to debug signing when `key.properties` is absent

## iOS / macOS
- iOS deployment target 12.0 → **13.0**, macOS 10.14 → **10.15** (Podfiles enforce it in `post_install`); stale `Podfile.lock`s deleted

## Music sources
- **YouTube**: fixed by youtube_explode_dart 3.x + multi-client manifest fallback
- **JioSaavn**: same endpoints (still live); added browser User-Agent header
- **Spotify import**: credentials moved to `lib/constants/app_credentials.dart`; supply your own via `--dart-define=SPOTIFY_CLIENT_ID=... --dart-define=SPOTIFY_CLIENT_SECRET=...` (redirect URI `blackhole://spotify/auth`)

---

## Database: Hive → Drift

Hive was fully replaced by **Drift (SQLite)**:

- `lib/Services/db/app_database.dart` — Drift schema: one `key_value(box, key, value)` table (JSON-encoded values) + a box registry. Uses `drift_flutter` with `shareAcrossIsolates: true` so the yt-link refresh isolate shares the main isolate's connection (no sqlite lock contention).
- `lib/Services/db/app_db.dart` — `AppDb`/`AppBox`: a Hive-compatible facade. Reads are synchronous from an in-memory cache (exactly Hive's model, so all 346 existing call sites keep their shape); writes update the cache instantly and persist to SQLite asynchronously. `box.listenable()` is preserved for every `ValueListenableBuilder`. Box names are case-insensitive like Hive.
- `lib/Services/db/hive_migration.dart` — one-time import: on first launch it scans the old data directory for `*.hive` files and copies everything (settings, playlists, favorites, downloads index, caches) into Drift, then marks itself done. **`hive_ce` stays in pubspec only for this reader** — remove it once your users have migrated.
- Backups now export boxes as `<box>.bhdb.json` inside the zip; restoring **old Hive-based backup zips still works** (legacy `.hive` entries are read and imported).
- Fixed typed-cast landmines: JSON round-trips return `List<dynamic>`, so `as List<int>`-style casts on box reads were replaced with `List<int>.from(...)` (audio_service, app_ui, youtube_services).

**Required once:** Drift uses code generation —

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/Services/db/app_database.g.dart` (commit it). Run it again whenever the schema changes.

## Build & verify (on your machine)

```bash
flutter --version           # needs 3.32+ stable
flutter clean
flutter pub get             # regenerates pubspec.lock + lib/l10n/
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter analyze
flutter run                 # Android device/emulator
flutter build apk --release
```

**Desktop (Windows/Linux):** the runner folders still contain the 2021-era template
(e.g. `windows/runner/run_loop.cpp`). Refresh them once:

```bash
flutter create --platforms=windows,linux .
# then restore APPLICATION_ID "com.shadow.blackhole" in linux/CMakeLists.txt if overwritten
```

**iOS/macOS:** `cd ios && pod install --repo-update` (same for `macos/`) before first build.

## Runtime smoke-test checklist
1. Home feed loads (Saavn) · 2. Search returns songs · 3. Saavn song plays · 4. YouTube tab loads and a video plays · 5. Download completes with tags + artwork · 6. Local music tab lists device songs (grant audio permission) · 7. Backup/restore works · 8. Share buttons work · 9. Notification playback controls on Android 13+ (allow notifications)

## Known follow-ups (non-blocking)
- `ConcatenatingAudioSource` (just_audio) is deprecated — migrate to `setAudioSources`/`addAudioSource` playlist API in a dedicated pass with device testing
- `sliding_up_panel` and `palette_generator` are discontinued but compile fine; consider vendoring or replacing later
- If `flutter analyze` flags anything in `LyricView` params (flutter_lyric 3.x), check `LyricStyles` presets — the widget accepts `style:` for theming
