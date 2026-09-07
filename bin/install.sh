#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGY_DIR="$HOME/.gemini/antigravity-cli"
SETTINGS_FILE="$AGY_DIR/settings.json"
STATUSLINE_DEST="$HOME/.gemini/statusline.sh"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.sh"

blue='\033[38;5;111m'
green='\033[38;5;155m'
red='\033[38;5;203m'
yellow='\033[38;5;221m'
cyan='\033[38;5;117m'
dim='\033[2m'
reset='\033[0m'

ok()   { echo -e "  ${green}✓${reset} $1"; }
warn() { echo -e "  ${yellow}!${reset} $1"; }
fail() { echo -e "  ${red}✗${reset} $1"; exit 1; }
info() { echo -e "  ${cyan}ℹ${reset} $1"; }

echo
echo -e "  ${blue}agy-statusline installer${reset}"
echo -e "  ${dim}────────────────────────────────────────────────────────────────────────${reset}"
echo

# ── 1. Check CLI dependencies ────────────────────────────────
for dep in jq git; do
    command -v "$dep" >/dev/null 2>&1 || fail "Missing dependency: $dep  →  install it and retry"
done
ok "Dependencies found (jq, git)"

# ── 2. Check agy directory ───────────────────────────────────
[ -d "$AGY_DIR" ] || fail "Antigravity CLI not found at $AGY_DIR — is agy installed?"
ok "Found agy config at ${dim}$AGY_DIR${reset}"

# ── 3. Font Detection & Optional Installation ────────────────
detect_nerd_font() {
    local os="$(uname -s)"
    if [ "$os" = "Darwin" ]; then
        find "$HOME/Library/Fonts" "/Library/Fonts" -maxdepth 2 -type f \( -iname "*nerd*" -o -iname "*powerline*" \) 2>/dev/null | head -n 1
    else
        if command -v fc-list >/dev/null 2>&1; then
            fc-list : family | grep -iE "nerd|powerline" | head -n 1
        else
            find "$HOME/.local/share/fonts" "$HOME/.fonts" "/usr/share/fonts" -type f \( -iname "*nerd*" -o -iname "*powerline*" \) 2>/dev/null | head -n 1
        fi
    fi
}

install_nerd_font() {
    local os="$(uname -s)"
    info "Installing JetBrainsMono Nerd Font..."
    if [ "$os" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo -e "  ${dim}Running: brew install --cask font-jetbrains-mono-nerd-font...${reset}"
            if brew install --cask font-jetbrains-mono-nerd-font; then
                ok "JetBrainsMono Nerd Font installed via Homebrew"
                return 0
            fi
            warn "Homebrew install failed, trying direct archive download..."
        fi
        
        # Direct download fallback
        local tmp_dir
        tmp_dir=$(mktemp -d)
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        echo -e "  ${dim}Downloading ${url}...${reset}"
        if curl -fsSL "$url" -o "$tmp_dir/JetBrainsMono.tar.xz"; then
            tar -xf "$tmp_dir/JetBrainsMono.tar.xz" -C "$HOME/Library/Fonts" 2>/dev/null || true
            rm -rf "$tmp_dir"
            ok "Installed JetBrainsMono Nerd Font to ~/Library/Fonts"
            return 0
        else
            rm -rf "$tmp_dir"
            warn "Download failed. Please install a Nerd Font manually."
            return 1
        fi
    else
        local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
        mkdir -p "$font_dir"
        local tmp_dir
        tmp_dir=$(mktemp -d)
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        echo -e "  ${dim}Downloading ${url}...${reset}"
        if curl -fsSL "$url" -o "$tmp_dir/JetBrainsMono.tar.xz"; then
            tar -xf "$tmp_dir/JetBrainsMono.tar.xz" -C "$font_dir" 2>/dev/null || true
            rm -rf "$tmp_dir"
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f "$font_dir" 2>/dev/null || true
            fi
            ok "Installed JetBrainsMono Nerd Font to $font_dir"
            return 0
        else
            rm -rf "$tmp_dir"
            warn "Download failed. Please install a Nerd Font manually."
            return 1
        fi
    fi
}

detected_font=$(detect_nerd_font || true)
font_label="JetBrainsMono Nerd Font"

if [ -n "$detected_font" ]; then
    font_file=$(basename "$detected_font")
    font_label=$(echo "$font_file" | sed -E 's/\.(ttf|otf)$//')
    ok "Compatible font detected: ${dim}$font_label${reset}"
else
    warn "No Nerd Font or Powerline font detected in standard font paths."
    do_install="n"
    if [ -t 0 ]; then
        echo -en "  ${yellow}?${reset} Would you like to automatically install JetBrainsMono Nerd Font now? [Y/n]: "
        read -r reply
        reply=$(echo "$reply" | tr '[:upper:]' '[:lower:]')
        if [[ -z "$reply" || "$reply" == "y" || "$reply" == "yes" ]]; then
            do_install="y"
        fi
    fi

    if [ "$do_install" = "y" ]; then
        if install_nerd_font; then
            font_label="JetBrainsMono Nerd Font"
        fi
    else
        warn "Skipping font install. Note that arrow glyphs () require a Nerd Font to render correctly."
    fi
fi

# ── 4. Copy statusline script ────────────────────────────────
if [ -f "$STATUSLINE_DEST" ]; then
    cp "$STATUSLINE_DEST" "${STATUSLINE_DEST}.bak"
    warn "Backed up existing statusline to ${dim}${STATUSLINE_DEST}.bak${reset}"
fi

cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
chmod +x "$STATUSLINE_DEST"
ok "Installed statusline to ${dim}$STATUSLINE_DEST${reset}"

# ── 5. Update settings.json ──────────────────────────────────
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

STATUS_CMD='bash "$HOME/.gemini/statusline.sh"'
CURRENT_CMD=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null || true)

if [ "$CURRENT_CMD" = "$STATUS_CMD" ]; then
    ok "settings.json already configured"
else
    tmp=$(mktemp)
    jq --arg cmd "$STATUS_CMD" \
        '.statusLine = {"type": "command", "command": $cmd, "enabled": true}' \
        "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    ok "Updated ${dim}$SETTINGS_FILE${reset} with statusLine config"
fi

# ── 6. Terminal Font Setup Instructions ──────────────────────
echo
echo -e "  ${blue}┌────────────────────────────────────────────────────────────────────────┐${reset}"
echo -e "  ${blue}│${reset}  ${green}Terminal Font Configuration Required${reset}                                  ${blue}│${reset}"
echo -e "  ${blue}├────────────────────────────────────────────────────────────────────────┤${reset}"
echo -e "  ${blue}│${reset}  To display Powerline arrows (${yellow}${reset}) and git glyphs (${yellow}⎇${reset}) properly,        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  ensure your terminal emulator is set to use a ${yellow}Nerd Font${reset}:               ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}macOS Terminal.app:${reset} Settings (⌘,) → Profiles → Font → Change...    ${blue}│${reset}"
echo -e "  ${blue}│${reset}    Select ${green}JetBrainsMono Nerd Font${reset} (or ${green}${font_label}${reset})         ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}iTerm2:${reset} Settings (⌘,) → Profiles → Text → Font                         ${blue}│${reset}"
echo -e "  ${blue}│${reset}    Choose ${green}JetBrainsMono Nerd Font${reset} (or enable Non-ASCII font)           ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}VS Code / Cursor / Antigravity Terminal:${reset}                           ${blue}│${reset}"
echo -e "  ${blue}│${reset}    Settings (⌘,) → search ${dim}\"terminal.integrated.fontFamily\"${reset}            ${blue}│${reset}"
echo -e "  ${blue}│${reset}    Set to: ${green}'JetBrainsMono Nerd Font'${reset}                                    ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}Ghostty:${reset} Add to ~/.config/ghostty/config:                              ${blue}│${reset}"
echo -e "  ${blue}│${reset}    ${green}font-family = \"JetBrainsMono Nerd Font\"${reset}                              ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}Alacritty:${reset} In ~/.config/alacritty/alacritty.toml:                       ${blue}│${reset}"
echo -e "  ${blue}│${reset}    ${green}[font.normal] family = \"JetBrainsMono Nerd Font\"${reset}                   ${blue}│${reset}"
echo -e "  ${blue}│${reset}                                                                        ${blue}│${reset}"
echo -e "  ${blue}│${reset}  • ${dim}Kitty:${reset} In ~/.config/kitty/kitty.conf:                                  ${blue}│${reset}"
echo -e "  ${blue}│${reset}    ${green}font_family JetBrainsMono Nerd Font${reset}                             ${blue}│${reset}"
echo -e "  ${blue}└────────────────────────────────────────────────────────────────────────┘${reset}"
echo

# ── 7. Interactive Acknowledgment ────────────────────────────
if [ -t 0 ]; then
    echo -en "  ${yellow}→${reset} Once you have updated your terminal font, press ${green}[Enter]${reset} to finish: "
    read -r _
    echo
fi

echo -e "  ${green}All set!${reset} Restart agy or open a new terminal session to enjoy your status line."
echo
