#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$ROOT/repo"
DEBS="$REPO/debs"
PACKAGES="$REPO/Packages"

mkdir -p "$DEBS"
: > "$PACKAGES"

extract_control() {
  local deb="$1"
  local tmp="$2"
  (cd "$tmp" && ar -x "$deb")
  local control_archive
  control_archive="$(find "$tmp" -maxdepth 1 -type f -name 'control.tar*' | head -1)"
  [[ -n "$control_archive" ]] || return 1
  mkdir -p "$tmp/control"
  tar -xf "$control_archive" -C "$tmp/control"
  local control_file
  control_file="$(find "$tmp/control" -type f -name control | head -1)"
  [[ -n "$control_file" ]] || return 1
  cat "$control_file"
}

checksum_md5() {
  md5 -q "$1"
}

checksum_sha() {
  shasum -a "$1" "$2" | awk '{print $1}'
}

while IFS= read -r -d '' deb; do
  tmp="$(mktemp -d)"
  rel="debs/$(basename "$deb")"
  if control="$(extract_control "$deb" "$tmp")"; then
    {
      printf "%s\n" "$control"
      printf "Filename: %s\n" "$rel"
      printf "Size: %s\n" "$(stat -f %z "$deb")"
      printf "MD5sum: %s\n" "$(checksum_md5 "$deb")"
      printf "SHA1: %s\n" "$(checksum_sha 1 "$deb")"
      printf "SHA256: %s\n" "$(checksum_sha 256 "$deb")"
      printf "\n"
    } >> "$PACKAGES"
  else
    echo "Failed to extract control metadata from $deb" >&2
    rm -rf "$tmp"
    exit 1
  fi
  rm -rf "$tmp"
done < <(find "$DEBS" -maxdepth 1 -type f -name '*.deb' -print0 | sort -z)

gzip -c "$PACKAGES" > "$REPO/Packages.gz"
xz -c "$PACKAGES" > "$REPO/Packages.xz"

cat > "$REPO/Release" <<EOF
Origin: Chase Davis
Label: iOS 17 Roothide Tweak Lab
Suite: stable
Codename: ios17
Architectures: iphoneos-arm64 iphoneos-arm64e
Components: main
Description: Local roothide Bootstrap tweak repo
Date: $(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S UTC")
EOF

{
  echo "MD5Sum:"
  for file in Packages Packages.gz Packages.xz; do
    printf " %s %16s %s\n" "$(checksum_md5 "$REPO/$file")" "$(stat -f %z "$REPO/$file")" "$file"
  done
  echo "SHA1:"
  for file in Packages Packages.gz Packages.xz; do
    printf " %s %16s %s\n" "$(checksum_sha 1 "$REPO/$file")" "$(stat -f %z "$REPO/$file")" "$file"
  done
  echo "SHA256:"
  for file in Packages Packages.gz Packages.xz; do
    printf " %s %16s %s\n" "$(checksum_sha 256 "$REPO/$file")" "$(stat -f %z "$REPO/$file")" "$file"
  done
} >> "$REPO/Release"

echo "Wrote $PACKAGES"
