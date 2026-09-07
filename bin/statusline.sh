#!/usr/bin/env bash
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "agy"
    exit 0
fi

# ── Standalone 2-Line HUD Engine ─────────────────────────────────────────────
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

[
  "raw_model=\($raw_model | @sh)",
  "model=\($model | @sh)",
  "plan=\($plan | @sh)",
  "cwd=\($cwd | @sh)",
  "vcs_branch=\($vcs_branch | @sh)",
  "agent_state=\($agent_state | @sh)",
  "ctx_pct=\($ctx_pct | @sh)",
  "q5h_pct=\(($q5h_pct // "") | tostring | @sh)",
  "q5h_sec=\(($q5h_sec // "") | tostring | @sh)",
  "qwk_pct=\(($qwk_pct // "") | tostring | @sh)",
  "qwk_sec=\(($qwk_sec // "") | tostring | @sh)"
] | .[]
') || { printf "agy"; exit 0; }

eval "$parsed_vars"

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

# Git branch fallback
[ -z "$cwd" ] && cwd=$(pwd)
git_branch=""
if [ -n "$vcs_branch" ]; then
    git_branch="$vcs_branch"
elif git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
              || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi
[ -z "$git_branch" ] && git_branch="main"

cwd_name=$(basename "$cwd")

# Capitalize state
state_name="$(tr '[:lower:]' '[:upper:]' <<< "${agent_state:0:1}")${agent_state:1}"

# Helpers
fmt_duration() {
    local sec=$1
    [ -z "$sec" ] || [ "$sec" -le 0 ] && return
    local mins=$(( sec / 60 ))
    local days=$(( mins / (24 * 60) ))
    mins=$(( mins - days * 24 * 60 ))
    local hours=$(( mins / 60 ))
    mins=$(( mins % 60 ))
    if [ "$days" -gt 0 ]; then
        printf "%dd %dh" "$days" "$hours"
    elif [ "$hours" -gt 0 ]; then
        printf "%dh %dm" "$hours" "$mins"
    else
        printf "%dm" "$mins"
    fi
}

make_bar() {
    local pct=${1%.*}
    pct=${pct:-0}
    local width=${2:-10}
    local filled_n=$(( (pct * width + 50) / 100 ))
    [ "$filled_n" -gt "$width" ] && filled_n=$width
    [ "$filled_n" -lt 0 ] && filled_n=0
    local empty_n=$(( width - filled_n ))
    
    local col="\033[38;2;158;206;106m" # soft emerald
    if [ "$pct" -ge 90 ]; then
        col="\033[38;2;247;118;142m"   # tokyo red
    elif [ "$pct" -ge 70 ]; then
        col="\033[38;2;224;175;104m"   # tokyo warm honey
    fi
    local track="\033[38;2;51;65;85m"   # slate dark track
    local reset="\033[0m"

    local filled_str="" empty_str="" i
    for (( i=0; i<filled_n; i++ )); do filled_str+="█"; done
    for (( i=0; i<empty_n;  i++ )); do empty_str+="░"; done

    printf "%b%s%b%s%b" "$col" "$filled_str" "$track" "$empty_str" "$reset"
}

# ── Tokyo Night Color Palette (Line 1 & Line 2) ─────────────────────────────
c_model="\033[1;38;2;122;162;247m"     # Sapphire Blue   (#7aa2f7)
c_tier="\033[1;38;2;255;199;119m"      # Warm Gold Badge (#ffc777)
c_dir="\033[1;38;2;224;175;104m"       # Warm Honey      (#e0af68)
c_git="\033[1;38;2;187;154;247m"       # Lavender Purple (#bb9af7)
c_state="\033[1;38;2;158;206;106m"     # Soft Emerald    (#9ece6a)
c_sep="\033[38;2;100;116;139m │ \033[0m" # Muted Slate Separator
c_subsep="\033[38;2;100;116;139m | \033[0m" # Subtle inner pipe
c_label="\033[1;38;2;226;232;240m"     # Crisp White Label
c_muted="\033[38;2;148;163;184m"       # Dim Muted Clock
reset="\033[0m"

# Dynamic agent state colors (Tokyo Night theme)
case "$agent_state" in
    running|executing) c_state="\033[1;38;2;255;158;100m" ;; # Sunset Orange (#ff9e64)
    thinking)          c_state="\033[1;38;2;125;207;255m" ;; # Ice Cyan      (#7dcfff)
    auth)              c_state="\033[1;38;2;247;118;142m" ;; # Tokyo Red     (#f7768e)
    *)                 c_state="\033[1;38;2;158;206;106m" ;; # Soft Emerald  (#9ece6a)
esac

# ── Assemble Line 1 ──────────────────────────────────────────────────────────
#  3.8 Flash Med |  Pro │  net-worth-tracker │  main │ ● Idle
line1="${c_model} ${model}${reset}${c_subsep}${c_tier} ${plan}${reset}${c_sep}${c_dir} ${cwd_name}${reset}${c_sep}${c_git} ${git_branch}${reset}${c_sep}${c_state}● ${state_name}${reset}"

# ── Assemble Line 2 ──────────────────────────────────────────────────────────
# 󰍛 Context █░░░░░░░░░ 11% │  Usage ██████████ 96% ( 4h 51m) |  ██████░░░░ 57% ( 3d 13h)
ctx_bar=$(make_bar "$ctx_pct" 10)
line2="${c_label}󰍛 Context${reset} ${ctx_bar} ${ctx_pct}%"

if [ -n "$q5h_pct" ]; then
    u5h_bar=$(make_bar "$q5h_pct" 10)
    dur5h=$(fmt_duration "$q5h_sec")
    reset5h=""
    [ -n "$dur5h" ] && reset5h=" (${c_muted} ${dur5h}${reset})"

    usage_str="${c_label} Usage${reset} ${u5h_bar} ${q5h_pct}%${reset5h}"

    if [ -n "$qwk_pct" ]; then
        uwk_bar=$(make_bar "$qwk_pct" 10)
        durwk=$(fmt_duration "$qwk_sec")
        resetwk=""
        [ -n "$durwk" ] && resetwk=" (${c_muted} ${durwk}${reset})"
        usage_str="${usage_str} |  ${uwk_bar} ${qwk_pct}%${resetwk}"
    fi

    line2="${line2}${c_sep}${usage_str}"
fi

printf "%b\n%b" "$line1" "$line2"
exit 0
