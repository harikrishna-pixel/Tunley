# 05 · Business Rules

All rules are **pure Dart** in `lib/core/rules/` with unit tests. Every number comes from `assets/config/app_config.json` (§10), never a literal in a widget.

## 1. Pre-flight and free limit

**Pre-flight order** (stop at the first failure):
1. **Readable**: AVFoundation can open the file and it has an audio track → else E1 (`unreadable`) or E4 for "no audio track" with copy "This video has no sound".
2. **Not DRM**: `AVURLAsset.hasProtectedContent == false` → else **E4**.
3. **Downloaded**: iCloud items are downloaded first (progress in 18 as "Downloading from iCloud… x%"); failure → **E3**.
4. **Space**: free space ≥ `estimateBytes × 2 + 50 MB` → else **E2** (show the real missing MB).
5. **Pro gate** (free users): Pro format (FLAC/AAC/OGG), Alarm/Text tone, Volume boost, Merge, Batch (2+ files) → **P2** sheet. Never counts a conversion.
6. **Free limit**: free user with `usedToday ≥ 3 + rewardedToday` → **P3** (with "Watch a short ad for 1 more", max 2 per day).

**Free limit**
- 3 conversions per local day; resets at local midnight (`DateTime.now()` local, re-checked on app foreground).
- A conversion is counted **only when a job finishes successfully** and the output file exists. Failed, cancelled, interrupted → never counted.
- Re-saving / re-sharing an existing result never counts.
- Store `usedToday` + `dayKey` (yyyy-MM-dd) locally (drift). Changing the clock back doesn't give extra uses (keep the max dayKey seen).
- Pro users: no counter shown anywhere (Home, Result, toasts).

## 2. Premium trigger map (situational paywalls)

| ID | Trigger | Screen | Frequency cap |
|----|---------|--------|---------------|
| P1 | End of onboarding (also after Skip) | 10 Paywall (closable) | Once |
| P2 | Tap a Pro feature: FLAC/AAC/OGG, Alarm/Text tone, Volume boost, Merge, Batch, multi-select | 11 sheet | Every time (it's a gate) |
| P3 | Free user starts a 4th conversion today | 12 dialog with countdown | Every time |
| P4 | 3rd successful conversion of the day | Card inside Result (09c) | Max 1 / day |
| P5 | 10th file lifetime (free user) | 13 dialog | Once |
| P6 | First close of P1 | 14 Exit offer, 10-min real timer | **Once ever** (store `exitOfferShownAt`; timer end time persisted, survives restarts; after expiry never again) |
| P7 | Trial day 2 (24 h before renewal) | Local notification → 15 | Once per trial |
| P8 | Opens app ≥ 14 days after subscription lapsed / cancelled | 16 Win-back | Once per 90 days |
| P9 | After any purchase attempt | 17 result / toast | – |

**Trial eligibility (every paywall):** before rendering any paywall, sheet or card, check introductory-offer eligibility (RevenueCat `checkTrialOrIntroductoryPriceEligibility` / StoreKit `isEligibleForIntroOffer`). Not eligible → no "free"/"trial" words anywhere, show the real renewal price, CTA "Continue" / "Get Tunely Pro" / "Get Yearly", hide the trial timeline (states 10d, 11b, 13b; P4 card says "Go unlimited").

**Global guards** (checked by `PaywallTriggers.canShow`):
- Never two sales screens in a row, **with one deliberate exception decided by Praba: P1 close → P6 exit offer, once ever** (common top-app pattern; the offer has a real persisted timer and "No thanks" returns to the app).
- Never during converting / batch, never right after an error screen, never during onboarding questions.
- Max **1 unrequested paywall per session** (P1, P4, P5, P8 count; P2/P3 are user-initiated gates and don't).
- Frequency "Just once in a while" (O3) → P4 at most once every 3 sessions.
- Pro users never see P1–P6, P8.

## 3. Personalisation map (from onboarding)

| Answer | Effect |
|--------|--------|
| O2 **Ringtones** (default) | Home hero "Make a ringtone from any video" (CTA "Choose a video or song"); Convert opens in **Ringtone** mode; Paywall header "Unlimited ringtones, alarms & text tones" |
| O2 **MP3 from videos** | Hero "Turn any video into an MP3" (CTA "Choose a video"); default MP3 256 kbps; Picker opens on **Videos**; Paywall header MP3 variant |
| O2 **Convert files** | Hero "Convert audio to any format" (CTA "Choose an audio file"); Picker opens on **Audio files**; default format = last used; Paywall header convert variant |
| O3 **Every day** | Yearly plan emphasised; P5 heavy-user dialog after 10 files |
| O3 **A few times a week** (default) | Default behaviour, Yearly pre-selected |
| O3 **Just once in a while** | Lifetime listed second; P4 max once per 3 sessions |

Editable in Settings › Your preferences (24). Changes apply immediately. Store as user properties `goal`, `frequency` (see `08`).

## 4. Conversion presets and size estimates

| Preset | Codec | Bitrate | Sample rate |
|--------|-------|---------|-------------|
| Standard | MP3/AAC | 128 kbps | 44.1 kHz |
| **High** (default) | MP3/AAC | 256 kbps | 44.1 kHz |
| Best | MP3/AAC | 320 kbps | source (max 48 kHz) |
| WAV | PCM 16-bit | – | 44.1 kHz, stereo |
| FLAC | lossless | – | source |
| OGG Vorbis | VBR q≈ bitrate | 128/256/320 equivalent | 44.1 kHz |
| Ringtone (M4R) | AAC | 128 kbps | 44.1 kHz |

**Estimate** (`SizeEstimator`): lossy = `bitrate × seconds / 8 × 1.01`; WAV = `44100 × 2 × 2 × seconds`; FLAC = WAV × 0.55 (shown with "~"). Seconds = trimmed duration. Show as "~1.3 MB" (1 decimal under 10 MB, integers above). Footer shows "(from 86 MB)" = source file size.

Quality never upsamples: if the source audio bitrate is lower than the preset, show the preset but add caption "Source is 128 kbps. Higher won't improve it."

## 5. Self-marketing prompts

| Prompt | When | Caps |
|--------|------|------|
| **Rating** (26) | After the 2nd ringtone **or** 5th successful conversion, on the Result screen, 1.5 s after it opens | Max 2 times ever, ≥ 30 days apart; never after an error or a paywall in the same session. 4–5★ → `in_app_review` (Apple sheet); 1–3★ → in-app feedback form (mail) |
| **Notifications** (27) | Before the first batch, or right after a trial starts (the reminder only works if allowed; copy says "Allow notifications and we'll remind you") | Once each; if denied, never ask again; trial reminder then shown in-app on day 2 |
| **Milestones** (30) | First ringtone, 10 files, 50 files | Once each |
| **Share card** (31) | From Milestone or Result share on a ringtone | – |
| **Update** (29) | Newer version in config with `minRecommended` > current | Once per version |
| **More apps** | Settings row + empty My files card (Shrink) | Never a pop-up |

## 6. Error rules

- Every error screen says **what happened**, **"Your original file is safe and unchanged"**, and gives **one primary next step**.
- Error codes: `AUD-VFR-02` (variable frame rate), `AUD-DEC-01` (decode), `AUD-ENC-03` (encode), `AUD-INT-04` (interrupted), `AUD-IO-05` (write). Shown small on E1 and attached to support mail.
- E1 primary = **compatibility mode**: re-run as M4A/AAC 256 kbps via `AVAssetExportSession` (AppleM4A preset), then transcode if the user wanted another format.
- E2 secondary action = "How to free up space" help sheet (iOS has no public deep link to iPhone Storage).
- No audio track → E4 state 35b. Stale/missing folder bookmark → E5 state 36b "Choose folder again".
- E5: output kept in `Application Support/Pending/` for 7 days; Try again re-saves without re-encoding.
- Batch: one failure never stops the queue; finished files are saved immediately; S4 offers "Retry failed (n)".
- Toasts never carry errors that need a decision (only "Couldn't convert this file · Details").

## 7. Ringtone rules

- Max length **30 s** (enforced by the selection; default selection = loudest 30 s window, else 0:00–0:30).
- Fade in / out default **2 s** each (0–5 s, 0.5 s steps).
- Output: **M4R** (AAC 128 kbps in MPEG-4), file name `<source>_tone.m4r`.
- Types: **Ringtone** (free), **Alarm** and **Text tone** (Pro). Text tone defaults to 5 s selection. Type is saved as metadata for My files filters.
- After saving: Result 09b → "Set as ringtone" → **Guide (20)**:
  - iOS 26+: Step 1 open share sheet (`share_plus` with the .m4r) → tap **Use as Ringtone**; Step 2 open Settings › Sounds & Haptics › Ringtone; Step 3 pick it (it's at the top).
  - iOS ≤ 18: GarageBand guide (Help article with 6 steps); the link is always visible at the bottom of step 1.
- Event `guide_step_viewed` per step with `ios_version`.

## 8. Files and storage

- **Library copy:** every output is written to the app's `Documents/Library/` (feeds My files; visible in Files › On My iPhone › Tunely with `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`). iOS deletes this folder when the app is deleted.
- **Tunely folder (survives deletion):** on the **first Save to Files**, open the system folder picker (`UIDocumentPickerViewController(forOpeningContentTypes: [.folder])`) suggesting **iCloud Drive › Tunely** (create it if needed). Store a **security-scoped bookmark**; afterwards Save to Files copies there silently with toast "Saved to Files › Tunely". Settings › Save to shows the folder and lets the user change it. If the bookmark is stale or the folder is gone → E5 with "Choose folder again".
- This is why the copy says "Copies saved to your Tunely folder in Files, kept even if you delete the app". **Don't promise that for the library copy.**
- File names: `<source name>.<ext>`; duplicates get ` 2`, ` 3`. Rename in My files renames the real file.
- Temp files in `tmp/Tunely/`; cleaned on success, failure, cancel, and on launch (> 24 h old).
- **Delete (39) removes the library copy only.** Copies in the user's Tunely folder and the original in Photos are never deleted by Tunely.
- Originals are **never modified or deleted**. PHPicker gives a copy; Files picker uses security-scoped access read-only.

## 9. Background work (per iOS version: never over-promise)

| iOS | Single conversion | Batch / long merge | Copy shown |
|---|---|---|---|
| 26+ | `BGContinuedProcessingTask` with system progress UI; may still be stopped by the system | Same | "On iOS 26 it keeps going." |
| 16–25 | `beginBackgroundTask` (~30 s extra time); after that the job **pauses** | Pauses when suspended; resumes from the next file when the app returns | "On older iOS it may pause until you come back." |

- A paused/interrupted job is saved as "Paused" in My files with Resume; it never counts as a conversion and never corrupts files.
- Never promise "we'll notify you when it's done" on iOS 16–25; the notification is sent only if the job actually finished.
- Event `background_interrupted` when a job pauses.

## 11. Merge rules (screen 41, Pro)
- 2–10 inputs (audio or video), order = list order (drag handle), remove with ×, "Add" opens the picker in multi-select.
- Crossfade Off / 1 / 2 / 3 s (default 1 s); total length shown = sum − crossfades.
- "Save as" uses the same format/quality presets as Convert (default MP3 256 kbps); estimate shown.
- Mixed sample rates are resampled to 44.1 kHz; mono inputs upmixed to stereo.
- One merge = no free-limit impact (Pro only).

## 12. Ads rules (free users only; Pro = no ads)

Ads are in V1.0. Network: Google AdMob **or** ironSource/Unity LevelPlay mediation (or any network) behind one `AdsService` (`06`). The rules are the same whichever network is used.

| Placement | Format | When | Caps |
|---|---|---|---|
| **Ad break** (42 → 43) | Interstitial | After the user taps **Save to Files / Set as ringtone / Done** on Result, the file is already saved, our notice (42) appears, the user taps **Continue**, then the network ad (43). Ad closed → back to Result | Not in the first session; not before the user's 3rd conversion ever; every 2nd conversion; min 3 min apart; max 6 per day |
| **Rewarded** | Rewarded video | "Watch a short ad for 1 more" on P3 Daily limit (12) | +1 conversion only after the SDK reward callback; max 2 per day |
| **Ads & tracking pre-prompt** (44) | – | Once, after onboarding + first paywall, before the system ATT prompt | Once ever; then `ATTrackingManager.requestTrackingAuthorization` |

**Never:** on app open/exit, during onboarding, while converting, inside sheets/paywalls, after an error screen, on the same screen as a house (Marberx) card, or right after a paywall in the same flow (if P4/P5/P6 showed, skip the ad break). **Nothing of ours is ever drawn over a network ad.** No banners in V1.0 (keeps the premium look).

**Consent:** in the EEA/UK/Switzerland show Google's UMP consent form first (required by Google); then 44 → ATT. Denied tracking = non-personalised ads, app works the same.

**No fill / offline:** skip the ad silently (no house ad in its place, no error). Rewarded unavailable → hide the button.

## 13. Cross-promotion of Marberx apps (house ads, never pushy)

| Surface | Rule |
|---|---|
| **More from Marberx** screen (45) | Always available from Settings › More apps from Marberx. One "Picked for you" app chosen by the user's goal/usage, then a short list. Opens the App Store product page (`SKStoreProductViewController`, stays in app) |
| **Card on Result** (09d) | Small, dismissible card "From the makers of Tunely". Only after a success, at most once every 5 successes and once per day, never in the first 3 days, never in the same session as an ad break, never with the P4 upsell card. × hides it for 30 days; hidden 3 times → never again |
| **Empty My files** (38) | One quiet card (Shrink) |
| **Relevance** | Pick the app that matches what the user just did (e.g. converted a big video → Shrink; Bible-reading users → BibleHi). Never show an app the user already has (check with `LSApplicationQueriesSchemes`/URL scheme where possible) |
| **Never** | Pop-ups, interstitial house ads, fake urgency, rewards for installs, house cards for Pro users more than once a week |

The list, texts and App Store IDs come from `app_config.json` → `moreApps` so they can change without an app update.

## 10. `app_config.json` (defaults)

```json
{
  "freeConversionsPerDay": 3,
  "ringtoneMaxSeconds": 30,
  "textToneDefaultSeconds": 5,
  "fadeDefaultSeconds": 2,
  "fadeMaxSeconds": 5,
  "batchMaxFiles": 50,
  "mergeMaxFiles": 10,
  "volumeBoostMaxDb": 6,
  "spaceMarginMb": 50,
  "pendingKeepDays": 7,
  "tempMaxAgeHours": 24,
  "upsellCardEveryNthSuccess": 3,
  "heavyUserFiles": 10,
  "exitOfferMinutes": 10,
  "winBackAfterDays": 14,
  "winBackCooldownDays": 90,
  "maxUnrequestedPaywallsPerSession": 1,
  "rating": { "afterRingtones": 2, "afterConversions": 5, "maxTimes": 2, "minDaysBetween": 30, "delayMs": 1500 },
  "milestones": [1, 10, 50],
  "update": { "latest": "1.0.0", "minRecommended": "1.0.0" },
  "ads": { "enabled": true, "provider": "admob", "firstSessionAds": false, "minConversionsBeforeFirstAd": 3, "everyNthConversion": 2, "minSecondsBetween": 180, "maxPerDay": 6, "rewardedMaxPerDay": 2 },
  "moreApps": [ { "id": "shrink", "name": "Shrink: Video Compressor", "appStoreId": "TBD", "pitch": "Make videos smaller, free up GBs" }, { "id": "biblehi", "name": "BibleHi: AI Bible Chat", "appStoreId": "TBD" }, { "id": "imageresizer", "name": "Image Resizer", "appStoreId": "TBD" } ],
  "houseCard": { "everyNthSuccess": 5, "minDaysSinceInstall": 3, "hideDays": 30 }
}
```

## 14. Invite friends / referral (summary; full spec in `12`)

| Rule | Default |
|---|---|
| Login | Optional, only for the inviter. Never asked anywhere except Invite friends / Account |
| Friend reward | 7 days Pro when a valid code is redeemed (no account) |
| Inviter reward | 7 days Pro after the friend's **first successful conversion or ringtone**, only with a verified email |
| Limits | One redeem per iPhone (DeviceCheck), no self-referral, max 10 rewarded invites per inviter per year |
| Where offered | Settings (Account row, Invite friends, Have an invite code?) and Account. Never a pop-up, never during a task, never in the same session as a paywall |
| Config | `referral.enabled`, `referral.friendDays` (7), `referral.inviterDays` (7), `referral.yearlyCap` (10) in `app_config.json` |
