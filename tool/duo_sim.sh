#!/usr/bin/env bash
# Builds Tunely with Xcode 27.1 + the iOS 27.1 SDK and runs it on the
# iPhone Duo simulator, then screenshots both displays.
#
#   tool/duo_sim.sh                 # find Xcode 27.1+ in /Applications
#   XCODE=/path/to/Xcode.app tool/duo_sim.sh
#   tool/duo_sim.sh --export-skill  # also export Apple's resizability skill
#
# Fold poses (folded / book / flat) are only in Device Hub; simctl can't set
# the hinge. Screenshots land in build/duo/.
set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$PATH:$HOME/.pub-cache/bin"
BUNDLE_ID=com.marberx.audioconverter
OUT=build/duo

version_of() { /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$1/Contents/Info.plist" 2>/dev/null; }
at_least_27_1() { [[ "$(printf '%s\n27.1\n' "$1" | sort -V | head -1)" == "27.1" ]]; }

if [[ -z "${XCODE:-}" ]]; then
  for app in /Applications/Xcode*.app; do
    v=$(version_of "$app") || continue
    if at_least_27_1 "$v"; then XCODE=$app; break; fi
  done
fi
if [[ -z "${XCODE:-}" ]] || ! at_least_27_1 "$(version_of "$XCODE")"; then
  echo "Xcode 27.1 or later not found. Install it, or set XCODE=/path/to/Xcode.app." >&2
  exit 1
fi
export DEVELOPER_DIR="$XCODE/Contents/Developer"
echo "Using $(xcodebuild -version | head -1) at $XCODE"

if [[ "${1:-}" == "--export-skill" ]]; then
  mkdir -p build/apple_skills
  (cd build/apple_skills && xcrun agent skills export)
  echo "Apple skills exported to build/apple_skills (copy into .cursor/skills to use them in Cursor)."
fi

if ! xcrun simctl list runtimes | grep -q "iOS 27\.1"; then
  echo "Downloading the iOS 27.1 simulator runtime (about 8 GB)…"
  xcodebuild -downloadPlatform iOS
fi
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-27-[0-9-]*' | sort -V | tail -1)
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-Duo
if ! xcrun simctl list devicetypes | grep -q "$DEVICE_TYPE"; then
  echo "This Xcode has no iPhone Duo device type (needs 27.1, not 27.0)." >&2
  exit 1
fi

UDID=$(xcrun simctl list devices available | grep -E "^\s+Tunely iPhone Duo \(" | grep -oE '[0-9A-F-]{36}' | head -1 || true)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "Tunely iPhone Duo" "$DEVICE_TYPE" "$RUNTIME")
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
open "$XCODE/Contents/Applications/DeviceHub.app" 2>/dev/null || open -a Simulator
xcrun simctl bootstatus "$UDID" -b

fvm flutter build ios --simulator --debug
xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$UDID" "$BUNDLE_ID"
sleep 8

mkdir -p "$OUT"
xcrun simctl io "$UDID" screenshot --display=primary "$OUT/outer.png"
# The inner display is black while folded; unfold in Device Hub, then rerun
# this line (or the whole script).
xcrun simctl io "$UDID" screenshot --display=primary-1 "$OUT/inner.png" || true
echo "Screenshots: $OUT/outer.png, $OUT/inner.png  (device $UDID)"
echo "Next: in Device Hub fold/unfold and rotate; check the 'Build and iPhone Duo' section of docs/handoff/09_QA_Acceptance_Checklist.md."
