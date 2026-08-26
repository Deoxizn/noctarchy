# Changelog

<!-- Newest first. For new entries: add a dated section at the top,
     one bullet per change: - Description ([`short-hash`](commit-url)).
     Skip README rewordings, screenshots and demo videos. -->

## 2026-08-26

- Initial release — Niri + Noctalia shell replacement for Omarchy
- Niri config: scrollable tiling, spring animations, pink/blue/green focus ring, workspace binds, window/layer rules, xwayland-satellite
- Noctalia config: top bar, workspaces/clock/network/battery/volume/brightness/tray/media widgets, swaylock, wallpaper-driven theming
- Theme bridge hook: maps Omarchy colors.toml → Noctalia config.toml accent + Niri border colors live on every theme change
- Auto-sync hook: pulls repo and re-runs sync.sh after `omarchy-update`, flock-guarded, notifies on failure
- libalpm guard: prevents stock `omarchy-restart-shell` from killing Noctalia during package upgrades
- Menu suite: 13 scripts — fuzzel, menu, power, keybinds, restart, config, themes, media, version, update, terminal, splash, kernel
- Plymouth boot splash + SDDM greeter theme matching the Noctarchy identity
- Kernel submenu: CachyOS variants (default, BORE, EEVDF, LTS, RT-BORE) via chaotic-aur
- HiddenCommands.md: every stock Omarchy command the Noctarchy menu leaves out
- Branding: screensaver.txt + about.txt ASCII art
- Website: noctarchy.dirty.pizza landing page (CNAME ready)
- Install/sync/uninstall: full lifecycle with dry-run, backup, 3-way KDL merge, state tracking

## Fixes (post-release)

- Fixed `noctarchy-fuzzel`: fuzzel 1.14 uses `--background-color`/`--text-color` individually, not `--color` — wrapper was passing an invalid option and crashing all menus
- Fixed Niri config KDL parse error: `@DEFAULT_AUDIO_SINK@` inside `spawn` strings broke the KDL parser; switched media key binds to `spawn-sh`
- Fixed `install.sh` + `sync.sh` fastfetch branding: logo replacement regex stopped at first `}` inside nested padding objects — replaced with brace-counting parser
- Fixed Niri keybind conflicts: `Mod+Shift+F` was bound three times (fullscreen, focus-tiling, file manager) — re-separated to `SUPER+Ctrl+F`/`SUPER+Shift+P`/`SUPER+Shift+F`
- Fixed universal copy/paste: `SUPER+C/V/X` now use `wtype -M ctrl` to simulate Ctrl+C/V/X since Niri lacks Hyprland's `send-shortcut`
- Fixed Niri window rules: added `match` prefix to `app-id` and `open-floating true` value (bare `open-floating` is invalid)
- Fixed Niri layer rules: added `match` prefix to `namespace` and `blur` → `background-effect { blur true }` (standalone `blur` is invalid)
- Fixed `allow-when-locked=true` syntax: must be on keybind declaration line, not inside braces
- Fixed duplicate keybinds: `Mod+K`, `Mod+C`, `Mod+Ctrl+L` were each bound twice
- Fixed `overview` → `toggle-overview` (invalid action name)
- Fixed sync.sh: skip SDDM/UWSM/Plymouth sections gracefully when sudo unavailable (no TTY)
- Fastfetch: auto-detect foot/kitty/ghostty terminal for sixel/auto logo protocol instead of hardcoded `file` type
- Theme hook: now patches `config.toml` accent colors and Niri border colors, not just unused `theme.toml`
