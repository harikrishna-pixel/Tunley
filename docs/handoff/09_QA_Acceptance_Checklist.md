# 09 · QA Acceptance Checklist

Test on a **real iPhone** with iOS 16/17 **and** iOS 26, in light and dark mode, at default and 200% text size. Sandbox Apple Account for purchases.

## Build and iPhone Duo
- [ ] Built with **Xcode 27.1 + iOS 27.1 SDK** (`fvm flutter build ios`); the app launches (UIScene lifecycle) on iOS 27.1 and still on iOS 16
- [ ] iPhone Duo simulator (`tool/duo_sim.sh`): folded (outer display) shows the bottom tab bar; unfolded shows the vertical tab rail and centred content, no letterboxing
- [ ] Fold and unfold mid-flow (Convert, Trim, Progress, Paywall, a sheet, a dialog): the layout follows the new size without restarting, nothing is clipped, the job keeps running
- [ ] Rotate the unfolded display: every screen scrolls, nothing overflows; content stays clear of the status bar strip on every edge
- [ ] Device Hub book pose: no primary button sits in the fold (see question #23)

## Screen transitions
- [ ] Every screen, sheet and dialog uses the transition in `04_Design_System.md` › Screen transitions (push slide, tab cross-fade, fade-through to Result, slide-up paywalls, spring sheets, dialog fade + scale)
- [ ] Swipe-back works on every pushed screen (blocked only while a job runs)
- [ ] Tabs keep their scroll position and state when switching
- [ ] Shared thumbnail animates between screens (Hero)
- [ ] No frame over 16 ms (8 ms on ProMotion) during transitions, measured with the DevTools performance overlay on an older iPhone and a ProMotion iPhone
- [ ] No white flash in dark mode, no flicker, no layout jump when content loads (skeletons)
- [ ] Reduce Motion on: transitions become short cross-fades

## Design
- [ ] All 53 screens + 24 states match `Design/Screens_PNG` in light and dark (spacing, copy, icons, colours)
- [ ] Theme follows the system setting live (switch in Control Centre while the app is open)
- [ ] Dynamic Type 200%: no clipped text, buttons grow, lists scroll
- [ ] VoiceOver: every icon button has a label; waveform handles adjustable with swipe up/down
- [ ] All dialogs/sheets show scrim + blur; one primary button per screen

## Onboarding & personalisation
- [ ] First launch shows O1–O5 → P1; second launch goes straight to Home
- [ ] O2 = Ringtones / MP3 / Convert changes Home hero, Picker start tab, Convert mode and Paywall header (`05` §3)
- [ ] O3 = Rarely: Lifetime is second on P1; P4 max once per 3 sessions
- [ ] Skip on any step → Home with defaults; P1 still shown once
- [ ] Preferences changes apply immediately

## Core conversion
- [ ] Video from Photos (PHPicker) → MP3 256: plays, correct length, size within ±5% of the estimate
- [ ] No Photos permission prompt ever appears
- [ ] Audio file from Files (MP3, M4A, WAV, FLAC) → every free format
- [ ] Pro: FLAC, AAC, OGG outputs open in Files and play
- [ ] Merge (41): 3 files, reorder by drag, remove one, crossfade 0/1/2/3 s audible, total length correct, originals unchanged
- [ ] Standard / High / Best estimates update live; caption appears when the source bitrate is lower
- [ ] Trim: handles, ±1 s nudge, fades audible, preview playback matches the output
- [ ] Volume boost +6 dB: louder, no clipping (check peak ≤ −0.3 dBFS)
- [ ] Merge 3 files (Pro): order kept, crossfade works
- [ ] Progress smooth; Cancel → S1; Stop doesn't count a conversion; temp files removed
- [ ] iOS 26: Run in background keeps going with the system progress UI
- [ ] iOS 16–25: leaving the app pauses the job after the extra time; it shows as Paused, resumes correctly, never counts as a conversion, no corrupted file; captions on 18/21 are shown
- [ ] Original video/audio never modified (compare checksum before/after)

## Free limit & paywalls
- [ ] Counter shows 3 → 2 → 1 → 0 after successes only; failed/cancelled don't count
- [ ] 4th attempt → P3 with a real countdown to local midnight; resets after midnight
- [ ] Setting the clock back doesn't restore uses
- [ ] P2 opens for every Pro control; "Use MP3 instead" switches format and closes
- [ ] P4 card appears after the 3rd success, max once a day
- [ ] P5 after the 10th file, once
- [ ] P6 appears only on the first close of P1, once ever; timer continues after app restart; never shown again after expiry
- [ ] Never two paywalls in a row; never after an error; max 1 unrequested per session
- [ ] Pro users never see the counter, PRO badges, Pro chip, P1–P6, P8

## Trial eligibility
- [ ] With a Sandbox account that already used the trial: P1, P2, P3, P4, P5 show no "free"/"trial" words, real price, correct CTA (states 10d, 11b, 13b); P6 is not shown if not eligible

## Purchases (Sandbox / TestFlight)
- [ ] Prices come from the store (change storefront → prices change); per-week and SAVE % computed
- [ ] Yearly trial: terms line, CTA, timeline dates correct; trial-ineligible account shows the no-trial copy
- [ ] Weekly, Lifetime, Exit offer ($14.99) and Win-back ($17.99) purchase flows
- [ ] Restore with and without purchases (17b Restored / 17d No purchases found)
- [ ] Airplane mode while buying or restoring → 17e Offline; converting still works offline
- [ ] Pending (Ask to Buy) and Failed states
- [ ] Trial reminder notification fires 24 h before the end (use a Sandbox accelerated renewal) and opens P7; in-app P7 if notifications denied
- [ ] Manage subscription opens the system sheet

## Ringtone
- [ ] **Physical iOS 26 device:** sharing the .m4r shows "Use as Ringtone" and it works end-to-end (gate for Store 3 and guide copy; if it fails, switch the guide to GarageBand only and change Store 3)
- [ ] Ringtone mode limits the selection to 30 s; default = loudest window
- [ ] M4R saved; iOS 26: share sheet shows "Use as Ringtone" and it appears in Settings › Sounds & Haptics
- [ ] iOS ≤ 18: GarageBand guide reachable from step 1 and Help
- [ ] Alarm / Text tone gated for free users
- [ ] Milestone "first ringtone" once

## Files
- [ ] First Save to Files asks for the folder (suggests iCloud Drive › Tunely); later saves are silent with toast
- [ ] Delete the app, reinstall: files in the Tunely folder still there
- [ ] Moved/deleted folder → 36b "Can’t find your Tunely folder" → Choose folder again
- [ ] My files filters, play, share, rename (renames the real file), delete (S3)
- [ ] Empty state shows the Shrink card

## Errors
- [ ] DRM file (.m4p) → E4 before converting
- [ ] Video without sound → 35b "This video has no sound"
- [ ] Delete in My files removes only the library copy; the copy in the Tunely folder and the original in Photos remain
- [ ] iCloud-only video offline → E3
- [ ] Low storage (fill the device) → E2 with the real MB
- [ ] Forced engine failure → E1 with code; compatibility mode works
- [ ] iCloud Drive full while saving → E5; Try again works without re-converting
- [ ] Batch with one bad file → S4; others saved

## Ads and cross-promotion
- [ ] Test ad unit IDs only in debug/TestFlight; production IDs only in release
- [ ] No ad in the first session or before the 3rd conversion ever; then every 2nd conversion, ≥ 3 min apart, max 6/day
- [ ] Ad break always shows our notice 42 first; ad appears only after Continue; file is already saved
- [ ] Never an ad on app open/exit, onboarding, during conversion, after an error, after a paywall in the same flow
- [ ] Nothing drawn over the network ad; closing it returns to Result
- [ ] Rewarded on P3 gives +1 only after the reward callback; max 2/day; button hidden if no ad loaded
- [ ] Pro users: zero ads, no 42/44 screens
- [ ] EEA: UMP form before 44/ATT; ATT denied → non-personalised ads, app works the same
- [ ] No fill / airplane mode: no ad, no error, no blank screen
- [ ] Marberx card: capped (once per 5 successes, once/day, not first 3 days, never with an ad break or P4); × hides 30 days
- [ ] More from Marberx opens the App Store sheet inside the app; list comes from config

## Prompts
- [ ] Rating after the 2nd ringtone or 5th conversion; never after an error; 4–5★ Apple sheet, 1–3★ feedback; max twice
- [ ] Notification pre-prompt only before the first batch / at trial start
- [ ] Update sheet once per version (config)

## Account and referral (V1.3)
- [ ] Every feature (convert, ringtone, save, buy, restore) works without an account; login is asked only from Invite friends / Account
- [ ] Create account: inline validation, existing-email message, live code preview; Terms & Privacy links open
- [ ] Sign in error is generic; 5 wrong attempts → 15-min lock message; reset shows "If an account exists…" and Resend after 60 s
- [ ] Verify-email banner; inviter reward held until verified
- [ ] Friend opens an invite link on a fresh install → 53 prefilled → 7 days Pro unlocked (no account)
- [ ] Inviter gets 7 days Pro only after the friend's first successful conversion; stats on 47 update
- [ ] Same iPhone can't redeem twice (DeviceCheck, also after reinstall); self-referral rejected; cap 10/year shows the limit message
- [ ] Delete account works in-app with password; files and Pro subscription unaffected; signed out afterwards
- [ ] Offline on every form shows the inline offline message; typed data kept

## Analytics
- [ ] All checks in `08_Analytics_Events.md` › QA checks pass

## App Store
- [ ] 8 screenshots uploaded (6.9"); description contains "Some features require a Tunely Pro subscription." and auto-renew terms
- [ ] Privacy nutrition label matches the SDK table in `06` (incl. advertising data and tracking if ATT allowed)
- [ ] `PrivacyInfo.xcprivacy` present for the app and every ad SDK/adapter; `app-ads.txt` live
- [ ] LAME licence listed in Settings › Licences **and written legal sign-off received** (release gate)
- [ ] Every claim in `14_Traceability_and_Compliance.md` › Claims register has evidence
- [ ] Captions (`text3`) and success text reach ≥ 4.5:1 contrast in both themes
