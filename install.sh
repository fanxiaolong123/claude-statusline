#!/usr/bin/env bash
# Claude Code statusline installer.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/install.sh | bash
# Env overrides:
#   CLAUDE_STATUSLINE_REPO   default: liberty-app-xiaolong-fan/claude-statusline
#   CLAUDE_STATUSLINE_BRANCH default: main
#   CLAUDE_DIR               default: $HOME/.claude

set -e

REPO="${CLAUDE_STATUSLINE_REPO:-liberty-app-xiaolong-fan/claude-statusline}"
BRANCH="${CLAUDE_STATUSLINE_BRANCH:-main}"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SCRIPT_DEST="${CLAUDE_DIR}/statusline.sh"
SETTINGS="${CLAUDE_DIR}/settings.json"
STAMP=$(date +%Y%m%d-%H%M%S)

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

say "Checking dependencies"
missing=()
for cmd in jq python3 perl curl; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
  die "Missing required commands: ${missing[*]}. Install them and retry."
fi

mkdir -p "$CLAUDE_DIR"

if [ -f "$SCRIPT_DEST" ]; then
  bak="${SCRIPT_DEST}.bak-${STAMP}"
  cp "$SCRIPT_DEST" "$bak"
  say "Backed up existing statusline.sh -> $bak"
fi

# Source: prefer local file when running from a git checkout, else fetch from GitHub.
src_local="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)/statusline.sh"
if [ -f "$src_local" ]; then
  say "Installing statusline.sh from local checkout"
  cp "$src_local" "$SCRIPT_DEST"
else
  url="https://raw.githubusercontent.com/${REPO}/${BRANCH}/statusline.sh"
  say "Fetching $url"
  curl -fsSL "$url" -o "$SCRIPT_DEST" || die "Failed to fetch statusline.sh"
fi
chmod +x "$SCRIPT_DEST"

say "Updating $SETTINGS"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "${SETTINGS}.bak-${STAMP}"
  tmp=$(mktemp)
  jq --arg cmd "bash ${SCRIPT_DEST}" \
     '.statusLine = {type:"command", command:$cmd}' \
     "$SETTINGS" > "$tmp" || die "jq failed to update settings.json"
  mv "$tmp" "$SETTINGS"
else
  cat > "$SETTINGS" <<JSON
{
  "statusLine": {
    "type": "command",
    "command": "bash ${SCRIPT_DEST}"
  }
}
JSON
fi

say "Done. Restart Claude Code (or open a new session) to see the statusline."
