# 01 · Product Requirements: Tunely V1.0

## Goal

Let anyone with an iPhone **turn a video into an MP3**, **convert audio to another format**, and **make a ringtone they can actually set**, in a few taps, on the device, with an honest free tier.

## Target users

General iPhone users (not audio professionals): people who saw a song in a video and want it as a ringtone, want the sound of a clip as an MP3, or need a file in a different format for another app.

## Success metrics (first 90 days)

| Metric | Target |
|--------|--------|
| Onboarding completion | ≥ 75% |
| First conversion within the first session | ≥ 60% of new users |
| Ringtone guide completion (step 3 reached) | ≥ 50% of ringtones made |
| Trial start rate (of new users) | ≥ 8% |
| Trial → paid | ≥ 35% |
| Crash-free sessions | ≥ 99.5% |
| App Store rating | ≥ 4.6 |

## V1.0 features

| # | Feature | Free | Pro |
|---|---------|------|-----|
| F1 | **Video → audio** (from Photos via system picker, or Files) | MP3, M4A, WAV | + FLAC, AAC, OGG |
| F2 | **Convert audio format** (audio file from Files / other apps) | MP3, M4A, WAV | + FLAC, AAC, OGG |
| F3 | **Quality presets** Standard 128 / High 256 (default) / Best 320 kbps, with estimated output size | ✓ | ✓ |
| F4 | **Ringtone maker**: pick up to 30 s, fade in/out, save as M4R | Ringtone | + Alarm and Text tone types |
| F5 | **Ringtone setup guide** (iOS 26 share sheet "Use as Ringtone"; GarageBand guide for iOS ≤ 18) | ✓ | ✓ |
| F6 | **Trim & fade** (waveform, handles, ±1 s nudge, fade in/out 0–5 s) | ✓ | ✓ |
| F7 | **Volume boost** up to +6 dB with limiter (no clipping) | – | ✓ |
| F8 | **Merge audio** (screen 41): 2–10 files, drag to reorder, remove, preview, crossfade Off / 1 / 2 / 3 s, Save as format | – | ✓ |
| F9 | **Batch convert** up to 50 files; keeps going in the background on iOS 26, may pause on iOS 16–25 (`05` §9); notification when it actually finishes | – | ✓ |
| F10 | **My files**: library of everything made (filters All / Audio / Ringtones / Alarms), play, share, rename, delete | ✓ | ✓ |
| F11 | Save to Files: copy into the user-picked **Tunely folder** (iCloud Drive › Tunely by default), which survives app deletion; the in-app library copy does not (see `05` §8). Share sheet | ✓ | ✓ |
| F12 | **Daily limit** | 3 conversions / day | Unlimited |
| F13 | Personalised onboarding (goal + frequency) and Settings › Your preferences | ✓ | ✓ |
| F14 | Light + dark mode, Dynamic Type, VoiceOver | ✓ | ✓ |
| F15 | Analytics events (see `08`) and crash reporting | ✓ | ✓ |

| F16 | **Ads** (AdMob or ironSource/LevelPlay mediation): ad break after saving (every 2nd conversion, never mid-task), rewarded "+1 conversion" on the daily limit | Yes | **No ads** |
| F17 | **More from Marberx**: gentle cross-promotion (screen 45, small Result card, empty state) | Yes | Rarely |
| F18 | **Help & FAQ** content (see `15_Help_FAQ.md`) | ✓ | ✓ |

| F19 | **Invite friends (referral)**: optional account only for the inviter; friend redeems a code without an account; both get 7 days Pro (see `12`) | ✓ | ✓ |

**Login is optional** and only used for referral rewards. No cloud sync.

## What counts as one conversion (free limit)

One finished output file = one conversion: a video→audio file, a format conversion or a ringtone. Batch and Merge are Pro (no limit). **Failed or cancelled jobs never count.** Saving or sharing the same result again doesn't count. The counter resets at local midnight.

## Supported files

- **Input video:** MOV, MP4, M4V (anything AVFoundation can read), from Photos (PHPicker) or Files.
- **Input audio:** MP3, M4A, AAC, WAV, AIFF, CAF, FLAC (and OGG if the decoder is added; see `11`).
- **Not supported:** DRM-protected files (Apple Music `.m4p`, streaming downloads) → screen E4. Damaged files → E1.
- **Output:** MP3 (LAME), M4A, WAV (PCM 16-bit), M4R (ringtone) free · FLAC, AAC (.aac/ADTS), OGG Vorbis Pro. AIFF output and custom bitrate/sample rate are **not in V1.0** (`10`).

## Definition of done (V1.0)

- All 53 screens + 24 states built in light and dark, matching the PNGs.
- Every rule in `05_Business_Rules.md` implemented and unit-tested in Dart.
- Every event in `08_Analytics_Events.md` fires once, with the right properties, verified in the analytics debug view.
- Purchases, restore, trial reminder and offers work in Sandbox and TestFlight.
- All of `09_QA_Acceptance_Checklist.md` passes on a real iPhone (iOS 16 and iOS 26).
