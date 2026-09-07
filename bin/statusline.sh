#!/bin/bash
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "agy"
    exit 0
fi

# ── ANSI-256 colors — match ~/.config/ccstatusline/settings.json ─────────────
# (colorLevel=2, widget colors as configured)
CC_MODEL=203     # brightRed   — model name
CC_CTX=203       # brightRed   — context bar (same segment group as model)
CC_GIT=111       # brightBlue  — git branch (⎇ icon + name)
CC_SESSION=155   # brightGreen — session usage slider
CC_WEEKLY=140    # brightMagenta — weekly usage slider

# ANSI sequences
ESC=$'\033'
RESET="${ESC}[0m"                  # full attribute reset (≡ ccstatusline's [49m[39m)
POWERLINE_ARROW=$'\xee\x82\xb0'   # U+E0B0 — Nerd Font solid right arrow 

# ── Bar characters ────────────────────────────────────────────────────────────
# slider:  ▓ (U+2593 DARK SHADE) / ░ (U+2591 LIGHT SHADE)  — session & weekly
# ctx bar: █ (U+2588 FULL BLOCK) / ░ (U+2591 LIGHT SHADE)  — context progress-short

# Build a session/weekly slider:  ▓▓▓░░░░░░░
slider_bar() {
    local pct=$1 width=$2
    local filled_n
    filled_n=$(printf "%.0f" "$(awk "BEGIN{print $pct/100*$width}")")
    (( filled_n > width )) && filled_n=$width
    local empty_n=$(( width - filled_n )) bar="" i
    for (( i=0; i<filled_n; i++ )); do bar+="▓"; done
    for (( i=0; i<empty_n;  i++ )); do bar+="░"; done
    printf "%s" "$bar"
}

# Build a context bar:  [███████░░░░░░░░░]
ctx_bar() {
    local pct=$1 width=${2:-16}
    local filled_n
    filled_n=$(printf "%.0f" "$(awk "BEGIN{print $pct/100*$width}")")
    (( filled_n > width )) && filled_n=$width
    local empty_n=$(( width - filled_n )) bar="" i
    for (( i=0; i<filled_n; i++ )); do bar+="█"; done
    for (( i=0; i<empty_n;  i++ )); do bar+="░"; done
    printf "[%s]" "$bar"
}

# ── Number formatters ─────────────────────────────────────────────────────────
# Percentage: 1 decimal place — "28.0%" (session/weekly, matches ccstatusline)
fmt_pct()     { printf "%.1f" "$1"; }
# Percentage for context bar: strip ".0" — "(42%)" not "(42.0%)"
fmt_pct_ctx() { printf "%.1f" "$1" | sed 's/\.0$//'; }
# Token counts: 420000→420k, 1000000→1.0M  (matches ccstatusline fmt)
fmt_k() {
    local n=$1
    if   [ "$n" -ge 1000000 ]; then awk "BEGIN{printf \"%.1fM\", $n/1000000}"
    elif [ "$n" -ge 1000    ]; then awk "BEGIN{printf \"%.0fk\", $n/1000}"
    else printf "%d" "$n"
    fi
}

# ── Extract all data in one jq pass ──────────────────────────────────────────
parsed_vars=$(printf "%s" "$input" | jq -r '
. as $root |
($root.model.id // "" | ascii_downcase) as $model_id |
(if ($model_id | test("claude|anthropic|3p")) then "3p" else "gemini" end) as $quota_pool |
(if $quota_pool == "3p" then "3p-5h" else "gemini-5h" end) as $q5h_key |
(if $quota_pool == "3p" then "3p-weekly" else "gemini-weekly" end) as $qwk_key |

# Full model name (ccstatusline rawValue:true — no brand stripping)
($root.model.display_name // $root.model.id // "agy") as $model_name |

# CWD: workspace.current_dir > cwd > workspace.project_dir
($root.workspace.current_dir // $root.cwd // $root.workspace.project_dir // "") as $cwd |

# VCS fields from payload (avoids git subprocess when available)
($root.vcs.branch // "") as $vcs_branch |
($root.vcs.root   // "") as $vcs_root |

# Context window — keep 1 decimal precision for the bar calc
(($root.context_window.used_percentage // 0) | . * 10 | round | . / 10) as $ctx_pct |
($root.context_window.total_input_tokens  // null) as $ctx_tokens |
($root.context_window.context_window_size // null) as $ctx_size |

# Session (5h) usage — supports agy, Claude Code, and ccstatusline schemas
(if   $root.quota[$q5h_key].remaining_fraction != null
 then ((1 - $root.quota[$q5h_key].remaining_fraction) * 100)
 elif $root.rate_limits.five_hour.used_percentage != null
 then ($root.rate_limits.five_hour.used_percentage | tonumber)
 elif $root.rate_limit_period.used_percentage != null
 then ($root.rate_limit_period.used_percentage | tonumber)
 else null
 end) as $ses_pct |

# Weekly (7d) usage
(if   $root.quota[$qwk_key].remaining_fraction != null
 then ((1 - $root.quota[$qwk_key].remaining_fraction) * 100)
 elif $root.rate_limits.seven_day.used_percentage != null
 then ($root.rate_limits.seven_day.used_percentage | tonumber)
 else null
 end) as $wk_pct |

# Token throughput speed (ccstatusline total-speed widget)
($root.total_speed // null) as $speed |

[
  "model_name=\($model_name | @sh)",
  "cwd=\($cwd | @sh)",
  "vcs_branch=\($vcs_branch | @sh)",
  "vcs_root=\($vcs_root | @sh)",
  "ctx_pct=\($ctx_pct | @sh)",
  "ctx_tokens=\(($ctx_tokens // "" | tostring) | @sh)",
  "ctx_size=\(($ctx_size // "" | tostring) | @sh)",
  "ses_pct=\(($ses_pct // "") | tostring | @sh)",
  "wk_pct=\(($wk_pct // "") | tostring | @sh)",
  "speed=\(($speed // "") | @sh)",
  "terminal_width=\((($root.terminal_width // 80) | if . <= 0 then 80 else . end) | @sh)"
] | .[]
') || { printf "agy"; exit 0; }

eval "$parsed_vars"

[ -z "$cwd" ] && cwd=$(pwd)

# ── Git branch — prefer payload vcs.branch, fall back to running git ─────────
git_branch=""
if [ -n "$vcs_branch" ]; then
    git_branch="$vcs_branch"
elif git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
              || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# ── Build segments ────────────────────────────────────────────────────────────
# Layout matches ccstatusline config:
#   model  [speed]  context-bar  [git-branch]  [session]  [weekly]
# Each segment: leading space + content + trailing space, in its ANSI-256 color.
# Separated by the Powerline U+E0B0 arrow (plain reset before it; next segment opens its own color).

segments=()

# 1. Model
segments+=("${ESC}[38;5;${CC_MODEL}m ${model_name} ${RESET}")

# 2. Total speed (optional — only when payload provides it)
if [ -n "$speed" ]; then
    segments+=("${ESC}[38;5;${CC_CTX}m ${speed} ${RESET}")
fi

# 3. Context bar — "progress-short" display with token counts when available
if [ -n "$ctx_pct" ]; then
    local ctx_bar_str ctx_str 2>/dev/null || true
    if [ -n "$ctx_tokens" ] && [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
        # Full form: [███████░░░░░░░░░] 420k/1.0M (42%)
        ctx_bar_str=$(ctx_bar "$ctx_pct" 16)
        ctx_str="${ESC}[38;5;${CC_CTX}m ${ctx_bar_str} $(fmt_k "$ctx_tokens")/$(fmt_k "$ctx_size") ($(fmt_pct_ctx "$ctx_pct")%) ${RESET}"
    else
        # Short form: [████████░░] (78%)
        ctx_bar_str=$(ctx_bar "$ctx_pct" 10)
        ctx_str="${ESC}[38;5;${CC_CTX}m ${ctx_bar_str} ($(fmt_pct_ctx "$ctx_pct")%) ${RESET}"
    fi
    segments+=("$ctx_str")
fi

# 4. Git branch — ⎇ icon (U+2387 ALTERNATIVE KEY SYMBOL, same as ccstatusline)
if [ -n "$git_branch" ]; then
    segments+=("${ESC}[38;5;${CC_GIT}m ⎇ ${git_branch} ${RESET}")
fi

# 5. Session (5h) slider
if [ -n "$ses_pct" ] && [ "$ses_pct" != "0" ]; then
    ses_bar=$(slider_bar "$ses_pct" 10)
    segments+=("${ESC}[38;5;${CC_SESSION}m Session: ${ses_bar} $(fmt_pct "$ses_pct")% ${RESET}")
fi

# 6. Weekly (7d) slider
if [ -n "$wk_pct" ] && [ "$wk_pct" != "0" ]; then
    wk_bar=$(slider_bar "$wk_pct" 10)
    segments+=("${ESC}[38;5;${CC_WEEKLY}m Weekly: ${wk_bar} $(fmt_pct "$wk_pct")% ${RESET}")
fi

# ── Assemble with Powerline arrows ────────────────────────────────────────────
# Each segment already ends with RESET, so we only need the arrow glyph itself
# between segments. The arrow renders in the terminal's default fg color,
# exactly matching ccstatusline's [49m[39m + arrow behaviour.
# Each segment opens its own color at the start, so no color leaks.

output=""
n=${#segments[@]}
for (( i=0; i<n; i++ )); do
    output+="${segments[$i]}"
    if (( i < n-1 )); then
        output+="${POWERLINE_ARROW}"
    fi
done

# ── Output ────────────────────────────────────────────────────────────────────
printf "%b" "$output"

exit 0
