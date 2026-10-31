#!/bin/sh
# Builds ios/Frameworks/lame.xcframework (dynamic, LGPL) and vorbis.xcframework
# (static libogg + libvorbis + libvorbisenc, BSD) from the official release tarballs.
#
#   packages/tunely_engine/tool/build_codecs.sh          # iOS device + simulator
#   packages/tunely_engine/tool/build_codecs.sh --mac    # also macOS libs for tool/engine_check
#
# LAME needs written legal sign-off before App Store submission (docs/handoff/11 #1, 14).
set -eu

LAME_VERSION=3.100
LAME_SHA=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
OGG_VERSION=1.3.5
OGG_SHA=0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664
VORBIS_VERSION=1.3.7
VORBIS_SHA=0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab
MIN_IOS=16.0

here="$(cd "$(dirname "$0")" && pwd)"
plugin="$(cd "$here/.." && pwd)"
out="$plugin/ios/Frameworks"
work="${CODEC_WORK:-${TMPDIR:-/tmp}/tunely_codecs}"
jobs="$(sysctl -n hw.ncpu)"
mkdir -p "$work" "$out"

fetch() {
  url="$1"; file="$work/$2"; sha="$3"
  [ -f "$file" ] || curl -fsSL -o "$file" "$url"
  echo "$sha  $file" | shasum -a 256 -c - >/dev/null
  rm -rf "$work/${2%.tar.gz}"
  tar xzf "$file" -C "$work"
}

fetch "https://downloads.sourceforge.net/project/lame/lame/$LAME_VERSION/lame-$LAME_VERSION.tar.gz" \
  "lame-$LAME_VERSION.tar.gz" "$LAME_SHA"
fetch "https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz" \
  "libogg-$OGG_VERSION.tar.gz" "$OGG_SHA"
fetch "https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz" \
  "libvorbis-$VORBIS_VERSION.tar.gz" "$VORBIS_SHA"

# build <name> <src> <sdk> <arch> <target> <host> [configure args...]
build() {
  name="$1"; src="$2"; sdk="$3"; arch="$4"; target="$5"; host="$6"; shift 6
  prefix="$work/install/$sdk-$arch"
  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  dir="$work/build/$name-$sdk-$arch"
  rm -rf "$dir" && mkdir -p "$work/build" && cp -Rp "$src" "$dir"
  (
    cd "$dir"
    sed -i '' 's/-force_cpusubtype_ALL//g' configure
    CC="$(xcrun --sdk "$sdk" -f clang) -arch $arch -target $target -isysroot $sysroot" \
    CPP="$(xcrun --sdk "$sdk" -f clang) -E -arch $arch -target $target -isysroot $sysroot" \
    CPPFLAGS="-I$prefix/include" \
    CFLAGS="-arch $arch -target $target -isysroot $sysroot -O2 -fPIC" \
    LDFLAGS="-arch $arch -target $target -isysroot $sysroot" \
    PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
      ./configure --host="$host" --prefix="$prefix" --disable-shared --enable-static "$@" >/dev/null
    make -j"$jobs" >/dev/null
    make install >/dev/null
  )
}

slices="iphoneos:arm64:arm64-apple-ios$MIN_IOS:aarch64-apple-darwin
iphonesimulator:arm64:arm64-apple-ios$MIN_IOS-simulator:aarch64-apple-darwin
iphonesimulator:x86_64:x86_64-apple-ios$MIN_IOS-simulator:x86_64-apple-darwin"
if [ "${1:-}" = "--mac" ]; then
  slices="$slices
macosx:arm64:arm64-apple-macos12.0:aarch64-apple-darwin"
fi

for slice in $slices; do
  IFS=: read -r sdk arch target host <<EOF
$slice
EOF
  echo "building $sdk $arch"
  long_double=8
  [ "$arch" = x86_64 ] && long_double=16
  build lame "$work/lame-$LAME_VERSION" "$sdk" "$arch" "$target" "$host" \
    --disable-frontend --disable-decoder --disable-gtktest ac_cv_header_stdc=yes \
    ac_cv_sizeof_short=2 ac_cv_sizeof_unsigned_short=2 ac_cv_sizeof_int=4 \
    ac_cv_sizeof_unsigned_int=4 ac_cv_sizeof_long=8 ac_cv_sizeof_unsigned_long=8 \
    ac_cv_sizeof_float=4 ac_cv_sizeof_double=8 ac_cv_sizeof_long_double=$long_double \
    ac_cv_c_bigendian=no
  build ogg "$work/libogg-$OGG_VERSION" "$sdk" "$arch" "$target" "$host"
  build vorbis "$work/libvorbis-$VORBIS_VERSION" "$sdk" "$arch" "$target" "$host" \
    --with-ogg="$work/install/$sdk-$arch" --disable-oggtest --disable-docs --disable-examples
done

plist() {
  name="$1"; version="$2"; platform="$3"
  cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$name</string>
  <key>CFBundleIdentifier</key><string>com.mbxtunely.$name</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$name</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
  <key>MinimumOSVersion</key><string>$MIN_IOS</string>
</dict>
</plist>
EOF
}

# Flattens `<ogg/x.h>` / `<vorbis/x.h>` includes so the headers work inside a framework.
flatten() {
  sed -e 's#<ogg/\([A-Za-z_]*\.h\)>#"\1"#' -e 's#<vorbis/\([A-Za-z_]*\.h\)>#"\1"#' "$1" > "$2"
}

# framework <sdk> <archs>: lipo the slices of one platform into lame.framework and vorbis.framework.
framework() {
  sdk="$1"; archs="$2"; platform="$3"
  dest="$work/frameworks/$sdk"
  rm -rf "$dest" && mkdir -p "$dest"
  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  first="$(echo "$archs" | cut -d' ' -f1)"

  lame="$dest/lame.framework"
  mkdir -p "$lame/Headers" "$lame/Modules"
  dylibs=""
  for arch in $archs; do
    case "$sdk" in
      iphoneos) target="$arch-apple-ios$MIN_IOS" ;;
      *) target="$arch-apple-ios$MIN_IOS-simulator" ;;
    esac
    xcrun --sdk "$sdk" clang -dynamiclib -arch "$arch" -target "$target" -isysroot "$sysroot" \
      -Wl,-all_load "$work/install/$sdk-$arch/lib/libmp3lame.a" \
      -install_name @rpath/lame.framework/lame \
      -compatibility_version 1 -current_version 1 \
      -o "$dest/lame-$arch"
    dylibs="$dylibs $dest/lame-$arch"
  done
  lipo -create $dylibs -output "$lame/lame"
  rm -f $dylibs
  cp "$work/install/$sdk-$first/include/lame/lame.h" "$lame/Headers/"
  printf 'framework module lame {\n  umbrella header "lame.h"\n  export *\n}\n' \
    > "$lame/Modules/module.modulemap"
  plist lame "$LAME_VERSION" "$platform" > "$lame/Info.plist"

  vorbis="$dest/vorbis.framework"
  mkdir -p "$vorbis/Headers" "$vorbis/Modules"
  archives=""
  for arch in $archs; do
    lib="$work/install/$sdk-$arch/lib"
    libtool -static -o "$dest/vorbis-$arch.a" \
      "$lib/libogg.a" "$lib/libvorbis.a" "$lib/libvorbisenc.a" 2>/dev/null
    archives="$archives $dest/vorbis-$arch.a"
  done
  lipo -create $archives -output "$vorbis/vorbis"
  rm -f $archives
  inc="$work/install/$sdk-$first/include"
  for h in ogg/ogg.h ogg/os_types.h ogg/config_types.h vorbis/codec.h vorbis/vorbisenc.h; do
    flatten "$inc/$h" "$vorbis/Headers/$(basename "$h")"
  done
  printf '#include "ogg.h"\n#include "codec.h"\n#include "vorbisenc.h"\n' \
    > "$vorbis/Headers/vorbis.h"
  printf 'framework module vorbis {\n  umbrella header "vorbis.h"\n  export *\n}\n' \
    > "$vorbis/Modules/module.modulemap"
  plist vorbis "$VORBIS_VERSION" "$platform" > "$vorbis/Info.plist"
}

framework iphoneos "arm64" iPhoneOS
framework iphonesimulator "arm64 x86_64" iPhoneSimulator

for name in lame vorbis; do
  rm -rf "$out/$name.xcframework"
  xcodebuild -create-xcframework \
    -framework "$work/frameworks/iphoneos/$name.framework" \
    -framework "$work/frameworks/iphonesimulator/$name.framework" \
    -output "$out/$name.xcframework" >/dev/null
done

cp "$work/lame-$LAME_VERSION/COPYING" "$out/LAME_LICENSE.txt"
cat "$work/libogg-$OGG_VERSION/COPYING" > "$out/VORBIS_LICENSE.txt"
printf '\n\n----- libvorbis -----\n\n' >> "$out/VORBIS_LICENSE.txt"
cat "$work/libvorbis-$VORBIS_VERSION/COPYING" >> "$out/VORBIS_LICENSE.txt"

if [ "${1:-}" = "--mac" ]; then
  mac="$work/mac"
  rm -rf "$mac" && mkdir -p "$mac/lame/include" "$mac/lame/lib" "$mac/vorbis/include" "$mac/vorbis/lib"
  inst="$work/install/macosx-arm64"
  cp "$inst/include/lame/lame.h" "$mac/lame/include/"
  printf 'module lame {\n  header "lame.h"\n  link "mp3lame"\n  export *\n}\n' \
    > "$mac/lame/include/module.modulemap"
  cp "$inst/lib/libmp3lame.a" "$mac/lame/lib/"
  for h in ogg/ogg.h ogg/os_types.h ogg/config_types.h vorbis/codec.h vorbis/vorbisenc.h; do
    flatten "$inst/include/$h" "$mac/vorbis/include/$(basename "$h")"
  done
  printf '#include "ogg.h"\n#include "codec.h"\n#include "vorbisenc.h"\n' \
    > "$mac/vorbis/include/vorbis.h"
  printf 'module vorbis {\n  umbrella header "vorbis.h"\n  link "ogg"\n  link "vorbis"\n  link "vorbisenc"\n  export *\n}\n' \
    > "$mac/vorbis/include/module.modulemap"
  cp "$inst/lib/libogg.a" "$inst/lib/libvorbis.a" "$inst/lib/libvorbisenc.a" "$mac/vorbis/lib/"
  echo "macOS libs: $mac"
fi
echo "done: $out"
