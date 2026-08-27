#!/bin/bash
# noctarchy: keep omarchy-update from resurrecting the Omarchy shell.
# Re-inserts an early-exit guard into /usr/share/omarchy/bin/omarchy-restart-shell
# whenever an omarchy package upgrade overwrites it. Idempotent.

f=/usr/share/omarchy/bin/omarchy-restart-shell
[[ -f $f ]] || exit 0
grep -q 'noctarchy' "$f" && exit 0

sudo python3 - "$f" <<'PYEOF'
import sys

p = sys.argv[1]
s = open(p).read()
guard = (
    "#!/bin/bash\n"
    "\n"
    "# noctarchy: Noctalia handles the shell; skip Omarchy shell restart.\n"
    'if pgrep -x noctalia >/dev/null 2>&1; then\n'
    '  echo "Noctalia active; skipping Omarchy shell restart."\n'
    "  exit 0\n"
    "fi\n"
)
s = s.replace("#!/bin/bash\n", guard, 1)
open(p, "w").write(s)
print("guard applied to", p)
PYEOF
