#!/usr/bin/env bash
# One-command installer. Works from a clone (./install.sh) or via:
#   bash <(curl -fsSL https://raw.githubusercontent.com/USER/claude-peon/main/install.sh)
#
# When piped from curl there is no local checkout, so we clone the repo first.
set -euo pipefail

REPO_URL="https://github.com/dglazkoff/claude-peon-notifier.git"

if [[ -f "$(dirname "${BASH_SOURCE[0]}")/bin/claude-peon" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  echo "→ Cloning claude-peon…"
  TMP="$(mktemp -d)"
  git clone --depth 1 "$REPO_URL" "$TMP/claude-peon"
  ROOT="$TMP/claude-peon"
fi

chmod +x "$ROOT/bin/claude-peon" "$ROOT/share/"*.sh 2>/dev/null || true
exec "$ROOT/bin/claude-peon" install
