# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- Replacement player shell removed.
- No launcher, full-screen overlay, or separate mock player surface.
- Upgrade migration moves existing installs onto native-only polish defaults.
- No SwiftUI or Swift runtime linkage in the Spotify tweak dylib.
- Native-first defaults that preserve Spotify's own layout.
- Upgrade migration that disables the older gray-card/glow-heavy settings.
- Album-art rounding, light artwork accent, native control tint, and native chrome polish are the default visual changes.
- Low Power Mode enabled by default.
- In-app floating settings button is opt-in to avoid overlapping Spotify controls.
- Experimental cards, player, tab bar, label tinting, debug badge, and force mode remain available from Settings.
- PreferenceLoader pane with matching controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
