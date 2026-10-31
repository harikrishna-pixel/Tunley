# 06 · Technical Architecture: Flutter (iOS first, Android-ready)

## Decision

- **UI, logic, rules, purchases, analytics, library:** Flutter (one codebase; Android later).
- **Audio decoding / encoding / editing:** a small **native plugin** (`packages/tunely_engine`), Swift now and Kotlin later, behind one Pigeon API.
- Reason: Flutter has no audio encoder. FFmpegKit was discontinued in 2025, so **don't use FFmpeg packages**. Apple's AVFoundation / AudioToolbox are fast and free; MP3 and OGG need two small open-source encoders (below).

## Encoders per output format (iOS)

| Output | How | Licence / note |
|--------|-----|----------------|
| M4A / AAC / M4R | `AVAssetReader` (LPCM) → `AVAssetWriter` (`kAudioFormatMPEG4AAC`, `.m4a`; M4R = same file with `.m4r` extension, type `com.apple.m4a-audio`) | Apple, free |
| WAV | `AVAssetWriter` LPCM 16-bit (`.wav`) | Apple |
| FLAC | `ExtAudioFile` / `AVAudioFile` with `kAudioFormatFLAC` (supported by Apple's converter since iOS 11) | Apple |
| **MP3** | **LAME** (`libmp3lame`) fed with PCM from `AVAssetReader` | LGPL: planned as a **dynamic xcframework** + licence notice in Settings › Licences. **Release gate: written legal sign-off before App Store submission** (Praba's decision: use LAME, confirm with a lawyer). See `11` #1 and `14` |
| OGG Vorbis (Pro) | `libogg` + `libvorbis` (xcframeworks) | BSD |
| Compatibility mode | `AVAssetExportSession` preset `AVAssetExportPresetAppleM4A` | Apple |

**Decoding inputs:** `AVAssetReader` reads video audio tracks and MP3/M4A/WAV/AIFF/CAF/FLAC. OGG input is optional (libvorbis decode) and off by default.

**Editing:** trim = `timeRange` on the reader; fades = gain ramp applied to PCM buffers (`vDSP_vrampmul`); volume boost = gain + soft limiter in PCM (AVAudioMix can't go above 1.0); merge = sequential readers into one writer (optional crossfade); all in one pass where possible.

## Stack

| Area | Choice |
|------|--------|
| Flutter / Dart | **Flutter 3.47.8** (Dart 3.13), pinned per project with FVM (`.fvmrc`; run `fvm flutter …`). 3.41+ is required for the UIScene lifecycle |
| Toolchain | **Xcode 27.1 with the iOS 27.1 SDK** (required for iPhone Duo; apps built with the iOS 27 SDK must use the UIScene lifecycle or they fail to launch). macOS 26.6+, Apple silicon |
| Min OS | **iOS 16.0** (iOS 26 features behind availability checks); Android later minSdk 26 |
| State | Riverpod (`flutter_riverpod` + generator) |
| Navigation | `go_router` (shell: Home / My files / Settings) |
| Database | `drift` (library items, usage counters, trigger state) |
| Settings | `shared_preferences` |
| Config | `assets/config/app_config.json` (+ optional `firebase_remote_config` for A/B values) |
| Native bridge | **Pigeon** + EventChannel `tunely/progress` |
| Pick videos | **PHPicker via our plugin** (no Photos permission; returns a file copy). Don't use `photo_manager` (needs library access) |
| Pick audio / folders | `file_picker` (audio types) + plugin method for folder picker & security-scoped bookmarks |
| Waveform | Plugin returns N peak values (`waveform(path, buckets)`); drawn with `CustomPainter` |
| Playback | `just_audio` (preview in Trim, Result, My files) |
| Share | `share_plus` (ringtone guide uses the share sheet) |
| Purchases | **RevenueCat `purchases_flutter`** (recommended: trial/offer handling, paywall A/B tests, win-back) or `in_app_purchase`; see `07` |
| Notifications | `flutter_local_notifications` (trial reminder, batch done) |
| Rating | `in_app_review` |
| Update check | `package_info_plus` + config |
| **Analytics** | One `Analytics` service (provider-swappable). Default provider **Mixpanel** (`mixpanel_flutter`); alternatives Amplitude / PostHog. See `08` |
| Crashes | `firebase_crashlytics` |
| Localisation | `flutter_localizations` + ARB |
| Fonts / icons | Plus Jakarta Sans (bundled), `phosphor_flutter` only |
| Theme | `ThemeExtension<AppColors>` light + dark from `design-tokens.json`; `ThemeMode.system` |
| Ads | One `AdsService` interface (`lib/core/ads/`) with providers: **AdMob** (`google_mobile_ads`, incl. UMP consent and AdMob mediation adapters) **or** **ironSource / Unity LevelPlay** (official LevelPlay Flutter plugin; check the current package name) with AdMob as a network. Interstitial + rewarded only. Flag `ads.enabled` + `ads.provider` in config |
| Tracking prompt | `app_tracking_transparency` (after our pre-prompt 44) |
| Account & referral | Existing Marberx/Bible auth + referral API with `app_id = "tunely"` (`12`); `dio` client, tokens in Keychain (`flutter_secure_storage`), deferred deep links via Branch (`flutter_branch_sdk`), DeviceCheck token via the plugin, RevenueCat `logIn(accountId)` for inviter rewards |
| Cross-promo | `SKStoreProductViewController` via a tiny plugin method `showAppStore(appId)`; list from `app_config.json` |

## Repository structure

```
tunely/
  lib/
    main.dart
    app/                router, theme, DI, config
    core/
      design_system/    tokens.dart, buttons, chips, radio_card, segmented, tool_tile, pro_badge, free_counter,
                        waveform_view, player_card, trial_timeline, status_box, toast, sheet, dialog
      engine/           audio_engine.dart (Dart interface), models (MediaInfo, ConvertRequest, Job)
      rules/            preflight.dart, free_limit.dart, size_estimator.dart, paywall_triggers.dart,
                        personalization.dart, rating_rules.dart, ringtone_rules.dart   ← pure Dart + tests
      library/          drift db, repository, folder bookmark service
      entitlements/     purchases (RevenueCat), isPro, offers
      analytics/        analytics.dart (interface), mixpanel_analytics.dart, debug_analytics.dart, events.dart
      notifications/
    features/
      onboarding/ home/ picker/ convert/ trim/ progress/ result/ ringtone_guide/ batch/ merge/
      my_files/ settings/ preferences/ help/ paywall/ offers/ errors/ prompts/
  packages/tunely_engine/
    pigeons/engine.dart
    ios/Classes/        AudioEngine.swift, Encoders/(Lame, Vorbis, Flac, Aac, Pcm), Picker.swift, Bookmarks.swift, Storage.swift
    ios/Frameworks/     lame.xcframework (dynamic), ogg.xcframework, vorbis.xcframework
    android/            Kotlin stubs (UnimplementedError) → Media3 later
  assets/config/app_config.json
  assets/fonts/
  test/
  docs/handoff/
```

## Native plugin API (`tunely_engine`, Pigeon sketch)

```dart
enum OutFormat { mp3, m4a, wav, m4r, flac, aac, ogg }   // AIFF: V1.1
class MediaInfo { String path; int bytes; double durationSec; bool hasAudio; bool isProtected;
                  bool isLocal; int? sourceBitrate; int sampleRate; int channels; String container; }
class ConvertRequest { List<String> inputs;          // 1 = convert, 2+ = merge (in order)
                       OutFormat format; int bitrateKbps; int? sampleRate;
                       double startSec; double endSec; double fadeInSec; double fadeOutSec;
                       double gainDb; double crossfadeSec; String outputName; }
class ConvertResult { String jobId; String outputPath; int outputBytes; double seconds; }

@HostApi() abstract class EngineApi {
  @async List<String> pickVideos(int maxCount);              // PHPicker, returns temp copies
  @async MediaInfo inspect(String path);
  @async List<double> waveform(String path, int buckets);    // 0..1 peaks
  @async ConvertResult convert(String jobId, ConvertRequest r); // progress via EventChannel {jobId, fraction}
  void cancel(String jobId);
  @async String? pickFolder();                               // returns bookmark id
  @async String copyToBookmarkedFolder(String path, String bookmarkId); // throws stale_bookmark / io
  int freeBytes();
  void cleanTemp(int olderThanHours);
  @async bool startContinuedBatch(String title);             // iOS 26 BGContinuedProcessingTask
}
```

Error codes (typed): `unreadable`, `no_audio`, `protected`, `icloud`, `no_space`, `interrupted`, `decode`, `encode`, `io`, `stale_bookmark`, `unknown` → mapped to screens in `05` §6.

## Rules live in Dart

Pre-flight, free limit, size estimates, trigger caps, personalisation, rating, ringtone rules: pure Dart with unit tests. Native receives final numbers (bitrate, range, fades, gain).

## Purchases

RevenueCat with anonymous app user ID (account login is optional and only for referral; on sign-in call `logIn(accountId)` so inviter rewards reach the right user). `Purchases.configure` at launch; `CustomerInfo` stream → `isPro`. Offerings: `default` (Yearly/Weekly/Lifetime), `exit` (yearly offer), `winback`. Details in `07`.

## Analytics

`Analytics.track(Event e, Map props)` + `setUserProps`. Events are constants in `events.dart` (generated from the table in `08`). A `DebugAnalytics` provider logs to console and an in-app debug list (debug builds only). No file names, paths, or personal data ever.

## SDK data and App Privacy (fill from the real build, then verify with network traffic)

| SDK | Data it collects | Purpose | Linked to user? | Tracking? | Privacy manifest |
|---|---|---|---|---|---|
| RevenueCat | App user ID (anonymous), purchase history, device/app info | Purchases, entitlements | Likely **linked** (user ID) | No | Included in SDK |
| Mixpanel | Distinct ID (= RevenueCat ID), events in `08`, device/app info; IP ignored | Product analytics | Likely **linked** (same ID) | No | Included in SDK |
| AdMob / LevelPlay + mediated networks | IDFA (only if ATT allowed), IP, device info, ad interactions, coarse location | Advertising, ad measurement | Linked (by networks) | **Yes, if ATT allowed** | Each SDK ships its own; add all mediated adapters' manifests |
| Firebase Crashlytics | Crash logs, installation ID, device info | Diagnostics | Not linked (default) | No | Included in SDK |
| Marberx auth API (V1.3, only if the user creates an account) | Name, email, hashed password, referral code, app user ID, DeviceCheck token | Account, referral rewards | **Linked** | No | Our own (declare email/name) |
| Branch (deferred deep links) | Device info, IP, link click data | Invite links | Check Branch docs; likely not linked | No (configure without IDFA) | Included in SDK |
| LAME / libvorbis | Nothing | Encoding | – | – | – |

Final App Privacy answers come from this table after the build is checked with a proxy (Charles/Proxyman) and the generated privacy report in Xcode. Draft answers are in `AppStore/App_Store_Listing.md`.

## iOS project settings

- `Info.plist`: `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, `CFBundleDocumentTypes` + `UTImportedTypeDeclarations` for audio/video "Open in Tunely", notification permission via `UserNotifications` `requestAuthorization` after our pre-prompt (27) (no Info.plist key needed), `CADisableMinimumFrameDurationOnPhone = YES` (120 Hz), **no** `NSPhotoLibraryUsageDescription` (PHPicker doesn't need it), `NSUserTrackingUsageDescription` ("Allow tracking to see more relevant ads. Tunely works the same either way."), `GADApplicationIdentifier` (AdMob) / LevelPlay app key, the networks' `SKAdNetworkItems` list. Publish `app-ads.txt` on the developer website.
- Share extension (later, V1.1): "Convert with Tunely" from Photos/Files.
- `PrivacyInfo.xcprivacy`: required-reason APIs (disk space, file timestamps, UserDefaults) + SDK manifests (RevenueCat, Mixpanel, Firebase).
- `BGTaskSchedulerPermittedIdentifiers` for the continued batch task (iOS 26).
- iPhone only (`TARGETED_DEVICE_FAMILY = 1`), **including iPhone Duo**. Portrait is requested on regular iPhones, but layouts never depend on it: iPhone Duo resizes the app when it folds or unfolds, and its inner display ignores the portrait lock.
- UIScene lifecycle: `UIApplicationSceneManifest` with `FlutterSceneDelegate`; `AppDelegate` registers plugins in `didInitializeImplicitFlutterEngine`. Never use `UIScreen.main`, `UIDevice.orientation`, `statusBarOrientation` or the idiom for layout; native code finds its presenter through `connectedScenes`.

## Ads implementation notes (Phase 8b)

- `lib/core/ads/ads_service.dart`: `AdsService` with `AdMobAdsService` (google_mobile_ads 9.2, UMP consent first), `LevelPlayAdsService` (stub until question #18 picks it) and `NoAdsService` (Pro, disabled, or a release build without `--dart-define=ADMOB_INTERSTITIAL_IOS` / `ADMOB_REWARDED_IOS`). Debug uses Google's test units; `GAD_APPLICATION_ID` comes from `ios/Flutter/*.xcconfig` (test ID until the production App ID exists).
- Rules: `AdPolicy` and `HouseCardPolicy` in `lib/core/rules/`; state in `lib/app/ads.dart`; counters in `UsageStore` (`ad_memory`, `house_card`, `installed_at`, `tracking_prompt_shown`).
- ATT (`trackingStatus` / `requestTracking`) and `openAppStorePage` (SKStoreProductViewController) are in `tunely_engine`, so no extra packages.
- Mediation adapters and the full `SKAdNetworkItems` list are added with the production AdMob account (question #18).

## iPhone Duo (Xcode 27.1, iOS 27.1 SDK)

- Built with the iOS 27.1 SDK, the app fills both displays. Flutter draws its own bars, so the system's vertical bar strip arrives as a per-edge safe-area inset: always use `SafeArea` or read `MediaQuery.paddingOf` edge by edge.
- `lib/app/adaptive.dart` decides layout from the window only: below 600 pt the bottom tab bar; from 600 pt (inner display, rotated) a vertical tab rail on the edge with the larger side inset, and phone-designed screens centred at 640 pt (`AdaptivePage`, applied to every route by `AppTransitions`). Sheets cap at 560 pt, dialogs at 440 pt, toasts at 560 pt.
- Height can be short (rotated inner display): fixed-height screens scale down and scroll (Progress ring 160–250 pt).
- The fold (crease) isn't reported to Flutter on iOS yet (`MediaQuery.displayFeatures` is empty). TODO(question #23): keep primary buttons out of the fold once reserved regions are available.
- Test: `tool/duo_sim.sh` (Xcode 27.1) builds, installs and screenshots both displays; fold poses in Device Hub. `test/duo_layout_test.dart` checks every main route at Duo sizes; `TUNELY_DUO=1 fvm flutter test test/screens_golden_test.dart --update-goldens` renders `test/goldens/duo/`.

## Performance targets

- 1-min video → MP3 256 kbps in < 3 s on iPhone 13.
- 30 s ringtone in < 1.5 s.
- Waveform for a 5-min file in < 400 ms (cache by file hash).
- Progress events max 10/s.
