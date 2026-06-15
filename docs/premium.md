# Premium Tweak Suite

These packages are intended to be higher-value than the first visual tranches. They combine multiple behaviors, Settings controls, event handling, and polished surfaces.

| Package | Value proposition |
| --- | --- |
| IslandCommand Pro | Dynamic Island-style command/status surface with live battery, events, and aperture styling. |
| DockShelf Pro | Gesture-revealed dock shelf with quick lanes and premium dock treatment. |
| FocusLens Pro | Context-aware quiet-hours profile with dimming, badge softening, and Focus-style status panel. |
| NotificationForge | Notification platter/banner redesign with priority lane accents and quiet-hours styling. |
| ControlCenter Studio | Control Center module and glyph theme engine. |
| HomeScreenZen Pro | Declutter system for labels, badges, widgets, and dock surfaces. |
| ApertureFX | SpringBoard animation pack for icons, banners, folders, and island surfaces. |
| StatusLab Pro | Status bar customization suite for labels, signal, battery, and activity indicators. |
| LockScreen Atmosphere | Lock screen visual engine for clock tinting, charging glow, and ambience. |
| SpringBoard Automations | Local trigger/action engine for charging, battery, ringer, network, and time modes. |

## Settings And Defaults

All premium tweaks are versioned `1.0.1-1`, include PreferenceLoader panes, and install disabled by default. Enable and respring one tweak at a time from Settings so a bad interaction does not immediately push SpringBoard back into a boot loop.

Every pane includes:

- `Enabled`: the main runtime gate.
- `Palette`: shared premium color presets.
- `Reset to Safe Defaults`: writes `enabled = false`.
- `Apply with Respring`: runs `sbreload`, falling back to `killall SpringBoard`.
