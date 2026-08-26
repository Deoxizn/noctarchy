# Hidden Commands

Every stock Omarchy menu command the Noctarchy menu leaves out, runnable by hand.

## omarchy commands

| Command | What it does |
|---|---|
| `omarchy defaults terminal` | Reset terminal to stock theme |
| `omarchy defaults keybindings` | Reset keybindings to stock |
| `omarchy defaults theme` | Reset theme to default |
| `omarchy defaults shell` | Reset shell settings to stock |
| `omarchy refresh hyprland` | Regenerate Hyprland config from templates |
| `omarchy refresh fonts` | Rebuild font cache |
| `omarchy refresh desktop` | Refresh desktop entries |
| `omarchy theme set <name>` | Apply a theme by name |
| `omarchy theme list` | List available themes |
| `omarchy theme current` | Show current theme |
| `omarchy update` | Update system packages |
| `omarchy version` | Show Omarchy version |

## Noctarchy commands

| Command | What it does |
|---|---|
| `noctarchy-version` | Show Noctarchy version |
| `noctarchy-fuzzel` | Launch Noctarchy-themed fuzzel |
| `noctarchy-menu` | Launch root menu |
| `noctarchy-power` | Launch power menu |
| `noctarchy-keybinds` | Show keybinding list |
| `noctarchy-themes` | Theme switcher with previews |
| `noctarchy-restart` | Restart Noctalia shell |
| `noctarchy-config` | Edit Noctalia config |
| `noctarchy-update` | Update Noctarchy + system |
| `noctarchy-media` | MPRIS media controls |
| `noctarchy-terminal` | Launch terminal |
| `noctarchy-splash run adopt` | Adopt Noctarchy boot splash |
| `noctarchy-splash run refresh` | Refresh splash assets |
| `noctarchy-splash run status` | Check splash status |
| `noctarchy-kernel run default` | Install CachyOS default kernel |
| `noctarchy-kernel run bore` | Install BORE kernel |
| `noctarchy-kernel run eevdf` | Install EEVDF kernel |
| `noctarchy-kernel run lts` | Install LTS kernel |
| `noctarchy-kernel run rt-bore` | Install RT BORE kernel |
| `noctarchy-kernel run status` | Check kernel status |

## Niri commands

| Command | What it does |
|---|---|
| `niri msg action load-config-file` | Reload Niri config live |
| `niri msg action focus-window left` | Focus window left |
| `niri msg action focus-window right` | Focus window right |
| `niri msg action focus-workspace-up` | Focus workspace up |
| `niri msg action focus-workspace-down` | Focus workspace down |
| `niri msg action move-window-to-workspace-up` | Move window to workspace up |
| `niri msg action move-window-to-workspace-down` | Move window to workspace down |
| `niri msg -t keyboard-layouts` | List keyboard layouts |
| `niri msg -t outputs` | List connected outputs |
| `niri msg -t windows` | List open windows |
| `niri msg -t workspaces` | List workspaces |
| `niri msg -t focused-window` | Show focused window info |
| `niri msg -t version` | Show Niri version |

## Noctalia commands

| Command | What it does |
|---|---|
| `noctalia --version` | Show Noctalia version |
| `systemctl --user restart noctalia` | Restart Noctalia shell |
| `systemctl --user status noctalia` | Check Noctalia status |
| `journalctl --user -u noctalia` | View Noctalia logs |
