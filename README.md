# Tunely

Video to MP3, audio converter and ringtone maker. Flutter (iOS first), native audio engine in
`packages/tunely_engine`. Specs live in `docs/handoff/`.

## Setup

- Flutter **3.47.8** is pinned with FVM (`.fvmrc`). In this folder `flutter` / `dart` run the pinned
  SDK (see `~/.zshrc`); elsewhere `fvm flutter …` works too.
- Xcode 27.1 with the iOS 27.1 SDK. iPhone Duo: `tool/duo_sim.sh`.

```bash
flutter run \
  --dart-define=REVENUECAT_IOS_KEY=appl_xxx \
  --dart-define=MIXPANEL_TOKEN_DEV=xxxxxxxx
```

| `--dart-define` | Used for |
|---|---|
| `REVENUECAT_IOS_KEY` | Purchases. Without it, debug builds use the demo store and release builds sell nothing |
| `MIXPANEL_TOKEN_DEV` | Analytics in debug builds (Mixpanel project **Tunely-Dev**) |
| `MIXPANEL_TOKEN` | Analytics in release builds (Mixpanel project **Tunely**) |
| `LEVELPLAY_APP_KEY`, `LEVELPLAY_INTERSTITIAL_IOS`, `LEVELPLAY_REWARDED_IOS` | ironSource LevelPlay (defaults to Tunely / Audio Converter production IDs). AdMob unused this version |

Without a Mixpanel token, events stay on the device: they print to the console and show in
Settings › Component gallery › Analytics events.

## Analytics

Every event in `docs/handoff/08_Analytics_Events.md` goes through one interface,
`Analytics` (`lib/core/analytics/analytics.dart`). Features call the typed helpers in
`lib/core/analytics/events.dart` (for example `analytics.taskCompleted(...)`), never a vendor SDK.
Super and user properties are kept up to date by `AnalyticsSync` (`lib/app/analytics_sync.dart`).

- Mixpanel ignores the IP for geolocation; data residency (US/EU) is `analytics.residency` in
  `assets/config/app_config.json`.
- `distinct_id` is the RevenueCat `appUserID`. Connect RevenueCat → Integrations → Mixpanel so
  renewals land in the same funnels.
- Never put file names, paths, emails or free text in properties. `test/analytics_test.dart` checks
  every helper's name and property keys, that the helpers match the event table in `08`, and that
  real flows send no file names.

### Switching to Amplitude, PostHog or another provider

1. Add the provider's package (ask first, see `.cursor/rules/tunely.mdc`).
2. Add one class that implements `Analytics` (`track`, `setUserProps`, `setSuperProps`, `identify`,
   `reset`), next to `MixpanelAnalytics`.
3. Return it from `createAnalytics()` in `lib/core/analytics/analytics.dart`.

Nothing else changes: event names, properties and call sites stay the same.

## Tests

```bash
flutter analyze
flutter test
TUNELY_GOLDENS=1 flutter test test/screens_golden_test.dart --update-goldens  # phone screenshots
TUNELY_DUO=1 flutter test test/screens_golden_test.dart --update-goldens      # iPhone Duo sizes
```
