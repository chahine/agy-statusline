#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATUSLINE="$ROOT_DIR/bin/statusline.sh"

green='\033[38;5;155m'
red='\033[38;5;203m'
dim='\033[2m'
reset='\033[0m'
bold='\033[1m'

pass_count=0
fail_count=0

run_test() {
    local name="$1"
    local input="$2"
    local expected_pattern="$3"
    local assert_exit_code="${4:-0}"
    local env_prefix="${5:-}"
    local forbidden_pattern="${6:-}"

    local output exit_code=0
    if [ -n "$env_prefix" ]; then
        output=$(printf "%s" "$input" | env $env_prefix "$STATUSLINE") || exit_code=$?
    else
        output=$(printf "%s" "$input" | "$STATUSLINE") || exit_code=$?
    fi

    if [ "$exit_code" -ne "$assert_exit_code" ]; then
        echo -e "  ${red}FAIL${reset} $name (expected exit code $assert_exit_code, got $exit_code)"
        fail_count=$((fail_count + 1))
        return
    fi

    # Replace newlines with space for multi-line regex matching
    local flat_output
    flat_output=$(printf "%s" "$output" | tr '\n' ' ')

    if [ -n "$forbidden_pattern" ] && [[ "$flat_output" =~ $forbidden_pattern ]]; then
        echo -e "  ${red}FAIL${reset} $name (found forbidden pattern: $forbidden_pattern)"
        echo -e "    ${dim}Actual output:${reset} $output"
        fail_count=$((fail_count + 1))
        return
    fi

    if [[ "$flat_output" =~ $expected_pattern ]]; then
        echo -e "  ${green}PASS${reset} $name"
        pass_count=$((pass_count + 1))
    else
        echo -e "  ${red}FAIL${reset} $name"
        echo -e "    ${dim}Expected pattern:${reset} $expected_pattern"
        echo -e "    ${dim}Actual output:${reset} $output"
        fail_count=$((fail_count + 1))
    fi
}

echo
echo -e "${bold}Running agy-statusline test suite...${reset}"
echo -e "${dim}─────────────────────────────────────────────────${reset}"

# 1. Empty stdin test
run_test "Empty input returns agy" "" "^agy *$"

# 2. Cold session (0% context, 2% 5h, 27% weekly)
payload_cold='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Google AI Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/agy-statusline",
  "context_window": {"used_percentage": 0},
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.98, "reset_in_seconds": 17700},
    "gemini-weekly": {"remaining_fraction": 0.73, "reset_in_seconds": 237600}
  },
  "terminal_width": 120
}'
run_test "Cold session renders correctly" "$payload_cold" "3.8 Flash Med.*Pro.*agy-statusline.*main.*● Idle.*Context.*░░░░░░░░░░.*0%.*Usage.*░░░░░░░░░░.*2%.*4h 55m.*███.*27%.*2d 18h"

# 3. Running state test (Hot Red-Orange bullet #ff3d00 / 255;61;0)
payload_running='{
  "model": {"id": "gemini-3.1-pro", "display_name": "Gemini 3.1 Pro"},
  "plan_tier": "Google AI Pro",
  "agent_state": "running",
  "vcs": {"branch": "feature/test"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 50},
  "terminal_width": 120
}'
run_test "Running state triggers hot bullet" "$payload_running" "3.1 Pro.*feature/test.*255;61;0m● Running"

# 4. Thinking state test (Electric Sky bullet #38bdf8 / 56;189;248)
payload_thinking='{
  "model": {"id": "gemini-3.8-flash-high", "display_name": "3.8 Flash High"},
  "plan_tier": "Google AI Pro",
  "agent_state": "thinking",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 20},
  "terminal_width": 120
}'
run_test "Thinking state triggers sky blue bullet" "$payload_thinking" "56;189;248m● Thinking"

# 5. High quota warning (>=90% usage triggers Coral Red #ff4b4b / 255;75;75)
payload_high_quota='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Google AI Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 10},
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.04, "reset_in_seconds": 3600}
  },
  "terminal_width": 120
}'
run_test "High quota >=90% triggers red bar" "$payload_high_quota" "255;75;75m██████████.*96%"

# 6. Medium load quota (70-89% triggers Gold #ffd600 / 255;214;0)
payload_med_quota='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Google AI Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 10},
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.25, "reset_in_seconds": 7200}
  },
  "terminal_width": 120
}'
run_test "Medium quota triggers gold bar" "$payload_med_quota" "255;214;0m████████.*75%"

# 7. 3rd-party model pool (Claude / Anthropic)
payload_3p='{
  "model": {"id": "claude-3-7-sonnet", "display_name": "Claude 3.7 Sonnet"},
  "plan_tier": "Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 5},
  "quota": {
    "3p-5h": {"remaining_fraction": 0.50, "reset_in_seconds": 10800},
    "3p-weekly": {"remaining_fraction": 0.80, "reset_in_seconds": 400000}
  },
  "terminal_width": 120
}'
run_test "3rd-party model selects 3p quota pool" "$payload_3p" "3.7 Sonnet.*50%.*3h 0m.*20%.*4d 15h"

# 8. Missing quota objects (graceful degradation)
payload_no_quota='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Free",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 15},
  "terminal_width": 120
}'
run_test "Missing quota renders context without crashing" "$payload_no_quota" "Context.*15%"

# 9. Responsive width < 75 cols (abbreviated labels & 5-block bars)
payload_narrow='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 20},
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.80, "reset_in_seconds": 7200},
    "gemini-weekly": {"remaining_fraction": 0.90, "reset_in_seconds": 180000}
  },
  "terminal_width": 74
}'
run_test "Responsive width < 75 cols compacts labels and bars" "$payload_narrow" "Ctx.*░░░░.*20%.*Use.*░░░░.*20%"

# 10. Responsive width < 95 cols (branch & directory truncation)
payload_trunc='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Pro",
  "agent_state": "idle",
  "vcs": {"branch": "feature/super-long-branch-name"},
  "cwd": "/workspace/super-long-directory-name",
  "context_window": {"used_percentage": 10},
  "terminal_width": 90
}'
run_test "Responsive width < 95 cols truncates long names" "$payload_trunc" "super-l…ry-name.*featur…h-name"

# 11. Responsive width < 68 cols (drops weekly quota to avoid line wrap)
payload_super_narrow='{
  "model": {"id": "gemini-3.8-flash-med", "display_name": "3.8 Flash Med"},
  "plan_tier": "Pro",
  "agent_state": "idle",
  "vcs": {"branch": "main"},
  "cwd": "/workspace/project",
  "context_window": {"used_percentage": 20},
  "quota": {
    "gemini-5h": {"remaining_fraction": 0.80, "reset_in_seconds": 7200},
    "gemini-weekly": {"remaining_fraction": 0.50, "reset_in_seconds": 180000}
  },
  "terminal_width": 65
}'
# Check that 5h quota is present (20% 2h 0m) but weekly 50% is omitted from output
run_test "Responsive width < 68 cols drops weekly quota" "$payload_super_narrow" "Ctx.*20%.*Use.*20%.*2h 0m" 0 "" "50%"

# 12. Glyph mode: Unicode
run_test "Glyph mode unicode renders standard Unicode symbols" "$payload_cold" "⚡ 3.8 Flash Med.*✦ Pro.*📁 .*⎇ main.*● Idle.*🧠 Context" 0 "AGY_STATUSLINE_GLYPHS=unicode"

# 13. Glyph mode: ASCII
run_test "Glyph mode ascii renders text brackets" "$payload_cold" "\[M\] 3.8 Flash Med.*\[P\] Pro.*\[D\] .*\[B\] main.*\* Idle.*\[C\] Context.*\[U\] Usage" 0 "AGY_STATUSLINE_GLYPHS=ascii"

# 14. Glyph mode: None
run_test "Glyph mode none renders plain text" "$payload_cold" "3.8 Flash Med.*Pro.*agy-statusline.*main.*● Idle.*Context.*Usage" 0 "AGY_STATUSLINE_GLYPHS=none"

# 15. Theme: Nord
run_test "Theme nord uses Frost cyan" "$payload_cold" "136;192;208m.*3.8 Flash Med" 0 "AGY_STATUSLINE_THEME=nord"

# 16. Theme: Catppuccin
run_test "Theme catppuccin uses Catppuccin blue" "$payload_cold" "137;180;250m.*3.8 Flash Med" 0 "AGY_STATUSLINE_THEME=catppuccin"

# 17. Theme: Light
run_test "Theme light uses Deep Teal" "$payload_cold" "0;115;150m.*3.8 Flash Med" 0 "AGY_STATUSLINE_THEME=light"

# 18. Config file loading (~/.config/agy-statusline/config.json)
CONFIG_DIR="$HOME/.config/agy-statusline"
CONFIG_PATH="$CONFIG_DIR/config.json"
CONFIG_BACKUP=""
if [ -f "$CONFIG_PATH" ]; then
    CONFIG_BACKUP=$(mktemp)
    cp "$CONFIG_PATH" "$CONFIG_BACKUP"
fi

mkdir -p "$CONFIG_DIR"
cat <<'EOF' > "$CONFIG_PATH"
{
  "theme": "solarized",
  "glyphs": "ascii"
}
EOF

# Solarized cyan is 42;161;152m and ASCII model glyph is [M]
run_test "Config file properly overrides defaults" "$payload_cold" "42;161;152m.*\[M\] 3.8 Flash Med" 0 "AGY_STATUSLINE_THEME= AGY_STATUSLINE_GLYPHS="

# Restore or clean up config file
if [ -n "$CONFIG_BACKUP" ]; then
    mv "$CONFIG_BACKUP" "$CONFIG_PATH"
else
    rm -f "$CONFIG_PATH"
fi

# 19. CLI argument: --version
out_ver=$("$STATUSLINE" --version)
if [[ "$out_ver" =~ agy-statusline\ 0\.1\.0 ]]; then
    echo -e "  ${green}PASS${reset} CLI flag --version returns version string"
    pass_count=$((pass_count + 1))
else
    echo -e "  ${red}FAIL${reset} CLI flag --version"
    fail_count=$((fail_count + 1))
fi

# 20. CLI argument: --help
out_help=$("$STATUSLINE" --help)
if [[ "$out_help" =~ USAGE: ]]; then
    echo -e "  ${green}PASS${reset} CLI flag --help returns usage info"
    pass_count=$((pass_count + 1))
else
    echo -e "  ${red}FAIL${reset} CLI flag --help"
    fail_count=$((fail_count + 1))
fi

echo -e "${dim}─────────────────────────────────────────────────${reset}"
if [ "$fail_count" -eq 0 ]; then
    echo -e "${green}All $pass_count tests passed successfully!${reset}"
    echo
    exit 0
else
    echo -e "${red}$fail_count of $((pass_count + fail_count)) tests failed.${reset}"
    echo
    exit 1
fi
