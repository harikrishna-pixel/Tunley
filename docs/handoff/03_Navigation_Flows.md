# 03 · Navigation Flows

Numbers = screens in `02_Screens_and_States.md`. Diagrams are Mermaid (render on GitHub or in Cursor preview).

## 1. First launch

```mermaid
flowchart LR
  A[Launch] --> O1[01 O1 Value demo] --> O2[02 O2 Goal] --> O3[03 O3 Frequency] --> O4[04 O4 Honest] --> O5[05 O5 Privacy]
  O5 --> P1[10 P1 Paywall]
  O1 & O2 & O3 & O4 -. Skip .-> P1
  P1 -- close, first time --> P6[14 P6 Exit offer]
  P1 -- buy / trial --> H[06 Home]
  P6 -- claim / no thanks --> AC[44 Ads & tracking]
  AC -- Continue: UMP in EEA, then ATT --> H
```

## 2. Core: video or audio → file

```mermaid
flowchart LR
  H[06 Home] --> PK[07 Choose a file]
  PK -- 1 file --> CV[08 Convert]
  PK -- 2+ files, Pro --> B[21 Batch]
  PK -- 2+ files, Free --> P2[11 P2 sheet]
  CV -- Trim & fade --> TR[19 Trim & fade] --> CV
  CV -- Pro format --> P2
  P2 -- Use MP3 instead --> CV
  CV -- Convert --> PF{Pre-flight}
  PF -- ok --> PR[18 Converting] --> R[09 Result]
  PF -- limit --> P3[12 P3 Daily limit]
  PF -- DRM --> E4[35 E4]
  PF -- no space --> E2[33 E2]
  PF -- iCloud fail --> E3[34 E3]
  PR -- Cancel --> S1[37 Stop?]
  PR -- error --> E1[32 E1]
  R -- Save fails --> E5[36 E5]
```

Pre-flight order (Dart, `05` §1): readable → not DRM → downloaded (iCloud) → enough space → Pro gate (format / tone type / batch) → free limit.

## 3. Ringtone

```mermaid
flowchart LR
  H[06 Home hero 'Make a ringtone'] --> PK[07] --> CVR[08b Convert · Ringtone mode]
  CVR -- Alarm / Text tone, Free --> P2[11 P2]
  CVR -- Create ringtone --> PR[18] --> RR[09b Result · Set as ringtone]
  RR -- Set as ringtone --> G1[20 Guide step 1] --> G2[20b step 2] --> G3[20c step 3] --> H
  G1 -- iOS ≤ 18 link --> GB[GarageBand guide, in Help]
  RR --> M5[30 Milestone · first ringtone]
```

## 4. Tabs

- **Home** (06) → tools: Video to MP3 → 07 (Videos tab) · Convert format → 07 (Audio files tab) · Trim & fade → 07 → 19 → 08 · Merge audio → 07 multi-select (Pro) → **41 Merge** → 18 → 09 · Volume boost → 07 → 19 with boost row highlighted · Batch → 07 multi-select (Pro).
- **My files** (22) → row tap plays inline · ⋯ menu: Share, Rename, Set as ringtone (→ 20), Delete (→ 39) · empty → 38.
- **Settings** (23) → 24 Preferences · 20 guide · 25 Help · Rate (Apple review sheet) · More apps (App Store product page) · Restore (→ 17b / toast) · Manage subscription (system sheet `showManageSubscriptions`).

## 5. Monetization moments

```mermaid
flowchart TD
  A[3rd success today] --> P4[09c upsell card in Result]
  B[4th conversion attempt] --> P3[12 P3]
  C[10th file lifetime] --> P5[13 P5]
  D[Trial day 2] --> N[Local notification] --> P7[15 P7]
  E[Return ≥14 days after lapse] --> P8[16 P8]
  P1 & P3 & P5 & P7 & P8 -- purchase --> P9[17 P9 result / toast Welcome to Pro]
```

## 6. Ads and cross-promotion

```mermaid
flowchart LR
  R[09 Result] -- Save / Set as ringtone / Done --> AB{Ad due? 05 §12}
  AB -- no --> R
  AB -- yes --> N[42 Ad break notice] -- Continue --> AD[43 Network ad] -- close --> R
  N -- Remove ads with Pro --> P1[10 P1]
  P3[12 P3 Daily limit] -- Watch a short ad --> RW[43 Rewarded ad] -- reward callback --> CV[08 Convert, +1]
  S[23 Settings] -- More apps from Marberx --> MA[45 More from Marberx] -- Get --> AS[App Store sheet]
  R -. house card 09d, capped .-> AS
```

## 6b. Account and referral (optional)

```mermaid
flowchart LR
  S[23 Settings] -->|Invite friends| SO[46 Invite signed out]
  SO -->|Create free account| SU[48 Create account] --> R[47 Invite friends]
  SO -->|I already have an account| SI[49 Sign in] --> R
  SI -->|Forgot password| FP[50 Reset password]
  S -->|Account row, signed in| A[51 Account] -->|Delete account| D[52 Delete account]
  A --> R
  S -->|Have an invite code?| C[53 Redeem code]
  L[Friend's invite link] -->|first open, deferred deep link| C
```
Transitions: 46/53 = full-screen cover (slide up); 48–52 = push. Signed-in users tapping Invite friends go straight to 47.

## 7. Deep links

`tunely://home`, `tunely://paywall?trigger=<name>`, `tunely://guide`, `tunely://files`, `tunely://invite` (46/47), universal link `https://tunely.app/i/<CODE>` → 53 with the code prefilled. The trial-reminder notification opens `tunely://paywall?trigger=trial_reminder` (shows P7). Batch-done notification opens My files.
