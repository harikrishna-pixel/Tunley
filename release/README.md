# Release files

- `app_store/en-US/*.txt`: App Store Connect text fields from `docs/handoff/AppStore/App_Store_Listing.md`. The description keeps "Some features require a Tunely Pro subscription." (Guideline 2.3.2) — `test/release_metadata_test.dart` checks it and the field lengths.
- App identity: bundle ID `com.marberx.audioconverter` (iOS and Android), App Store ID `6829206161` (`app_config.json` → `appStoreId`).
- `app-ads.txt`: publish on the developer website before ads go live.
- `apple-app-site-association`: replace `TEAMID` with the Apple Team ID and serve it at `https://tunely.app/.well-known/apple-app-site-association` (JSON, no redirect) so invite links open the app.
- Screenshots: `docs/handoff/AppStore/Screenshots_6.9in/` (01 → 08). iPhone Duo screenshots: `tool/duo_sim.sh` (question #24).
- Build: `tool/release.sh` checks the release gates, runs analyze + tests, and builds the IPA.
