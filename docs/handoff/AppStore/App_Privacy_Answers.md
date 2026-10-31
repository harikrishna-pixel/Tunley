# App Privacy answers (App Store Connect › App Privacy)

Built from the SDK table in `06_Technical_Architecture.md`, the app's `ios/Runner/PrivacyInfo.xcprivacy` and the integrations in the current build (RevenueCat, Mixpanel, AdMob + UMP, Firebase Crashlytics, Marberx account API). **Before submitting:** confirm with a network capture (Proxyman/Charles) and Xcode › Product › Archive › Generate Privacy Report, and add every mediated ad network's own manifest.

**Do you or your third-party partners collect data from this app?** Yes.

## Data types

| Category › Type | Collected by | Linked to the user | Used for tracking | Purposes |
|---|---|---|---|---|
| Contact Info › Name | Marberx account API (only if the user creates the optional invite account) | Yes | No | App Functionality |
| Contact Info › Email Address | Marberx account API (optional account) | Yes | No | App Functionality |
| Identifiers › User ID | RevenueCat app user ID = Mixpanel distinct ID; account ID | Yes | No | App Functionality, Analytics |
| Identifiers › Device ID | AdMob (IDFA, only when tracking is allowed) | Yes | **Yes** | Third-Party Advertising |
| Purchases › Purchase History | RevenueCat | Yes | No | App Functionality |
| Usage Data › Product Interaction | Mixpanel (events in `08`); AdMob (ad interactions) | Yes | Yes (AdMob, when tracking is allowed) | Analytics; Third-Party Advertising |
| Usage Data › Advertising Data | AdMob | Yes | Yes (when tracking is allowed) | Third-Party Advertising |
| Location › Coarse Location | AdMob (IP-derived, for ads) | No | No | Third-Party Advertising |
| Diagnostics › Crash Data | Firebase Crashlytics (paths and file names redacted) | No | No | App Functionality |
| Diagnostics › Performance Data | Firebase Crashlytics | No | No | App Functionality |

**Not collected:** audio, video or any user content (files are converted on the device and never uploaded), contacts, photos (PHPicker gives the app only the picked copy), precise location, health, financial info, browsing history, search history, sensitive info.

## Tracking

- "Data Used to Track You": **Identifiers › Device ID, Usage Data › Product Interaction, Usage Data › Advertising Data** (AdMob, only after the user allows tracking in the ATT prompt; denied = non-personalised ads).
- `NSUserTrackingUsageDescription` is set; the ATT prompt follows our explainer (44) and Google's UMP form in the EEA/UK/CH.
- The app's own manifest declares `NSPrivacyTracking = false`; Google Mobile Ads ships its own manifest with its tracking domains.

## Notes for the Privacy Policy (marberx.com/tunely/privacy)

- Optional account: name, email, hashed password, referral code, app user ID and a DeviceCheck token (one redemption per iPhone); deletable in the app (Settings › Account › Delete account) or via support.
- Analytics never include file names, paths, emails, names or free text (`08` › Rules); Mixpanel ignores the IP.
- Ads: AdMob (and mediated networks if added) for free users only; Pro has no ads.
