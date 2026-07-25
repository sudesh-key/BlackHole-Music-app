# BlackHole — Modernization & Refactoring Plan

**Baseline:** v1.15.10 (last commit Dec 2023) · ~37k LOC Dart · 117 files
**Target:** Flutter 3.32+ stable / Dart 3.8+ · all platforms · architecture preserved (Hive + get_it) · no Firebase

---

## Phase 1 — Toolchain & Build System

### Android (currently won't compile on modern Flutter)
| Item | Current | Target |
|---|---|---|
| Android Gradle Plugin | 7.1.3 (imperative `apply from: flutter.gradle`) | 8.7+ via declarative `plugins {}` DSL |
| Gradle wrapper | 7.2 | 8.10+ |
| Kotlin | 1.8.22 | 2.1+ |
| compileSdk | 33 | 36 |
| targetSdk | 29 | 35 (Play Store requirement) |
| minSdk | 21 | 23 (required by several updated plugins) |
| Java | 8 (implicit) | 17 (source/target compatibility) |
| namespace | missing (manifest package) | `com.shadow.blackhole` in build.gradle |

Changes: rewrite `android/settings.gradle` + `android/build.gradle` + `android/app/build.gradle` to the new Flutter Gradle plugin DSL; move `package=` out of AndroidManifest into `namespace`; add `android:exported` attributes; update ProGuard/R8 rules; debug-signing fallback so the project builds without `key.properties`.

### iOS / Desktop
- iOS: bump deployment target to 13.0+, refresh Podfile to current Flutter template.
- macOS: deployment target 10.15+.
- Windows/Linux: refresh CMake runner files to current Flutter template versions; replace discontinued `just_audio` desktop backends where needed.

---

## Phase 2 — Dependency Modernization

### Replacements (discontinued / dead packages)
| Package | Status | Replacement |
|---|---|---|
| `audiotagger` (git fork) | Discontinued, Android-only | Remove — consolidate on `metadata_god` (already in use) for tag read/write |
| `carousel_slider` 4.x | Ownership transferred; 4.x conflicts with Flutter 3.24+ `CarouselController` | `carousel_slider` 5.x (`CarouselSliderController` rename) |
| `sliding_up_panel` | Discontinued | Keep pinned (pure Dart, still compiles) or vendor into `lib/CustomWidgets` |
| `persistent_bottom_nav_bar` (git fork) | Fork of old v4 | Latest official release; adapt `PersistentTabView.custom` usage |
| `hive` / `hive_flutter` | Unmaintained since 2023 | `hive_ce` / `hive_ce_flutter` (drop-in community fork) |
| `lint` | Superseded | `flutter_lints` latest |
| `uuid` 3.x | Major behind | `uuid` 4.x |

### Major upgrades (breaking API changes to migrate in code)
- `youtube_explode_dart` 2.0.4 → **latest 2.x** — the single most important fix: old cipher/stream extraction is broken by YouTube changes. Migrate `getManifest` calls (client hints now required: `ytClients: [YoutubeApiClient.android, ...]`).
- `share_plus` 7 → latest — `Share.share()` / `Share.shareXFiles()` → `SharePlus.instance.share(ShareParams(...))`.
- `connectivity_plus` 5 → latest — `onConnectivityChanged` now emits `List<ConnectivityResult>`.
- `receive_sharing_intent` 1.4 → latest — static methods moved to `ReceiveSharingIntent.instance`, text stream merged into media stream (`SharedMediaType.text`/`.url`).
- `file_picker` 6 → latest; `device_info_plus` 9 → latest; `package_info_plus` 5 → latest; `permission_handler` 11 → latest; `app_links` 3 → 6 (`allUriLinkStream` → `uriLinkStream`); `get_it` 7 → 8; `just_audio` 0.9 → 0.10; `audio_service` → latest 0.18.x.

---

## Phase 3 — Dart / Flutter API Migration
- `Theme.of(context).accentColor` (33 uses) → `Theme.of(context).colorScheme.secondary`.
- `textScaleFactor` (4 uses) → `TextScaler` API.
- Material 3 compatibility pass on `lib/theme/app_theme.dart` (explicit `useMaterial3` decision, `CardTheme` → `CardThemeData`, `DialogTheme` → `DialogThemeData`, etc.).
- Replace any `WidgetsBinding`/`window` legacies, `MaterialStateProperty` → `WidgetStateProperty`.
- Fix all remaining analyzer errors/warnings until `flutter analyze` is clean.

## Phase 4 — Music Source APIs
1. **JioSaavn** (`lib/APIs/api.dart`) — endpoint host still live; update request params/headers, verify each endpoint (home, search, song details, radio, lyrics), keep the built-in proxy fallback for geo-blocked regions.
2. **YouTube / YT Music** (`lib/Services/youtube_services.dart`, `lib/Services/ytmusic/`) — rewrite stream-URL resolution on new `youtube_explode_dart` API with multi-client fallback; cache expiring URLs as before.
3. **Spotify import** (`lib/APIs/spotify_api.dart`) — hardcoded shared credentials are dead; move client ID/secret to a config constant you supply from your own (free) Spotify Developer app. Token-refresh flow kept.

## Phase 5 — Verification
- `flutter pub get` resolves with zero overrides.
- `flutter analyze` → 0 errors.
- Build check per platform (`flutter build apk --debug` locally on your machine; sandbox has no Android SDK).
- Runtime smoke test checklist: home feed loads, search works, song plays (Saavn + YouTube), download works, local music tab, backup/restore.

## External items needed from you
1. **Nothing for Firebase** — not used.
2. **Spotify import (optional):** create a free app at developer.spotify.com and paste Client ID/Secret into `lib/APIs/spotify_api.dart` (I'll mark the spot). Redirect URI: `blackhole://spotify/auth`.
3. **Release signing:** your own `key.properties` + keystore for release builds (debug builds work without).
4. **Final device build/test** on your machine — I'll verify pub get + analyze in my sandbox, but APK build and on-device testing need your Android SDK.
