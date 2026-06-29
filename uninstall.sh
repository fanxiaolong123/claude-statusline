#!/usr/bin/env bash
# Remove the statusline.sh script and unset .statusLine from settings.json.
# Backups created by install.sh (statusline.sh.bak-* / settings.json.bak-*) are left alone.

set -e

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DEST="${CLAUDE_DIR}/statusline.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"

if [ -f "$SCRIPT_DEST" ]; then
  rm "$SCRIPT_DEST"
  echo "Removed $SCRIPT_DEST"
fi

if [ -f "$SETTINGS" ]; then
  tmp=$(mktemp)
  jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Cleared .statusLine from $SETTINGS"
fi

echo "Done."
