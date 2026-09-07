# agy-statusline

A fast, beautiful 2-line status line for Google DeepMind's **Antigravity CLI (`agy`)**.

Displays active model and tier, workspace directory, git branch, agent execution state, live context window usage, and rolling 5-hour and weekly quota gauges with reset durations.

```
 3.8 Flash Med |  Pro │  net-worth-tracker │  main │ ● Idle
󰍛 Context █░░░░░░░░░ 11% │  Usage ██████████ 96% ( 4h 51m) |  ██████░░░░ 57% ( 3d 13h)
```

---

## Features

- **2-Line HUD Layout**: Clean multi-line layout separating session identity from live telemetry and quotas.
- **Model & Plan Display**: Shortened model name (`3.8 Flash Med`, `Sonnet 3.7`, etc.) along with current plan tier (` Pro` / `Free`).
- **Workspace & Git**: Shows current repository folder (` <dir>`) and active branch (` <branch>`).
- **Agent Lifecycle State**: Color-coded live state (`● Idle`, `● Thinking`, `● Running`).
- **Context Window Bar**: 10-step progress bar (`█`/`░`) colored dynamically by consumption percentage.
- **Dual Quota Monitoring**: Real-time 5-hour rolling session quota and 7-day weekly quota gauges with live reset countdown timers (` 4h 51m`, ` 3d 13h`).
- **High Compatibility**: Integrates seamlessly with `agy-hud` or runs as a self-contained pure Bash + `jq` script.
- **Smart Installer**: Auto-detects installed Nerd Fonts, offers automated one-click font installation (via Homebrew or direct archive download), and guides terminal configuration.

---

## Visual Elements

### Line 1 — Workspace & Session
| Element | Icon / Format | Description |
|:---|:---|:---|
| **Model & Plan** | ` 3.8 Flash Med \|  Pro` | Active model identifier and subscription tier |
| **Workspace** | ` net-worth-tracker` | Current working directory basename |
| **Git Branch** | ` main` | Active VCS branch |
| **Agent State** | `● Idle` | Current agent state (Idle / Running / Thinking) |

### Line 2 — Context & Quotas
| Element | Icon / Format | Description |
|:---|:---|:---|
| **Context** | `󰍛 Context █░░░░░░░░░ 11%` | Context window fill bar and percentage |
| **Session Usage** | ` Usage ██████████ 96% ( 4h 51m)` | 5-hour rolling rate limit usage & reset timer |
| **Weekly Usage** | `██████░░░░ 57% ( 3d 13h)` | 7-day rate limit usage & reset timer |

---

## Requirements

1. **Antigravity CLI (`agy`)**: Installed and initialized (`~/.gemini/antigravity-cli`).
2. **`jq`**: JSON processor (`brew install jq` on macOS or `sudo apt install jq` on Linux).
3. **`git`**: For branch resolution.
4. **Nerd Font**: Terminal font with glyph support (e.g. JetBrainsMono Nerd Font, FiraCode, Meslo) to display icons properly. The installer can install this for you.

---

## Installation

### Automated Install

```bash
git clone https://github.com/chahine/agy-statusline.git
cd agy-statusline
bash bin/install.sh
```

The installer will:
1. Verify system dependencies (`jq`, `git`, and `agy`).
2. Auto-detect installed Nerd Fonts or offer to install **JetBrainsMono Nerd Font** automatically.
3. Install `statusline.sh` to `~/.gemini/statusline.sh`.
4. Configure `~/.gemini/antigravity-cli/settings.json` to enable `statusLine`.
5. Display a live preview of the 2-line HUD.

---

## Uninstall

To remove the statusline configuration:

```bash
bash bin/uninstall.sh
```

---

## License

MIT
