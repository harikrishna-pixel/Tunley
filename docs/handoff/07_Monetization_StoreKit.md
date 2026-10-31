# 07 · Monetization & StoreKit

**Model:** subscription + lifetime, honest free tier (3 conversions/day) **with light ads** (ad break after saving, rewarded "+1 conversion"). Pro removes all ads. Referral (V1.3): friend and inviter each get 7 days Pro as a RevenueCat promotional entitlement (see `12`); login is optional and never needed to buy or restore.
**Recommended implementation:** RevenueCat `purchases_flutter` (handles trials, offers, win-back, paywall A/B tests and analytics). `in_app_purchase` also works; product logic stays the same.

## Products (App Store Connect)

Intended US prices (shown in the designs). In code always show the store's localized price (`StoreProduct.priceString`) and **compute** the per-week figure and "SAVE xx%" from the real prices. Never hard-code prices.

| Product ID (suggested) | Type | Price (US) | Notes |
|------------------------|------|-----------|-------|
| `tunely.pro.weekly` | Auto-renewable, 1 week | $4.99 | Group "Tunely Pro" |
| `tunely.pro.yearly` | Auto-renewable, 1 year | $29.99 | **3-day free trial** (introductory offer). Pre-selected. Shown as $0.58/wk, SAVE 88% vs weekly |
| `tunely.pro.lifetime` | Non-consumable | $39.99 | "Pay once, yours forever" |
| `tunely.pro.yearly.exit` | Auto-renewable, 1 year | $29.99 with **intro price $14.99 for the first year** (pay up front) | Same group. Used only by P6 Exit offer. Users who already had a trial still get the intro price if eligible; otherwise RevenueCat falls back to a **promotional offer** on `tunely.pro.yearly` (signed via RevenueCat) |
| Win-back (P8) | Offer on `tunely.pro.yearly` | $17.99 first year (40% off) | iOS 18+: Apple **win-back offer** configured in App Store Connect; iOS 16–17: promotional offer. Eligibility = lapsed subscriber |

****Exit offer decision (Praba, 25 Oct 2026):** keep P6 right after the first close of P1, once ever. Implementation: `tunely.pro.yearly.exit` with an **introductory price** ($14.99 first year). Apple allows one introductory offer per subscription group per customer, so check eligibility first; if not eligible, don't show P6 (promotional offers are only for current/former subscribers, so they are NOT used for P6). Test in Sandbox before building the UI.

One entitlement:** `pro` = active weekly/yearly (incl. trial and offers) **or** lifetime.

RevenueCat offerings: `default` (yearly, weekly, lifetime), `exit` (yearly.exit), `winback` (yearly with win-back offer).

## Entitlement logic

- On launch / foreground: `getCustomerInfo()` → `isPro`; listen to `addCustomerInfoUpdateListener`.
- Cache `isPro` locally so the app works offline; re-verify when online.
- Restore → `restorePurchases()` → P9 Restored (plan + renewal date) or toast "No purchases found for this Apple Account".
- Pro unlocks immediately: hide Pro chip, PRO badges, free counter, P4 card; enable all formats and tools.

## Paywall rules (App Review safe, no dark patterns)

- **Close X always visible** from the first frame (no delay).
- **Yearly pre-selected.** Weekly is never pre-selected.
- **Trial timeline** on P1: Today "Full access, free" · Day 2 "Reminder" · Day 3 "$29.99/yr starts" (dates computed from today).
- **Terms line changes with the plan** (above the CTA):
  - Yearly: "Free for 3 days, then $29.99 / year. Cancel anytime."
  - Weekly: "$4.99 / week. Cancel anytime."
  - Lifetime: "$39.99 one-time purchase. No subscription."
  - **Not eligible for trial (applies to EVERY paywall, sheet and card: P1, P2, P3, P4, P5):** no "free"/"trial" wording; Yearly line "$29.99 / year. Cancel anytime."; CTA "Continue" (P1), "Get Tunely Pro" (P2/P3), "Get Yearly" (P5); timeline hidden. Designs: states 10d, 11b, 13b.
- CTA per plan: "Start my free trial" / "Continue" / "Buy lifetime".
- Links: Restore · Terms of Use (Apple EULA or own) · Privacy Policy.
- Benefits list must match real Pro features only: Unlimited conversions & ringtones · FLAC, AAC, OGG formats · Batch up to 50 files · No ads · Merge audio, volume boost · Alarm & text tones. (AIFF and custom bitrate are NOT in V1.0.)
- Paywall header text follows the onboarding goal (`05` §3).

## Situational paywalls and offers

Full trigger map and caps: `05_Business_Rules.md` §2.

| Screen | Offering | Default plan | Copy focus |
|--------|----------|--------------|------------|
| P1 Main | default | Yearly | Goal-based header + trial timeline |
| P2 Pro feature sheet | default | Yearly trial | The tapped feature + "Use MP3 instead (free)" escape |
| P3 Daily limit | default | Yearly trial | "You're on a roll", real countdown, "Come back tomorrow" |
| P4 Upsell card | default | Yearly trial | Inline card, no pop-up |
| P5 Heavy user | default | Yearly | Personal stats, "$2.50/mo" (computed) |
| P6 Exit offer | exit | Yearly $14.99 | Once ever, real 10-min timer, "No thanks, continue with Free" |
| P7 Trial reminder | – | – | Keep Pro / **Manage or cancel subscription** (`showManageSubscriptions`) |
| P8 Win-back | winback | Yearly $17.99 | "Your ringtones and files are still here", valid-until date |

## Trial reminder (onboarding O4: "Allow notifications and we'll remind you")

- Wording never promises guaranteed delivery. When a trial starts: ask notification permission (27), then schedule a local notification **24 h before the trial ends** ("Your free trial ends tomorrow. Keep Pro or cancel in two taps.") → opens P7.
- If notifications are denied: show P7 in-app on the first open during the last 24 h.
- Cancel the notification if the user cancels or upgrades to lifetime.

## Purchase result handling (P9)

| Result | UI |
|--------|----|
| Success | Close paywall, toast "Welcome to Tunely Pro!", unlock |
| Pending (Ask to Buy / SCA) | P9 Pending |
| User cancelled | Back to paywall silently (P1 first close → P6 rule) |
| Error | P9 Failed: "You haven't been charged" |
| Restore found / not found | P9 Restored / toast |

## App Store listing disclosure (Guideline 2.3.2)

Store screenshots show some Pro features (all formats, batch) **without** labels. The description must therefore include: **"Some features require a Tunely Pro subscription."** plus the standard auto-renewal terms. See `AppStore/App_Store_Listing.md`.

## Ads (V1.0)

Rules and caps: `05_Business_Rules.md` §12. Cross-promotion: §13.
- Network: **AdMob or ironSource/LevelPlay mediation** (Praba decides; default AdMob with mediation, `11` #18). Code only talks to `AdsService`.
- Formats: interstitial (ad break 42 → 43) and rewarded (+1 conversion on P3). No banners, no app-open ads.
- **Pro = no ads.** "No ads" is listed in Pro benefits (paywall, Pro sheet, Settings card).
- Ad revenue + subscription: keep ads light so they don't hurt ratings (ads were ~8% of competitors' 1★ reviews).
