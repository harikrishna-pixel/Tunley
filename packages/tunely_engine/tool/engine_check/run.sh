#!/bin/sh
# Builds the engine core for macOS and converts a generated test file to every bundled format.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
core="$here/../../ios/Classes/Core"
work="${TMPDIR:-/tmp}/tunely_engine_check"
rm -rf "$work" && mkdir -p "$work/out"

say -o "$work/voice.aiff" "Tunely turns any video into an MP3 or a ringtone. Nothing is uploaded. Your original file stays safe and unchanged."
afconvert -f m4af -d aac "$work/voice.aiff" "$work/input.m4a"

# Set CODEC_MAC to the "macOS libs" folder printed by tool/build_codecs.sh --mac to include MP3 and OGG.
flags=""
if [ -n "${CODEC_MAC:-}" ]; then
  for lib in lame vorbis; do
    flags="$flags -I $CODEC_MAC/$lib/include -L $CODEC_MAC/$lib/lib"
  done
fi

swiftc -O -parse-as-library $flags \
  $(find "$core" -name '*.swift') "$here/main.swift" -o "$work/engine_check"
"$work/engine_check" "$work/input.m4a" "$work/out"
