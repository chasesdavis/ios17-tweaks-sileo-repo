#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEOS_PATH="${THEOS:-/Users/chase/theos}"
BUILD_ROOT="${BUILD_ROOT:-/tmp/ios17_tweak_lab_build}"
export THEOS="$THEOS_PATH"

mkdir -p "$ROOT/repo/debs"
rm -f "$ROOT/repo/debs"/*.deb
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/tweaks"
if [[ -d "$ROOT/shared" ]]; then
  mkdir -p "$BUILD_ROOT/shared"
  cp -R "$ROOT/shared"/. "$BUILD_ROOT/shared"/
fi

status=0
for tweak_dir in "$ROOT"/tweaks/*; do
  [[ -d "$tweak_dir" ]] || continue
  name="$(basename "$tweak_dir")"
  work="$BUILD_ROOT/tweaks/$name"
  mkdir -p "$work"
  cp -R "$tweak_dir"/. "$work"/
  rm -rf "$work/.theos" "$work/packages"

  echo "==> Building $name"
  if (cd "$work" && make clean package THEOS_PACKAGE_SCHEME=roothide FINALPACKAGE=1 DEBUG=0); then
    mkdir -p "$tweak_dir/packages"
    rm -f "$tweak_dir/packages"/*.deb
    find "$work/packages" -maxdepth 1 -type f -name '*.deb' -print0 2>/dev/null | while IFS= read -r -d '' deb; do
      cp "$deb" "$tweak_dir/packages/"
      cp "$deb" "$ROOT/repo/debs/"
      echo "    copied $(basename "$deb")"
    done
  else
    echo "!! Build failed: $name" >&2
    status=1
  fi
done

exit "$status"
