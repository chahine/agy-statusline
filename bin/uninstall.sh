#!/usr/bin/env bash
set -e

AGY_DIR="$HOME/.gemini/antigravity-cli"
SETTINGS_FILE="$AGY_DIR/settings.json"
STATUSLINE_DEST="$HOME/.gemini/statusline.sh"

blue='\033[38;5;111m'
green='\033[38;5;155m'
yellow='\033[38;5;221m'
dim='\033[2m'
reset='\033[0m'

ok()   { echo -e "  ${green}✓${reset} $1"; }
warn() { echo -e "  ${yellow}!${reset} $1"; }

echo
echo -e "  ${blue}agy-statusline uninstaller${reset}"
echo -e "  ${dim}─────────────────────────────────────────────────${reset}"
echo

# ── Remove from settings.json ────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
    tmp=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Removed statusLine configuration from ${dim}$SETTINGS_FILE${reset}"
fi

# ── Restore backup or remove script ──────────────────────────
if [ -f "${STATUSLINE_DEST}.bak" ]; then
    mv "${STATUSLINE_DEST}.bak" "$STATUSLINE_DEST"
    ok "Restored previous statusline from backup"
elif [ -f "$STATUSLINE_DEST" ]; then
    rm "$STATUSLINE_DEST"
    ok "Removed ${dim}$STATUSLINE_DEST${reset}"
fi

echo
echo -e "  ${green}Done!${reset} Statusline uninstalled. Restart agy to apply changes."
echo
