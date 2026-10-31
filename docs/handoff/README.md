# Tunely – MP3 & Ringtone Maker (iOS) · Developer Handoff

**Version:** V1.3 handoff · 25 Oct 2026 (invite friends / referral with optional login: see `CHANGELOG.md`) · **Design: Direction A “Refined Premium” (violet), light + dark mode** · **Stack: Flutter (iOS first, Android later) + small native Swift audio engine**
**Owner / product director:** Praba (Marberx Technologies)
**Working app name:** "Tunely – MP3 & Ringtone Maker". This is a placeholder until App Store name and trademark checks are done (see `11_Open_Questions.md`).
**Design canvas (live, clickable):** https://claude.ai/artifact/GPcEZ5n3JQkurP7F4SCKvg

---

## What this app is

An iPhone app that **turns any video into an MP3**, **converts audio between formats**, and **makes ringtones** (trim the best 30 seconds, fade in/out, then set it with a step-by-step guide). Everything happens **on the iPhone**. Nothing is uploaded.

Business model: **subscription with an honest free tier** (3 free conversions every day, full quality, no watermark). **Light ads** for free users (ad break after saving, rewarded +1 conversion; Pro removes ads) and gentle **More from Marberx** cross-promotion. **Invite friends** referral (both get 7 days Pro) with an optional account used only for rewards.

---

## Read in this order

| # | File | What it gives you |
|---|------|-------------------|
| 0 | `00_Research.md` | Competitors, review pains vs loved features, onboarding and store-screenshot teardown: *why* the app looks like this |
| 1 | `01_Product_Requirements.md` | Scope, features, Free vs Pro, what "done" means |
| 2 | `02_Screens_and_States.md` | Every screen (53 + 24 states) with purpose, contents, entry/exit |
| 3 | `03_Navigation_Flows.md` | How screens connect (diagrams) |
| 4 | `04_Design_System.md` + `design-tokens.json` | Light + dark colour tokens, Plus Jakarta Sans, Phosphor icons, spacing, components, motion |
| 5 | `05_Business_Rules.md` | Free limit, premium trigger map, personalisation map, rating rules, errors, ringtone rules, conversion presets |
| 6 | `06_Technical_Architecture.md` | Flutter stack, folders, native plugin API, encoders (MP3/FLAC/OGG), file storage |
| 7 | `07_Monetization_StoreKit.md` | Products, prices, entitlement, situational paywalls, exit/win-back offers |
| 8 | `08_Analytics_Events.md` | **Analytics platform, naming rules, user properties, the full event table**, funnels, QA |
| 9 | `09_QA_Acceptance_Checklist.md` | Test cases that must pass before release |
| 10 | `10_Roadmap_and_Out_of_Scope.md` | What is NOT in V1.0 |
| 11 | `11_Open_Questions.md` | Decisions still pending, each with a default so you're never blocked |
| 12 | `12_Account_and_Referral.md` | Optional login (only for invite rewards), auth API, referral code, deep links, rewards, anti-abuse, account deletion |
| 13 | `13_Growth_and_Marketing_Plan.md` | Onboarding, personalisation, paywalls, triggers, self-marketing, A/B tests |
| 15 | `15_Help_FAQ.md` | Full Help & FAQ text for the app and the support web page |
| 14 | `14_Traceability_and_Compliance.md` | Feature → screen → event → test → store claim matrix, claims register, iOS capability table, release gates |

## Folders

| Folder | Contents |
|--------|----------|
| `Design/Screens_PNG/Light/` | All 53 screens, light mode (onboarding first: 01–05), 1170 × 2532 (@3x of 390 × 844 pt). File numbers match `02_Screens_and_States.md` |
| `Design/Screens_PNG/Dark/` | The same 53 screens in dark mode |
| `Design/Screens_PNG/States/` | 24 extra states (Home per goal, Audio tab, Ringtone mode, Ringtone result, upsell card, Paywall per goal, **trial-ineligible paywalls**, Purchase restored/pending/none/offline, no-sound video, folder not found, Guide steps 2–3, sign-in error, reset sent, invite code success/invalid), light + dark |
| `Design/Overview_All_Screens_Light.png` / `_Dark.png` | All 53 screens on one image, starting with the onboarding screens (8 per row) |
| `Design/HTML_Source/` | Design source of every screen: exact colours, sizes, spacing, copy. See its README |
| `Design/Images/` | Sample photos used in the mock-ups (placeholders only) |
| `Fonts/` | Plus Jakarta Sans TTF (400–800) + OFL licence → copy to `assets/fonts/` |
| `AppStore/` | 8 App Store screenshots (1290 × 2796, 6.9") + listing copy |
| `Cursor/` | Cursor rules file and step-by-step Flutter build prompts |

## How to use this with Cursor

1. Create the **Flutter** project (iOS 16+ first, Android later; see `06_Technical_Architecture.md`). Audio conversion runs in a small native Swift plugin inside the repo.
2. Copy this whole folder into the repo as `/docs/handoff/`.
3. Copy `Cursor/tunely.mdc` to `.cursor/rules/tunely.mdc`.
4. Run the prompts in `Cursor/CURSOR_BUILD_PROMPTS.md` **one phase at a time**. Check each phase against `09_QA_Acceptance_Checklist.md` before moving on.

## Ground rules (non-negotiable)

- **Never change or delete the user's original video or song.** Tunely only reads it and writes a new file.
- **No file ever leaves the device.** No upload, no cloud conversion.
- **No full Photos access.** Use the system picker (PHPicker), so the user only shares the files they choose.
- **Ads only between tasks**, after the file is saved, with our notice first; never over or during anything else; none for Pro (`05` §12). Cross-promotion is gentle and capped (`05` §13).
- **Honest free tier:** 3 free conversions a day, always visible. Failed or cancelled conversions never use a free conversion.
- **Trial reminder:** if the user allows notifications, schedule a reminder one day before a trial ends (screen 15); in-app fallback otherwise. Never word it as guaranteed.
- **Release gates:** legal sign-off for LAME (MP3), live Terms/Privacy URLs, iOS 26 ringtone route tested on a real device, every store claim backed by evidence (`14`).
- **Every screen works in light and dark mode.**
- **Toasts are information only.** Anything that needs a decision gets a full screen or sheet.
- **Analytics:** every event in `08_Analytics_Events.md`, through one `Analytics` service. No file names, no personal data.
- Pixel details come from the PNGs + HTML source. Behaviour comes from these documents. If they conflict, ask Praba.
