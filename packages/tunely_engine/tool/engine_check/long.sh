#!/bin/sh
# 60-minute memory/speed check (`06` › Performance, Phase 10): builds a
# 60-min AAC file, converts it with the engine core on macOS and reports
# wall time and peak memory. MP3 needs CODEC_MAC (tool/build_codecs.sh --mac).
set -e
here="$(cd "$(dirname "$0")" && pwd)"
core="$here/../../ios/Classes/Core"
work="${TMPDIR:-/tmp}/tunely_engine_long"
minutes="${MINUTES:-60}"
rm -rf "$work" && mkdir -p "$work/out"

python3 - "$work/tone.wav" "$minutes" <<'PY'
import math, struct, sys, wave
path, minutes = sys.argv[1], int(sys.argv[2])
rate = 44100
with wave.open(path, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(rate)
    second = b''.join(
        struct.pack('<hh', *(2 * [int(9000 * math.sin(2 * math.pi * (220 + 110 * (i // 11025 % 4)) * i / rate))]))
        for i in range(rate))
    for _ in range(minutes * 60):
        w.writeframes(second)
PY
afconvert -f m4af -d aac -b 256000 "$work/tone.wav" "$work/input.m4a"
rm "$work/tone.wav"

flags=""
if [ -n "${CODEC_MAC:-}" ]; then
  for lib in lame vorbis; do
    flags="$flags -I $CODEC_MAC/$lib/include -L $CODEC_MAC/$lib/lib"
  done
fi
swiftc -O -parse-as-library -D LONG_CHECK $flags \
  $(find "$core" -name '*.swift') "$here/main.swift" -o "$work/engine_long"
/usr/bin/time -l "$work/engine_long" "$work/input.m4a" "$work/out" 2> "$work/time.txt"
grep -E "real|maximum resident set size" "$work/time.txt"
