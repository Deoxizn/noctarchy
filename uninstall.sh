#!/usr/bin/env bash
# ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
# ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
# ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
# ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
# ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝

# noctarchy uninstaller
# Restores stock Omarchy (omarchy-shell + Hyprland)
# https://github.com/deoxizn/noctarchy

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/noctarchy-backup"

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
  read -rp "$1 [y/N] " REPLY
  [[ "$REPLY" =~ ^[Yy]$ ]]
}

echo ""
ok "═══════════════════════════════════════════"
ok "  Noctarchy Uninstaller"
ok "═══════════════════════════════════════════"
echo ""

if ! confirm "This will remove Noctarchy and restore stock Omarchy. Continue?"; then
  info "Aborted."
  exit 0
fi

# ──────────────────────────────────────────────
# Stop and disable Noctalia service
# ──────────────────────────────────────────────

info "Stopping Noctalia..."
if systemctl --user is-enabled --quiet noctalia.service 2>/dev/null; then
  systemctl --user disable --now noctalia.service 2>/dev/null || true
  ok "  noctalia.service stopped and disabled"
else
  warn "  noctalia.service not running"
fi

# ──────────────────────────────────────────────
# Remove Noctalia configs
# ──────────────────────────────────────────────

info "Removing Noctalia configs..."
rm -rf "$HOME/.config/noctalia" 2>/dev/null || true
ok "  ~/.config/noctalia removed"

# ──────────────────────────────────────────────
# Remove Niri configs
# ──────────────────────────────────────────────

info "Removing Niri configs..."
rm -rf "$HOME/.config/niri" 2>/dev/null || true
ok "  ~/.config/niri removed"

# ──────────────────────────────────────────────
# Restore Hyprland configs from backup
# ──────────────────────────────────────────────

info "Restoring Hyprland configs from backup..."
LATEST_BACKUP=""
if [[ -d "$BACKUP_DIR" ]]; then
  LATEST_BACKUP=$(ls -1d "$BACKUP_DIR"/*/ 2>/dev/null | tail -1)
fi

if [[ -n "$LATEST_BACKUP" ]]; then
  ok "  Using backup: $LATEST_BACKUP"
  for f in "$LATEST_BACKUP"/*.lua "$LATEST_BACKUP"/*.conf; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f")
    cp "$f" "$HOME/.config/hypr/$base"
    ok "  restored hypr/$base"
  done
else
  warn "  No backup found — Hyprland configs may be missing"
  warn "  You may need to run: omarchy refresh hyprland"
fi

# ──────────────────────────────────────────────
# Restore omarchy autostart stub
# ──────────────────────────────────────────────

info "Restoring Hyprland autostart..."
HYPRLAND_FILE="$HOME/.config/hypr/hyprland.lua"
if [[ -f "$HYPRLAND_FILE" ]]; then
  # Remove the noctarchy autostart stub
  python3 - "$HYPRLAND_FILE" << 'STUBPY'
import sys

path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()

marker = 'package.loaded["default.hypr.autostart"]'
new_lines = [l for l in lines if marker not in l and "Noctarchy: prevent default omarchy autostart" not in l]

if len(new_lines) != len(lines):
    with open(path, "w") as f:
        f.writelines(new_lines)
    print("  autostart stub removed")
else:
    print("  no noctarchy autostart stub found")
STUBPY
fi

# ──────────────────────────────────────────────
# Re-enable stock omarchy services
# ──────────────────────────────────────────────

info "Re-enabling stock Omarchy services..."
if ! systemctl --user is-enabled --quiet omarchy-sleep-lock.service 2>/dev/null; then
  systemctl --user enable omarchy-sleep-lock.service 2>/dev/null || true
  ok "  omarchy-sleep-lock.service re-enabled"
fi

# ──────────────────────────────────────────────
# Remove noctarchy scripts
# ──────────────────────────────────────────────

info "Removing noctarchy scripts..."
shopt -s nullglob
noctarchy_bins=("$HOME/.local/bin/"noctarchy-*)
if (( ${#noctarchy_bins[@]} )); then
  rm -f "${noctarchy_bins[@]}"
  ok "  removed ${#noctarchy_bins[@]} noctarchy-* scripts from ~/.local/bin/"
fi
shopt -u nullglob

# ──────────────────────────────────────────────
# Remove theme bridge hook
# ──────────────────────────────────────────────

if [[ -f "$HOME/.config/omarchy/hooks/theme-set.d/noctalia-sync.sh" ]]; then
  rm "$HOME/.config/omarchy/hooks/theme-set.d/noctalia-sync.sh"
  ok "  Removed theme bridge hook"
fi

# ──────────────────────────────────────────────
# Remove Stellarchy leftovers
# ──────────────────────────────────────────────

if [[ -f "$HOME/.config/omarchy/hooks/post-update.d/stellarchy-repo-sync.sh" ]]; then
  rm "$HOME/.config/omarchy/hooks/post-update.d/stellarchy-repo-sync.sh"
  ok "  Removed leftover Stellarchy hook"
fi

# ──────────────────────────────────────────────
# Remove libalpm guard
# ──────────────────────────────────────────────

rm -f /usr/local/bin/noctarchy-guard-restart-shell.sh 2>/dev/null || true
rm -f /usr/share/libalpm/hooks/noctarchy-restart-shell-guard.hook 2>/dev/null || true

# Revert guard patch from omarchy-restart-shell
F=/usr/share/omarchy/bin/omarchy-restart-shell
if [[ -f "$F" ]] && grep -q 'noctarchy' "$F" 2>/dev/null; then
  GUARD_REVERT=$(mktemp /tmp/noctarchy-guard-revert.XXXXXX.py)
  cat > "$GUARD_REVERT" << 'PYEOF'
import sys
p = sys.argv[1]
with open(p) as f:
    lines = f.readlines()
result = []
for i, l in enumerate(lines):
    stripped = l.strip()
    if stripped == "exit 0" and i + 1 < len(lines) and lines[i+1].strip() == "fi":
        continue
    if stripped == "fi" and i > 0 and lines[i-1].strip() == "exit 0":
        continue
    if "noctarchy" in l or "Noctalia handles the shell" in l or "pgrep -x noctalia" in l or "Noctalia active" in l:
        continue
    result.append(l)
with open(p, "w") as f:
    f.writelines(result)
print("guard reverted")
PYEOF
  sudo python3 "$GUARD_REVERT" "$F"
  rm -f "$GUARD_REVERT"
  ok "  Reverted guard patch from omarchy-restart-shell"
fi
ok "  libalpm guard removed"

# ──────────────────────────────────────────────
# Restore stock plymouth splash
# ──────────────────────────────────────────────

if grep -q '^Theme=noctarchy' /etc/plymouth/plymouthd.conf 2>/dev/null; then
  info "Restoring stock Omarchy splash..."
  sudo plymouth-set-default-theme omarchy
  if mountpoint -q /boot && command -v limine-mkinitcpio &>/dev/null; then
    if sudo limine-mkinitcpio; then
      ok "  Stock splash restored, initramfs rebuilt"
    else
      warn "  limine-mkinitcpio failed — run it manually before rebooting"
    fi
  else
    warn "  /boot not mounted or limine-mkinitcpio missing — run: sudo limine-mkinitcpio"
  fi
fi

# ──────────────────────────────────────────────
# Remove SDDM theme and restore stock
# ──────────────────────────────────────────────

if [[ -d /usr/share/sddm/themes/noctarchy ]]; then
  info "Removing noctarchy SDDM theme..."
  sudo rm -rf /usr/share/sddm/themes/noctarchy
  if [[ -f /etc/sddm.conf.d/10-theme.conf ]] && grep -q '^Current=noctarchy' /etc/sddm.conf.d/10-theme.conf; then
    sudo sed -i 's/^Current=.*/Current=omarchy/' /etc/sddm.conf.d/10-theme.conf
    ok "  Theme removed, greeter back to omarchy"
  else
    ok "  Theme removed"
  fi
fi

# ──────────────────────────────────────────────
# Remove noctarchy state
# ──────────────────────────────────────────────

info "Removing noctarchy state..."
rm -rf "$HOME/.local/state/noctarchy" 2>/dev/null || true
ok "  ~/.local/state/noctarchy removed"

# ──────────────────────────────────────────────
# Remove repo directory
# ──────────────────────────────────────────────

if [[ -d "$HOME/.local/opt/noctarchy" ]]; then
  echo ""
  read -rp "Remove repo at ~/.local/opt/noctarchy? [y/N] " REMOVE_REPO
  if [[ "$REMOVE_REPO" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.local/opt/noctarchy"
    ok "  Removed ~/.local/opt/noctarchy"
  else
    info "  Repo preserved at ~/.local/opt/noctarchy"
  fi
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

echo ""
ok "═══════════════════════════════════════════"
ok "  Noctarchy removed!"
ok "  Log out and back in to restore stock Omarchy"
ok "═══════════════════════════════════════════"
echo ""
info "If Hyprland doesn't start, run: omarchy refresh hyprland"
