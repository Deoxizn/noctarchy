#!/bin/bash
# noctarchy: post-update hook — re-assert the Noctarchy Plymouth boot splash.
#
# omarchy-settings-dev owns /usr/share/plymouth/themes/omarchy/ and, on every
# pacman -Syu that upgrades it (including kernel updates), overwrites that
# theme dir and re-asserts `Theme=omarchy`, clobbering the Noctarchy splash.
# Noctarchy's splash lives in its own self-contained dir, so re-adopting is
# safe and idempotent. Run after every update so the boot splash sticks.

SPLASH_BIN="$HOME/.local/bin/noctarchy-splash"
[[ -x $SPLASH_BIN ]] || SPLASH_BIN="$(command -v noctarchy-splash 2>/dev/null)"

if [[ -z $SPLASH_BIN ]]; then
  echo "[noctarchy-splash] skipped: noctarchy-splash not found on PATH" >&2
  exit 0
fi

# Adopt only if needed: skip the prompt-less rebuild when already active.
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
