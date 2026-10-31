# 13 · Growth and Marketing Plan

Built from the research in `00_Research.md`. The aim: **trust first, then convert**. Competitors earn money but also 1★ reviews ("scam", "can't cancel"); Tunely earns money *and* a high rating.

## 1. Onboarding (conversion + personalisation)

- 5 short screens; the 2 questions (goal, frequency) are the only inputs, each with a clear payoff ("We'll put your favourite tool first").
- O4 "Honest and simple" pre-empts the top two complaints *before* the paywall. That raises trust and trial starts.
- O5 privacy: "only the file you pick", no permission prompt.
- P1 at the end, closable, trial timeline; first close → once-ever exit offer.

## 2. Personalised in-app experience

| Goal | Home hero | Picker | Convert default | Paywall header |
|------|-----------|--------|-----------------|----------------|
| Ringtones | Make a ringtone from any video | Videos | Ringtone mode | Unlimited ringtones, alarms & text tones |
| MP3 | Turn any video into an MP3 | Videos | MP3 256 | MP3 variant |
| Convert | Convert audio to any format | Audio files | Last used | Convert variant |

Frequency changes plan emphasis and upsell cadence (`05` §3).

## 3. Situational paywalls

P1 onboarding · P2 Pro feature (with a free escape) · P3 daily limit (real countdown) · P4 inline card after 3 successes · P5 heavy user · P6 exit offer (once) · P7 trial reminder (trust) · P8 win-back. Caps in `05` §2.

## 4. Self-marketing inside the app

- **Rating** only at happy moments (2nd ringtone / 5th file), 2 times max, 1–3★ routed to feedback.
- **Milestones** (first ringtone, 10, 50 files) with a **share card** "Made with Tunely" (organic installs).
- **Share sheet** default file names stay clean (no ads/watermarks) but the share card carries the brand.
- **More from Marberx** (screen 45) in Settings, a capped card on Result and the empty My files state, never as a pop-up.
- **Invite friends** (V1.3): Settings › Invite friends, "Give 1 week · Get 1 week". Friend needs no account; inviter's optional account only keeps the link and rewards. Never a pop-up (`12` §9).
- **What's new** sheet once per version to re-engage.

## 5. Ads (light, honest)

Ad break only after the file is saved, with our own notice first; rewarded "+1 conversion" on the daily limit; none for Pro; none in the first session. "Short ads, never mid-task" is the promise (O4). Details `05` §12.

## 5b. Cross-promotion of Marberx apps

More from Marberx screen (always available), a small relevant card on Result (capped, dismissible) and the empty My files card. Never pop-ups. Details `05` §13. Every Marberx app links to the others the same way, so users discover the family without feeling pushed.

## 6. App Store (ASO + screenshots)

- Title/subtitle target "MP3 converter", "ringtone maker", "video to MP3". Full listing in `AppStore/App_Store_Listing.md`.
- 8 screenshots: outcome first (ringtone), then speed + size, easy setup, popular formats, trim & fade, batch, merge songs, privacy. **No Pro badges, credits, limits or prices** in screenshots; the 2.3.2 line is in the description.
- In-App Events later: "Make your holiday ringtone" (Dec), "Summer song ringtone" (Jun).

## 7. A/B test ideas (after 2–4 weeks of data)

| # | Test | Metric |
|---|------|--------|
| 1 | P1 header goal-based vs generic "Tunely Pro" | Trial rate |
| 2 | Trial timeline vs benefit list only | Trial rate, trial → paid |
| 3 | Free limit 3/day vs 2/day | D7 retention vs revenue per user |
| 4 | Exit offer 50% vs 40% | Accept rate, revenue |
| 5 | Lifetime $39.99 vs $49.99 | Revenue per paywall view |
| 6 | P4 card after 2nd vs 3rd success | Trial rate, rating |
| 7 | Onboarding with vs without O3 | Completion, trial rate |

Run with RevenueCat Experiments (paywalls) and remote config (limits); read results in Mixpanel.

## 8. Launch checklist (marketing)

- Privacy and Terms pages live; support email working
- 3 short screen-recording videos (video → ringtone in 20 s) for App Preview, Reels, TikTok
- Ask the first 100 happy users via the rating rule; reply to every review in the first month
- Cross-promote from Shrink (Settings row, empty states)
