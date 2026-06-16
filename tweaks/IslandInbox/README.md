# Island Inbox

Island Inbox is a SpringBoard tweak for iOS 17 roothide that turns incoming banner-style notifications into a compact Dynamic Island queue.

## What It Does

- Replaces notification banners with tiny Island chips.
- Tap the Island queue to expand a mini notification center.
- Swipe left on a chip or row to archive it.
- Swipe right on a chip or row to open the source when SpringBoard exposes an activation path.
- Long-press a chip or row to show quick reply controls.

## Build

```bash
cd "/Users/chase/ios17 tweaks/tweaks/IslandInbox"
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```

Because this repo path contains a space, the repo build script is usually safer:

```bash
cd "/Users/chase/ios17 tweaks"
./scripts/build-all.sh
```

The built package appears in `tweaks/IslandInbox/packages/` and is copied to `repo/debs/`.
