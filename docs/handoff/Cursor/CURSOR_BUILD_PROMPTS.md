# Cursor Build Prompts: Flutter (iOS first). Run one phase at a time

**Setup**
1. `flutter create --org com.marberx --platforms ios,android tunely` (Android folder stays for later; build/test iOS now).
2. Copy this whole handoff folder into the repo as `/docs/handoff/`.
3. Copy `Cursor/tunely.mdc` to `.cursor/rules/tunely.mdc`.
4. Paste each prompt into Cursor Agent. After each phase: run on a **real iPhone**, tick the matching items in `09_QA_Acceptance_Checklist.md`, commit.

---

### Phase 1: Foundation and design system
```
Read docs/handoff/README.md, 04_Design_System.md, design-tokens.json and 06_Technical_Architecture.md.
Create the folder structure from 06 (lib/app, lib/core, lib/features, packages/tunely_engine, assets).
Add: flutter_riverpod (+ riverpod_generator), go_router, drift, shared_preferences, intl/flutter_localizations, phosphor_flutter.
Bundle Plus Jakarta Sans (docs/handoff/Fonts/*.ttf → assets/fonts/).
From design-tokens.json create AppColors (ThemeExtension, light + dark incl. proBadgeBg/proBadgeText/link), AppText, spacing/radius,
HeroGradient, light + dark ThemeData; MaterialApp uses ThemeMode.system.
Reusable widgets (both themes): PrimaryButton, IconSquareButton, TextLinkButton, SegmentedControl, FormatChip (with optional PRO badge),
RadioCard (with right-aligned size label), ToolTile, ProBadge, ProChip, FreeCounter, AppCard/ListGroup, StatusBox, HeroCard, PlayerCard,
WaveformView (CustomPainter, selectable range + handles), TrialTimeline, Toast (overlay, one at a time), AppBottomSheet and AppDialog
(scrim + BackdropFilter blur 10), AppTabBar (Home / My files / Settings).
go_router shell with placeholder tabs. Typed AppConfig provider from assets/config/app_config.json (values in 05 §10).
Debug-only "Component gallery" with a light/dark toggle; compare against Design/Screens_PNG.
iOS deployment target 16.0, iPhone only (including iPhone Duo), portrait on regular iPhones but every layout driven by window size. Build with Xcode 27.1 / iOS 27.1 SDK and Flutter 3.47.8 via FVM (`fvm flutter …`).
Create lib/app/transitions.dart (AppTransitions: push with iOS swipe-back, fadeThrough, modalUp, sheet, dialog, tab cross-fade) exactly as
04_Design_System.md › Screen transitions, and use it for EVERY go_router route (CustomTransitionPage). Enable 120 Hz
(CADisableMinimumFrameDurationOnPhone = YES). Add a Reduce Motion fallback (150 ms cross-fade).
```

### Phase 2: Rules in Dart (no UI)
```
Read 05_Business_Rules.md fully.
Implement pure Dart in lib/core/rules/: Preflight (order in §1), FreeLimit (3/day, local midnight, success-only counting, clock-back safe),
SizeEstimator (§4 formulas + low-source caption), PaywallTriggers (P1–P8 with all caps and global guards in §2), Personalization (§3 map),
RatingRules (§5), RingtoneRules (30 s max, loudest-window default, fades, tone types). Full unit tests incl.:
42 s at 256 kbps → ~1.3 MB; 30 s ringtone → ~0.5 MB; cancelled job doesn't count; exit offer only once ever; 2 paywalls in a row blocked.
```

### Phase 3: Native audio engine plugin (packages/tunely_engine)
```
Read 06 "Encoders per output format" and "Native plugin API".
Pigeon definitions in pigeons/engine.dart → generate Dart + Swift.
Swift: pickVideos (PHPickerViewController, copies to tmp), inspect (AVURLAsset: duration, audio track, hasProtectedContent, bitrate),
waveform (peaks via AVAssetReader, cached), convert: AVAssetReader → PCM → [trim range, fade ramps (vDSP), gain + soft limiter] →
encoder: AAC/M4A/M4R (AVAssetWriter), WAV (LPCM), FLAC (ExtAudioFile kAudioFormatFLAC), MP3 (LAME dynamic xcframework),
OGG (libvorbis). Merge = sequential inputs with optional crossfade. Progress via EventChannel (max 10/s), cancel, typed error codes
(unreadable, no_audio, protected, icloud, no_space, interrupted, decode, encode, io, stale_bookmark, unknown).
pickFolder + security-scoped bookmark + copyToBookmarkedFolder, freeBytes, cleanTemp, beginBackgroundTask for every job.
Kotlin stub throwing UnimplementedError. Dart AudioEngine on top. Temporary debug screen: pick a video → MP3/M4A/WAV/FLAC/OGG/M4R,
play each output with just_audio and open it in Files.
```

### Phase 4: Core flow: screens 06, 07, 08 (+08b), 19, 18, 09 (+09b)
```
Build Home (06, personalised hero from goal, tools grid, free counter, recent), Choose a file (02: Videos via pickVideos, Audio files via
file_picker, Recent from library), Convert (03: Audio file / Ringtone segmented, format chips with PRO badges, quality cards with live
estimates, Trim & fade row, footer summary), Ringtone mode (08b), Trim & fade (19 with WaveformView, ±1 s, fades, boost row),
Converting (18: ring, time left, Run in background, Cancel), Result (09/04b: player card, stats, cross-sell row, Save to Files /
Set as ringtone, Share). Match Design/Screens_PNG in both themes; read exact values from HTML_Source (Home, Picker, Convert, TrimEditor,
Progress, Result). Wire Preflight, FreeLimit and SizeEstimator. Library rows in drift. Save to Files = folder picker on first save
(suggest iCloud Drive › Tunely), then silent copy + toast.
```

### Phase 5: Errors and edge cases: 32–40, toasts (28)
```
Build E1 Conversion failed (compatibility mode = AVAssetExportPresetAppleM4A then transcode), E2 No storage (real MB),
E3 iCloud, E4 Copy-protected (also "This video has no sound"), E5 Save failed (pending folder 7 days, choose folder again),
S1 Stop converting, S2 My files empty (Shrink card from config), S3 Delete, S4 Batch partial. Toast catalogue exactly as 28.
Map plugin error codes per 05 §6. Kill the app mid-conversion and verify originals untouched, temp cleaned, no free use counted.
```

### Phase 6: Onboarding and personalisation: 01–05, 24, 23 (Settings), 22 (My files), 25 (Help), 20 (Ringtone guide)
```
Onboarding O1–O5 (first launch only, Skip on every step), storing goal + frequency; Personalization applied to Home hero, Picker tab,
Convert mode, Paywall header. Settings (23) with Preferences (24), Save to folder row, Help (25), Rate, More apps, Restore, Manage,
Licences link. My files (22) with filters, inline play, ⋯ menu (Share, Rename real file, Set as ringtone, Delete).
Ringtone guide (20, 3 steps, iOS 26 share sheet "Use as Ringtone"; GarageBand article for iOS ≤ 18 behind #available check).
```

### Phase 7: Monetization: 10–17, P4 card
```
Read 07_Monetization_StoreKit.md and 05 §2. RevenueCat purchases_flutter with anonymous IDs; entitlement "pro"; offerings default /
exit / winback; products tunely.pro.weekly, tunely.pro.yearly (3-day trial), tunely.pro.lifetime, tunely.pro.yearly.exit.
StoreKit configuration file for local testing with the intended prices. Build P1 Paywall (goal header, trial timeline with real dates,
plans with computed per-week + SAVE %, terms line + CTA per plan, trial-ineligible copy on EVERY paywall: states 10d, 11b, 13b), P2 sheet with "Use MP3 instead", P3 with
countdown, P4 card in Result, P5, P6 exit offer (once ever, persisted timer), P7 trial reminder (+ local notification 24 h before
trial end, in-app fallback), P8 win-back, P9 results. Enforce PaywallTriggers caps everywhere. Pro unlocks instantly and hides all
free-tier UI.
```

### Phase 8: Batch, merge, prompts: 21, 27, 26, 29, 30, 31
```
Batch (21, up to 50, sequential; iOS 26 BGContinuedProcessingTask; iOS 16–25 pause/resume per 05 §9), Merge screen 41 (Pro: 2–10 files, drag reorder, remove, preview, crossfade Off/1/2/3 s, Save as), states 35b/36b/17d/17e,
Notification pre-prompt (27, only before first batch / at trial start), Rating (26, rules §5, in_app_review / feedback mail),
Update sheet (29 via config), Milestones (30) and Share card (31, render to image and share).
```

### Phase 8b: Ads and cross-promotion (42–45, 09d)
```
Read 05_Business_Rules.md §12–13, 06 (Ads rows, SDK privacy table) and 07 › Ads.
Create lib/core/ads/: abstract AdsService { init(); loadInterstitial(); showInterstitial(); loadRewarded(); showRewarded(onReward);
isReady(format); } with AdMobAdsService (google_mobile_ads + UMP consent + mediation adapters) and LevelPlayAdsService (ironSource /
Unity LevelPlay plugin); provider from app_config.json. AdPolicy (pure Dart, unit-tested): first-session block, min 3 conversions,
every 2nd conversion, 180 s gap, 6/day, never after error/paywall in the same flow, Pro = never.
Build 42 Ad break notice (dialog over Result) → interstitial on Continue → back to Result; rewarded "Watch a short ad for 1 more" on P3
(+1 only in the reward callback, max 2/day, hidden if not loaded); 44 Ads & tracking pre-prompt once (UMP first in EEA, then ATT);
45 More from Marberx (config list, SKStoreProductViewController); Result house card 09d with HouseCardPolicy caps; Settings row → 45.
Use test ad unit IDs in debug. Fire every ad_* / house_card_* / more_apps_* event in 08.
```

### Phase 9: Analytics layer (every event)
```
Read docs/handoff/08_Analytics_Events.md fully.
Create lib/core/analytics/: abstract Analytics { track(String event, Map<String,Object> props); setUserProps(Map); setSuperProps(Map);
identify(String id); reset(); }, MixpanelAnalytics (mixpanel_flutter, ignore IP, EU/US residency from config, project token per
flavor: Tunely-Dev for debug, Tunely for release), DebugAnalytics (console + in-app debug list in the Component gallery),
FakeAnalytics for tests. events.dart: one constant per event name in 08 and typed helper methods with the exact properties
(e.g. trackTaskCompleted({task, format, quality, mode, sizeMb, secondsTaken, durationS, freeLeft})).
Super properties: app_version, ios_version, is_pro, plan, goal, frequency, theme, session_number (update on change).
User properties table in 08. identify() with the RevenueCat appUserID. Wire EVERY event in 08 at the listed trigger, fired once,
after success. Never pass file names/paths. Add unit tests that each helper emits the right name + property keys.
Checklist: run the app through every flow and confirm each event in Mixpanel Live View (Dev project).
Document in README how to switch the provider (Amplitude/PostHog) by replacing one class.
```

### Phase 9b: Account and referral (46–53, Settings rows)
```
Read docs/handoff/12_Account_and_Referral.md fully. Login is OPTIONAL and only for the inviter; never ask for it anywhere else.
Build lib/features/account/: AuthRepository (existing Marberx API, app_id "tunely": signup, login, refresh, forgot, verify/resend,
me, change password, random code, delete), tokens in flutter_secure_storage, silent sign-out on refresh failure.
Screens 46 Invite (signed out), 47 Invite (signed in), 48 Create account, 49 Sign in (+error), 50 Reset password (+sent),
51 Account (verify banner, code, random code, sign out), 52 Delete account (password confirm, in-app, Apple 5.1.1(v)),
53 Redeem code (enter/success/invalid; no login). Settings 23: Account row, Invite friends, Have an invite code?.
ReferralRepository: redeem (code + RevenueCat appUserID + DeviceCheck token from the plugin), qualify after the friend's first
successful conversion, stats. Branch deferred deep link → open 53 prefilled; universal link https://tunely.app/i/<CODE>.
Inline errors (offline, server, validation); never lose typed form data. Fire every account/referral event in 08.
```

### Phase 10: Hardening and release
```
Accessibility pass (200% text, VoiceOver, Reduce Motion), performance targets in 06, memory with 60-min files, PrivacyInfo.xcprivacy,
App Privacy answers (from the SDK table in 06, incl. advertising/tracking and account name/email), app-ads.txt, Crashlytics, Licences page (LAME, Vorbis, Flutter licences),
app icon, launch screen, TestFlight. Run the whole 09 checklist on iOS 16/17 and iOS 26 devices.
Prepare App Store listing from AppStore/App_Store_Listing.md (keep the 2.3.2 line).
Transition pass: check every route, sheet and dialog against 04 › Screen transitions; profile with the DevTools performance overlay on an
older iPhone and a ProMotion iPhone (no frame > 16 ms / 8 ms); move any heavy work that runs during a transition to after it completes.
```

### Later: Android
```
Implement the same Pigeon API in Kotlin (Media3 Transformer for AAC, LAME for MP3, MediaStore, Photo Picker, foreground service).
No Dart changes should be needed.
```
