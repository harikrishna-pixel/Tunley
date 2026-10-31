# App Store Listing (draft)

Screenshots in `Screenshots_6.9in/` are **1290 × 2796** (iPhone 6.9" slot; App Store Connect scales them for smaller iPhones). Upload in order 01 → 08.

**Screenshot rule:** no Pro badges, credits, limits or prices in any screenshot. Pro features (FLAC/AAC/OGG, batch) appear without a label. Because of that, the description **must** keep the line "Some features require a Tunely Pro subscription." (Guideline 2.3.2).

| # | File | Headline | Sub-line | Chip(s) |
|---|------|----------|----------|---------|
| 1 | `01_Any_video_ringtone.png` | Any video, your ringtone | Pull the sound, keep the best 30 seconds | Ringtone ready · 0:30 fade in & out |
| 2 | `02_Video_to_MP3.png` | Video to MP3 in 3 taps | See the file size before you convert | MP3 · 1.3 MB · Done in 3 s |
| 3 | `03_Set_ringtone.png` | Set it as your ringtone in seconds | Step-by-step guide · no GarageBand on iOS 26 | Use as Ringtone |
| 4 | `04_Popular_formats.png` | All popular formats in one tap | MP3, M4A, WAV, FLAC, AAC, OGG | FLAC · WAV · MP3 |
| 5 | `05_Cut_and_fade.png` | Cut and fade to the second | Keep exactly the part you love | 0:08 – 0:38 |
| 6 | `06_Batch_convert.png` | Convert many files at once | Pick them all, tap once, done | 8 files · MP3 |
| 7 | `07_Merge_songs.png` | Join songs into one mix | Reorder, crossfade, done | 4 files · 3:42 |
| 8 | `08_Private_on_iPhone.png` | Private. Made on your iPhone | Converted on the device, never uploaded | Never uploaded |

**Before upload, verify** every claim in `14_Traceability_and_Compliance.md` › Claims register ("Done in 3 s", file-size estimate, "no GarageBand on iOS 26", "never uploaded"). Store 3 is **provisional** until the iOS 26 ringtone route is tested on a real iPhone.

## Text fields

- **Name (30):** Tunely – MP3 & Ringtone Maker *(29 chars; final after trademark check)*
- **Subtitle (30):** Video to MP3, Audio Converter
- **Promotional text (170):** Turn any video into an MP3 or a ringtone in seconds. Trim, fade, convert to any format. Nothing uploaded, 3 free conversions every day.
- **Keywords (100):** mp3,converter,ringtone,maker,video,audio,extract,m4a,wav,flac,trim,cutter,alarm,tone,sound,extractor
  *(Validate with ASO research; don't repeat words from name/subtitle in the final set; no competitor brands.)*
- **Category:** Music (secondary: Utilities)

**Description:**
> Turn any video into an MP3, convert audio to any format, and make ringtones you can actually set, right on your iPhone.
>
> • Video to MP3: pick a video and keep just the sound, with the file size shown before you convert
> • Ringtone maker: choose the best 30 seconds, add fade in and out, and follow the simple guide to set it (no GarageBand needed on iOS 26)
> • Convert audio: MP3, M4A, WAV, FLAC, AAC and OGG
> • Trim and fade to the second
> • Batch convert, merge audio and volume boost
> • Your files, organised in one place and saved to your own Tunely folder in Files
> • Private: everything is converted on your iPhone and nothing is uploaded
> • Batch convert and merge songs into one mix
>
> Free to use with 3 conversions every day, supported by short ads shown only between tasks. **Some features require a Tunely Pro subscription**: unlimited conversions and ringtones, no ads, FLAC/AAC/OGG, batch up to 50 files, merge audio, volume boost, alarm and text tones.
>
> Tunely Pro: Weekly $4.99, Yearly $29.99 (3-day free trial), or Lifetime $39.99 (one-time purchase). Prices are in USD and may vary by country.
> Payment is charged to your Apple Account at confirmation of purchase (after the free trial, if any). Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. If you allow notifications, we'll remind you one day before your trial ends. Manage or cancel anytime in Settings › Apple Account › Subscriptions.
> Only convert files you own or have the right to use. Copy-protected music (such as Apple Music) can't be converted.
> Terms of Use: [TERMS URL, see 11_Open_Questions #11] · Privacy Policy: [PRIVACY URL, see 11_Open_Questions #11]

## App Privacy (nutrition label)

Final answers to enter: **`App_Privacy_Answers.md`** (Phase 10). The draft below is kept for history.

### Draft

Final answers only after checking the SDK table in `06_Technical_Architecture.md` against a real network capture.
- Likely: **Identifiers** (User ID: RevenueCat/Mixpanel anonymous ID), **Purchases** (purchase history), **Usage Data** (product interaction), **Diagnostics** (crash data). User ID, purchases and usage are probably **linked** (same anonymous ID); diagnostics not linked. **Advertising:** AdMob/LevelPlay collect device ID (only if the user allows tracking), ad interactions and coarse location for ads, so answer **"Data Used to Track You"** for Identifiers/Usage if ATT can be allowed. Publish `app-ads.txt`.
- **Contact info (name, email) + User ID: linked, App Functionality**, only for users who create the optional invite account (V1.3). No user content collected (files never leave the device).

## App Review notes (paste in "Notes")

> Tunely converts files locally with Apple frameworks plus LAME (MP3) and libvorbis (OGG). No login is required. An optional email account exists only for invite rewards (Settings › Invite friends); test account: [ADD DEMO EMAIL / PASSWORD]. Account deletion: Settings › Account › Delete account. Free users get 3 conversions per day; Pro features can be tested with the sandbox. To test DRM handling, choose an Apple Music file; the app explains it can't be converted.
