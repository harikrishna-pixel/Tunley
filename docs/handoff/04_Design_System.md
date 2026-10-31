# 04 · Design System: "Direction A · Refined Premium" (violet, light + dark)

Machine-readable version: `design-tokens.json`. Exact per-element values: `Design/HTML_Source/*.dc.html` (inline styles; the `const T = {…}` block in every file is the same token set).

**V1.0 ships light AND dark mode** and follows the iPhone setting (`ThemeMode.system`).

## Design principles

1. **One accent colour** (violet `#5B3FE6`). Green / amber / red only for status, never decoration.
2. **One gradient**, the brand `hero`. Allowed on: Home hero card, Result player card, Paywall header, Exit/Win-back offer headers, Milestone / Update / Rating icon tiles, logo tile, App Store backgrounds. Nowhere else.
3. **One icon family**: Phosphor (regular + fill + bold). No emoji, no 3D art.
4. **One primary button per screen.** Secondary actions = text links or icon buttons.
5. **Real content over decoration**: real photos/thumbnails and real waveforms instead of illustrations.
6. **Pop-ups dominate**: every dialog / sheet sits on `scrim` + 10 pt background blur.
7. **Honesty is visible**: the free counter, estimated output size and "nothing uploaded" lines are part of the design, not decoration. Don't drop them.

## Colour tokens

| Token | Light | Dark | Use |
|-------|-------|------|-----|
| `bg` | #F5F4FA | #0E0D16 | Screen background |
| `surface` | #FFFFFF | #181626 | Cards, sheets, dialogs |
| `surface2` | #EEECF6 | #221F33 | Segmented track, chips, timer boxes |
| `border` | #E5E2F0 | #2C2942 | Card / input borders, off toggles |
| `divider` | #EFEDF5 | #25223A | List separators |
| `text` | #15132B | #F3F1FF | Primary text |
| `text2` | #5C5875 | #ABA7C6 | Secondary text |
| `text3` | #6B6784 | #8C88A8 | Captions, inactive tab, meta |
| `accent` | #5B3FE6 | #6F4EF2 | Primary buttons, selection, links, progress, active tab, waveform selection |
| `accentText` | #FFFFFF | #FFFFFF | Text on accent |
| `accentSoft` | #EEEAFF | rgba(132,102,255,0.18) | Info boxes, icon tiles, selected chip bg |
| `accentOnSoft` | #3F25C9 | #C4B5FF | Text/icons on accentSoft |
| `link` | #5B3FE6 | #B3A1FF | Text links |
| `success` | #0F7350 | #3CCB8C | Done, checks, output size |
| `successSoft` | #E4F4EC | rgba(60,203,140,0.14) | Safe / success boxes |
| `warn` | #9A5A12 | #F2B25C | Warnings |
| `warnSoft` | #FDF0DF | rgba(242,178,92,0.14) | Warning boxes |
| `danger` | #C2331F | #FF7A68 | Errors, destructive |
| `dangerSoft` | #FDECEA | rgba(255,122,104,0.14) | Error boxes |
| `hero` | linear-gradient(135deg, #3F25C9 0%, #5B3FE6 55%, #7B4DFF 100%) | linear-gradient(135deg, #3A22BD 0%, #5537E0 55%, #7A4FFF 100%) | Brand gradient (see rule 2) |
| `heroText` | #FFFFFF | #FFFFFF | Text on hero |
| `tab` | rgba(255,255,255,0.94) | rgba(24,22,38,0.94) | Tab bar / bottom bars (+ blur) |
| `toast` | #1C1A2E | #2E2A48 | Toast background (white text) |
| `shadow` | 0 1px 2px rgba(21,19,43,0.05), 0 8px 24px rgba(21,19,43,0.06) | 0 1px 2px rgba(0,0,0,0.3) | Selected segment, floating chips |
| `scrim` | rgba(16,12,40,0.52) | rgba(0,0,0,0.64) | Behind dialogs & sheets (+ blur 10) |
| `gold` | #E0A21B | #E0A21B | Crown icon / Pro only |
| `proBadgeBg` | #15132B | #F3F1FF | PRO badge background |
| `proBadgeText` | #FFD36B | #3F25C9 | PRO badge text |

**Flutter:** `AppColors extends ThemeExtension<AppColors>` with these fields, `light` and `dark` instances; widgets read `context.colors.x`. Never hard-code hex values in widgets.

## Typography: Plus Jakarta Sans

Bundled TTFs (OFL) in `Fonts/` → `assets/fonts/`. Weights 400–800. Support Dynamic Type up to 200% (`MediaQuery.textScaler`).

| Style | Size / weight / tracking | Example |
|-------|--------------------------|---------|
| Large title | 26 / 800 / −3% | "Tunely", "My files", "Settings" |
| Title | 26 / 800 / −2% | "Your MP3 is ready", error headlines |
| Hero title | 22 / 800 / −2% | Home hero "Make a ringtone from any video" |
| Timecode | 32 / 800, tabular figures | Trim "0:12.40" |
| Dialog title | 19–22 / 800 | Sheets, dialogs |
| Nav title / section | 17 / 800 | Top bars, "Tools", "Recent" |
| Button | 16 / 800 | Primary buttons |
| Body | 15 / 600 | Rows, body copy (line-height 1.45) |
| Subhead | 14 / 700 | Row titles, card titles |
| Caption | 13 / 600 | Section labels (sentence case) |
| Footnote | 12 / 600 | Meta, legal, file info |
| Micro | 11 / 700 | Badges, durations, tab labels |

## Spacing, layout, radius

- 4-pt grid: 4, 6, 8, 10, 12, 14, 16, 18, 20, 24. Screen side padding **20** (24 on onboarding and paywall).
- Top bar starts at the safe area (~54 pt). Bottom CTA area: 12 top / 30 bottom.
- Tab bar 84 pt incl. home indicator, `tab` colour + blur, 1 pt `divider` top line.

| Element | Radius |
|---------|--------|
| Badges, durations | 6 |
| Chips, format chips, segmented items | 12 |
| Primary buttons, rows, small cards | 16 |
| Cards, plan cards, quality cards | 18 |
| Hero card, player card, dialogs | 24 |
| Bottom-sheet top corners | 28 |

## Components

| Component | Spec |
|-----------|------|
| **Primary button** | 54 h, radius 16, `accent`, white 16/800, optional leading icon 18. Disabled: `surface2` / `text3` |
| **Icon button** | 54×54, radius 16, `surface` + 1 pt `border` (Share next to Save) |
| **Text link** | 44 h, 15/700 `link` (or `text2` for Not now / Later / Skip) |
| **Hero card** | `hero`, radius 24, padding 18, decorative ring (white 8%), white text, white inner button with `#3F25C9` text |
| **Player card** | `hero`, file thumb 56, title/meta, white 48 play button, 48-bar waveform (played = white, rest = white 35%), timecodes |
| **Segmented control** | Track `surface2`, inset 4, radius 12; selected `surface` + `shadow`, 13/800 |
| **Format chip** | 3 per row, 44 h, radius 12; selected = 2 pt `accent` border + `accentSoft` bg + `accentOnSoft` text; PRO badge top-right (free users only) |
| **Radio card** (quality, plans) | `surface`, radius 18; selected 2 pt `accent` border + filled radio; size estimate right-aligned 14/800 |
| **Tool tile** | 3-column grid, `surface` + `border`, radius 16, icon tile 36 `accentSoft`, label 12/700, optional PRO badge |
| **PRO badge** | `proBadgeBg` / `proBadgeText`, radius 6, 9/800 "PRO". Never in App Store screenshots |
| **Pro chip** | `surface` + `border`, radius 17, gold crown 16 + "Pro" 13/700 (free users only) |
| **Free counter** | 6 pt `success` dot + "2 of 3 free today" 12/700 `text2`; turns `warn` at 0 left |
| **Waveform editor** | Bars 3 pt, gap 2; selected range `accent`, outside `border`; handles 14×56 `accent` with white grip; playhead 2 pt `text` |
| **Trial timeline** | 3 rows with icon circles (lock-open / bell / star), connecting 2 pt line, day labels 13/800 |
| **Status box** | soft colour + strong text, radius 14 ("Your original file is safe and unchanged" uses `successSoft`) |
| **Toggle** | iOS switch 46×28; on = `accent` |
| **Toast** | `toast` bg, radius 16, white 14/600, 28 pt coloured icon circle, optional action; top; 3 s (5 s with action). Info only |
| **Dialog** | `surface`, radius 24, padding 24, on `scrim` + blur σ 10 |
| **Bottom sheet** | `surface`, top radius 28, grabber 40×5, padding 24, on `scrim` + blur |
| **Tab bar** | Home / My files / Settings; icons 24 (fill when active), 11/700 label; active `link`, inactive `text3` |

## Icons: Phosphor (`phosphor_flutter`)

| Use | Icon |
|-----|------|
| App mark | `waveform` (bold) |
| Tabs | `house` (fill active), `folders`, `gearSix` |
| Back / close / chevron | `caretLeft` (bold), `x` (bold), `caretRight` |
| Ringtone / alarm / text tone | `bellRinging`, `alarm`, `chatCircleDots` |
| Video to MP3 / convert / trim | `filmSlate`, `arrowsLeftRight`, `scissors` |
| Merge / boost / batch | `intersect` (or `stack`), `speakerHigh`, `stack` |
| File types | `fileAudio`, `musicNotes`, `videoCamera` |
| Play / pause | `play` (fill), `pause` (fill) |
| Pro | `crown` (fill, `gold`) |
| Save / share / delete | `downloadSimple`, `export`, `trash` |
| Status | `checkCircle` (fill), `xCircle` (fill), `warningCircle`, `info` |
| Privacy / storage / cloud | `shieldCheck`, `lockSimple`, `hardDrives`, `cloudArrowDown` |
| Settings rows | `slidersHorizontal`, `question`, `star` (fill), `squaresFour`, `arrowCounterClockwise`, `creditCard` |

## Motion

- Progress ring animates continuously, % ticks smoothly; time left updates max 2×/s.
- Result: success check scales in (200 ms), output size counts up (500 ms).
- Waveform bars grow in from the centre on load (300 ms, staggered).
- Sheets: iOS spring; dialogs fade + scale 0.96 → 1 (200 ms); scrim + blur fade 200 ms.
- Toasts slide down 250 ms, fade out 200 ms.
- Exit-offer timer ticks every second (real time, stored end time).
- Respect Reduce Motion (show final states).


## Screen transitions (must be smooth on every screen)

Every move between screens must feel native and smooth: **no jumps, no blank frames, no flicker, no stutter**. This applies to every screen, sheet and dialog in both light and dark mode. It's a release requirement, not a nice-to-have.

### Transition map

| Movement | Transition | Duration / curve |
|----------|-----------|------------------|
| Push to a detail / next step (e.g. Convert → Converting (18) → Result (09)) | iOS slide from the right with parallax (`CupertinoPageTransitionsBuilder`); **swipe-back from the left edge works everywhere** except while a job is running | 350 ms, iOS default curve |
| Back / pop | Reverse of push, follows the finger on swipe-back | interactive |
| Tab switch (Home / My files / Settings) | Cross-fade only, **no slide**; each tab keeps its scroll position and state (`StatefulShellRoute.indexedStack`) | 200 ms, easeOut |
| Onboarding (O1–O5) | Horizontal page slide, swipeable, progress dots animate | 300 ms, easeOutCubic |
| Running screen → Result | Fade-through: running screen fades out, Result fades in with scale 0.98 → 1, then the success animation starts. Use `pushReplacement` so Back goes to the step before | 300 ms, easeOutCubic |
| Shared element | `Hero` on the file thumbnail and name (Choose a file → Convert → Converting → Result) and the Result player card → My files row, so it visibly travels between screens | 350 ms |
| Full-screen paywalls (P1, P7, P8 only) | Slide up from the bottom (`fullscreenDialog`), slide down on close | 350 ms in / 250 ms out |
| Bottom sheets (see Presentation per screen) | iOS spring from the bottom; scrim + 10 pt blur fade in together; drag down to dismiss | spring (damping ≈ 0.86), scrim 200 ms |
| Dialogs (see Presentation per screen) | Fade + scale 0.96 → 1; scrim + blur fade | 200 ms, easeOut |
| Toasts | Slide down from the top + fade; out: fade | 250 ms in / 200 ms out |
| Content inside a screen (state changes, segmented control, list items appearing/removing) | `AnimatedSwitcher` / `AnimatedSize` / `AnimatedList`; never hard cuts | 150–250 ms |
| Loading longer than 300 ms | Skeleton placeholders in the final layout (no layout jump when content arrives), not a centred spinner | – |

**One shared helper:** create `lib/app/transitions.dart` with `AppTransitions` (push, fadeThrough, modalUp, sheet, dialog) and use it in **every** `go_router` route via `CustomTransitionPage` / `pageBuilder`. No screen may use a default or ad-hoc transition.

### Presentation per screen (the one source of truth)

| Presentation | Screens |
|---|---|
| `push` (slide, swipe-back) | 47 Invite friends, 48 Create account, 49 Sign in, 50 Reset password, 51 Account, 52 Delete account, 45 More from Marberx, 07 Choose a file, 08 Convert, 19 Trim, 20 Guide, 21 Batch, 41 Merge, 24 Preferences, 25 Help, 32–36 error screens |
| `fadeThrough` (replace) | 18 Converting → 09 Result |
| `fullScreenDialog` (slide up) | 46 Invite friends (signed out), 53 Redeem invite code, 44 Ads & tracking pre-prompt, 10 P1 Paywall, 15 P7 Trial reminder, 16 P8 Win-back, 01–05 onboarding (as one flow) |
| `sheet` (bottom, spring) | 11 P2 Pro feature, 27 Notification pre-prompt, 31 Share card, 36 E5 Save failed |
| `dialog` (centred, fade + scale) | 42 Ad break notice, 12 P3 Daily limit, 13 P5 Heavy user, 14 P6 Exit offer, 17 P9 Purchase result, 26 Rating, 27 Notification, 29 Update, 30 Milestone, 37 Stop converting, 39 Delete |
| network-controlled | 43 Network ad (AdMob/LevelPlay present it themselves) |
| `tabCrossFade` | 06 Home, 22 My files, 23 Settings |

Contrast: `text3` and `success` were darkened in V1.1 so all captions reach ≥ 4.5:1 on `bg` and `surface` in both themes.

### Smoothness rules (60 fps, 120 fps on ProMotion iPhones)

- Build with **Impeller** (Flutter default on iOS) and enable 120 Hz: set `CADisableMinimumFrameDurationOnPhone = YES` in `Info.plist`.
- Never do heavy work while a transition is running: start waveform rendering, engine start and thumbnail decoding **after** the route animation completes (`ModalRoute.of(context)?.animation` status completed, or `WidgetsBinding.instance.endOfFrame`).
- Pre-load what the next screen needs: `precacheImage` for thumbnails/photos, fetch data before pushing when it's quick (< 100 ms).
- Wrap expensive painters (waveforms, progress rings, charts, video previews) in `RepaintBoundary`; use `const` widgets; avoid `Opacity` widgets in animations (use `FadeTransition`).
- No `setState` on the whole screen for progress updates: progress uses a small `ValueListenableBuilder` / Riverpod `select` so only the ring rebuilds.
- Images use fixed sizes and `cacheWidth`/`cacheHeight` so decoding never blocks a frame.
- Haptics: light impact on success, selection click on segmented controls and plan cards (`HapticFeedback`).

### Reduce Motion

When iOS Reduce Motion is on (`MediaQuery.disableAnimationsOf(context)`), replace slides, scales and springs with a 150 ms cross-fade, and show final values without count-up animations.

### Acceptance (must pass before release)

- Flutter DevTools performance overlay on a real **iPhone 12 or older** and a **ProMotion iPhone**: no frame over 16 ms (8 ms on ProMotion) during any transition in `09_QA_Acceptance_Checklist.md`.
- Every route uses `AppTransitions`; swipe-back works on every pushed screen.
- Record a screen video of the full main flow and every sheet/dialog in light and dark: no flicker, no white flash in dark mode, no layout jump.

## Dark mode

- Same layout and token names, only values change.
- Hero gradient stays violet in both themes.
- Photos are never dimmed except under a scrim.
- Status colours on their soft backgrounds must reach ≥ 4.5:1 contrast in both themes.

## App icon (to design)

Violet `hero` gradient square, white Phosphor-style `waveform` mark (bold), no text. Same mark as the Home logo tile.
