# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- In-app SpotifyReframe settings panel from a floating Spotify-side control.
- Forced visual mode with a visible launch badge and window-level tint wash.
- Glass-style playlist, album, and queue cards.
- Tunable album-art rounding and glow.
- Refined tab bar and navigation bar treatment.
- Now Playing surface polish.
- Optional label tinting and background wash.
- PreferenceLoader pane with matching controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
