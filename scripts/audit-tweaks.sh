#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/docs/audit.md"
DEBS="$ROOT/repo/debs"

forbidden_regex='password|credential|payment|purchase|receipt|drm|keychain|contacts|addressbook|CoreLocation|CLLocation|microphone|AVAudioRecorder|camera|AVCapture|exfil|upload|http://|https://|rm -rf|/var/mobile/Library/SMS|/var/mobile/Library/AddressBook'

{
  echo "# Audit"
  echo
  echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo
  echo "## Static Tweak Checks"
  echo
  echo "| Tweak | Roothide | Filter | Package | UI boundary | Deb | Deb contents | Prefs | Arch |"
  echo "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"

  for tweak_dir in "$ROOT"/tweaks/*; do
    [[ -d "$tweak_dir" ]] || continue
    name="$(basename "$tweak_dir")"
    roothide="fail"
    filter="fail"
    package="fail"
    boundary="pass"
    deb="missing"
    contents="missing"
    prefs="n/a"
    arch="n/a"
    lower="$(printf "%s" "$name" | tr '[:upper:]' '[:lower:]')"

    grep -q 'THEOS_PACKAGE_SCHEME = roothide' "$tweak_dir/Makefile" && roothide="pass"
    [[ -f "$tweak_dir/$name.plist" ]] && grep -q 'com.apple.springboard' "$tweak_dir/$name.plist" && filter="pass"
    [[ -f "$tweak_dir/control" ]] && grep -q "Package: com.chasedavis." "$tweak_dir/control" && package="pass"
    if grep -q 'Prefs_INSTALL_PATH = /Library/PreferenceBundles' "$tweak_dir/Makefile" 2>/dev/null; then
      prefs="missing"
    fi
    if grep -Eiq "$forbidden_regex" "$tweak_dir/Tweak.xm" "$tweak_dir/control" "$tweak_dir/README.md" 2>/dev/null; then
      boundary="review"
    fi
    deb_path="$(find "$DEBS" -maxdepth 1 -type f -iname "*${lower}*.deb" | head -1)"
    if [[ -n "$deb_path" ]]; then
      deb="present"
    elif find "$tweak_dir/packages" -maxdepth 1 -type f -name '*.deb' 2>/dev/null | grep -q .; then
      deb="present-local"
      deb_path="$(find "$tweak_dir/packages" -maxdepth 1 -type f -name '*.deb' | head -1)"
    fi

    if [[ -n "${deb_path:-}" ]]; then
      tmp="$(mktemp -d)"
      if (cd "$tmp" && ar -x "$deb_path") 2>/dev/null; then
        control_archive="$(find "$tmp" -maxdepth 1 -type f -name 'control.tar*' | head -1)"
        data_archive="$(find "$tmp" -maxdepth 1 -type f -name 'data.tar*' | head -1)"
        if [[ -n "$control_archive" ]]; then
          mkdir -p "$tmp/control"
          tar -xf "$control_archive" -C "$tmp/control" 2>/dev/null || true
          arch="$(awk -F': ' '/^Architecture:/ {print $2; exit}' "$tmp/control/control" 2>/dev/null || printf "unknown")"
        fi
        if [[ -n "$data_archive" ]] && tar -tf "$data_archive" | grep -q "Library/MobileSubstrate/DynamicLibraries/${name}.dylib" && tar -tf "$data_archive" | grep -q "Library/MobileSubstrate/DynamicLibraries/${name}.plist"; then
          contents="pass"
        else
          contents="review"
        fi
        if [[ "$prefs" == "missing" ]] && [[ -n "$data_archive" ]] && tar -tf "$data_archive" | grep -q "Library/PreferenceBundles/.*Prefs.bundle" && tar -tf "$data_archive" | grep -q "Library/PreferenceLoader/Preferences/.*Prefs.plist"; then
          prefs="class-mismatch"
          mkdir -p "$tmp/data"
          tar -xf "$data_archive" -C "$tmp/data" 2>/dev/null || true
          bundle_dir="$(find "$tmp/data/Library/PreferenceBundles" -maxdepth 1 -type d -name '*Prefs.bundle' 2>/dev/null | head -1)"
          if [[ -n "$bundle_dir" && -f "$bundle_dir/Info.plist" ]]; then
            principal="$(plutil -extract NSPrincipalClass raw -o - "$bundle_dir/Info.plist" 2>/dev/null || true)"
            executable="$(plutil -extract CFBundleExecutable raw -o - "$bundle_dir/Info.plist" 2>/dev/null || basename "$bundle_dir" .bundle)"
            if [[ -n "$principal" && -f "$bundle_dir/$executable" ]] && nm -gU "$bundle_dir/$executable" 2>/dev/null | grep -Fq "_OBJC_CLASS_\$_${principal}"; then
              prefs="pass"
            fi
          fi
        fi
      else
        contents="review"
      fi
      rm -rf "$tmp"
    fi

    echo "| $name | $roothide | $filter | $package | $boundary | $deb | $contents | $prefs | $arch |"
  done

  echo
  echo "## Repo Checks"
  echo
  for file in "$ROOT/repo/Packages" "$ROOT/repo/Packages.gz" "$ROOT/repo/Packages.xz" "$ROOT/repo/Release"; do
    if [[ -s "$file" ]]; then
      echo "- pass: ${file#$ROOT/}"
    else
      echo "- missing: ${file#$ROOT/}"
    fi
  done

  echo
  echo "## Manual Device Test Order"
  echo
  priority=(SilentToast IconLabelPro AuraDock KineticBadges VelvetAlerts VolumeRibbon ChargingAurora GhostDock)
  seen=" "
  index=1
  for name in "${priority[@]}"; do
    if [[ -d "$ROOT/tweaks/$name" ]]; then
      echo "$index. $name"
      seen="$seen$name "
      index=$((index + 1))
    fi
  done
  while IFS= read -r name; do
    if [[ "$seen" != *" $name "* ]]; then
      echo "$index. $name"
      index=$((index + 1))
    fi
  done < <(find "$ROOT/tweaks" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
  echo
  echo "Install one tweak at a time, respring, verify SpringBoard stability, then proceed."
} > "$OUT"

echo "Wrote $OUT"
