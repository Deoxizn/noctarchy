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
  swayidle swaylock swaybg mako xwayland-satellite; do
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
    then
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
  # TODO: create noctalia-sync.sh bridge script
  # cp "$REPO_DIR/hooks/theme-set.d/noctalia-sync.sh" "$HOOK_DIR/noctalia-sync.sh"
  # chmod +x "$HOOK_DIR/noctalia-sync.sh"
fi
ok "Theme bridge hook (placeholder — needs noctalia-sync.sh)"

# ──────────────────────────────────────────────
# Install auto-sync hook
# ──────────────────────────────────────────────

info "Installing omarchy-update auto-sync hook..."

if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/omarchy/hooks/post-update.d"
  # TODO: create noctarchy-repo-sync.sh
  # sed "s|@REPO_DIR@|$REPO_DIR|" "$REPO_DIR/hooks/post-update.d/noctarchy-repo-sync.sh" \
  #   > "$HOME/.config/omarchy/hooks/post-update.d/noctarchy-repo-sync.sh"
  # chmod +x "$HOME/.config/omarchy/hooks/post-update.d/noctarchy-repo-sync.sh"
fi
ok "Auto-sync hook (placeholder — needs hook script)"

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
# Sync current theme
# ──────────────────────────────────────────────

info "Syncing current theme to Noctalia..."

# TODO: implement theme sync
ok "Theme sync (placeholder — needs noctalia-sync.sh)"

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
