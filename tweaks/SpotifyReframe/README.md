# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- Custom UIKit Reframe Player shell built from scratch.
- The Player launcher is visible by default, has placement controls, and the shell never auto-opens.
- Upgrade migration moves old AI preview installs onto the Reframe Player defaults.
- No SwiftUI or Swift runtime linkage in the Spotify tweak dylib.
- Native-first defaults that preserve Spotify's own layout.
- Upgrade migration that disables the older gray-card/glow-heavy settings.
- Minimal album-art rounding as the only default visual polish.
- Low Power Mode enabled by default.
- In-app floating settings button is opt-in to avoid overlapping Spotify controls.
- Experimental cards, player, tab bar, label tinting, debug badge, and force mode remain available from Settings.
- PreferenceLoader pane with matching controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
