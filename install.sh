#!/usr/bin/env bash
# ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
# ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
# ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
# ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
# ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝

# noctarchy installer
# Replaces omarchy-shell + Hyprland with Niri + Noctalia
# https://github.com/deoxizn/noctarchy

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# When run via sudo, $HOME points to /root — resolve the real user's home
if [[ -n "${SUDO_USER:-}" ]]; then
  HOME="$(eval echo "~$SUDO_USER")"
fi

BACKUP_DIR="$HOME/.config/noctarchy-backup"
BACKUP_TS="$(date +%Y%m%d%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_TS"
OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
STATE_DIR="$HOME/.local/state/noctarchy"
STATE_REPO_FILE="$STATE_DIR/repo-dir"
XDG_REPO_DEFAULT="$HOME/.local/opt/noctarchy"
YES=false
DRY_RUN=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[noctarchy]${NC} $*"; }
ok()    { echo -e "${GREEN}[noctarchy]${NC} $*"; }
warn()  { echo -e "${YELLOW}[noctarchy]${NC} $*"; }
err()   { echo -e "${RED}[noctarchy]${NC} $*" >&2; }

confirm() {
  if $YES; then return 0; fi
  read -rp "$1 [y/N] " REPLY
  [[ "$REPLY" =~ ^[Yy]$ ]]
}

run() {
  if $DRY_RUN; then
    info "[dry-run] would run: $*"
    return 0
  fi
  "$@"
}

run_sudo() {
  if $DRY_RUN; then
    info "[dry-run] would run: sudo $*"
    return 0
  fi
  sudo "$@"
}

# ──────────────────────────────────────────────
# Preflight checks
# ──────────────────────────────────────────────

if $DRY_RUN; then
  echo ""
  ok "═══════════════════════════════════════════"
  ok "  DRY RUN MODE — no changes will be made"
  ok "═══════════════════════════════════════════"
  echo ""
fi

if [[ ! -d "$OMARCHY_PATH/default" ]]; then
  err "Omarchy not found at $OMARCHY_PATH"
  err "Install omarchy first: https://github.com/basecamp/omarchy"
  exit 1
fi
ok "Omarchy found at $OMARCHY_PATH"

if [[ "$(id -u)" -eq 0 ]]; then
  err "Do not run this installer as root"
  exit 1
fi

# Refresh package databases
info "Refreshing package databases..."
if ! $DRY_RUN; then
  run_sudo pacman -Sy --noconfirm
fi

# ──────────────────────────────────────────────
# Install dependencies
# ──────────────────────────────────────────────

info "Checking dependencies..."

DEPS_PKGS=()
for pkg in niri noctalia fuzzel grim slurp wl-clipboard libnotify \
  swayidle swaylock swaybg mako xwayland-satellite playerctl; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    DEPS_PKGS+=("$pkg")
  fi
done

if [[ ${#DEPS_PKGS[@]} -gt 0 ]]; then
  if $DRY_RUN; then
    info "[dry-run] would install: ${DEPS_PKGS[*]}"
  else
    info "Installing: ${DEPS_PKGS[*]}"
    run_sudo pacman -S --noconfirm "${DEPS_PKGS[@]}"
    ok "Dependencies installed"
  fi
else
  ok "All dependencies already installed"
fi

# ──────────────────────────────────────────────
# Backup existing configs
# ──────────────────────────────────────────────

if $DRY_RUN; then
  info "[dry-run] would backup configs to $BACKUP_PATH"
else
  info "Backing up existing configs to $BACKUP_PATH"
  mkdir -p "$BACKUP_PATH"

  # Backup Hyprland configs
  for f in "$HOME/.config/hypr"/*.lua "$HOME/.config/hypr"/*.conf; do
    [[ -f "$f" ]] && cp "$f" "$BACKUP_PATH/"
  done

  # Backup omarchy shell.json
  [[ -f "$HOME/.config/omarchy/shell.json" ]] && cp "$HOME/.config/omarchy/shell.json" "$BACKUP_PATH/"

  # Backup existing niri config
  [[ -f "$HOME/.config/niri/config.kdl" ]] && cp "$HOME/.config/niri/config.kdl" "$BACKUP_PATH/"

  # Backup existing noctalia config
  [[ -d "$HOME/.config/noctalia" ]] && cp -r "$HOME/.config/noctalia" "$BACKUP_PATH/noctalia"

  ok "Backup complete"
fi

# ──────────────────────────────────────────────
# Install Niri config
# ──────────────────────────────────────────────

info "Installing Niri config..."

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/niri"
  cp "$REPO_DIR/config/niri/config.kdl" "$HOME/.config/niri/config.kdl"
fi
ok "  niri/config.kdl"

# ──────────────────────────────────────────────
# Install Noctalia config
# ──────────────────────────────────────────────

info "Installing Noctalia config..."

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/noctalia"
  cp "$REPO_DIR/config/noctalia/config.toml" "$HOME/.config/noctalia/config.toml"
fi
ok "  noctalia/config.toml"

# ──────────────────────────────────────────────
# Disable Hyprland autostart (Noctarchy uses Niri)
# ──────────────────────────────────────────────

info "Disabling Hyprland autostart..."

# Prevent omarchy shell from launching — we use Noctalia instead
# Similar to how Stellarchy stubs the autostart module
HYPRLAND_FILE="$HOME/.config/hypr/hyprland.lua"
if [[ -f "$HYPRLAND_FILE" ]]; then
  if grep -q 'package.loaded\["default.hypr.autostart"\] = true' "$HYPRLAND_FILE" 2>/dev/null; then
    warn "  hyprland.lua already has autostart override — skipped"
  elif $DRY_RUN; then
    info "[dry-run] would patch hyprland.lua (disable default autostart)"
  else
    python3 - "$HYPRLAND_FILE" << 'STUBPY'
import sys

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

marker = 'package.loaded["default.hypr.autostart"]'
lines = [l for l in lines if marker not in l and "Noctarchy: prevent default omarchy autostart" not in l]
while lines and lines[0].strip() == "":
    lines.pop(0)

stub = [
    "-- Noctarchy: prevent default omarchy autostart (Niri + Noctalia handles shell launch).\n",
    "-- Must be set AFTER bootstrap.lua: it clears package.loaded for default.hypr.*\n",
    "-- on every load/reload, so a stub placed before it gets wiped.\n",
    'package.loaded["default.hypr.autostart"] = true\n',
    "\n",
]

idx = next((i for i, l in enumerate(lines) if "default/hypr/bootstrap.lua" in l), None)
anchor = "after bootstrap.lua dofile"
if idx is None:
    idx = next((i for i, l in enumerate(lines) if 'require("default.hypr.omarchy")' in l), None)
    anchor = "before require(default.hypr.omarchy)"
if idx is None:
    sys.exit(1)

lines[idx + 1:idx + 1] = stub
with open(path, "w") as f:
    f.writelines(lines)
print(f"  injected {anchor}")
sys.exit(0)
STUBPY
    if [[ $? -eq 0 ]]; then
      ok "  hyprland.lua patched (default autostart disabled)"
    else
      err "  Could not patch hyprland.lua automatically"
    fi
  fi
fi

# ──────────────────────────────────────────────
# Install Noctalia systemd service
# ──────────────────────────────────────────────

info "Installing Noctalia systemd service..."

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/noctalia.service" <<EOF
[Unit]
Description=Noctalia Shell
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/noctalia
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable noctalia.service
fi
ok "  noctalia.service (auto-restart enabled)"

# ──────────────────────────────────────────────
# Disable stock Omarchy shell services
# ──────────────────────────────────────────────

if systemctl --user is-enabled --quiet omarchy-sleep-lock.service 2>/dev/null; then
  if ! $DRY_RUN; then
    systemctl --user disable --now omarchy-sleep-lock.service 2>/dev/null || true
  fi
  ok "  omarchy-sleep-lock.service disabled"
fi

if systemctl --user is-enabled --quiet omarchy-shell.service 2>/dev/null; then
  if ! $DRY_RUN; then
    systemctl --user disable --now omarchy-shell.service 2>/dev/null || true
  fi
  ok "  omarchy-shell.service disabled"
fi

# ──────────────────────────────────────────────
# Install theme bridge hook
# ──────────────────────────────────────────────

info "Installing theme bridge hook..."

HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
if ! $DRY_RUN; then
  mkdir -p "$HOOK_DIR"
  cp "$REPO_DIR/hooks/theme-set.d/noctalia-sync.sh" "$HOOK_DIR/noctalia-sync.sh"
  chmod +x "$HOOK_DIR/noctalia-sync.sh"
fi
ok "Theme bridge hook installed"

# ──────────────────────────────────────────────
# Install auto-sync hook
# ──────────────────────────────────────────────

info "Installing omarchy-update auto-sync hook..."

HOOK_DIR="$HOME/.config/omarchy/hooks/post-update.d"
if ! $DRY_RUN; then
  mkdir -p "$HOOK_DIR"
  sed "s|@REPO_DIR@|$REPO_DIR|" "$REPO_DIR/hooks/post-update.d/noctarchy-repo-sync.sh" \
    > "$HOOK_DIR/noctarchy-repo-sync.sh"
  chmod +x "$HOOK_DIR/noctarchy-repo-sync.sh"
fi
ok "Auto-sync hook installed"

# ──────────────────────────────────────────────
# Write state file
# ──────────────────────────────────────────────

if ! $DRY_RUN; then
  mkdir -p "$STATE_DIR"
  echo "$REPO_DIR" > "$STATE_REPO_FILE"
fi
ok "State file written: $STATE_REPO_FILE"

# ──────────────────────────────────────────────
# Install noctarchy menu suite
# ──────────────────────────────────────────────

info "Installing noctarchy menu suite..."

if ! $DRY_RUN; then
  mkdir -p "$HOME/.local/bin"
  for f in "$REPO_DIR"/scripts/noctarchy-*; do
    [[ -f "$f" ]] && install -m755 "$f" "$HOME/.local/bin/"
  done
fi
ok "noctarchy menus installed"

# ──────────────────────────────────────────────
# SDDM greeter — noctarchy theme
# ──────────────────────────────────────────────

info "SDDM greeter..."
SDDM_SRC="$REPO_DIR/branding/sddm-theme"
SDDM_DST="/usr/share/sddm/themes/noctarchy"
OMARCHY_SDDM="/usr/share/sddm/themes/omarchy"
SDDM_CONF="/etc/sddm.conf.d/10-theme.conf"

if ! $DRY_RUN; then
  if [[ -d $OMARCHY_SDDM ]]; then
    run_sudo mkdir -p "$SDDM_DST"
    for f in logo.png metadata.desktop theme.conf; do
      if [[ ! -f $SDDM_DST/$f ]] || ! cmp -s "$SDDM_SRC/$f" "$SDDM_DST/$f"; then
        run_sudo cp "$SDDM_SRC/$f" "$SDDM_DST/$f"
      fi
    done
    # Main.qml from repo (has logo size cap); stock assets from omarchy
    for f in Main.qml; do
      src="$SDDM_SRC/$f"
      if [[ -f "$src" ]] && ! cmp -s "$src" "$SDDM_DST/$f"; then
        run_sudo cp "$src" "$SDDM_DST/$f"
      fi
    done
    for f in bullet.png entry.png entry-failed.png lock.png lock-failed.png; do
      if [[ -f $OMARCHY_SDDM/$f ]] && ! cmp -s "$OMARCHY_SDDM/$f" "$SDDM_DST/$f"; then
        run_sudo cp "$OMARCHY_SDDM/$f" "$SDDM_DST/$f"
      fi
    done
    if [[ -f $SDDM_CONF ]] && grep -q '^Current=omarchy' "$SDDM_CONF"; then
      run_sudo sed -i 's/^Current=.*/Current=noctarchy/' "$SDDM_CONF"
    fi
    # Also patch the omarchy login override if present
    for f in /etc/sddm.conf.d/99-omarchy-login.conf /etc/sddm.conf.d/omarchy.conf; do
      if [[ -f "$f" ]] && grep -q '^Current=omarchy' "$f" 2>/dev/null; then
        run_sudo sed -i 's/^Current=.*/Current=noctarchy/' "$f"
      fi
      # Ensure RememberLastSession=false so SDDM doesn't remember old session
      if [[ -f "$f" ]] && grep -q '^RememberLastSession=true' "$f" 2>/dev/null; then
        run_sudo sed -i 's/^RememberLastSession=true/RememberLastSession=false/' "$f"
      fi
    done
    # Patch autologin.conf to default to niri
    AUTOLOGIN="/etc/sddm.conf.d/autologin.conf"
    if [[ -f "$AUTOLOGIN" ]] && grep -q 'Session=omarchy' "$AUTOLOGIN" 2>/dev/null; then
      run_sudo sed -i 's/Session=.*/Session=niri.desktop/' "$AUTOLOGIN"
      ok "autologin.conf patched → niri.desktop"
    fi
    ok "SDDM greeter: noctarchy theme active"
  else
    warn "  Omarchy SDDM theme not found — skipping (greeter stays stock)"
  fi

  # Set Niri as default session via Autologin section
  SDDM_SESSION="/etc/sddm.conf.d/10-session.conf"
  SDDM_SESSION_SRC="$REPO_DIR/branding/sddm/10-session.conf"
  if [[ -f "$SDDM_SESSION_SRC" ]]; then
    if [[ ! -f "$SDDM_SESSION" ]] || ! grep -q 'niri.desktop' "$SDDM_SESSION" 2>/dev/null || grep -q 'Session=wayland=' "$SDDM_SESSION" 2>/dev/null; then
      run_sudo mkdir -p /etc/sddm.conf.d
      run_sudo cp "$SDDM_SESSION_SRC" "$SDDM_SESSION"
      ok "SDDM default session set to Niri"
    else
      ok "SDDM default session already set to Niri"
    fi
  else
    if [[ ! -f "$SDDM_SESSION" ]] || ! grep -q 'niri.desktop' "$SDDM_SESSION" 2>/dev/null; then
      run_sudo mkdir -p /etc/sddm.conf.d
      run_sudo bash -c 'printf "[Autologin]\nSession=niri.desktop\n\n[Users]\nRememberLastUser=true\nRememberLastSession=false\n" > /etc/sddm.conf.d/10-session.conf'
      ok "SDDM default session set to Niri"
    else
      ok "SDDM default session already set to Niri"
    fi
  fi

  # Install UWSM niri session file (sorts first in SDDM session list)
  UWSM_SESSION_DIR="/usr/local/share/wayland-sessions"
  UWSM_SESSION_SRC="$REPO_DIR/branding/uwsm-sessions/00-niri-uwsm.desktop"
  if [[ -f "$UWSM_SESSION_SRC" ]]; then
    run_sudo mkdir -p "$UWSM_SESSION_DIR"
    if [[ ! -f "$UWSM_SESSION_DIR/00-niri-uwsm.desktop" ]] || ! cmp -s "$UWSM_SESSION_SRC" "$UWSM_SESSION_DIR/00-niri-uwsm.desktop"; then
      run_sudo cp "$UWSM_SESSION_SRC" "$UWSM_SESSION_DIR/00-niri-uwsm.desktop"
      ok "UWSM niri session installed"
    else
      ok "UWSM niri session already installed"
    fi
  fi
else
  info "[dry-run] would install noctarchy SDDM greeter theme (+ switch Current= if stock)"
fi

# ──────────────────────────────────────────────
# Plymouth splash — noctarchy theme
# ──────────────────────────────────────────────

info "Plymouth boot splash..."
PLYMOUTH_SRC="$REPO_DIR/branding/plymouth"
PLYMOUTH_DST="/usr/share/plymouth/themes/noctarchy"
OMARCHY_PLY="/usr/share/plymouth/themes/omarchy"

if ! $DRY_RUN; then
  if [[ -d $OMARCHY_PLY ]]; then
    run_sudo mkdir -p "$PLYMOUTH_DST"
    for pair in "noctarchy-logo.png:logo.png" "noctarchy.plymouth:noctarchy.plymouth"; do
      src="$PLYMOUTH_SRC/${pair%%:*}"
      dst="$PLYMOUTH_DST/${pair##*:}"
      if [[ ! -f $dst ]] || ! cmp -s "$src" "$dst"; then
        run_sudo cp "$src" "$dst"
      fi
    done
    for f in bullet.png entry.png lock.png progress_bar.png progress_box.png omarchy.script; do
      if [[ -f $OMARCHY_PLY/$f ]] && ! cmp -s "$OMARCHY_PLY/$f" "$PLYMOUTH_DST/$f"; then
        run_sudo cp "$OMARCHY_PLY/$f" "$PLYMOUTH_DST/$f"
      fi
    done
    if ! grep -q '^Theme=noctarchy' /etc/plymouth/plymouthd.conf 2>/dev/null; then
      run_sudo plymouth-set-default-theme noctarchy
    fi
    ok "Plymouth splash: noctarchy theme active"
  else
    warn "  Omarchy plymouth theme not found — skipping"
  fi
else
  info "[dry-run] would install noctarchy plymouth splash theme"
fi

# ──────────────────────────────────────────────
# Sync current theme
# ──────────────────────────────────────────────

info "Syncing current theme to Noctalia..."

if ! $DRY_RUN && [[ -x "$HOME/.config/omarchy/hooks/theme-set.d/noctalia-sync.sh" ]]; then
  "$HOME/.config/omarchy/hooks/theme-set.d/noctalia-sync.sh"
  ok "Theme synced to Noctalia"
else
  ok "Theme sync (noctalia-sync.sh not installed yet — run sync.sh after)"
fi

# ──────────────────────────────────────────────
# Branding (screensaver.txt / about.txt)
# ──────────────────────────────────────────────

info "Installing branding art..."

BRANDING_DIR="$HOME/.config/omarchy/branding"
if ! $DRY_RUN; then
  mkdir -p "$BRANDING_DIR"
  for f in screensaver.txt about.txt; do
    src="$REPO_DIR/branding/$f"
    dst="$BRANDING_DIR/$f"
    if [[ -f "$src" ]]; then
      if [[ ! -f "$dst" ]]; then
        cp "$src" "$dst"
        ok "  $f installed"
      elif grep -q 'ponshys\|Stellarchy\|omarchy × caelestia' "$dst" 2>/dev/null; then
        cp "$src" "$dst"
        ok "  $f rebranded (was stock/other)"
      else
        ok "  $f customized — left untouched"
      fi
    fi
  done

  # Install noctarchy.png for fastfetch
  FF_LOGO_SRC="$REPO_DIR/branding/noctarchy.png"
  FF_LOGO_DST="$BRANDING_DIR/noctarchy.png"
  if [[ -f "$FF_LOGO_SRC" ]]; then
    if [[ ! -f "$FF_LOGO_DST" ]] || ! cmp -s "$FF_LOGO_SRC" "$FF_LOGO_DST"; then
      cp "$FF_LOGO_SRC" "$FF_LOGO_DST"
      ok "  noctarchy.png installed"
    fi
  fi

  # Brand fastfetch config
  FF_DIR="$HOME/.config/fastfetch"
  FF_STOCK="/etc/fastfetch/config.jsonc"
  if [[ -f "$FF_STOCK" ]]; then
    mkdir -p "$FF_DIR"
     if [[ ! -f "$FF_DIR/config.jsonc" ]]; then
       cp "$FF_STOCK" "$FF_DIR/config.jsonc"
     fi
     cp "$FF_STOCK" "$FF_DIR/config.jsonc"
     python3 - "$FF_DIR/config.jsonc" << 'FFPY'
import sys, re
path = sys.argv[1]
with open(path) as f:
    text = f.read()

# Replace logo section by counting braces
start = text.find('"logo"')
if start >= 0:
    brace_start = text.index('{', start)
    depth = 0
    for i in range(brace_start, len(text)):
        if text[i] == '{': depth += 1
        elif text[i] == '}': depth -= 1
        if depth == 0:
            old_logo = text[start:i+1]
            break
    new_logo = ('"logo": {\n'
                '    "type": "file",\n'
                '    "source": "~/.config/omarchy/branding/noctarchy.png",\n'
                '    "width": 32,\n'
                '    "padding": {\n'
                '      "top": 1,\n'
                '      "right": 2,\n'
                '      "left": 2\n'
                '    }\n'
                '  }')
    text = text.replace(old_logo, new_logo, 1)

# Brand OS version
pattern = r'"text":\s*"version=\$\(omarchy-version\).*"'
replacement = '"text": "rev=$(noctarchy-version 2>/dev/null); ver=$(omarchy-version); echo \\"Noctarchy${rev:+ $rev} (Omarchy $ver)\\""'
text = re.sub(pattern, replacement, text)

with open(path, "w") as f:
    f.write(text)
FFPY
    ok "  fastfetch branded (noctarchy.png logo)"
  fi
else
  info "[dry-run] would install branding art"
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

echo ""
ok "═══════════════════════════════════════════"
ok "  Noctarchy installed!"
ok "  Log out and back in to start Niri + Noctalia"
ok "═══════════════════════════════════════════"
echo ""
info "After logging in:"
info "  - Niri config: ~/.config/niri/config.kdl"
info "  - Noctalia config: ~/.config/noctalia/config.toml"
info "  - Revert: ./uninstall.sh"
