#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGY_DIR="$HOME/.gemini/antigravity-cli"
SETTINGS_FILE="$AGY_DIR/settings.json"
STATUSLINE_DEST="$HOME/.gemini/statusline.sh"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.sh"

unattended="n"
custom_theme=""
custom_glyphs=""
custom_separator=""
custom_time_format=""

while [ $# -gt 0 ]; do
    case "$1" in
        -y|--yes)
            unattended="y"
            shift
            ;;
        --theme)
            custom_theme="$2"
            shift 2
            ;;
        --glyphs)
            custom_glyphs="$2"
            shift 2
            ;;
        --separator)
            custom_separator="$2"
            shift 2
            ;;
        --time-format)
            custom_time_format="$2"
            shift 2
            ;;
        -h|--help)
            cat <<'EOF'
Usage: install.sh [OPTIONS]

OPTIONS:
  -y, --yes                   Run in non-interactive/unattended mode
  --theme <name>              Preset theme (tokyo-night, catppuccin, nord, solarized, light)
  --glyphs <mode>             Preset glyph mode (nerd, unicode, ascii, none)
  --separator <style>         Preset separator (bar, pipe, slant, bubble, slash, minimal)
  --time-format <fmt>         Preset time format (relative, absolute, both)
  -h, --help                  Show this help message
EOF
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

if [ ! -t 0 ]; then
    unattended="y"
fi

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
for dep in jq git curl; do
    command -v "$dep" >/dev/null 2>&1 || fail "Missing dependency: $dep  →  install it and retry"
done
ok "Dependencies found (jq, git, curl)"

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
    if [ "$unattended" != "y" ] && [ -t 0 ]; then
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
        warn "Skipping font install. Note that Nerd Font icons (    󰍛  ) require a Nerd Font (or set AGY_STATUSLINE_GLYPHS=unicode / ascii)."
    fi
fi

# ── 4. Locate or install statusline executable ───────────────
if command -v agy-statusline >/dev/null 2>&1; then
    STATUS_CMD="agy-statusline"
    RUNNER="agy-statusline"
    ok "Found agy-statusline in PATH (${dim}$(command -v agy-statusline)${reset})"
else
    STATUS_CMD='bash "$HOME/.gemini/statusline.sh"'
    RUNNER="$STATUSLINE_DEST"
    if [ -f "$STATUSLINE_DEST" ]; then
        cp "$STATUSLINE_DEST" "${STATUSLINE_DEST}.bak"
        warn "Backed up existing statusline to ${dim}${STATUSLINE_DEST}.bak${reset}"
    fi

    if [ -f "$STATUSLINE_SRC" ]; then
        cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
    else
        info "Fetching statusline.sh from GitHub repository..."
        curl -fsSL "https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/statusline.sh" -o "$STATUSLINE_DEST" || fail "Failed to download statusline.sh from GitHub"
    fi
    chmod +x "$STATUSLINE_DEST"
    ok "Installed statusline to ${dim}$STATUSLINE_DEST${reset}"
fi

# ── 4b. Configure agy-statusline defaults & Wizard ───────────
STATUSLINE_CONFIG_DIR="$HOME/.config/agy-statusline"
mkdir -p "$STATUSLINE_CONFIG_DIR"

chosen_theme="${custom_theme:-tokyo-night}"
chosen_glyphs="${custom_glyphs:-nerd}"
chosen_separator="${custom_separator:-bar}"
chosen_time_format="${custom_time_format:-relative}"

if [ "$unattended" != "y" ] && [ -t 0 ] && [ ! -f "$STATUSLINE_CONFIG_DIR/config.json" ]; then
    echo
    echo -e "  ${cyan}Configuration Wizard${reset}"
    echo -e "  ${dim}────────────────────────────────────────────────────────────────────────${reset}"

    echo -e "  Select color theme:"
    echo -e "    ${green}1)${reset} Tokyo Night ${dim}(Default - High-contrast vibrant dark)${reset}"
    echo -e "    ${green}2)${reset} Catppuccin  ${dim}(Mocha soft pastel palette)${reset}"
    echo -e "    ${green}3)${reset} Nord        ${dim}(Arctic cold frost blue)${reset}"
    echo -e "    ${green}4)${reset} Solarized   ${dim}(Classic solarized dark)${reset}"
    echo -e "    ${green}5)${reset} Light       ${dim}(High-contrast daylight theme)${reset}"
    echo -en "  Choice [1-5, default 1]: "
    read -r t_choice
    case "$t_choice" in
        2) chosen_theme="catppuccin" ;;
        3) chosen_theme="nord" ;;
        4) chosen_theme="solarized" ;;
        5) chosen_theme="light" ;;
        *) chosen_theme="tokyo-night" ;;
    esac

    echo
    echo -e "  Select glyph mode:"
    echo -e "    ${green}1)${reset} Nerd Font ${dim}(Default -     󰍛  )${reset}"
    echo -e "    ${green}2)${reset} Unicode   ${dim}(Standard UTF-8 - ⚡ ✦ 📁 ⎇ 🧠 ⚡ 🕒)${reset}"
    echo -e "    ${green}3)${reset} ASCII     ${dim}(Pure text - [M] [P] [D] [B] [C] [U])${reset}"
    echo -e "    ${green}4)${reset} None      ${dim}(No icons, minimal text labels)${reset}"
    echo -en "  Choice [1-4, default 1]: "
    read -r g_choice
    case "$g_choice" in
        2) chosen_glyphs="unicode" ;;
        3) chosen_glyphs="ascii" ;;
        4) chosen_glyphs="none" ;;
        *) chosen_glyphs="nerd" ;;
    esac

    echo
    echo -e "  Select separator style:"
    echo -e "    ${green}1)${reset} Bar     ${dim}(Default - │)${reset}"
    echo -e "    ${green}2)${reset} Pipe    ${dim}(|)${reset}"
    echo -e "    ${green}3)${reset} Slant   ${dim}(Powerline slant )${reset}"
    echo -e "    ${green}4)${reset} Bubble  ${dim}(Powerline bubble )${reset}"
    echo -e "    ${green}5)${reset} Slash   ${dim}(/)${reset}"
    echo -e "    ${green}6)${reset} Minimal ${dim}(Spaces only)${reset}"
    echo -en "  Choice [1-6, default 1]: "
    read -r s_choice
    case "$s_choice" in
        2) chosen_separator="pipe" ;;
        3) chosen_separator="slant" ;;
        4) chosen_separator="bubble" ;;
        5) chosen_separator="slash" ;;
        6) chosen_separator="minimal" ;;
        *) chosen_separator="bar" ;;
    esac
    echo
fi

if [ ! -f "$STATUSLINE_CONFIG_DIR/config.json" ]; then
    cat <<EOF > "$STATUSLINE_CONFIG_DIR/config.json"
{
  "theme": "$chosen_theme",
  "glyphs": "$chosen_glyphs",
  "separator": "$chosen_separator",
  "time_format": "$chosen_time_format",
  "show_git_dirty": true
}
EOF
    ok "Created statusline configuration at ${dim}$STATUSLINE_CONFIG_DIR/config.json${reset}"
else
    if [ -n "$custom_theme" ] || [ -n "$custom_glyphs" ] || [ -n "$custom_separator" ] || [ -n "$custom_time_format" ]; then
        tmp=$(mktemp)
        jq \
          --arg t "$chosen_theme" \
          --arg g "$chosen_glyphs" \
          --arg s "$chosen_separator" \
          --arg tf "$chosen_time_format" \
          '. + {theme: $t, glyphs: $g, separator: $s, time_format: $tf}' \
          "$STATUSLINE_CONFIG_DIR/config.json" > "$tmp" && mv "$tmp" "$STATUSLINE_CONFIG_DIR/config.json"
        ok "Updated statusline configuration at ${dim}$STATUSLINE_CONFIG_DIR/config.json${reset}"
    fi
fi

# ── 4c. Install Shell Completions ────────────────────────────
if [ -d "$SCRIPT_DIR/../completions" ]; then
    mkdir -p "$STATUSLINE_CONFIG_DIR/completions"
    cp -r "$SCRIPT_DIR/../completions/"* "$STATUSLINE_CONFIG_DIR/completions/" 2>/dev/null || true
    ok "Installed shell completions in ${dim}$STATUSLINE_CONFIG_DIR/completions${reset}"
fi

# ── 4d. Configure HUD defaults if agy-hud present ───────────
HUD_CONFIG_DIR="$HOME/.config/agy-hud"
if [ ! -f "$HUD_CONFIG_DIR/config.json" ]; then
    mkdir -p "$HUD_CONFIG_DIR"
    cat <<'EOF' > "$HUD_CONFIG_DIR/config.json"
{
  "show_model": true,
  "show_progress_bar": true,
  "multiline": true,
  "color": true,
  "debug": false,
  "show_git_branch": true,
  "show_cwd": true,
  "show_agent_state": true,
  "show_icons": true,
  "context_value": "percent",
  "usage_value": "used"
}
EOF
    ok "Created HUD configuration at ${dim}$HUD_CONFIG_DIR/config.json${reset}"
fi

# ── 5. Update settings.json ──────────────────────────────────
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

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
echo -e "  ${blue}│${reset}  To display status line icons (${yellow}    󰍛  ${reset}) properly,                   ${blue}│${reset}"
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
if [ "$unattended" != "y" ] && [ -t 0 ]; then
    echo -en "  ${yellow}→${reset} Once you have updated your terminal font, press ${green}[Enter]${reset} to finish: "
    read -r _
    echo
fi

echo -e "  ${green}All set!${reset} Status line installed. Preview:"
echo
cols=$(tput cols 2>/dev/null || echo 120)
[ "$cols" -lt 100 ] && cols=120
printf '{"model":{"id":"gemini-3.8-flash-med","display_name":"3.8 Flash Med"},"plan_tier":"Google AI Pro","agent_state":"idle","vcs":{"branch":"main"},"cwd":"%s","context_window":{"used_percentage":11},"quota":{"gemini-5h":{"remaining_fraction":0.04,"reset_in_seconds":17460},"gemini-weekly":{"remaining_fraction":0.43,"reset_in_seconds":306000}},"terminal_width":%d}' "$(pwd)" "$cols" | "$RUNNER"
echo
echo
