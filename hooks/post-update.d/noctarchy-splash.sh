#!/bin/bash
# noctarchy: post-update hook — re-assert the Noctarchy Plymouth boot splash.
#
# omarchy-settings-dev owns /usr/share/plymouth/themes/omarchy/ and, on every
# pacman -Syu that upgrades it (including kernel updates), overwrites that
# theme dir and re-asserts `Theme=omarchy`, clobbering the Noctarchy splash.
# Noctarchy's splash lives in its own self-contained dir, so re-adopting is
# safe and idempotent.
#
# To avoid an initramfs rebuild on every single update, only adopt when a
# kernel package (or its headers) was actually part of this transaction —
# that is the only case that rebuilds the initramfs and resets the theme.

SPLASH_BIN="$HOME/.local/bin/noctarchy-splash"
[[ -x $SPLASH_BIN ]] || SPLASH_BIN="$(command -v noctarchy-splash 2>/dev/null)"

if [[ -z $SPLASH_BIN ]]; then
  echo "[noctarchy-splash] skipped: noctarchy-splash not found on PATH" >&2
  exit 0
fi

# Kernel packages (and their matching -headers), excluding linux-firmware* and linux-api-headers.
# Matches: linux, linux-{lts,zen,hardened,rt,rt-lts,omarchy-bore,cachyos-bore,...} and variants.
# Uses a generic match for any linux-* kernel, then filters out firmware/api-headers.
KERNEL_RE='\[ALPM\] (upgraded|installed|downgraded|reinstalled) linux(-[a-z0-9-]+)?(-headers)?([ (])'

tx_start=$(awk '/\[ALPM\] transaction started/{n=NR} END{print n}' /var/log/pacman.log 2>/dev/null)
[[ $tx_start =~ ^[0-9]+$ ]] || tx_start=1

if ! awk "NR>$tx_start" /var/log/pacman.log 2>/dev/null | grep -E "$KERNEL_RE" | grep -vE "linux-(firmware|api-headers)" | grep -q .; then
  echo "[noctarchy-splash] no kernel update in this transaction, skipping (no initramfs rebuild needed)"
  exit 0
fi

# Kernel was updated this transaction. Adopt only if needed: skip the
# prompt-less rebuild when already active.
if grep -q '^Theme=noctarchy' /etc/plymouth/plymouthd.conf 2>/dev/null; then
  echo "[noctarchy-splash] noctarchy theme already active, skipping"
  exit 0
fi

# The hook runs in the update terminal where sudo is cached; prefer a direct
# non-interactive adopt to avoid TTY hangs. Fall back to the script otherwise.
if sudo -n true 2>/dev/null; then
  "$SPLASH_BIN" run adopt
else
  echo "[noctarchy-splash] sudo not available in hook — run: noctarchy-splash" >&2
fi
