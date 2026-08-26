#!/usr/bin/env bash
# ██████╗ ██╗  ██╗ █████╗ ███╗   ██╗████████╗ ██████╗ ███╗   ███╗
# ██╔══██╗██║  ██║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗████╗ ████║
# ██████╔╝███████║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
# ██╔═══╝ ██╔══██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
# ██║     ██║  ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
# ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝

# noctarchy sync
# Applies the current checkout's state to an existing noctarchy install:
# menu scripts, hooks, config merges (personal edits preserved), branding.
# Never pulls — the auto-sync hook pulls then calls this; manual passes:
# git pull then ./sync.sh.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.local/state/noctarchy"
STATE_REPO_FILE="$STATE_DIR/repo-dir"
DRY_RUN=false
ADOPT_KDL=false

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=true ;;
    --adopt-kdl) ADOPT_KDL=true ;;
    -h|--help)
      echo "Usage: ./sync.sh [--dry-run] [--adopt-kdl]"
      echo "  --dry-run    show what would change without touching anything"
      echo "  --adopt-kdl  adopt repo versions of niri config that have no"
      echo "               sync history (your current file is backed up first)"
      exit 0 ;;
    *)
      printf '\033[0;31m[noctarchy]\033[0m %s\n' "Unknown argument: $arg (see --help)"
      exit 1 ;;
  esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[noctarchy]${NC} $*"; }
ok()    { echo -e "${GREEN}[noctarchy]${NC} $*"; }
warn()  { echo -e "${YELLOW}[noctarchy]${NC} $*"; }
err()   { echo -e "${RED}[noctarchy]${NC} $*" >&2; }

changed=0

copy_if_changed() { # <src> <dst> <label>
  local src="$1" dst="$2" label="$3"
  if [[ ! -f $dst ]]; then
    if $DRY_RUN; then
      info "  [dry-run] would install $label"
    else
      mkdir -p "$(dirname "$dst")"
      install -m755 "$src" "$dst"
      ok "  installed $label"
    fi
    changed=$((changed+1))
  elif ! cmp -s "$src" "$dst"; then
    if $DRY_RUN; then
      info "  [dry-run] would update $label"
    else
      install -m755 "$src" "$dst"
      ok "  updated $label"
    fi
    changed=$((changed+1))
  else
    ok "  $label up to date"
  fi
}

# ──────────────────────────────────────────────
# Preflight
# ──────────────────────────────────────────────

if [[ ! -f "$HOME/.config/niri/config.kdl" ]]; then
  err "Niri config not found — is noctarchy installed?"
  err "Run ./install.sh first for a fresh install."
  exit 1
fi

# ──────────────────────────────────────────────
# Menu suite scripts → ~/.local/bin
# ──────────────────────────────────────────────

info "Menu suite scripts:"

shopt -s nullglob
repo_scripts=("$REPO_DIR"/scripts/noctarchy-*)
if (( ${#repo_scripts[@]} == 0 )); then
  warn "  no scripts found in repo"
fi
for src in "${repo_scripts[@]}"; do
  copy_if_changed "$src" "$HOME/.local/bin/$(basename "$src")" "$(basename "$src")"
done
# Scripts removed upstream but still installed locally
for dst in "$HOME/.local/bin/"noctarchy-*; do
  [[ -f "$REPO_DIR/scripts/$(basename "$dst")" ]] || warn "  $(basename "$dst") no longer in repo — left in place, remove manually if unwanted"
done
shopt -u nullglob

echo ""

# ──────────────────────────────────────────────
# Theme bridge hook
# ──────────────────────────────────────────────

info "Theme bridge hook:"
copy_if_changed "$REPO_DIR/hooks/theme-set.d/noctalia-sync.sh" \
  "$HOME/.config/omarchy/hooks/theme-set.d/noctalia-sync.sh" "noctalia-sync.sh"

echo ""

# ──────────────────────────────────────────────
# Auto-sync hook
# ──────────────────────────────────────────────

info "Auto-sync hook:"
if [[ -f "$REPO_DIR/hooks/post-update.d/noctarchy-repo-sync.sh" ]]; then
  HOOK_DST="$HOME/.config/omarchy/hooks/post-update.d/noctarchy-repo-sync.sh"
  sed "s|@REPO_DIR@|$REPO_DIR|" "$REPO_DIR/hooks/post-update.d/noctarchy-repo-sync.sh" > "$HOOK_DST.tmp"
  if [[ ! -f "$HOOK_DST" ]] || ! cmp -s "$HOOK_DST.tmp" "$HOOK_DST"; then
    mv "$HOOK_DST.tmp" "$HOOK_DST"
    chmod +x "$HOOK_DST"
    ok "  installed noctarchy-repo-sync.sh"
  else
    rm -f "$HOOK_DST.tmp"
    ok "  noctarchy-repo-sync.sh up to date"
  fi
  changed=$((changed+1))
else
  warn "  repo hook not found — skipping"
fi

# ──────────────────────────────────────────────
# Niri config — merge from repo
# ──────────────────────────────────────────────

NIRI_SRC="$REPO_DIR/config/niri/config.kdl"
NIRI_DST="$HOME/.config/niri/config.kdl"
NIRI_BASE="$HOME/.config/niri/.noctarchy-base/config.kdl"
info "Niri config:"

if [[ ! -f $NIRI_SRC ]]; then
  warn "  repo config.kdl not found — skipping"
elif [[ ! -f $NIRI_DST ]]; then
  if $DRY_RUN; then
    info "  [dry-run] would install config.kdl"
  else
    mkdir -p "$(dirname "$NIRI_DST")"
    install -m644 "$NIRI_SRC" "$NIRI_DST"
    mkdir -p "$(dirname "$NIRI_BASE")"
    cp -f "$NIRI_SRC" "$NIRI_BASE"
    ok "  installed config.kdl"
  fi
  changed=$((changed+1))
elif cmp -s "$NIRI_SRC" "$NIRI_DST"; then
  mkdir -p "$(dirname "$NIRI_BASE")"
  cp -f "$NIRI_SRC" "$NIRI_BASE"
  ok "  config.kdl up to date"
elif [[ ! -f $NIRI_BASE ]]; then
  warn "  config.kdl differs and has no sync history — left untouched"
  warn "    review: diff \"$NIRI_SRC\" \"$NIRI_DST\""
  warn "    or adopt repo version (backs up yours): ./sync.sh --adopt-kdl"
else
  tmp_current="$(mktemp)"
  cp "$NIRI_DST" "$tmp_current"
  if git merge-file -L yours -L base -L repo "$tmp_current" "$NIRI_BASE" "$NIRI_SRC" >/dev/null 2>&1; then
    if $DRY_RUN; then
      info "  [dry-run] would merge repo changes into config.kdl (your edits kept)"
    else
      cp "$NIRI_DST" "$NIRI_DST.pre-upgrade.bak"
      install -m644 "$tmp_current" "$NIRI_DST"
      cp -f "$NIRI_SRC" "$NIRI_BASE"
      ok "  merged repo changes into config.kdl (backup: config.kdl.pre-upgrade.bak)"
    fi
    changed=$((changed+1))
  else
    cp "$tmp_current" "$HOME/.config/niri/config.kdl.conflict"
    warn "  config.kdl has conflicts — NOT applied"
    warn "    resolve manually: config.kdl.conflict → config.kdl"
    changed=$((changed+1))
  fi
  rm -f "$tmp_current"
fi

echo ""

# ──────────────────────────────────────────────
# Noctalia config
# ──────────────────────────────────────────────

NOCTALIA_SRC="$REPO_DIR/config/noctalia/config.toml"
NOCTALIA_DST="$HOME/.config/noctalia/config.toml"
info "Noctalia config:"

if [[ -f $NOCTALIA_SRC ]]; then
  copy_if_changed "$NOCTALIA_SRC" "$NOCTALIA_DST" "noctalia/config.toml"
else
  warn "  repo config.toml not found — skipping"
fi

echo ""

# ──────────────────────────────────────────────
# SDDM greeter — noctarchy theme
# ──────────────────────────────────────────────

SDDM_SRC="$REPO_DIR/branding/sddm-theme"
SDDM_DST="/usr/share/sddm/themes/noctarchy"
OMARCHY_SDDM="/usr/share/sddm/themes/omarchy"
SDDM_CONF="/etc/sddm.conf.d/10-theme.conf"

info "SDDM greeter:"
if [[ -d $OMARCHY_SDDM ]]; then
  if ! $DRY_RUN; then
    sudo mkdir -p "$SDDM_DST"
    for f in logo.png metadata.desktop theme.conf; do
      if [[ ! -f $SDDM_DST/$f ]] || ! cmp -s "$SDDM_SRC/$f" "$SDDM_DST/$f"; then
        sudo cp "$SDDM_SRC/$f" "$SDDM_DST/$f"
        ok "  updated $f"
        changed=$((changed+1))
      fi
    done
    for f in Main.qml bullet.png entry.png entry-failed.png lock.png lock-failed.png; do
      if [[ -f $OMARCHY_SDDM/$f ]] && ! cmp -s "$OMARCHY_SDDM/$f" "$SDDM_DST/$f"; then
        sudo cp "$OMARCHY_SDDM/$f" "$SDDM_DST/$f"
        ok "  refreshed $f from omarchy"
        changed=$((changed+1))
      fi
    done
    if [[ -f $SDDM_CONF ]] && grep -q '^Current=omarchy' "$SDDM_CONF"; then
      sudo sed -i 's/^Current=.*/Current=noctarchy/' "$SDDM_CONF"
      ok "  switched SDDM Current= to noctarchy"
      changed=$((changed+1))
    fi
    # Set Niri as default session
    SDDM_SESSION="/etc/sddm.conf.d/10-session.conf"
    if [[ ! -f "$SDDM_SESSION" ]] || ! grep -q 'niri.desktop' "$SDDM_SESSION" 2>/dev/null; then
      sudo mkdir -p /etc/sddm.conf.d
      sudo bash -c 'printf "[General]\nDisplayServer=wayland\nSession=wayland=niri.desktop\n" > /etc/sddm.conf.d/10-session.conf'
      ok "  SDDM default session set to Niri"
      changed=$((changed+1))
    fi
  else
    info "  [dry-run] would sync noctarchy SDDM theme"
  fi
else
  ok "  Omarchy SDDM theme not found — skipping"
fi

echo ""

# ──────────────────────────────────────────────
# Plymouth splash — noctarchy theme
# ──────────────────────────────────────────────

info "Plymouth splash:"
PLYMOUTH_SRC="$REPO_DIR/branding/plymouth"
PLYMOUTH_DST="/usr/share/plymouth/themes/noctarchy"
OMARCHY_PLY="/usr/share/plymouth/themes/omarchy"

if [[ -d $OMARCHY_PLY ]]; then
  if ! $DRY_RUN; then
    NEEDS_INITRD=false
    sudo mkdir -p "$PLYMOUTH_DST"
    for pair in "noctarchy-logo.png:logo.png" "noctarchy.plymouth:noctarchy.plymouth"; do
      src="$PLYMOUTH_SRC/${pair%%:*}"
      dst="$PLYMOUTH_DST/${pair##*:}"
      if [[ ! -f $dst ]] || ! cmp -s "$src" "$dst"; then
        sudo cp "$src" "$dst"
        NEEDS_INITRD=true
        changed=$((changed+1))
      fi
    done
    for f in bullet.png entry.png lock.png progress_bar.png progress_box.png omarchy.script; do
      if [[ -f $OMARCHY_PLY/$f ]] && ! cmp -s "$OMARCHY_PLY/$f" "$PLYMOUTH_DST/$f"; then
        sudo cp "$OMARCHY_PLY/$f" "$PLYMOUTH_DST/$f"
        NEEDS_INITRD=true
        changed=$((changed+1))
      fi
    done
    if ! grep -q '^Theme=noctarchy' /etc/plymouth/plymouthd.conf 2>/dev/null; then
      sudo plymouth-set-default-theme noctarchy
      NEEDS_INITRD=true
    fi
    if [[ $NEEDS_INITRD == true ]]; then
      ok "  rebuilding initramfs..."
      sudo limine-mkinitcpio || warn "  limine-mkinitcpio failed — run manually before rebooting"
    fi
  else
    info "  [dry-run] would sync noctarchy plymouth splash"
  fi
else
  ok "  Omarchy plymouth theme not found — skipping"
fi

echo ""

# ──────────────────────────────────────────────
# Fastfetch branding
# ──────────────────────────────────────────────

FF_DIR="$HOME/.config/fastfetch"
FF_STOCK="/etc/fastfetch/config.jsonc"

info "Fastfetch branding:"
if [[ -f $FF_DIR/config.jsonc ]] && [[ -f $FF_STOCK ]]; then
  if ! $DRY_RUN; then
    cp "$FF_STOCK" "$FF_DIR/config.jsonc"
    python3 - "$FF_DIR/config.jsonc" << 'FFPY'
import sys, re
path = sys.argv[1]
with open(path) as f:
    text = f.read()
pattern = r'"text":\s*"version=\$\(omarchy-version\).*"'
replacement = '"text": "rev=$(noctarchy-version 2>/dev/null); ver=$(omarchy-version); echo \\"Noctarchy${rev:+ $rev} (Omarchy $ver)\\""'
text = re.sub(pattern, replacement, text)
with open(path, "w") as f:
    f.write(text)
FFPY
    ok "  branded fastfetch"
  fi
else
  ok "  fastfetch config unchanged or custom — left untouched"
fi

echo ""

# ──────────────────────────────────────────────
# Branding (screensaver.txt / about.txt)
# ──────────────────────────────────────────────

info "Branding:"
BRANDING_DIR="$HOME/.config/omarchy/branding"
declare -A BRAND_STOCK=(
  ["screensaver.txt"]="/usr/share/omarchy/logo.txt"
  ["about.txt"]="/usr/share/omarchy/icon.txt"
)
for f in screensaver.txt about.txt; do
  src="$REPO_DIR/branding/$f"
  dst="$BRANDING_DIR/$f"
  stock="${BRAND_STOCK[$f]}"
  if [[ ! -f $src ]]; then
    warn "  $f missing from repo — skipping"
    continue
  fi
  mkdir -p "$BRANDING_DIR"
  if [[ ! -f $dst ]]; then
    if ! $DRY_RUN; then cp "$src" "$dst"; fi
    ok "  $f installed"
    changed=$((changed+1))
  elif cmp -s "$dst" "$src"; then
    ok "  $f up to date"
  elif [[ -n $stock && -f $stock ]] && cmp -s "$dst" "$stock"; then
    if $DRY_RUN; then
      info "  [dry-run] would replace stock $f with Noctarchy art"
    else
      cp "$src" "$dst"
    fi
    ok "  $f rebranded (was stock Omarchy art)"
    changed=$((changed+1))
  elif grep -q 'Noctarchy' "$dst"; then
    if $DRY_RUN; then
      info "  [dry-run] would refresh $f to current Noctarchy art"
    else
      cp "$src" "$dst"
    fi
    ok "  $f refreshed (older noctarchy version)"
    changed=$((changed+1))
  else
    ok "  $f customized — left untouched"
  fi
done
unset BRAND_STOCK

echo ""

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

if (( changed == 0 )); then
  ok "Everything already up to date."
elif $DRY_RUN; then
  info "$changed item(s) would be synced."
else
  ok "$changed item(s) synced."
  echo -e "${CYAN}[noctarchy]${NC} If keybinds changed, run: ${YELLOW}niri msg action load-config-file${NC}"
fi
