#!/usr/bin/env bash
set -f

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
    echo "agy-statusline 0.1.0"
    exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<'EOF'
agy-statusline 0.1.0 - Fast, beautiful 2-line status line for Antigravity CLI (agy)

USAGE:
  echo '<telemetry-json>' | agy-statusline
  agy-statusline [OPTIONS]

OPTIONS:
  -h, --help         Show this help message and exit
  -v, --version      Show version information and exit
  -p, --preview      Render a sample statusline preview
  --setup [OPTIONS]  Run configuration setup wizard for Antigravity CLI
  --uninstall        Uninstall statusline configuration and restore backup
  --update           Update agy-statusline to the latest release

ENVIRONMENT VARIABLES:
  AGY_STATUSLINE_THEME        Color theme: tokyo-night, catppuccin, nord, solarized, light
  AGY_STATUSLINE_GLYPHS       Glyph mode: nerd, unicode, ascii, none
  AGY_STATUSLINE_SEPARATOR    Separator style: bar, pipe, slant, bubble, slash, minimal
  AGY_STATUSLINE_TIME_FORMAT  Time format: relative, absolute, both

CONFIGURATION FILE:
  ~/.config/agy-statusline/config.json
EOF
    exit 0
fi

if [ "$1" = "--setup" ]; then
    if command -v agy-statusline-setup >/dev/null 2>&1; then
        exec agy-statusline-setup "${@:2}"
    elif [ -f "$SCRIPT_DIR/install.sh" ]; then
        exec bash "$SCRIPT_DIR/install.sh" "${@:2}"
    else
        exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/install.sh)" bash "${@:2}"
    fi
fi

if [ "$1" = "--uninstall" ]; then
    if command -v agy-statusline-uninstall >/dev/null 2>&1; then
        exec agy-statusline-uninstall "${@:2}"
    elif [ -f "$SCRIPT_DIR/uninstall.sh" ]; then
        exec bash "$SCRIPT_DIR/uninstall.sh" "${@:2}"
    else
        exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/uninstall.sh)"
    fi
fi

if [ "$1" = "--update" ]; then
    echo "Checking for agy-statusline updates..."
    if command -v brew >/dev/null 2>&1 && brew list agy-statusline >/dev/null 2>&1; then
        exec brew upgrade agy-statusline
    elif [ -d "$SCRIPT_DIR/../.git" ]; then
        (cd "$SCRIPT_DIR/.." && git pull --ff-only)
        echo "Successfully updated agy-statusline via git."
        exit 0
    else
        dest="$HOME/.gemini/statusline.sh"
        if curl -fsSL "https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/statusline.sh" -o "$dest"; then
            chmod +x "$dest"
            echo "Successfully updated $dest."
            exit 0
        else
            echo "Failed to update statusline.sh."
            exit 1
        fi
    fi
fi

if [ "$1" = "--preview" ] || [ "$1" = "-p" ] || { [ -t 0 ] && [ -z "$1" ]; }; then
    cols=$(tput cols 2>/dev/null || echo 120)
    [ "$cols" -lt 80 ] && cols=120
    printf '{"model":{"id":"gemini-3.8-flash-med","display_name":"3.8 Flash Med"},"plan_tier":"Google AI Pro","agent_state":"idle","vcs":{"branch":"%s"},"cwd":"%s","context_window":{"used_percentage":11},"quota":{"gemini-5h":{"remaining_fraction":0.04,"reset_in_seconds":17460},"gemini-weekly":{"remaining_fraction":0.43,"reset_in_seconds":306000}},"terminal_width":%d}' \
        "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")" \
        "$(pwd)" \
        "$cols" | bash "${BASH_SOURCE[0]:-$0}"
    echo
    exit 0
fi

input=$(cat)

if [ -z "$input" ]; then
    printf "agy"
    exit 0
fi

# ── 1. Single-Pass JQ Parsing ────────────────────────────────────────────────
CACHE_FILE="$HOME/.cache/agy-hud/quota_cache.json"

parsed_vars=$(printf "%s" "$input" | jq -r '
. as $root |
($root.model.display_name // $root.model.id // "Gemini") as $raw_model |
($raw_model | gsub("Gemini|Claude|Thinking|\\(|\\)"; "") | gsub("Medium"; "Med") | gsub("^\\s+|\\s+$"; "")) as $model |
($root.plan_tier // "") as $raw_plan |
(if ($raw_plan | test("Pro|Google AI Pro")) then "Pro" elif $raw_plan != "" then "Free" else "" end) as $plan |
($root.workspace.current_dir // $root.cwd // $root.workspace.project_dir // "") as $cwd |
($root.vcs.branch // "") as $vcs_branch |
($root.agent_state // "idle") as $agent_state |
(($root.context_window.used_percentage // 0) | round) as $ctx_pct |
($root.model.id // "" | ascii_downcase) as $model_id |
(if ($model_id | test("claude|anthropic|3p")) then "3p" else "gemini" end) as $pool |
(if $pool == "3p" then "3p-5h" else "gemini-5h" end) as $k5h |
(if $pool == "3p" then "3p-weekly" else "gemini-weekly" end) as $kwk |

# 5h quota
(if $root.quota[$k5h].remaining_fraction != null then
  ((1 - $root.quota[$k5h].remaining_fraction) * 100 | round)
elif $root.rate_limits.five_hour.used_percentage != null then
  ($root.rate_limits.five_hour.used_percentage | tonumber | round)
else null end) as $q5h_pct |

($root.quota[$k5h].reset_in_seconds // null) as $q5h_sec |

# weekly quota
(if $root.quota[$kwk].remaining_fraction != null then
  ((1 - $root.quota[$kwk].remaining_fraction) * 100 | round)
elif $root.rate_limits.seven_day.used_percentage != null then
  ($root.rate_limits.seven_day.used_percentage | tonumber | round)
else null end) as $qwk_pct |

($root.quota[$kwk].reset_in_seconds // null) as $qwk_sec |
(($root.terminal_width // 0) | tonumber | round) as $term_width |

[
  "raw_model=\($raw_model | @sh)",
  "model_id=\($model_id | @sh)",
  "model=\($model | @sh)",
  "plan=\($plan | @sh)",
  "cwd=\($cwd | @sh)",
  "vcs_branch=\($vcs_branch | @sh)",
  "agent_state=\($agent_state | @sh)",
  "ctx_pct=\($ctx_pct | @sh)",
  "q5h_pct=\(($q5h_pct // "") | tostring | @sh)",
  "q5h_sec=\(($q5h_sec // "") | tostring | @sh)",
  "qwk_pct=\(($qwk_pct // "") | tostring | @sh)",
  "qwk_sec=\(($qwk_sec // "") | tostring | @sh)",
  "term_width=\($term_width | @sh)"
] | .[]
') || { printf "agy"; exit 0; }

eval "$parsed_vars"

# ── 2. Fallbacks & Pure Bash Transformations ─────────────────────────────────
# Fallback plan from cache if needed
if [ -z "$plan" ] && [ -f "$CACHE_FILE" ]; then
    plan=$(jq -r '.plan_name // ""' "$CACHE_FILE" 2>/dev/null || true)
fi
[ -z "$plan" ] && plan="Pro"

# Fallback quota from cache if payload was empty
if [ -z "$q5h_pct" ] && [ -f "$CACHE_FILE" ]; then
    cache_q=$(jq -r --arg m "$raw_model" '
      .models[$m] // empty |
      if .remainingFraction != null then
        ((1 - .remainingFraction) * 100 | round | tostring)
      else "" end
    ' "$CACHE_FILE" 2>/dev/null || true)
    [ -n "$cache_q" ] && q5h_pct="$cache_q"
fi

# Directory basename (pure Bash, 0 subshells)
[ -z "$cwd" ] && cwd="${PWD:-.}"
cwd_name="${cwd##*/}"
[ -z "$cwd_name" ] && cwd_name="$cwd"

# VCS branch (pure Bash fallback, only query git if not supplied by agy)
git_branch="$vcs_branch"
is_git=0
if [ -d "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    is_git=1
    if [ -z "$git_branch" ]; then
        git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
                  || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    fi
fi
[ -z "$git_branch" ] && git_branch="main"

# State Capitalization (pure Bash mapping, compatible with Bash 3.2+)
fc="${agent_state:0:1}"
case "$fc" in
    a) uc="A" ;; b) uc="B" ;; c) uc="C" ;; d) uc="D" ;; e) uc="E" ;;
    f) uc="F" ;; g) uc="G" ;; h) uc="H" ;; i) uc="I" ;; j) uc="J" ;;
    k) uc="K" ;; l) uc="L" ;; m) uc="M" ;; n) uc="N" ;; o) uc="O" ;;
    p) uc="P" ;; q) uc="Q" ;; r) uc="R" ;; s) uc="S" ;; t) uc="T" ;;
    u) uc="U" ;; v) uc="V" ;; w) uc="W" ;; x) uc="X" ;; y) uc="Y" ;;
    z) uc="Z" ;; *) uc="$fc" ;;
esac
state_name="${uc}${agent_state:1}"

# ── 3. Configuration & Themes ────────────────────────────────────────────────
CONFIG_FILE="$HOME/.config/agy-statusline/config.json"
cfg_theme=""
cfg_glyphs=""
cfg_separator=""
cfg_time_format=""
cfg_git_dirty=""
cfg_alias=""

if [ -f "$CONFIG_FILE" ]; then
    eval "$(jq -r --arg m "$raw_model" --arg mid "$model_id" --arg mod "$model" '
      [
        "cfg_theme=\((.theme // "") | @sh)",
        "cfg_glyphs=\((.glyphs // "") | @sh)",
        "cfg_separator=\((.separator // "") | @sh)",
        "cfg_time_format=\((.time_format // "") | @sh)",
        "cfg_git_dirty=\((if .show_git_dirty == false then "0" else "1" end) | @sh)",
        "cfg_alias=\((.model_aliases[$m] // .model_aliases[$mid] // .model_aliases[$mod] // "") | @sh)"
      ] | .[]
    ' "$CONFIG_FILE" 2>/dev/null || true)"
fi

theme="${AGY_STATUSLINE_THEME:-${cfg_theme:-tokyo-night}}"
glyph_mode="${AGY_STATUSLINE_GLYPHS:-${cfg_glyphs:-nerd}}"
sep_style="${AGY_STATUSLINE_SEPARATOR:-${cfg_separator:-bar}}"
time_style="${AGY_STATUSLINE_TIME_FORMAT:-${cfg_time_format:-relative}}"
show_dirty="${AGY_STATUSLINE_GIT_DIRTY:-${cfg_git_dirty:-1}}"

[ -n "$cfg_alias" ] && model="$cfg_alias"

# Check for uncommitted changes in git working tree
if [ "$is_git" -eq 1 ] && [ "$show_dirty" = "1" ]; then
    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
        git_branch="${git_branch}*"
    fi
fi

# Auto-detect Linux console / no-nerd-fonts
if [ "$glyph_mode" = "nerd" ] && { [ "$TERM" = "linux" ] || [ -n "$NO_NERD_FONTS" ]; }; then
    glyph_mode="unicode"
fi

# Glyphs
case "$glyph_mode" in
    unicode)
        i_model="⚡ "
        i_tier="✦ "
        i_dir="📁 "
        i_git="⎇ "
        i_ctx="🧠 "
        i_use="⚡ "
        i_clock="⏱ "
        bullet="● "
        ;;
    ascii)
        i_model="[M] "
        i_tier="[P] "
        i_dir="[D] "
        i_git="[B] "
        i_ctx="[C] "
        i_use="[U] "
        i_clock="[T] "
        bullet="* "
        ;;
    none)
        i_model=""
        i_tier=""
        i_dir=""
        i_git=""
        i_ctx=""
        i_use=""
        i_clock=""
        bullet="● "
        ;;
    *) # nerd (default)
        i_model=" "
        i_tier=" "
        i_dir=" "
        i_git=" "
        i_ctx="󰍛 "
        i_use=" "
        i_clock=" "
        bullet="● "
        ;;
esac

# Color Themes (Truecolor 24-bit ANSI)
case "$theme" in
    catppuccin)
        c_model="\033[1;38;2;137;180;250m"  # Blue (#89b4fa)
        c_tier="\033[1;38;2;249;226;175m"   # Yellow (#f9e2af)
        c_dir="\033[1;38;2;250;179;135m"    # Peach (#fab387)
        c_git="\033[1;38;2;203;166;247m"    # Mauve (#cba6f7)
        c_label="\033[1;38;2;205;214;244m"  # Text (#cdd6f4)
        c_track="\033[38;2;69;71;90m"       # Surface1 (#45475a)
        c_sep_color="\033[38;2;108;112;134m"
        c_muted="\033[38;2;166;173;200m"    # Subtext0 (#a6adc8)
        c_state_norm="\033[1;38;2;166;227;161m" # Green (#a6e3a1)
        c_state_run="\033[1;38;2;243;139;168m"  # Red (#f38ba8)
        c_state_think="\033[1;38;2;137;220;235m" # Sky (#89dceb)
        c_bar_warn="\033[38;2;243;139;168m"
        c_bar_med="\033[38;2;249;226;175m"
        c_bar_ok="\033[38;2;166;227;161m"
        ;;
    nord)
        c_model="\033[1;38;2;136;192;208m"  # Frost (#88c0d0)
        c_tier="\033[1;38;2;235;203;139m"   # Yellow (#ebcb8b)
        c_dir="\033[1;38;2;208;135;112m"    # Orange (#d08770)
        c_git="\033[1;38;2;180;142;173m"    # Purple (#b48ead)
        c_label="\033[1;38;2;236;239;244m"  # Snow White (#eceff4)
        c_track="\033[38;2;59;66;82m"       # Polar Night (#3b4252)
        c_sep_color="\033[38;2;76;86;106m"
        c_muted="\033[38;2;216;222;233m"
        c_state_norm="\033[1;38;2;163;190;140m" # Green (#a3be8c)
        c_state_run="\033[1;38;2;191;97;106m"   # Red (#bf616a)
        c_state_think="\033[1;38;2;129;161;193m" # Blue (#81a1c1)
        c_bar_warn="\033[38;2;191;97;106m"
        c_bar_med="\033[38;2;235;203;139m"
        c_bar_ok="\033[38;2;163;190;140m"
        ;;
    solarized)
        c_model="\033[1;38;2;42;161;152m"   # Cyan (#2aa198)
        c_tier="\033[1;38;2;181;137;0m"     # Yellow (#b58900)
        c_dir="\033[1;38;2;203;75;22m"      # Orange (#cb4b16)
        c_git="\033[1;38;2;211;54;130m"     # Magenta (#d33682)
        c_label="\033[1;38;2;238;232;213m"  # Base2 (#eee8d5)
        c_track="\033[38;2;7;54;66m"        # Base02 (#073642)
        c_sep_color="\033[38;2;88;110;117m"
        c_muted="\033[38;2;147;161;161m"
        c_state_norm="\033[1;38;2;133;153;0m"   # Green (#859900)
        c_state_run="\033[1;38;2;220;50;47m"    # Red (#dc322f)
        c_state_think="\033[1;38;2;38;139;210m" # Blue (#268bd2)
        c_bar_warn="\033[38;2;220;50;47m"
        c_bar_med="\033[38;2;181;137;0m"
        c_bar_ok="\033[38;2;133;153;0m"
        ;;
    light)
        c_model="\033[1;38;2;0;115;150m"    # Deep Teal
        c_tier="\033[1;38;2;175;95;0m"      # Dark Amber
        c_dir="\033[1;38;2;190;60;0m"       # Brick Orange
        c_git="\033[1;38;2;125;35;180m"     # Plum Purple
        c_label="\033[1;38;2;30;35;45m"     # Charcoal
        c_track="\033[38;2;210;215;225m"    # Light Gray Track
        c_sep_color="\033[38;2;140;150;165m"
        c_muted="\033[38;2;90;100;115m"
        c_state_norm="\033[1;38;2;0;135;60m"    # Forest Green
        c_state_run="\033[1;38;2;200;25;25m"    # Crimson
        c_state_think="\033[1;38;2;0;105;190m"  # Royal Blue
        c_bar_warn="\033[38;2;200;25;25m"
        c_bar_med="\033[38;2;175;95;0m"
        c_bar_ok="\033[38;2;0;135;60m"
        ;;
    *) # tokyo-night (default)
        c_model="\033[1;38;2;0;229;255m"       # Electric Cyan (#00e5ff)
        c_tier="\033[1;38;2;255;214;0m"        # Luminous Gold (#ffd600)
        c_dir="\033[1;38;2;255;133;0m"         # Vivid Tangerine (#ff8500)
        c_git="\033[1;38;2;217;70;239m"        # Electric Orchid (#d946ef)
        c_label="\033[1;38;2;240;246;252m"     # High-Luminance White
        c_track="\033[38;2;50;60;75m"          # Dark Slate Track
        c_sep_color="\033[38;2;110;120;145m"
        c_muted="\033[38;2;160;175;195m"       # Crisp Muted Timer
        c_state_norm="\033[1;38;2;0;230;118m"  # Bright Neon Green (#00e676)
        c_state_run="\033[1;38;2;255;61;0m"    # Hot Red-Orange (#ff3d00)
        c_state_think="\033[1;38;2;56;189;248m" # Electric Sky (#38bdf8)
        c_bar_warn="\033[38;2;255;75;75m"      # Bright Coral Red (#ff4b4b)
        c_bar_med="\033[38;2;255;214;0m"       # Luminous Gold (#ffd600)
        c_bar_ok="\033[38;2;0;230;118m"        # Bright Neon Green (#00e676)
        ;;
esac
reset="\033[0m"

# Separator style rendering
case "$sep_style" in
    slant)
        s_main="  "
        s_sub="  "
        ;;
    bubble)
        s_main="  "
        s_sub="  "
        ;;
    pipe)
        s_main=" | "
        s_sub=" | "
        ;;
    slash)
        s_main=" / "
        s_sub=" / "
        ;;
    minimal)
        s_main="  "
        s_sub="  "
        ;;
    *) # bar (default)
        s_main=" │ "
        s_sub=" | "
        ;;
esac
c_sep="${c_sep_color}${s_main}${reset}"
c_subsep="${c_sep_color}${s_sub}${reset}"

# Dynamic agent state colors
case "$agent_state" in
    running|executing) c_state="$c_state_run"   ;;
    thinking)          c_state="$c_state_think" ;;
    auth)              c_state="\033[1;38;2;255;23;68m" ;;
    *)                 c_state="$c_state_norm"  ;;
esac

# ── 4. Terminal Width & Responsive Adaptation ────────────────────────────────
[ -z "$term_width" ] || [ "$term_width" -le 0 ] && term_width=$(tput cols 2>/dev/null || echo 120)
[ -z "$term_width" ] && term_width=120

# Compact length of progress bars
bar_width=10
[ "$term_width" -lt 80 ] && bar_width=5

# Responsive labels
lbl_ctx="Context"
lbl_use="Usage"
if [ "$term_width" -lt 75 ]; then
    lbl_ctx="Ctx"
    lbl_use="Use"
fi

# Truncate branch & directory if terminal is narrow
if [ "$term_width" -lt 95 ]; then
    if [ "${#git_branch}" -gt 13 ]; then
        git_branch="${git_branch:0:6}…${git_branch: -6}"
    fi
    if [ "${#cwd_name}" -gt 15 ]; then
        cwd_name="${cwd_name:0:7}…${cwd_name: -7}"
    fi
fi

# Drop weekly quota on narrow terminals to prevent multi-line wrap
if [ "$term_width" -lt 68 ]; then
    qwk_pct=""
fi

# ── 5. Helper Functions ──────────────────────────────────────────────────────
fmt_duration() {
    local sec=$1
    [ -z "$sec" ] || [ "$sec" -le 0 ] && return
    local mins=$(( sec / 60 ))
    local days=$(( mins / (24 * 60) ))
    mins=$(( mins - days * 24 * 60 ))
    local hours=$(( mins / 60 ))
    mins=$(( mins % 60 ))
    local rel_str=""
    if [ "$days" -gt 0 ]; then
        rel_str=$(printf "%dd %dh" "$days" "$hours")
    elif [ "$hours" -gt 0 ]; then
        rel_str=$(printf "%dh %dm" "$hours" "$mins")
    else
        rel_str=$(printf "%dm" "$mins")
    fi

    if [ "$time_style" = "absolute" ] || [ "$time_style" = "both" ]; then
        local now abs_str=""
        now=$(date +%s 2>/dev/null || echo 0)
        if [ "$now" -gt 0 ]; then
            local target=$(( now + sec ))
            abs_str=$(date -r "$target" +"%H:%M" 2>/dev/null || date -d "@$target" +"%H:%M" 2>/dev/null || true)
        fi
        if [ -n "$abs_str" ]; then
            if [ "$time_style" = "absolute" ]; then
                printf "%s" "$abs_str"
                return
            else
                local sep_both=" · "
                [ "$glyph_mode" = "ascii" ] && sep_both=" / "
                printf "%s%s%s" "$rel_str" "$sep_both" "$abs_str"
                return
            fi
        fi
    fi

    printf "%s" "$rel_str"
}

BAR_FULL="████████████"
BAR_EMPTY="░░░░░░░░░░░░"
make_bar() {
    local pct=${1%.*}
    pct=${pct:-0}
    local width=${2:-10}
    local filled_n=$(( (pct * width + 50) / 100 ))
    [ "$filled_n" -gt "$width" ] && filled_n=$width
    [ "$filled_n" -lt 0 ] && filled_n=0
    local empty_n=$(( width - filled_n ))
    
    local col="$c_bar_ok"
    if [ "$pct" -ge 90 ]; then
        col="$c_bar_warn"
    elif [ "$pct" -ge 70 ]; then
        col="$c_bar_med"
    fi

    local filled_str="${BAR_FULL:0:filled_n}"
    local empty_str="${BAR_EMPTY:0:empty_n}"

    printf "%b%s%b%s%b" "$col" "$filled_str" "$c_track" "$empty_str" "$reset"
}

# ── 6. Assemble Output ───────────────────────────────────────────────────────
# Line 1: Identity & State
line1="${c_model}${i_model}${model}${reset}${c_subsep}${c_tier}${i_tier}${plan}${reset}${c_sep}${c_dir}${i_dir}${cwd_name}${reset}${c_sep}${c_git}${i_git}${git_branch}${reset}${c_sep}${c_state}${bullet}${state_name}${reset}"

# Line 2: Context & Telemetry
ctx_bar=$(make_bar "$ctx_pct" "$bar_width")
if [ "$ctx_pct" -ge 95 ]; then
    c_alert="\033[7;1;38;2;255;75;75m"
    line2="${c_label}${i_ctx}${lbl_ctx}${reset} ${ctx_bar} ${c_alert} ${ctx_pct}%! ${reset}"
else
    line2="${c_label}${i_ctx}${lbl_ctx}${reset} ${ctx_bar} ${ctx_pct}%"
fi

if [ -n "$q5h_pct" ]; then
    u5h_bar=$(make_bar "$q5h_pct" "$bar_width")
    dur5h=$(fmt_duration "$q5h_sec")
    reset5h=""
    [ -n "$dur5h" ] && reset5h=" (${c_muted}${i_clock}${dur5h}${reset})"

    usage_str="${c_label}${i_use}${lbl_use}${reset} ${u5h_bar} ${q5h_pct}%${reset5h}"

    if [ -n "$qwk_pct" ]; then
        uwk_bar=$(make_bar "$qwk_pct" "$bar_width")
        durwk=$(fmt_duration "$qwk_sec")
        resetwk=""
        [ -n "$durwk" ] && resetwk=" (${c_muted}${i_clock}${durwk}${reset})"
        usage_str="${usage_str}${c_subsep}${uwk_bar} ${qwk_pct}%${resetwk}"
    fi

    line2="${line2}${c_sep}${usage_str}"
fi

printf "%b\n%b" "$line1" "$line2"
exit 0
