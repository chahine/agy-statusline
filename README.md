# agy-statusline

A fast, beautiful Powerline status line for Google DeepMind's **Antigravity CLI (`agy`)**.

Displays active model, live context token usage with progress bars, git branch status, and real-time session (5h) and weekly (7d) quota consumption with shaded visual sliders.

```
 Gemini 2.5 Pro  [████░░░░░░░░░░░░] 245k/1.0M (24.5%)  ⎇ main  Session: ▓▓▓░░░░░░░ 32.0%  Weekly: ▓▓░░░░░░░░ 15.0% 
```

---

## Features

- **Powerline Segmented Layout**: Segmented with Nerd Font solid arrows (``) and individual ANSI-256 color groups.
- **Model Display**: Shows active model name (`Gemini 2.5 Pro`, `Claude 3.7 Sonnet`, etc.).
- **Context Window Bar**: Visual bar (`█`/`░`) displaying token counts and percentage used (e.g. `[████░░░░░░░░░░░░] 245k/1.0M (24.5%)`).
- **Git Branch Integration**: Shows current git branch with `⎇` branch symbol, using agy's VCS payload or subshell git fallback.
- **Session (5h) Quota Slider**: 10-step shaded slider (`▓`/`░`) showing rolling 5-hour quota usage.
- **Weekly (7d) Quota Slider**: 10-step shaded slider showing weekly quota usage.
- **Smart Quota Pool Detection**: Automatically routes quota queries to `gemini` or `3p`/`claude` based on active model id.
- **Blazing Fast**: Single-pass `jq` extraction with zero subshells when payload VCS data is available.

---

## Visual Elements

| Segment | Icon / Format | Description |
|:---|:---|:---|
| **Model** | `Gemini 2.5 Pro` | Current active model in the session |
| **Context** | `[████░░░░░░░░░░░░] 245k/1.0M (24.5%)` | Context window fill bar + token usage |
| **Git** | `⎇ main` | Active git branch for current workspace |
| **Session** | `Session: ▓▓▓░░░░░░░ 32.0%` | 5-hour rolling rate limit / quota |
| **Weekly** | `Weekly: ▓▓░░░░░░░░ 15.0%` | 7-day rolling rate limit / quota |

---

## Requirements

1. **Antigravity CLI (`agy`)**: Installed and initialized (`~/.gemini/antigravity-cli`).
2. **`jq`**: JSON processor (`brew install jq` on macOS or `sudo apt install jq` on Linux).
3. **`git`**: For branch resolution.
4. **Nerd Font**: Terminal font with Powerline glyph support (e.g., JetBrainsMono Nerd Font, FiraCode Nerd Font, Meslo, etc.) to render the `` arrow separator.

---

## Installation

### One-line Install via Git

```bash
git clone https://github.com/chahine/agy-statusline.git
cd agy-statusline
bash bin/install.sh
```

The installer will:
1. Back up any existing `~/.gemini/statusline.sh` to `~/.gemini/statusline.sh.bak`.
2. Install the script to `~/.gemini/statusline.sh`.
3. Update `~/.gemini/antigravity-cli/settings.json` to register the status line command.

Restart your `agy` session or open a new terminal to see the status line in action!

---

## Manual Configuration

If you prefer to configure manually, copy `bin/statusline.sh` to `~/.gemini/statusline.sh`:

```bash
cp bin/statusline.sh ~/.gemini/statusline.sh
chmod +x ~/.gemini/statusline.sh
```

Then add or update the `statusLine` section in `~/.gemini/antigravity-cli/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.gemini/statusline.sh\"",
    "enabled": true
  }
}
```

---

## Uninstallation

To restore your previous setup:

```bash
cd agy-statusline
bash bin/uninstall.sh
```

This removes the `statusLine` entry from `settings.json` and restores `~/.gemini/statusline.sh.bak` if present.

---

## License

[MIT](LICENSE) © [Chahine Mouhamad](https://github.com/chahine)
