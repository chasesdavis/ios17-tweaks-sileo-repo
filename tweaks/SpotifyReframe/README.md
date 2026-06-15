# SpotifyReframe

SpotifyReframe is a Spotify-only UI redesign tweak for Bootstrap / roothide.

It targets `com.spotify.client` and keeps behavior visual-only:

- Glass-style playlist, album, and queue cards.
- Tunable album-art rounding and glow.
- Refined tab bar and navigation bar treatment.
- Now Playing surface polish.
- Optional label tinting and background wash.
- PreferenceLoader pane with runtime-backed controls.

Build:

```bash
THEOS=/Users/chase/theos make clean package THEOS_PACKAGE_SCHEME=roothide
```
