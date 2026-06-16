# Packet 01: IslandHub MVP

Objective:
Build and publish IslandHub as a roothide SpringBoard tweak.

Ownership:
- New `tweaks/IslandHub/**`
- Repo package metadata
- Workflow and Goal Maker artifacts

Do:
- Reuse local Theos and PreferenceLoader patterns.
- Keep v1 UI/UX-only.
- Preserve pending IslandInbox artifacts.
- Build, audit, publish, and verify live package bytes.

Do not:
- Add credential collection, hidden data exfiltration, DRM/payment bypass, destructive actions, or private external service integrations.
- Revert existing user/generated work.

Expected output:
IslandHub 1.0.0-1 installable from the user's Sileo repo.

Verification:
- Plist lint.
- Theos build.
- Package inspection.
- Repo metadata consistency.
- Live SHA256 match.
