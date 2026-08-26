# Changelog

<!-- Newest first. For new entries: add a dated section at the top,
     one bullet per change: - Description ([`short-hash`](commit-url)).
     Skip README rewordings, screenshots and demo videos. -->

## 2026-08-26

- Initial release — Niri + Noctalia shell replacement for Omarchy
- Niri config: scrollable tiling, spring animations, pink/blue/green focus ring, workspace binds, window/layer rules, xwayland-satellite
- Noctalia config: top bar, workspaces/clock/network/battery/volume/brightness/tray/media widgets, swaylock, wallpaper-driven theming
- Theme bridge hook: maps Omarchy colors.toml → Noctalia palette + wallpaper sync on every theme change
- Auto-sync hook: pulls repo and re-runs sync.sh after `omarchy-update`, flock-guarded, notifies on failure
- libalpm guard: prevents stock `omarchy-restart-shell` from killing Noctalia during package upgrades
- Menu suite: 13 scripts — fuzzel, menu, power, keybinds, restart, config, themes, media, version, update, terminal, splash, kernel
- Plymouth boot splash + SDDM greeter theme matching the Noctarchy identity
- Kernel submenu: CachyOS variants (default, BORE, EEVDF, LTS, RT-BORE) via chaotic-aur
- HiddenCommands.md: every stock Omarchy command the Noctarchy menu leaves out
- Branding: screensaver.txt + about.txt ASCII art, fastfetch branded in sync.sh
- Website: noctarchy.dirty.pizza landing page (CNAME ready)
- Install/sync/uninstall: full lifecycle with dry-run, backup, 3-way KDL merge, state tracking
