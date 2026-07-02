#!/usr/bin/env bash
# One-command installer. Works from a clone (./install.sh) or via:
#   bash <(curl -fsSL https://raw.githubusercontent.com/dglazkoff/claude-peon-notifier/main/install.sh)
#
# When piped from curl there is no local checkout, so we clone the repo first.
set -euo pipefail

REPO_URL="https://github.com/dglazkoff/claude-peon-notifier.git"

# ${BASH_SOURCE[0]:-} — under `curl | bash` (no process substitution) BASH_SOURCE
# is unset, and set -u would otherwise abort here.
SELF="${BASH_SOURCE[0]:-}"

TMP=""
# Use the || idiom, not `[[ -n "$TMP" ]] && ...`: when TMP is empty the && form
# returns 1, and as the EXIT trap's last command that would make a successful
# install exit non-zero. `[[ -z ]] || ...` always returns 0 here.
cleanup() { [[ -z "$TMP" ]] || rm -rf "$TMP"; }
trap cleanup EXIT

if [[ -n "$SELF" && -f "$(dirname "$SELF")/bin/claude-peon" ]]; then
  ROOT="$(cd "$(dirname "$SELF")" && pwd)"
else
  echo "→ Cloning claude-peon…"
  TMP="$(mktemp -d)"
  git clone --depth 1 "$REPO_URL" "$TMP/claude-peon"
  ROOT="$TMP/claude-peon"
fi

chmod +x "$ROOT/bin/claude-peon" "$ROOT/share/"*.sh 2>/dev/null || true
# Forward our args (e.g. --lang ru) and don't `exec`, so the EXIT trap can clean up.
"$ROOT/bin/claude-peon" install "$@"
