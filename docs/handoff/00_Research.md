# 00 · Research: why Tunely looks and works the way it does

Sources: ScreensDesign market data (US App Store, revenue month Sep 2026, estimates), public App Store reviews (US, 1–2★ and 5★), and the competitors' App Store listings. Numbers are estimates for direction, not exact figures.

## 1. Competitors (US, monthly estimates)

| App | Revenue / mo | Downloads / mo | Rating | What it does |
|-----|-------------|----------------|--------|--------------|
| Garage Ringtones for iPhone | ~$450K | ~350K | 4.6 | Cut audio/video into ringtones; TikTok-sourced clips; GarageBand guide |
| Audio Editor / MP3 Converter apps (several) | ~$50–80K each | 20–70K | 4.4–4.7 | Convert, trim, merge, batch, pitch/tempo |
| ClipTone: Ringtone & AI Cover | ~$100K | ~100K | 4.8 | Video → ringtone + AI voice covers |
| Ringtones: for iPhone | ~$60K | ~100K | 4.4 | Ringtones from music and video |
| MP3 Converter: Video to Audio | ~$30K | ~100K | 4.7 | Video → MP3/AAC/FLAC/WAV, URL import |
| Ringtones for iPhone #1 | ~$30K | ~20K | 4.3 | Ringtones, fades, pitch, mic recording |
| Nota Ringtones | ~$20K | ~100K | 4.4 | Ringtones from video, fades, setup tutorials, free tier |

**Takeaway:** the money is in **ringtones**. Converting is the everyday job that brings people back. Tunely leads with "Any video → your ringtone" and keeps MP3/format conversion one tap away.

## 2. What 1–2★ reviews complain about (and our answer)

| Pain (share of low reviews, approx.) | Real review examples | Tunely answer |
|---|---|---|
| **"It said free" / surprise paywall** (~35%) | "You have to pay. I am not paying for my ringtone to be changed." · "7.99 PER WEEK?? THIS IS A SCAM" | Honest free tier: **3 free conversions every day, full quality, no watermark**, counter always visible. Onboarding O4 says it up front |
| **Trial charged / can't cancel** (~20%) | "I'm unable to cancel my free trial… borderline scam" · "They won't let me cancel and still trying to take money" | Trial timeline on the paywall, **reminder 1 day before the trial ends** (P7), "Manage or cancel subscription" link in Settings and on P7 |
| **Errors, endless loading, "doesn't work"** (~20%) | "Nothing works, keep getting errors" · "It keeps giving me error messages" | Each error screen says what happened, that the original is safe, and one next step (E1–E5). Compatibility mode. Failed jobs don't use a free conversion |
| **Can't set the ringtone** (~10%) | "I need GarageBand, but my iPhone will not update…" · "I can't set as a ringtone" | **Ringtone guide F3**: iOS 26 share sheet "Use as Ringtone" (no GarageBand). GarageBand guide only for iOS 18 and older |
| **Ads and rating pop-ups** (~8%) | "I never rate an app that solicited a review when I haven't even used it yet" | **Light ads only:** an ad break after the file is saved (our notice first), never mid-task, none in the first session, none for Pro. Rating asked only after a success (2nd ringtone / 5th conversion), max twice, never after an error |
| **Files lost when the app is deleted** | "If you delete the app all the converted documents are gone. BEWARE" | Save to Files copies into the user's **Tunely folder** (iCloud Drive › Tunely by default), which survives app deletion |
| Forced account | "Can't create account. Error message." | **No login needed.** An optional account exists only for invite rewards (V1.3) |

## 3. What 4–5★ reviews celebrate (keep these)

- **Easy and fast:** "3 taps". Core flow = Choose → Convert → Done.
- **Everything in one app:** convert, trim, fade, ringtone. Tunely has all four on Home.
- **Free tier that's actually usable.**
- **Good quality:** we show the bitrate and the **estimated output size before converting**.
- **Fade in/out and precise trimming:** F2 Trim & fade with ±1 s nudge buttons.

## 4. Onboarding teardown (top apps) → Tunely onboarding

Top ringtone apps use 3–6 intro screens, usually a value demo, a "what do you want?" question and a paywall at the end. Many hide the free option.

Tunely: **5 short screens + closable paywall P1**.
1. O1 Value demo (video turns into a ringtone)
2. O2 What do you want to make? (personalises Home, Picker and paywall)
3. O3 How often? (personalises plan emphasis and upsell frequency)
4. O4 Honest & simple (free tier, short ads never mid-task, trial reminder): answers the top 2 complaints *before* the paywall
5. O5 Privacy (only the files you pick; nothing uploaded)

## 5. Paywall teardown → Tunely paywalls

What converts in this niche: trial timeline (Today / Day 2 reminder / Day 3 charge), per-week price on the yearly plan, a "SAVE xx%" badge, 3 plans with Yearly pre-selected, and a one-time discount after the first close.
What creates 1★ reviews: hidden close button, weekly plan pre-selected, unclear trial terms. Tunely avoids all three (see `07_Monetization_StoreKit.md`).

## 6. Store screenshot teardown → Tunely screenshots

Top performers: big outcome headline (2–5 words), real app screen in a phone frame, 1–2 floating chips with a concrete number, a bold colour background, the ringtone outcome first.
Tunely's 8 screenshots follow that, with one rule: **no Pro badges, credits, limits or prices in screenshots** (users read them as "must pay"). Pro features may appear unlabelled; the description carries the 2.3.2 disclosure line. See `AppStore/App_Store_Listing.md`.

## 7. Positioning

**"Any video, your ringtone. Honest free tier, light ads, private."** Main competitors are ad-heavy or paywall-first; Tunely wins on trust and on making the ringtone step actually work.
