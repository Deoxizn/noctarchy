# Changelog

<!-- Newest first. For new entries: add a dated section at the top,
     one bullet per change: - Description ([`short-hash`](commit-url)).
     Skip README rewordings, screenshots and demo videos. -->

## 2026-09-03

- Attempted a searchable menu index (first flat inside the root menu, then a standalone `Super+Alt+/` picker) — scrapped both; any flattened form turned the hierarchy into a wall of rows. Hierarchical menus only; submenus keep `$1` direct-dispatch ([`7e6d6d3`](https://github.com/deoxizn/noctarchy/commit/7e6d6d3), [`81e8982`](https://github.com/deoxizn/noctarchy/commit/81e8982), [`842ad53`](https://github.com/deoxizn/noctarchy/commit/842ad53), [`d2e8ae7`](https://github.com/deoxizn/noctarchy/commit/d2e8ae7), [`37d10fc`](https://github.com/deoxizn/noctarchy/commit/37d10fc))
- Fix `sync.sh`/`install.sh` overwriting customized `fastfetch/config.jsonc` with stock on every run: only stock or already-branded configs are re-branded now; user-customized configs are detected and left untouched ([`7e6d6d3`](https://github.com/deoxizn/noctarchy/commit/7e6d6d3))
- Fold Setup into System and add a Fonts picker: `noctarchy-setup` deleted (its Defaults duplicated System → Default Apps; Hardware reachable via root Hardware; Network/Security moved to System). Root menu drops Setup; System gains Fonts, Network, Security. New `noctarchy-fonts` adapts `omarchy-font-set` (same terminal + fontconfig writes, foot keeps `:size`, no shell restart, `notify-send`) with a fuzzel picker marking the current font ([`efb37bb`](https://github.com/deoxizn/noctarchy/commit/efb37bb))

- Fix Firmware updater window closing instantly: the Update menu's Firmware entry now wraps `omarchy-update-firmware` with a Press-Enter hold (exit code preserved), so results stay visible instead of vanishing when fwupd exits ([`1003248`](https://github.com/deoxizn/noctarchy/commit/1003248))
- Fix double-Enter when running `noctarchy-update-run` from the Noctalia arch-updater widget: the script now only shows its Press-Enter hold when stdout is a TTY — the widget pipes runs through tee with its own press-key hold + `::EXIT` marker, so the old unconditional hold forced a second Enter ([`1003248`](https://github.com/deoxizn/noctarchy/commit/1003248))
- Fix splash wrapper failing under the pacman hook (`cp: cannot stat .../branding/plymouth/noctarchy-logo.png`): hooks run as root (`$HOME=/root`), so `noctarchy-splash` never saw `$HOME/.local/state/noctarchy/repo-path` and fell back to a bogus relative path. The wrapper now exports the matched user's `HOME` before calling the script ([`6591324`](https://github.com/deoxizn/noctarchy/commit/6591324))
- Fix hook wrapper shadowing the interactive script: `/usr/local/bin/noctarchy-splash` hid `~/.local/bin/noctarchy-splash` in PATH, so `noctarchy-splash run refresh` silently no-op'd. Renamed to `/usr/local/bin/noctarchy-splash-hook`, hook Exec updated ([`2d1c456`](https://github.com/deoxizn/noctarchy/commit/2d1c456))
- Bump Plymouth logo 280×302 → 400×432 (regenerated from the 604px `branding/noctarchy.png` master; Stellarchy renders 360×384 — the script draws native pixels, no scaling — so 280px looked tiny on HiDPI) ([`a4c4489`](https://github.com/deoxizn/noctarchy/commit/a4c4489))
- Automate splash kernel hook deployment: `install.sh` and `sync.sh` now install `/usr/local/bin/noctarchy-splash-hook` + `/etc/pacman.d/hooks/noctarchy-splash.hook` (and clean up the pre-rename wrapper + old post-update.d hook) — no manual `sudo install` per machine. Also fixes both scripts referencing the deleted `post-update.d/noctarchy-splash.sh` ([`336052c`](https://github.com/deoxizn/noctarchy/commit/336052c))
- Fix `noctarchy-repo-sync` silently doing nothing on machines without a repo checkout at the script location (e.g. FW13): it now resolves the repo via `~/.local/state/noctarchy/repo-path` first and sends a notification instead of exiting invisibly ([`e356361`](https://github.com/deoxizn/noctarchy/commit/e356361))
- `sync.sh` now auto-removes `~/.local/bin` scripts no longer in the repo (renames left orphans with only a warning before) plus timestamped `noctarchy-*.bak.*` backups ([`7280e54`](https://github.com/deoxizn/noctarchy/commit/7280e54))

## 2026-09-02

- Add System → Snapshots and Cleaner launchers: non-interfering wrappers for `snaptui` (btrfs snapshot TUI, `TUI.snaptui` 1000×720) and `omacleaner` (selective preinstall remover, `TUI.float` 1000×720); only launch if binary exists, otherwise notify — installs stay via `~/Work/snaptui/install.sh` and `~/Work/omacleaner/install.sh` ([`ea57bf7`](https://github.com/deoxizn/noctarchy/commit/ea57bf7))
- Fix lock screen 20s monitor power-off shipping: `scripts/lock.sh` → `scripts/noctarchy-lock` (`~/.local/bin/noctarchy-lock`) so `install.sh`/`sync.sh` deploy it (was skipped as non-`noctarchy-*`); `Mod+Ctrl+L` now spawns `noctarchy-lock`, `noctarchy-power` Lock uses it, `swayidle` adds `resume power-on-monitors` — fixes GF PC where lock never powered off ([`def5bb1`](https://github.com/deoxizn/noctarchy/commit/def5bb1))
- Add `Mod+grave` (`` ` ``) agent binding to repo `config/niri/config.kdl` (`omarchy-agent`) — was only in personal dotfiles, now in noctarchy; docs already listed it ([`def5bb1`](https://github.com/deoxizn/noctarchy/commit/def5bb1))
- Update website footer and README stellarchy link: `omartia-dots-remux` → `stellarchy` (`https://github.com/deoxizn/stellarchy`) ([`def5bb1`](https://github.com/deoxizn/noctarchy/commit/def5bb1))

## 2026-08-31

- Plymouth: add `libalpm` hook (`/etc/pacman.d/hooks/noctarchy-splash.hook`) that re-applies the Noctarchy splash on any `linux*` install/upgrade regardless of method (`omarchy-update`, `noctarchy-update-run`, or manual `pacman -U`); fixes hook never firing on direct `pacman -U` (previously only `post-update.d` via `omarchy-hook`). Removes redundant `post-update.d/noctarchy-splash.sh` and uses system-wide wrapper `/usr/local/bin/noctarchy-splash` for multi-user portability ([`e86fdd7`](https://github.com/deoxizn/noctarchy/commit/e86fdd7), [`5d0e08b`](https://github.com/deoxizn/noctarchy/commit/5d0e08b), [`e0d97c3`](https://github.com/deoxizn/noctarchy/commit/e0d97c3), [`4f6cec9`](https://github.com/deoxizn/noctarchy/commit/4f6cec9))
- Menu: alphabetize root menu (Capture, Hardware, Packages, Reminders, Restart, Share, Setup, System, System Update, Themes) and System submenu (Boot Splash, Config, Default Apps, Kernel, Maintenance) ([`316772e`](https://github.com/deoxizn/noctarchy/commit/316772e)); rename System items (Defaults→Default Apps, Splash→Boot Splash, Update→Maintenance) and root Trigger→Hardware, Update→System Update, remove duplicate Config ([`8fe98e2`](https://github.com/deoxizn/noctarchy/commit/8fe98e2))
- `noctarchy-update-run`: handle `gum` without TTY for the plugin tee fix ([`e190324`](https://github.com/deoxizn/noctarchy/commit/e190324))

## 2026-08-30

- Add Capture and Reminders as top-level menus: Capture (OCR text, QR decode, color picker, transcode) and Reminders (set/quick/clear) from HiddenCommands — all via `TUI.float` terminal, with color picker via `hyprpicker`
- Add System → Update submenu: drive encryption password, user password, sync system clock, reset Plymouth config, reset tmux config (from HiddenCommands Update section) — all via `TUI.float` terminal at 1000×720
- Fix `post-update.d/noctarchy-splash.sh` plymouth hook: handle `linux-omarchy-bore` (and any `linux-*` variant) and correctly skip initramfs rebuild when no kernel was updated — previously the deployed hook lacked the kernel gate and rebuilt on every `omarchy-settings-dev` update, and the work hook's regex missed `linux-omarchy-bore`
- Add `noctarchy-share` as top-level Share menu: share clipboard, file, folder, or receive via LocalSend (`omarchy-menu-share` + `localsend --headless`), matching Omarchy's share menu but working on Niri; add Niri window rule for LocalSend/Share at 1100×700 floating (matching Hyprland `localsend.lua`); move Share from Trigger → top-level
- Make disk/network speed tests work on Niri: network tests open `https://fast.com` via `omarchy-launch-webapp` (default browser app window, 1100×700 floating with fast.com gauges), disk test uses `TUI.float` terminal at 1000×720 — functional on Niri, not the Omarchy shell overlay
- `HiddenCommands.md`: add `omarchy-windows-key` (print OEM Windows key), update Share section to document `noctarchy-share`

## 2026-08-29

- mpv now opens as a floating window by default, matching Hyprland behavior. No fixed size is applied — mpv requests its own size based on the video's native resolution (4K plays at 4K, 1080p at 1080p, etc.). The `open-on-workspace "media"` rule still applies so mpv opens on the correct workspace
- Add beginner-friendly inline comments to the Niri config: every setting now has a short explanation of what it does and how to customize it, covering environment variables, cursor, input, layout, animations, keybindings, window rules, layer rules, startup commands, blur, clipboard, screenshots, and CSD
- Add `TUI.float` Niri window rule: apps launched with `--app-id=TUI.float` (noctarchy-install, noctarchy-themes, noctarchy-remove, noctarchy-network) now float at 1000×720 centered, matching the Hyprland `TUI.float` behavior

## 2026-08-28

- `theme-set.d/noctalia-sync.sh` no longer maps Noctalia's panel/menu/launcher surfaces (`mSurfaceVariant`, `mHover`, `mShadow`) to the theme's `selection` color, which could be light/near-white (e.g. `neo-eldritch`) and render the launcher and widget backgrounds white. It now derives those surfaces from the theme's dark background tones (`lighter_bg`, `dark_bg`, `darker_bg`) with sensible fallbacks, keeping `selection` only as the true selection color
- `noctarchy-update-run` no longer auto-closes when done: it now offers a reboot prompt when the kernel was updated (mirroring `omarchy-update-restart`), and otherwise holds the terminal open with a "Press Enter to close the update window" prompt so the update output can be reviewed before the window closes ([`bea4387`](https://github.com/deoxizn/noctarchy/commit/bea4387))
- `post-update.d/noctarchy-splash.sh` now only re-adopts the Plymouth splash when a **kernel package** (linux/linux-cachyos/linux-zen/… or their `-headers`) was part of that transaction, instead of rebuilding the initramfs on every update. Reads `/var/log/pacman.log` from the start of the latest transaction and matches kernel packages while excluding `linux-firmware*`

## 2026-08-27

- Make the Noctarchy Plymouth splash survive system updates: `omarchy-settings-dev` owns `/usr/share/plymouth/themes/omarchy/` and, on every `pacman -Syu` that upgrades it (including kernel updates), overwrites that theme dir and re-asserts `Theme=omarchy`, clobbering the adopt. Add a `post-update.d/noctarchy-splash.sh` hook that re-adopts the self-contained noctarchy theme after every update, and fix `noctarchy-splash` to resolve `branding/` via the `~/.local/state/noctarchy/repo-path` state file (so the installed `~/.local/bin` copy can find it).
- Document the default-agent keybind: `SUPER+grave` (`` ` ``) spawns the default coding agent (`omarchy-agent`, e.g. opencode) in a terminal; added to the README keybinds table and the website keybindings section. The binding itself lives in the personal `dotfiles/niri/config.kdl`
- Fix `noctarchy-update` "Noctarchy" entry opening a terminal and closing instantly: `noctarchy-terminal` now launches commands via `xdg-terminal-exec` (resolves your real default terminal — kitty, or foot on default Omarchy — and passes the command with correct per-terminal syntax) instead of a hardcoded list + bare positional args
- Add `noctarchy-update-run`: a Noctarchy-native updater that runs the same safe Omarchy primitives as `omarchy-update` (`requires-free-space`, `pkg-prune`, `snapshot`, `stay-awake`, `dev`, `keyring`, `system-pkgs`, `migrate`, `hook post-update`, `aur-pkgs`, `mise`, `orphan-pkgs`, `analyze-logs`) but without the `script` re-exec, the `omarchy-update-lock` race (two windows no longer fight over the lock and die instantly with "An Omarchy update is already running"), or the fragile `status`/`restart` tail (which call `omarchy-shell` and check for Hyprland). The Noctarchy repo sync still runs via the existing `post-update` hook. Reroute the Update menu's "Noctarchy" entry to it.
- Rewrite `noctarchy-update` as a menu matching Stellarchy: Noctarchy (omarchy-update), Channel picker, Extra themes, Hardware, Firmware, plus a new Repo sync entry (was the inline repo pull); drop Hyprsunset (Hyprland-only) ([`noctarchy-repo-sync`](https://github.com/deoxizn/noctarchy/scripts/noctarchy-repo-sync))
- Rewrite `HiddenCommands.md` to mirror Stellarchy's curated list, filtered for Niri/Noctalia: drop Hyprland-only and Omarchy-shell-dependent commands, add newer compatible ones (capture-text/qr, Taildrop send/receive, toggle, reinstall) ([`643a5d2`](https://github.com/deoxizn/noctarchy/commit/643a5d2))
- Add `System` and `Trigger` submenus to the root menu: `System` opens Config/Defaults/Kernel/Splash, `Trigger` opens Hardware/Speed Test (port of Stellarchy's stub submenus)
- Fix `sync.sh`: stop clobbering personalized `~/.config/noctalia/config.toml` on every update — an existing config is now preserved (only installed if absent) so per-machine bar/widget customizations (bongocat, arch-updater, lockscreen monitors) survive `omarchy-update` ([`40fc6a2`](https://github.com/deoxizn/noctarchy/commit/40fc6a2))

## 2026-08-26

- Swap screenshot bindings: `Ctrl+Print` saves to `~/Pictures`, `Alt+Print` copies to clipboard (easier to reach) ([`f9a1394`](https://github.com/deoxizn/noctarchy/commit/f9a1394))
- Lock screen now powers off monitors after 20s (only if still locked); swayidle handles 10min idle monitor power-off ([`fcd686f`](https://github.com/deoxizn/noctarchy/commit/fcd686f))
- Fix lock script: use `noctalia msg session lock` instead of broken `niri msg action lock` ([`3039ca0`](https://github.com/deoxizn/noctarchy/commit/3039ca0))
- Remove screensaver from power menu (Niri doesn't support per-output fullscreen launch)
- Remove redundant notifications from auto-sync hook (terminal already shows status)
- Uninstall: restore stock plymouth splash, remove SDDM theme, clean up theme bridge hook, offer to remove repo directory ([`2271d5b`](https://github.com/deoxizn/noctarchy/commit/2271d5b))
- Uninstall: revert `omarchy-restart-shell` guard patch to restore stock shell behavior
- Add libalpm guard: patch `omarchy-restart-shell` to skip when Noctalia is active (prevents "shell did not become ready" error on `omarchy-update`) ([`f1b2674`](https://github.com/deoxizn/noctarchy/commit/f1b2674))
- Restore palette source toggle in themes menu (switch between custom palette and Material You) ([`2164942`](https://github.com/deoxizn/noctarchy/commit/2164942))
- Fix noctalia service crash loop: skip start when already running via uwsm session ([`42f5056`](https://github.com/deoxizn/noctarchy/commit/42f5056))
- Install: show `uwsm stop` command in summary so users know how to start Niri ([`795ac4b`](https://github.com/deoxizn/noctarchy/commit/795ac4b))
- Install: remove `omarchy.desktop` after installing niri session so `uwsm stop` defaults to Niri on first logout ([`15760ef`](https://github.com/deoxizn/noctarchy/commit/15760ef))
- Website: clean up keybinds table, remove duplicate sections ([`53bfc26`](https://github.com/deoxizn/noctarchy/commit/53bfc26))
- Update README: full keybinds table, complete menu suite, Niri/Noctalia-specific sections ([`e06266b`](https://github.com/deoxizn/noctarchy/commit/e06266b))
- Fix theme hook wallpaper: copy wallpapers to noctalia state dir + call `noctalia msg wallpaper-set` ([`f0c323e`](https://github.com/deoxizn/noctarchy/commit/f0c323e))
- Add Config submenu: edit niri/noctalia/palettes/hooks/scripts from root menu ([`fddfb23`](https://github.com/deoxizn/noctarchy/commit/fddfb23))
- Remap keybinds: terminal → `Mod+Return`, power menu → `Mod+Escape`, launchers → `Mod+Space` (fuzzel) / `Mod+D` (Noctalia), apps → `Mod+Shift+B/E/F` ([`fbf030f`](https://github.com/deoxizn/noctarchy/commit/fbf030f))
- Rewrite `noctarchy-keybinds` parser: reads actual `config.kdl` with human-readable descriptions ([`d538cd6`](https://github.com/deoxizn/noctarchy/commit/d538cd6))
- Port all Stellarchy menu scripts: defaults, hardware, install, packages, remove, network, security, setup, speedtest, wifi-qr, update-hardware ([`3857111`](https://github.com/deoxizn/noctarchy/commit/3857111))
- Add theme toggle: switch between palette-derived and wallpaper-generated bar colors from themes menu ([`3857111`](https://github.com/deoxizn/noctarchy/commit/3857111))
- Add `noctarchy-themes-list`: theme browser with preview images via fuzzel icon protocol ([`3857111`](https://github.com/deoxizn/noctarchy/commit/3857111))
- Fix Escape back-navigation: all submenu scripts use `|| exec parent-menu` instead of `|| exit 0` ([`3857111`](https://github.com/deoxizn/noctarchy/commit/3857111))
- Fix niri keybind syntax: `?` → `slash` (invalid key name) ([`2cc33a0`](https://github.com/deoxizn/noctarchy/commit/2cc33a0))
- Fix Noctalia IPC: all `noctalia ipc` calls → `noctalia msg` (lock, launcher, clipboard, notifications) ([`75a08e4`](https://github.com/deoxizn/noctarchy/commit/75a08e4))
- Fix `noctarchy-fuzzel`: remove `--inner-border-width` (not supported in fuzzel 1.14) ([`56cd0ac`](https://github.com/deoxizn/noctarchy/commit/56cd0ac))
- Fix `sync.sh`: skip SDDM, UWSM and Plymouth sections gracefully when sudo unavailable (no TTY) ([`8001eec`](https://github.com/deoxizn/noctarchy/commit/8001eec))
- Fix fastfetch logo type: `auto` for ghostty/kitty, `sixel` for foot ([`f66be51`](https://github.com/deoxizn/noctarchy/commit/f66be51))
- Theme hook: patch Noctalia `config.toml` accent colors and Niri border colors on every theme change, not just unused `theme.toml` ([`f9567e1`](https://github.com/deoxizn/noctarchy/commit/f9567e1))
- Fix Niri config: window rules need `match` prefix on `app-id`, `open-floating` needs `true` value, layer rules need `background-effect { blur true }` not standalone `blur` ([`d82f430`](https://github.com/deoxizn/noctarchy/commit/d82f430))
- Fix `allow-when-locked=true` syntax: must be on keybind declaration line, not inside braces ([`d82f430`](https://github.com/deoxizn/noctarchy/commit/d82f430))
- Fix duplicate keybinds: `Mod+K`, `Mod+C`, `Mod+Ctrl+L` were each bound twice ([`d82f430`](https://github.com/deoxizn/noctarchy/commit/d82f430))
- Fix `overview` → `toggle-overview` (invalid action name) ([`d82f430`](https://github.com/deoxizn/noctarchy/commit/d82f430))
- Fastfetch: auto-detect foot/kitty/ghostty terminal for sixel/auto logo protocol ([`f9567e1`](https://github.com/deoxizn/noctarchy/commit/f9567e1))
- Fix `noctarchy-fuzzel`: fuzzel 1.14 uses `--background-color`/`--text-color` individually, not `--color` ([`7a0abb9`](https://github.com/deoxizn/noctarchy/commit/7a0abb9))
- Fix `install.sh` + `sync.sh` fastfetch branding: logo replacement regex stopped at first `}` inside nested padding — replaced with brace-counting parser ([`fc7c168`](https://github.com/deoxizn/noctarchy/commit/fc7c168))
- Fix Niri config KDL parse error: `@DEFAULT_AUDIO_SINK@` inside `spawn` strings broke the parser; switched media key binds to `spawn-sh` ([`a490ce4`](https://github.com/deoxizn/noctarchy/commit/a490ce4))
- Fix universal copy/paste: `SUPER+C/V/X` now use `wtype -M ctrl` since Niri lacks Hyprland's `send-shortcut` ([`4f3f558`](https://github.com/deoxizn/noctarchy/commit/4f3f558))
- Fix Niri keybind conflicts: `SUPER+Shift+F` was bound three times — re-separated ([`4106064`](https://github.com/deoxizn/noctarchy/commit/4106064))
- Website: full keybinds table, universal copy/paste honesty note ([`ed225cd`](https://github.com/deoxizn/noctarchy/commit/ed225cd))
- Website: rename keybinds section to "The night shift" ([`d82f430`](https://github.com/deoxizn/noctarchy/commit/d82f430))
- Initial release — Niri + Noctalia shell replacement for Omarchy ([`9cb988d`](https://github.com/deoxizn/noctarchy/commit/9cb988d))
- Niri config: scrollable tiling, spring animations, focus ring, workspace binds, window/layer rules, xwayland-satellite ([`9cb988d`](https://github.com/deoxizn/noctarchy/commit/9cb988d))
- Noctalia config: top bar, workspaces/clock/network/battery/volume/brightness/tray/media widgets, swaylock, wallpaper-driven theming ([`9cb988d`](https://github.com/deoxizn/noctarchy/commit/9cb988d))
- Theme bridge hook: maps Omarchy colors.toml → Noctalia palette + wallpaper sync on every theme change ([`43c3394`](https://github.com/deoxizn/noctarchy/commit/43c3394))
- Auto-sync hook: pulls repo and re-runs sync.sh after `omarchy-update` ([`43c3394`](https://github.com/deoxizn/noctarchy/commit/43c3394))
- libalpm guard: prevents stock `omarchy-restart-shell` from killing Noctalia during package upgrades ([`43c3394`](https://github.com/deoxizn/noctarchy/commit/43c3394))
- Menu suite: 13 scripts — fuzzel, menu, power, keybinds, restart, config, themes, media, version, update, terminal, splash, kernel ([`43c3394`](https://github.com/deoxizn/noctarchy/commit/43c3394))
- Plymouth boot splash + SDDM greeter theme matching the Noctarchy identity ([`af53ab7`](https://github.com/deoxizn/noctarchy/commit/af53ab7))
- Kernel submenu: CachyOS variants (default, BORE, EEVDF, LTS, RT-BORE) via chaotic-aur ([`af53ab7`](https://github.com/deoxizn/noctarchy/commit/af53ab7))
- HiddenCommands.md: every stock Omarchy command the Noctarchy menu leaves out ([`af53ab7`](https://github.com/deoxizn/noctarchy/commit/af53ab7))
- Branding: screensaver.txt + about.txt ASCII art, fastfetch branded in sync.sh ([`43c3394`](https://github.com/deoxizn/noctarchy/commit/43c3394))
- Website: noctarchy.dirty.pizza landing page ([`a3040f7`](https://github.com/deoxizn/noctarchy/commit/a3040f7))
- Install/sync/uninstall: full lifecycle with dry-run, backup, 3-way KDL merge, state tracking ([`9cb988d`](https://github.com/deoxizn/noctarchy/commit/9cb988d))
