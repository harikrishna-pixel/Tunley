# HTML Source: reference only

These `.dc.html` files are the design source of each screen (names in the "Source" column of `02_Screens_and_States.md`).

**Use them to read exact values**: every colour, font size, weight, padding, gap, radius and piece of copy is an inline `style="…"` on the element. Search for the text you see in the PNG to find its element.

**Do not ship or port this markup.** It's a design format (`{{placeholders}}`, `<sc-if>`, `<sc-for>`, `<dc-import>`) that only renders inside the design tool. Build Flutter widgets instead.

Notes:
- `/_blob/<id>` image paths = sample photos in `../Images/` (mapping in its README).
- Every file has a `theme` prop (light / dark). Colour values are in the `const T = { light: {…}, dark: {…} }` block in the `<script>`, identical to `design-tokens.json`.
- Some files also take a `clean` prop: `clean="true"` hides PRO badges, the Pro chip, free counter and upsell lines. It's only used for App Store screenshots. **The app never has a clean mode.**
- Props: `Home` / `Paywall` `goal` (ringtone · mp3 · convert), `Paywall` / `FeatureSheet` / `HeavyUser` `eligible` (trial eligibility), `Unsupported` `kind` (drm · noaudio), `SaveFailed` `kind` (full · folder), `Picker` `tab` (videos · audio), `Convert` `mode` (audio · ringtone), `Result` `mode` + `upsell`, `PurchaseResult` `state` (failed · restored · pending · none · offline), `RingtoneGuide` `step`.
- Wrapper files (`HomeDark`, `PickerDark`, `ConvertDark`, `ResultDark`, `ConvertRingtone`, `PickerAudioDark`, `ResultRingtoneDark`, `HomeMP3`, `HomeConvert`, `ResultUpsell`) only show another screen with different props.
- Overlay screens (FeatureSheet, LimitReached, HeavyUser, ExitOffer, PurchaseResult, Rating, Notify, Update, Milestone, ShareCard, SaveFailed, CancelConfirm, DeleteConfirm) embed the underlying screen with `<dc-import>` and draw the sheet/dialog on top (scrim + `backdrop-filter: blur(10px)`).
- `HomeA/B/C` are the three design directions (A chosen). `Store1–8` are the App Store screenshots.
- Icons are inline SVG paths from Phosphor (viewBox 0 0 256 256); use the same icons from `phosphor_flutter`.
- Ads & cross-promotion (V1.2): `AdBreak` (42), `AdState` (43, placeholder for the network ad), `AdsConsent` (44), `MoreApps` (45); `Result` has a `promo` prop (state 09d, wrapper `ResultPromo`).
- **V1.3 account & referral:** `ReferralSignedOut` (46), `Referral` (47), `SignUp` (48), `SignIn` (49, `state` normal · error), `ForgotPassword` (50, `state` form · sent), `Account` (51), `DeleteAccount` (52), `InviteCode` (53, `state` enter · success · invalid). Ported from the Shrink design with Tunely tokens.
