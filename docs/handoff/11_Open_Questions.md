# 11 · Open Questions

Each question has a **default**. If Praba hasn't answered, build the default and mark the code `// TODO(question #n)`.

| # | Question | Default |
|---|----------|---------|
| 1 | MP3 encoder: LAME (LGPL) | **Decided by Praba: use LAME, confirm with a lawyer.** Dynamic xcframework + licence notice + any source/relinking obligations the lawyer requires. **Release gate:** no App Store submission without written legal sign-off |
| 2 | Final app name and subtitle (trademark + App Store availability) | "Tunely – MP3 & Ringtone Maker" / subtitle "Video to MP3, Audio Converter" |
| 3 | RevenueCat or plain `in_app_purchase`? | **RevenueCat** (offers, win-back, experiments, Mixpanel integration) |
| 4 | Default save folder | iCloud Drive › Tunely (picker on first save, user can choose any folder) |
| 5 | Analytics platform | **Mixpanel** (+ RevenueCat + Crashlytics). Amplitude/PostHog possible by swapping the provider class |
| 6 | Exit offer implementation | Separate product `tunely.pro.yearly.exit` with $14.99 first-year **introductory** price, eligibility-checked; if not eligible, P6 is not shown (promotional offers are only for current/former subscribers) |
| 7 | Win-back offer on iOS 16–17 | Promotional offer via RevenueCat; Apple win-back offer on iOS 18+ |
| 8 | Is a ringtone a "conversion" for the free limit? | **Yes**, 3 per day combined. (An early canvas note mentioned "2nd ringtone → P3"; this is superseded by the 3/day combined rule in `05` §1) |
| 9 | OGG input decoding | Off in V1.0 (only OGG output for Pro) |
| 10 | Support email | support@marberx.com (confirm) |
| 11 | Privacy Policy / Terms URLs | marberx.com/tunely/privacy and /terms (to be published before submission) |
| 12 | Localisation at launch | English only; strings in ARB from day one |
| 13 | Min iOS | 16.0 (iOS 26 features behind `#available`) |
| 14 | App icon | Violet gradient + white waveform mark (see `04`); final art to be supplied |
| 15 | "More apps from Marberx" list | Shrink: Video Compressor (picked for you), BibleHi, Image Resizer; real App Store IDs and names from `app_config.json` → `moreApps` (confirm names/IDs) |
| 16 | iOS 26 "Use as Ringtone" from a third-party app's share sheet | Verify on a physical iOS 26 iPhone in Phase 6. Until verified, Store 3 and the guide are provisional; GarageBand guide stays as fallback |
| 17 | Exit offer right after the first paywall close | **Decided by Praba: keep** (once ever, real timer, eligibility-checked intro price) |
| 18 | Ad network | **Default: AdMob with mediation** (best Flutter support, UMP consent built in). Alternative: ironSource / Unity LevelPlay mediation with AdMob as a network. `AdsService` supports either; Praba to confirm account and app IDs |
| 19 | Ad frequency | Default caps in `05` §12 (every 2nd conversion, ≥ 3 min, max 6/day, none in first session). Tune after 2 weeks of data |
| 20 | Share accounts across Marberx apps? | **Default: no.** Accounts and codes are per app (`app_id = "tunely"`) |
| 21 | Invite link domain | **Default: tunely.app/i/<CODE>** via Branch; confirm the domain |
| 22 | Referral reward size | **Default: 7 days Pro each**, cap 10 rewarded invites per inviter per year |
| 23 | iPhone Duo fold (crease) | Flutter doesn't report the fold on iOS yet. **Default:** width-driven layouts, centred content on the inner display; revisit with reserved regions once Flutter exposes them (flutter/flutter#192515) or via a small native channel |
| 24 | iPhone Duo App Store screenshots | **Default:** add outer and inner display screenshots (both from `tool/duo_sim.sh`) to get the "optimised for iPhone Duo" badge |
| 25 | Marberx auth/referral API (base URL, exact paths, payloads, error codes) | **Default:** built against the endpoints in `12` §2 (`HttpAccountApi`, `lib/core/account/account_api.dart`); set `referral.apiBaseUrl` in `app_config.json`. Until then debug builds use an in-memory demo backend and release builds report a server error on account screens |
| 26 | Invite artwork for 46 / 47 | **Default:** brand-gradient banner with a Phosphor icon; the mock-up photo is a placeholder that isn't shipped (`Design/Images/README.md`) |
| 27 | Deferred deep links (friend installs from the link) | **Default:** universal link `https://tunely.app/i/<CODE>` opens 53 when installed; manual entry always available. Branch (`flutter_branch_sdk`) to be added later for first-install codes; needs the AASA file on tunely.app |
