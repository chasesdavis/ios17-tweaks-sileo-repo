# Workspace Instructions

This workspace contains iOS 17 Bootstrap / roothide / rootless Theos tweaks and a local static Sileo repo.

## Roughdraft

Use Roughdraft when reviewing or commenting on Markdown files. Treat `rd` in user messages as shorthand for Roughdraft, but do not create a shell alias or command named `rd`.

When asking the user to review Markdown, open one file at a time with:

```bash
roughdraft open "/absolute/path/to/file.md"
```

Leave the Roughdraft process running until the user clicks Done Reviewing.

## Theos

Use the local Theos install at `/Users/chase/theos`.

All tweaks in this workspace target:

```make
THEOS_PACKAGE_SCHEME = roothide
TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
```

Build from a tweak directory with:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```

## Safety Boundary

The first tranche is UI/UX-only. Do not add credential collection, DRM bypass, payment bypass, hidden data exfiltration, destructive filesystem changes, or privacy bypass behavior.
