# agy-statusline

<p align="center">
  <a href="https://github.com/chahine/agy-statusline/releases"><img src="https://img.shields.io/badge/version-0.1.0-blue.svg" alt="Version 0.1.0"></a>
  <a href="https://brew.sh"><img src="https://img.shields.io/badge/brew-agy--statusline-orange.svg" alt="Homebrew"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License MIT"></a>
  <img src="https://img.shields.io/badge/bash-3.2%2B-lightgrey.svg" alt="Bash 3.2+">
</p>

A fast, lightweight, and beautiful 2-line status line for Google DeepMind's **Antigravity CLI (`agy`)**.

Displays active model and subscription tier, current workspace directory, active git branch, agent execution lifecycle state, real-time context window usage, and rolling 5-hour and weekly quota gauges with countdown reset timers.

<p align="center">
  <img src="docs/preview.svg" alt="agy-statusline preview" width="100%">
</p>

---

## Installation

### Option 1: Homebrew (Recommended for macOS & Linux)

```bash
brew tap chahine/agy-statusline https://github.com/chahine/agy-statusline.git
brew install agy-statusline
agy-statusline-setup
```

*(Or in a single step: `brew install chahine/agy-statusline/agy-statusline && agy-statusline-setup`)*

### Option 2: 1-Line Remote Install (curl)

```bash
# Interactive setup wizard
curl -fsSL https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/install.sh | bash

# Headless / unattended setup (accepts all defaults)
curl -fsSL https://raw.githubusercontent.com/chahine/agy-statusline/main/bin/install.sh | bash -s -- -y
```

### Option 3: Manual Clone

```bash
git clone https://github.com/chahine/agy-statusline.git
cd agy-statusline
bash bin/install.sh
```

---

## Features

- **Clean 2-Line HUD**: Separates workspace and VCS identity (Line 1) from live telemetry and rate limits (Line 2).
- **Sub-35ms Single-Pass Performance**: 100% pure Bash parameter expansions and single-pass `jq` execution for 20-25ms rendering without terminal flicker.
- **Git Working Tree Dirty Detection**: Automatically detects uncommitted and staged modifications in current repo and appends a dirty indicator (`*`).
- **Model & Plan Intelligence**: Parses and formats official and 3rd-party models (`3.8 Flash Med`, `Sonnet 3.7`, `Pro`, `Free`) with custom alias mapping.
- **Dynamic Agent Lifecycle**: Color-coded live agent state indicator (`● Idle`, `● Thinking`, `● Running`).
- **Dynamic Context Window Bar & Alert Highlight**: 10-step progress bar (`█`/`░`) colored dynamically by consumption percentage, with inverted coral red alert on critical usage ($\ge 95\%$).
- **Dual Rolling Quota Monitors**: Real-time 5-hour rolling session quota and 7-day weekly quota gauges with countdown reset timers (`4h 51m`, `3d 13h`).
- **Flexible Time Formats**: Support for `relative` countdown durations, `absolute` clock times (`17:25`), or `both` (`4h 51m · 17:25`).
- **6 Configurable Separators**: `bar` (`│`), `pipe` (`|`), `slant` (``), `bubble` (``), `slash` (`/`), and `minimal` spaces.
- **Responsive Width Adaptation**: Automatically compacts labels, narrows progress bars, truncates long branches, and drops weekly quota on narrow terminals (<95, <80, <75, <68 cols) to prevent ugly line wraps.
- **5 Handcrafted Truecolor Themes**: `tokyo-night` (default), `catppuccin`, `nord`, `solarized`, and `light`.
- **4 Font Glyph Modes**: Support for `nerd` icons, standard universal `unicode` emojis, plain text `ascii` brackets, or clean text `none`.
- **Interactive Setup Wizard & Shell Completions**: Terminal configuration wizard, unattended mode (`-y`), Bash and Zsh tab-completions, and a 28-test automated regression suite with execution latency verification.

---

## Visual Layout

### Line 1 — Workspace & Session
| Element | Color (Tokyo Night) | Nerd Font Glyph | Unicode Fallback | Description |
|:---|:---|:---:|:---:|:---|
| **Model** | Electric Cyan (`#00e5ff`) | `` (`U+F490`) | `⚡` | Active model identifier (e.g. `3.8 Flash Med`) |
| **Plan Tier** | Luminous Gold (`#ffd600`) | `` (`U+F521`) | `✦` | Current subscription tier (`Pro` / `Free`) |
| **Workspace** | Vivid Tangerine (`#ff8500`) | `` (`U+F07C`) | `📁` | Current working directory basename |
| **Git Branch** | Electric Orchid (`#d946ef`) | `` (`U+F418`) | `⎇` | Active VCS branch |
| **Agent State** | Dynamic ANSI Color | `●` | `●` | Live state (`● Idle`, `● Thinking`, `● Running`) |

### Line 2 — Context & Telemetry
| Element | Color (Tokyo Night) | Nerd Font Glyph | Unicode Fallback | Description |
|:---|:---|:---:|:---:|:---|
| **Context** | Dynamic Gauge | `󰍛` (`U+DB80+U+DF5B`) | `🧠` | Context window fill bar and percentage |
| **5-Hour Quota** | Dynamic Gauge | `` (`U+F0E7`) | `⚡` | 5-hour rolling rate limit usage & reset countdown |
| **Weekly Quota** | Dynamic Gauge | — | — | 7-day rate limit usage & reset countdown |
| **Reset Timer** | Crisp Slate (`#a0afc3`) | `` (`U+F43A`) | `⏱` | Estimated countdown duration until quota bucket resets |

---

## Examples

### 1. Typical Session States

#### Standard Session (Idle)
```text
 3.8 Flash Med |  Pro │  agy-statusline │  main │ ● Idle
󰍛 Context █░░░░░░░░░ 11% │  Usage ██████████ 96% ( 4h 51m) |  ██████░░░░ 57% ( 3d 13h)
```

#### Active Command Execution (Running)
```text
 3.1 Pro |  Pro │  agy-statusline │  feature/hud │ ● Running
󰍛 Context ████████░░ 82% │  Usage █████████░ 88% ( 1h 22m) |  ████░░░░░░ 42% ( 5d 08h)
```

#### Deep Reasoning State (Thinking)
```text
 Sonnet 3.7 |  Pro │  agy-statusline │  develop │ ● Thinking
󰍛 Context ░░░░░░░░░░ 3% │  Usage ██░░░░░░░░ 24% ( 3h 10m) |  █░░░░░░░░░ 12% ( 6d 19h)
```

#### High Load / Near Quota Warning
When context or quota exceeds 90%, progress bars dynamically change to warning coral red:
```text
 3.8 Flash High |  Pro │  agy-statusline │  hotfix │ ● Running
󰍛 Context █████████░ 94% │  Usage ██████████ 99% ( 12m) |  █████████░ 91% ( 18h)
```

---

## Themes & Glyphs

For full ANSI color tables and visual mockups of every theme, see the **[Theme & Styling Gallery](docs/themes.md)**.

### Color Themes

`agy-statusline` includes 5 handcrafted truecolor (24-bit ANSI) themes:

| Theme | Accent Colors | Best Suited For |
|:---|:---|:---|
| `tokyo-night` *(default)* | Electric Cyan, Luminous Gold, Vivid Tangerine, Orchid | Modern dark terminals with high saturation |
| `catppuccin` | Pastel Blue, Yellow, Peach, Mauve, Green | Soft, eye-pleasing pastel color schemes |
| `nord` | Frost Cyan, Snow White, Polar Night, Aurora Green | Arctic and cold-tinted terminal themes |
| `solarized` | Solarized Cyan, Yellow, Orange, Base2 | Classic Ethan Schoonover dark solarized setups |
| `light` | Deep Teal, Amber, Brick Orange, Plum Purple | Light-background terminal profiles |

### Glyph Modes

Configure glyph rendering to match your terminal font environment:

| Mode | Example Output | Best Suited For |
|:---|:---|:---|
| `nerd` *(default)* | ` 3.8 Flash Med \|  Pro │  project │  main* │ ● Idle` | Terminals with JetBrainsMono or any Nerd Font |
| `unicode` | `⚡ 3.8 Flash Med \| ✦ Pro │ 📁 project │ ⎇ main* │ ● Idle` | Universal Unicode emojis and symbols |
| `ascii` | `[M] 3.8 Flash Med \| [P] Pro │ [D] project │ [B] main* │ * Idle` | TTYs, SSH sessions, and plain-text purists |
| `none` | `3.8 Flash Med \| Pro │ project │ main* │ ● Idle` | Clean minimalist display without icons or prefixes |

### Separator Styles

Customize segment dividers via `"separator"` in `config.json` or `AGY_STATUSLINE_SEPARATOR`:
- `bar` *(default)*: ` │ ` (sub-separator ` | `)
- `pipe`: ` | `
- `slant`: `  `
- `bubble`: `  `
- `slash`: ` / `
- `minimal`: `  ` (spaces only)

### Time Formats

Customize reset countdown display via `"time_format"` in `config.json` or `AGY_STATUSLINE_TIME_FORMAT`:
- `relative` *(default)*: `( 4h 55m)`
- `absolute`: `( 17:25)`
- `both`: `( 4h 55m · 17:25)`

---

## Configuration

You can configure your preferences permanently via `~/.config/agy-statusline/config.json`:

```json
{
  "theme": "tokyo-night",
  "glyphs": "nerd",
  "separator": "bar",
  "time_format": "relative",
  "show_git_dirty": true,
  "model_aliases": {
    "gemini-3.8-flash-med": "3.8 Flash Med",
    "gemini-3.1-pro": "3.1 Pro",
    "claude-3-7-sonnet": "Sonnet 3.7"
  }
}
```

Or override them dynamically via environment variables in your shell profile (`~/.bashrc`, `~/.zshrc`):

```bash
export AGY_STATUSLINE_THEME="catppuccin"        # tokyo-night, catppuccin, nord, solarized, light
export AGY_STATUSLINE_GLYPHS="unicode"         # nerd, unicode, ascii, none
export AGY_STATUSLINE_SEPARATOR="slash"        # bar, pipe, slant, bubble, slash, minimal
export AGY_STATUSLINE_TIME_FORMAT="both"       # relative, absolute, both
export AGY_STATUSLINE_GIT_DIRTY="1"            # 1 to show *, 0 to disable
```

---

## Responsive Width Adaptation

`agy-statusline` automatically detects your terminal width (from `agy` telemetry or `tput cols`) and dynamically scales:

- **Full Width (≥95 cols)**: Full names, 10-block progress bars (`██████████`), full labels (`Context`, `Usage`), and both 5-hour and weekly quotas.
- **Narrow (<95 cols)**: Long directory names and Git branch names are automatically truncated with middle ellipsis (e.g. `feat…name`).
- **Compact (<80 cols)**: Progress bars compact from 10 blocks to 5 blocks (`█████`).
- **Ultra-Compact (<75 cols)**: Labels abbreviate to `Ctx` and `Use`.
- **Minimal (<68 cols)**: Omits the weekly quota gauge entirely to guarantee no multi-line wrapping in split panes or narrow windows.

---

## CLI Usage

When installed via Homebrew or available in your `$PATH`:

```bash
# Render a live interactive preview using current terminal dimensions & branch
agy-statusline --preview

# Run the interactive configuration setup wizard
agy-statusline --setup
# Or run non-interactively with unattended defaults:
agy-statusline --setup -y

# Check for updates and upgrade to the latest release
agy-statusline --update

# Uninstall statusline configuration and restore previous backup
agy-statusline --uninstall

# Display help and available options
agy-statusline --help

# Check version
agy-statusline --version
```

*(Bash and Zsh shell completions are automatically installed with Homebrew or copied to `~/.config/agy-statusline/completions/`)*

---

## Terminal Font Setup

To render icons (`    󰍛  `) properly in default `nerd` mode, configure your terminal font to a [Nerd Font](https://www.nerdfonts.com/) (such as **JetBrainsMono Nerd Font**):

- **macOS Terminal.app**: Settings (⌘,) → Profiles → Font → Change... → Choose `JetBrainsMono Nerd Font`.
- **iTerm2**: Settings (⌘,) → Profiles → Text → Font → Choose `JetBrainsMono Nerd Font` (or enable *Use a different font for non-ASCII text*).
- **VS Code / Cursor / Antigravity Terminal**: Settings (⌘,) → search `terminal.integrated.fontFamily` → set to `'JetBrainsMono Nerd Font'`.
- **Ghostty**: In `~/.config/ghostty/config` add `font-family = "JetBrainsMono Nerd Font"`.
- **Alacritty**: In `~/.config/alacritty/alacritty.toml` add `[font.normal] family = "JetBrainsMono Nerd Font"`.
- **Kitty**: In `~/.config/kitty/kitty.conf` add `font_family JetBrainsMono Nerd Font`.

*(If you prefer not to install a custom font, simply set `AGY_STATUSLINE_GLYPHS=unicode` or `ascii`.)*

---

## Automated Testing

`agy-statusline` includes a 28-test regression suite covering cold starts, running/thinking states, warning thresholds, critical context highlight alerts, Claude/3P model pools, git dirty status, custom separators, time format modes, model aliases, responsive breakpoints, glyph engines, theme switching, CLI flags, and a sub-35ms performance benchmark.

Run the test suite locally:

```bash
bash tests/test_statusline.sh
```

---

## Uninstallation

### If installed via Homebrew:
```bash
agy-statusline-uninstall
brew uninstall agy-statusline
```

### If installed via script:
```bash
bash bin/uninstall.sh
```

---

## License

[MIT](LICENSE) © 2026 Mouhamad Chahine
