# 02 · Screens and States

53 screens + 24 extra states. PNGs: `Design/Screens_PNG/Light|Dark/<file>.png` and `Design/Screens_PNG/States/Light|Dark/`. HTML source: `Design/HTML_Source/<Source>.dc.html`.
Every screen exists in light and dark. Overlays (sheets / dialogs) sit on the `scrim` colour + 10 pt background blur.

Tabs: **Home · My files · Settings**.

## A. Onboarding (first launch only, shown first in the PNG folder and overview)

| # | File | Screen | Source | Content | Notes |
|---|------|--------|--------|---------|-------|
| 01 | 01_O1_Value_demo | O1 Value demo | `Onb1` | Video → ringtone visual, "Any video, your ringtone", Continue, Skip | |
| 02 | 02_O2_What_to_make | O2 What do you want to make? | `Onb2` | Ringtones / MP3 from videos / Convert audio files (single choice) | Saves `goal` → personalisation (`05` §3) |
| 03 | 03_O3_How_often | O3 How often? | `Onb3` | Every day / A few times a week / Just once in a while | Saves `frequency` |
| 04 | 04_O4_Honest_and_simple | O4 Honest & simple | `Onb4` | 3 free/day · Short ads, never mid-task · Trial reminder · Made on your iPhone | Must stay true: these are promises |
| 05 | 05_O5_Privacy | O5 Privacy | `Onb5` | "Your library stays private", Get started | → P1 paywall (closable) → Home |

Skip on any step → Home with defaults (goal = ringtone, frequency = weekly). Skip still shows P1 once.

## B. Core flow

| # | File | Screen | Source | What's on it | Comes from → goes to |
|---|------|--------|--------|--------------|----------------------|
| 06 | 06_Home | Home | `Home` | Logo, Pro chip (free users only), **personalised hero** (goal from O2: ringtone / MP3 / convert) with one CTA, Tools grid (Video to MP3, Convert format, Trim & fade, Merge audio PRO, Volume boost, Batch convert PRO), free counter "2 of 3 free today", Recent (2 latest), tab bar | App launch, tabs → 07 (hero / tool), 09 (recent), 10 (Pro chip) |
| 07 | 07_Choose_a_file | Choose a file | `Picker` | Tabs Videos / Audio files / Recent; grid with durations; selection footer "1 video selected · 0:42"; "Batch up to 50 files with Pro" hint; Continue. Videos come from **PHPicker** (system picker, no library permission) | 06 → 08 (single), 21 (multi, Pro) |
| 08 | 08_Convert_settings | Convert | `Convert` | Source card, segmented **Audio file / Ringtone**, Format chips (MP3 M4A WAV free · FLAC AAC OGG with PRO badge), Quality radio cards with **estimated output size** (shown as "~1.3 MB"), Trim & fade row, footer summary "MP3 · 256 kbps · 0:42 ~1.3 MB (from 86 MB)", primary "Convert to MP3" | 07 → 18 → 09 · PRO chip → 11 |
| 09 | 09_Result | Done | `Result` | Success header, hero player card (play, waveform, file name/meta), stats (input size / output size / time), cross-sell row ("Make it a ringtone" or "Also save as MP3"), primary **Save to Files** (or **Set as ringtone**) + Share icon, quiet free line "1 of 3 free left · Go unlimited" | 18 → 20 (ringtone), Files, Share |

## C. Paywalls and offers (rules in `05` §2, products in `07`)

| # | File | Screen | Source | Content |
|---|------|--------|--------|---------|
| 10 | 10_P1_Main_paywall | P1 Main paywall | `Paywall` (`goal`, `eligible` props) | Header per goal ("Unlimited ringtones, alarms & text tones" / MP3 / convert), 4 benefits, **trial timeline** Today / Day 2 Reminder / Day 3 charge (hidden when not eligible, state 10d), plans Yearly (pre-selected, $0.58/wk, SAVE 88%) / Weekly $4.99 / Lifetime $39.99, terms line changes per plan, CTA, Restore · Terms · Privacy, close X always visible |
| 11 | 11_P2_Pro_feature_sheet | P2 Pro feature tapped | `FeatureSheet` | Bottom sheet over Convert: "FLAC is a Pro format", 3 benefits, "Try Pro free for 3 days", **"Use MP3 instead (free)"** |
| 12 | 12_P3_Daily_limit | P3 Daily limit reached | `LimitReached` | Dialog over Home: "3 of 3 free conversions used today", **real countdown** to midnight, Get unlimited / **Watch a short ad for 1 more** (rewarded, max 2/day) / Come back tomorrow |
| – | States/09c | P4 Upsell card | `Result upsell=true` | Card inside Result after the 3rd success of the day: "3 files today — you're a natural · Go unlimited · 3 days free" (no pop-up) |
| 13 | 13_P5_Heavy_user | P5 Heavy user | `HeavyUser` | Dialog after the 10th file: stats (MP3s / ringtones / converted), Yearly at $2.50/mo, Start free trial / Not now |
| 14 | 14_P6_Exit_offer | P6 Exit offer | `ExitOffer` | Dialog over P1 after its first close, **once ever**: 50% OFF first year $14.99, real 10-minute timer, Claim / No thanks |
| 15 | 15_P7_Trial_ends_tomorrow | P7 Trial reminder | `TrialReminder` | Timeline (started / today reminder / charge date), Keep Pro, **Manage or cancel subscription** |
| 16 | 16_P8_Win_back | P8 Win-back | `WinBack` | Returning lapsed user: last ringtone, 40% off first year $17.99, valid until date |
| 17 | 17_P9_Purchase_result | P9 Purchase result | `PurchaseResult` (`state`) | Failed (default) / Restored / Pending (States 17b, 17c) |

## D. Flow screens

| # | File | Screen | Source | Content |
|---|------|--------|--------|---------|
| 18 | 18_F1_Converting | Converting | `Progress` | Progress ring %, time left, "Dance_night.mov → MP3", "nothing is uploaded", Run in background + caption "On iOS 26 it keeps going. On older iOS it may pause until you come back.", Cancel (→ 37) |
| 19 | 19_F2_Trim_and_fade | Trim & fade | `TrimEditor` | Playhead time, waveform with handles, selected range, −1 s / play / +1 s, Fade in, Fade out (2 s default), Volume boost (Pro · up to +6 dB), Done |
| 20 | 20_F3_Ringtone_guide | Ringtone guide | `RingtoneGuide` (`step` 1–3) | Step 1 "Tap Use as Ringtone" with share sheet mock + "Open share menu"; step 2 & 3 in States (20b, 20c). Link "On iOS 18 or older? Use the GarageBand way" |
| 21 | 21_F4_Batch | Batch convert (Pro) | `Batch` | Overall progress "3 of 8 done", per-file rows (done / converting % / waiting), background caption per iOS version, Stop, Run in background |
| 22 | 22_F5_My_files | My files | `MyFiles` | Filters All / Audio / Ringtones / Alarms, rows with play + more menu (Share, Rename, Set as ringtone, Delete), footer "Copies saved to your Tunely folder in Files, kept even if you delete the app" (see `05` §8) |
| 23 | 23_F6_Settings | Settings | `Settings` | Pro card (free users), Your preferences (What I make, Default format, Save to), **Account row** ("Sign in or create account · Optional · only for invite rewards"; signed in → 51), Help & more (**Invite friends · Get Pro free** → 46/47, **Have an invite code?** → 53, How to set a ringtone, Help & FAQ, Rate Tunely, More apps from Marberx), Subscription (Restore, Manage), footer links Terms · Privacy · Licences (Flutter `showLicensePage` + LAME/Vorbis notices) · Version |
| 24 | 24_F7_Your_preferences | Your preferences | `Preferences` | Same questions as O2/O3, editable |
| 41 | 41_F9_Merge_audio | Merge audio (Pro) | `Merge` | Hero summary "4 files · 3:42 total" + preview play, numbered rows with drag handle, thumbnail, name, duration, remove ×; "Add" (→ 07 multi-select); Crossfade segmented Off / 1 s / 2 s / 3 s; "Save as" row (format · bitrate · ~size → 08 settings); primary "Merge 4 files"; caption "2 to 10 files · originals are not changed" |
| 25 | 25_F8_Help | Help & FAQ | `Help` | Search + 7 expandable questions (full text in `15_Help_FAQ.md`), Contact support (mail with app version + iOS, no files) |

## E. Prompts and self-marketing (rules in `05` §5)

| # | File | Screen | Source | Content |
|---|------|--------|--------|---------|
| 26 | 26_M1_Rating | Rating pre-prompt | `Rating` | Over Result: "Your ringtone is ready! Enjoying Tunely?" 5 stars → 4–5★ Apple review sheet, 1–3★ feedback form |
| 27 | 27_M2_Notification | Notification pre-prompt | `Notify` | Over Batch: "Get a ping when it's done" (also used for the trial reminder), Turn on / Not now |
| 28 | 28_M3_Toasts | Toasts (catalogue) | `Toasts` | All toast types: success, info, warning. Info only, 3 s (5 s with action) |
| 29 | 29_M4_Update | What's new / update | `Update` | Dialog over Home with version, 3 bullets, Update now / Later |
| 30 | 30_M5_Milestone | Milestone | `Milestone` | "Your first ringtone!" (also 10 and 50 files), Share my ringtone / Close |
| 31 | 31_M6_Share_card | Share card | `ShareCard` | Sheet with a branded card "Made with Tunely" + AirDrop / Messages / Copy link / More |

## F. Errors and states (rules in `05` §6)

| # | File | Screen | Source | When |
|---|------|--------|--------|------|
| 32 | 32_E1_Conversion_failed | Conversion failed | `ConvFailed` | Engine error; shows % reached, cause, error code, **Try compatibility mode (AAC)** |
| 33 | 33_E2_No_storage | Not enough space | `NoStorage` | Free space < needed; real MB, 3 tips, Check again / How to free up space (help sheet; iOS has no public link to iPhone Storage) |
| 34 | 34_E3_iCloud | iCloud file not downloaded | `CloudError` | Download failed/slow; size, Low Data Mode hint, Try again / Pick another |
| 35 | 35_E4_Copy_protected | Copy-protected file | `Unsupported` | DRM file (.m4p etc.); Choose another / What can I convert? · State 35b: video with **no audio track** |
| 36 | 36_E5_Save_failed | Save failed | `SaveFailed` | Writing to Files failed; file kept in Tunely for 7 days, Save on this iPhone instead / Try again / Share instead · State 36b: **Tunely folder not found** (stale bookmark) → Choose folder again |
| 37 | 37_S1_Stop_converting | Stop converting? | `CancelConfirm` | Cancel tapped on 18; "won't use a free conversion" |
| 38 | 38_S2_My_files_empty | My files empty | `EmptyFiles` | No files yet; Make your first sound; "More from Marberx" card (Shrink) |
| 39 | 39_S3_Delete_file | Delete file | `DeleteConfirm` | "Delete from Tunely": removes the **library copy only**. Copies in the user's Tunely folder in Files and the original in Photos are kept (both stated in the dialog) |
| 40 | 40_S4_Batch_partial | Batch partial failure | `BatchPartial` | Batch done with failures; finished files already saved, Retry failed (n) |

## H. Ads and cross-promotion (rules in `05` §12–13)

| # | File | Screen | Source | Content |
|---|------|--------|--------|---------|
| 42 | 42_A1_Ad_break | Ad break notice | `AdBreak` | Dialog over Result: "Your MP3 is saved" ✓, "A short ad helps keep Tunely free. You'll be right back here after it.", **Continue** → 43, "Remove ads with Pro" → P1 |
| 43 | 43_A2_Ad_network_screen | Network ad | `AdState` | Placeholder for the full-screen interstitial/rewarded ad drawn by AdMob / LevelPlay. Tunely draws nothing on top; close → Result |
| 44 | 44_A3_Ads_and_tracking | Ads & tracking pre-prompt | `AdsConsent` | "Tunely is free, thanks to a few ads": ads only between tasks · files never leave your iPhone · next iPhone asks about tracking, either answer is fine. Continue → (UMP in EEA) → system ATT prompt; "Prefer no ads? See Pro" |
| 45 | 45_X1_More_from_Marberx | More from Marberx | `MoreApps` | "Picked for you" app card (Shrink, reason line), "Also from us" list (BibleHi, Image Resizer), Get buttons → App Store sheet; footer "No tracking, no rewards for installs" |
| – | States/09d | Result + Marberx card | `Result promo=true` | Small dismissible card "From the makers of Tunely · Shrink: Video Compressor · That video was 86 MB…" with View and × |

## F2. Account and referral (V1.3, optional login, rules in `12`)

Login is **only** for people who want the referral reward. Everything else works without an account.

| # | PNG | Screen | Source | Contents |
|---|-----|--------|--------|----------|
| 46 | 46_R1_Invite_friends_signed_out | Invite friends (signed out) | `ReferralSignedOut` | Photo, "Give 1 week · Get 1 week", "Invite friends, get Pro free", 3 steps, locked link `tunely.app/i/••••••`, privacy line, **Create free account**, "I already have an account" |
| 47 | 47_R2_Invite_friends | Invite friends (signed in) | `Referral` | Email chip, offer, link + code with Copy, stats (Friends joined / Pro earned / Pending), **Share invite link** |
| 48 | 48_R3_Create_account | Create account | `SignUp` | First name, Last name, Email, Password (show/hide, rule hint), live "Your invite code will be ANNA7K", Terms & Privacy line, Sign in link |
| 49 | 49_R4_Sign_in | Sign in | `SignIn` | Email, Password, Forgot password, Create account link. State 49b: "Email or password is incorrect" |
| 50 | 50_R5_Reset_password | Reset password | `ForgotPassword` | Email, Send reset link. State 50b: "Check your email" (no account enumeration), Resend after 60 s |
| 51 | 51_R6_Account | Account | `Account` | Name/email, **Verify your email** banner + Resend, invite code + "Use random code", Free Pro earned, Invite friends, Change password, Sign out, note "Pro is linked to your Apple ID", **Delete account** |
| 52 | 52_R7_Delete_account | Delete account | `DeleteAccount` | What is permanently deleted vs not affected (files, Pro subscription), password confirm, Delete account / Keep my account |
| 53 | 53_R8_Redeem_invite_code | Redeem invite code (no login) | `InviteCode` | Code field, "Added from your friend's link" when deep-linked, Apply code / Skip. States 53b success ("1 week of Pro unlocked… Make a file"), 53c invalid |

## G. Extra states (`Design/Screens_PNG/States/`)

| File | What |
|------|------|
| 06b_Home_goal_MP3 / 06c_Home_goal_Convert | Home hero per onboarding goal |
| 07b_Picker_Audio_tab | Picker on Audio files tab (goal = convert opens here) |
| 08b_Convert_Ringtone_mode | Convert in Ringtone mode: Ringtone / Alarm / Text tone, 30 s selection, fades, "M4R ringtone · 30 s", Create ringtone |
| 09b_Result_Ringtone | Result for a ringtone: primary "Set as ringtone" |
| 09d_Result_More_apps_card | Result with the gentle Marberx cross-promo card |
| 09c_Result_P4_upsell_card | P4 upsell card |
| 10b / 10c Paywall goal MP3 / Convert | Paywall header per goal |
| 17b / 17c Purchase restored / pending | P9 states |
| 17d Purchase none found / 17e Purchase offline | Restore found nothing · no internet when buying/restoring ("Converting still works without internet") |
| 10d Paywall no trial / 11b Pro sheet no trial / 13b Heavy user no trial | **Trial-ineligible** versions: no "free" wording, real renewal price, CTA "Continue" / "Get Tunely Pro" / "Get Yearly" |
| 35b E4 No sound | Input video has no audio track |
| 36b E5 Folder not found | Bookmarked Tunely folder moved/deleted |
| 20b / 20c Ringtone guide step 2 / 3 | Guide steps |
| 49b Sign in error · 50b Reset link sent · 53b Code success · 53c Code invalid | Account and referral states |

## Toasts (never for decisions)

Saved to Files › Tunely (Open) · Ringtone added (find it in Sounds) · Copied to clipboard · Converting in the background · "2 of 3 free conversions left today" (Go Pro) · Welcome to Tunely Pro! · File is still downloading from iCloud… · Couldn't convert this file (Details → E1).
