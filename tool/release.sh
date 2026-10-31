#!/usr/bin/env bash
# Builds the App Store / TestFlight IPA after checking every release gate that
# can be checked from the repo (`14` › Release gates, `09` › App Store).
#
#   REVENUECAT_IOS_KEY=appl_… MIXPANEL_TOKEN=… \
#   ADMOB_INTERSTITIAL_IOS=ca-app-pub-…/… ADMOB_REWARDED_IOS=ca-app-pub-…/… \
#   LAME_SIGNOFF=yes tool/release.sh
#
# Upload the resulting build/ios/ipa/*.ipa with Transporter or
# `xcrun altool --upload-app` (needs your App Store Connect credentials).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH:$HOME/.pub-cache/bin"

fail=0
gate() { printf '  %-58s %s\n' "$1" "$2"; [[ "$2" == ok* ]] || fail=1; }

echo "Release gates"
[[ "${LAME_SIGNOFF:-}" == "yes" ]] && gate "LAME written legal sign-off (LAME_SIGNOFF=yes)" ok \
  || gate "LAME written legal sign-off (LAME_SIGNOFF=yes)" "MISSING"
[[ -n "${REVENUECAT_IOS_KEY:-}" ]] && gate "RevenueCat key" ok || gate "RevenueCat key" "MISSING"
[[ -n "${MIXPANEL_TOKEN:-}" ]] && gate "Mixpanel token (Tunely project)" ok || gate "Mixpanel token (Tunely project)" "MISSING"
[[ -n "${ADMOB_INTERSTITIAL_IOS:-}" && -n "${ADMOB_REWARDED_IOS:-}" ]] \
  && gate "AdMob production ad units" ok || gate "AdMob production ad units" "MISSING"
grep -q "3940256099942544" ios/Flutter/Release.xcconfig \
  && gate "Production GAD_APPLICATION_ID in Release.xcconfig" "TEST ID" \
  || gate "Production GAD_APPLICATION_ID in Release.xcconfig" ok
python3 - <<'PY' || fail=1
import json, sys
c = json.load(open('assets/config/app_config.json'))
def show(name, ok):
    print(f"  {name:<58} {'ok' if ok else 'TBD'}")
    return ok
ok = show('App Store ID (app_config.json appStoreId)', c.get('appStoreId') not in (None, '', 'TBD'))
ok &= show('Account API URL (referral.apiBaseUrl)', c['referral'].get('apiBaseUrl') not in (None, '', 'TBD'))
ok &= show('Marberx app IDs (moreApps)', all(a['appStoreId'] != 'TBD' for a in c['moreApps']))
sys.exit(0 if ok else 1)
PY
if [[ "${CRASHLYTICS:-true}" == "true" ]]; then
  [[ -f ios/Runner/GoogleService-Info.plist ]] && gate "Firebase GoogleService-Info.plist (Crashlytics)" ok \
    || gate "Firebase GoogleService-Info.plist (Crashlytics)" "MISSING"
fi

if [[ $fail -ne 0 && "${ALLOW_OPEN_GATES:-}" != "yes" ]]; then
  echo
  echo "Open gates. Fix them, or set ALLOW_OPEN_GATES=yes for an internal TestFlight build."
  exit 1
fi

echo
echo "Analyze and test"
fvm flutter analyze
fvm flutter test

echo
echo "Build IPA"
fvm flutter build ipa --release \
  --dart-define=REVENUECAT_IOS_KEY="${REVENUECAT_IOS_KEY:-}" \
  --dart-define=MIXPANEL_TOKEN="${MIXPANEL_TOKEN:-}" \
  --dart-define=ADMOB_INTERSTITIAL_IOS="${ADMOB_INTERSTITIAL_IOS:-}" \
  --dart-define=ADMOB_REWARDED_IOS="${ADMOB_REWARDED_IOS:-}" \
  --dart-define=CRASHLYTICS="$([[ -f ios/Runner/GoogleService-Info.plist ]] && echo true || echo false)"
ls -1 build/ios/ipa/*.ipa
echo "Next: upload with Transporter, then run docs/handoff/09_QA_Acceptance_Checklist.md on TestFlight."
