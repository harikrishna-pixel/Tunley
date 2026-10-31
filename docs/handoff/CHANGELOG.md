# Changelog: Tunely handoff



## V1.3 · 25 Oct 2026 (Invite friends / referral, optional login)

- **Referral is now standard in every Marberx app** (Praba's decision). Login is optional and **only** for people who want the invite reward; converting, ringtones, buying and restoring never need an account.
- 8 new screens: 46 Invite friends (signed out), 47 Invite friends (signed in), 48 Create account, 49 Sign in, 50 Reset password, 51 Account, 52 Delete account (in-app, Apple 5.1.1(v)), 53 Redeem invite code (no login). States 49b, 50b, 53b, 53c.
- Settings (23): Account row "Optional · only for invite rewards", Invite friends · Get Pro free, Have an invite code?.
- Rewards: friend 7 days Pro on redeem; inviter 7 days Pro after the friend's first successful conversion (verified email). One redeem per iPhone (DeviceCheck), cap 10/year, `app_id = "tunely"` on the existing Marberx auth/referral API.
- Docs: `12` full spec (was "not used"), `01` F19, `02` section F2, `03` flow 6b + invite deep links, `06` stack + SDK table (auth API, Branch), `07`, `08` account/referral events + funnel, `09` QA section, `10`, `11` #20–22, `13`, `14` matrix row + release gates, `15` 4 new FAQ answers, App Store privacy + review notes, Cursor Phase 9b.
- Totals: **53 screens + 24 states**.

## V1.2 · 25 Oct 2026 (ads in V1, cross-promotion, FAQ, onboarding-first order)

- **Ads are in V1.0** (AdMob or ironSource/LevelPlay mediation behind one `AdsService`): new screens 42 Ad break notice, 43 Network ad, 44 Ads & tracking pre-prompt; rewarded "Watch a short ad for 1 more" on P3. Rules and caps in `05` §12. Pro removes ads ("No ads" added to paywall, Pro sheet, Settings).
- Removed every "No ads. Ever." promise: O4 now "Short ads, never mid-task"; App Store screenshot 7 is now **"Join songs into one mix"** (Merge); listing, research and growth plan updated; App Privacy now includes advertising/tracking.
- **Gentle cross-promotion:** new screen 45 More from Marberx, small capped Result card (state 09d), empty My files card. Rules in `05` §13.
- **New `15_Help_FAQ.md`**: full Help & FAQ text (35 questions); Help screen now has 7 questions incl. "Why do I see ads?".
- **PNG order:** onboarding screens are now 01–05 (then Home 06, Choose a file 07, Convert 08, Result 09). The overview image and all docs use the new numbers; screens 10–45 keep their numbers.
- New analytics events for ads, tracking, consent and cross-promotion (`08`), QA items (`09`), traceability rows (`14`), open questions #18–19.

## V1.1 · 25 Oct 2026 (external review fixes)

**New screens / states**
- 41 Merge audio (Pro): reorder, remove, preview, crossfade, Save as.
- Trial-ineligible paywalls: 10d Paywall, 11b Pro sheet, 13b Heavy user. Every paywall checks eligibility.
- 17d Restore: no purchases found · 17e Offline purchase/restore.
- 35b Video has no sound · 36b Tunely folder not found.
- Settings now shows Terms · Privacy · Licences · Version.

**Copy and honesty fixes**
- "Run in background" caption per iOS version (iOS 16–25 may pause).
- Trial reminder no longer promised as guaranteed ("Allow notifications and we'll remind you"); timeline says "Reminder".
- Delete removes the library copy only (dialog says so; button "Delete from Tunely").
- "Open iPhone Storage" → "How to free up space" (no public iOS link).
- "Exact size" → estimated size; Store 4 "All popular formats"; Store 7 chip "Zero ads, free or Pro"; Store 8 "Private. Made on your iPhone".
- AIFF output and custom bitrate removed from V1.0 (moved to `10` V1.1).
- Darker `text3` and light `success` tokens for ≥ 4.5:1 contrast.

**Docs**
- New `14_Traceability_and_Compliance.md` (traceability matrix, claims register, iOS capability table, release gates).
- One presentation type per screen (`04` › Presentation per screen).
- `05` §9 background behaviour per iOS, §11 Merge rules, trial-eligibility rule, exit-offer decision recorded.
- `06` SDK data / App Privacy table, LAME legal release gate, removed invalid Info.plist key.
- `07` exit offer = eligibility-checked introductory price (no promotional offer for new users).
- `08` new events (merge_started, background_interrupted, job_resumed, purchase_offline, trial_reminder_scheduled), `trial_eligible` property, Marberx-wide standard names.
- `09` tests for all of the above.

## Update · 25 Oct 2026 (earlier)
- Added **Screen transitions** spec (`04_Design_System.md`): transition for every movement, 60/120 fps smoothness rules, Reduce Motion, acceptance tests. Also added to the Cursor rules file, build prompts (Phase 1 + final hardening phase) and `09_QA_Acceptance_Checklist.md`.


## V1.0 · 24 Oct 2026

- First complete handoff: 40 screens + 12 states, light + dark, Direction A "Refined Premium" (violet).
- Docs 00–13 incl. research, situational paywalls, personalisation map and the full analytics event table.
- App Store: 8 screenshots (1290 × 2796) with no Pro badges, credits, limits or prices; Pro features shown unlabelled. Description carries the 2.3.2 disclosure line.
- Copy fixes during handoff:
  - Paywall benefits now "FLAC, AAC, OGG formats" (WAV is free) and "Merge audio, volume boost" (speed isn't in V1.0).
  - File location copy: "Copies saved to your Tunely folder in Files, kept even if you delete the app" (the app's own folder is removed by iOS on deletion; see `05` §8).
