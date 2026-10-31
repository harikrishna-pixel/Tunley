# 14 · Traceability and Compliance

One place to check that every feature is designed, specified, tracked, tested and honestly marketed. If a row is incomplete, the feature is not ready.

## 1. Feature traceability matrix

| Feature | Free / Pro | Screens | Rules | Analytics events | QA (09) | Store / paywall claim |
|---|---|---|---|---|---|---|
| Video → MP3/M4A/WAV | Free (3/day) | 06, 07, 08, 18, 09 | 05 §1, §4 | file_picked, task_started/completed/failed | Core conversion | Store 2 · "Video to MP3" |
| FLAC / AAC / OGG output | Pro | 08, 11, 11b | 05 §1–2 | pro_feature_tapped, task_completed | Core conversion | Store 4 · paywall "FLAC, AAC, OGG formats" |
| Quality presets + estimated size | Free | 08 | 05 §4 | settings_changed | Core conversion | Store 2 "See the file size before you convert" |
| Ringtone (M4R, 30 s, fades) | Free (counts as conversion) | 08b, 18, 09b | 05 §7 | ringtone_created | Ringtone | Store 1 |
| Alarm / Text tone | Pro | 08b, 11 | 05 §7 | pro_feature_tapped | Ringtone | Paywall header (ringtone goal) |
| Ringtone guide | Free | 20, 20b, 20c | 05 §7 | guide_opened, guide_step_viewed, guide_completed | Ringtone (physical iOS 26 test) | Store 3 (provisional until tested) |
| Trim & fade | Free | 19 | 05 §7 | trim_applied | Core conversion | Store 5 |
| Volume boost | Pro | 19, 11 | 05 §1 | trim_applied (boost_db), pro_feature_tapped | Core conversion | Paywall "volume boost" |
| Merge audio | Pro | 41, 07, 18, 09 | 05 §11 | merge_started, merge_completed | Core conversion (Merge) | Paywall "Merge audio" |
| Batch up to 50 | Pro | 07, 21, 40, 27 | 05 §9 | batch_started, batch_completed, background_interrupted | Core + Errors | Store 6 · paywall "Batch 50 files" |
| My files library | Free | 22, 38, 39 | 05 §8 | file_played, file_renamed, file_deleted | Files | – |
| Save to Tunely folder | Free | 09, 23, 36, 36b | 05 §8 | file_saved, save_folder_chosen | Files | MyFiles footer "kept even if you delete the app" (folder copy only) |
| Free limit 3/day | Free | 06, 09, 12, 09c | 05 §1 | limit_reached, task_completed.free_left | Free limit & paywalls | Onboarding O4 · description |
| Situational paywalls P1–P9 | – | 10–17, 10d, 11b, 13b, 17d, 17e | 05 §2, 07 | paywall_viewed (trial_eligible), purchase_* | Trial eligibility, Purchases | Description pricing + terms |
| Trial reminder | – | 27, 15 | 07 | trial_reminder_scheduled, trial_reminder_opened | Purchases | O4 "Allow notifications and we'll remind you" |
| Personalisation | Free | 02, 03, 24, 06b, 06c, 10b, 10c | 05 §3 | onboarding_question_answered, preferences_changed | Onboarding | – |
| Ads (ad break + rewarded) | Free only | 42, 43, 44, 12 | 05 §12 | ad_* events, tracking_result | Ads and cross-promotion | O4 "Short ads, never mid-task" · paywall "No ads" |
| More from Marberx | All (rare for Pro) | 45, 09d, 38 | 05 §13 | house_card_*, more_apps_* | Ads and cross-promotion | – |
| Merge (store) | Pro | 41 | 05 §11 | merge_* | Core | Store 7 "Join songs into one mix" |
| Account + referral (optional) | Free | 23, 46–53 | 12 | invite_*, signup_*, login_*, referral_* | Account and referral | "No login needed" stays true: account is optional |
| Privacy (on-device) | All | 05, 18, 09 | 06 | – | App Store | Store 8 "Converted on the device, never uploaded" |

## 2. Claims register (evidence required before submission)

| Claim | Where | Evidence needed | Status |
|---|---|---|---|
| "Done in 3 s" | Store 2 chip | Benchmark: 40-s 1080p clip → MP3 256 on iPhone 13 and newest iPhone, median of 10 runs | To verify |
| "See the file size before you convert" | Store 2, 08 | Estimate within ±5% on 20 test files | To verify |
| "MP3, M4A, WAV, FLAC, AAC, OGG" | Store 4 | Each output plays in Files, Music and VLC | To verify |
| "No GarageBand needed on iOS 26" / "Use as Ringtone" | Store 3, 20, description | Physical iOS 26 device test end-to-end | **Provisional** |
| "Short ads, never mid-task" / "Pro removes ads" | O4, 42, paywall | QA: no ad during conversion; Pro build shows zero ads | To verify |
| "Converted on the device, never uploaded" | Store 8, 18, 09, O4, O5 | Network capture during conversion shows no file upload | To verify |
| "Copies … kept even if you delete the app" | 22 footer, Help | Delete/reinstall test with iCloud Drive › Tunely folder | To verify |
| "Batch 50 files at once" | Paywall | 50-file batch completes on iOS 26 and resumes on iOS 16–25 | To verify |
| "We remind you a day before" | O4, description | Wording conditional on notifications; scheduling test in Sandbox | Wording fixed |

## 3. Supported-iOS capability table

| Capability | iOS 16–17 | iOS 18–25 | iOS 26+ |
|---|---|---|---|
| Single conversion in background | ~30 s extra, then pauses | Same | Continues (`BGContinuedProcessingTask`) |
| Batch / merge in background | Pauses when suspended, resumes on return | Same | Continues with system progress UI |
| Set ringtone | GarageBand guide | GarageBand guide | Share sheet "Use as Ringtone" (verify) + GarageBand fallback |
| Win-back offer | Promotional offer | Apple win-back offer (18+) | Apple win-back offer |
| 120 Hz animations | ProMotion devices | ProMotion devices | ProMotion devices |

## 4. Release gates (all must be ✓)

- [ ] Written legal sign-off for LAME (MP3) distribution method (`11` #1)
- [ ] Terms and Privacy pages live; same URLs in paywall, Settings and App Store
- [ ] App Privacy answers match the SDK table in `06` and a real network capture
- [ ] Every claim in §2 has evidence or the claim is removed
- [ ] iOS 26 ringtone route verified (or Store 3 + guide switched to GarageBand wording)
- [ ] Exit offer product and eligibility tested in Sandbox
- [ ] In-app account deletion works (Guideline 5.1.1(v)); App Privacy includes name + email (linked) for accounts
- [ ] Referral API with `app_id = "tunely"` live; Branch link domain verified
- [ ] All of `09_QA_Acceptance_Checklist.md` passes
