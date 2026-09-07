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
- **Smart Installer**: Auto-detects existing Nerd Fonts, offers automated one-click font installation (via Homebrew or direct archive download), and guides terminal configuration.
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
4. **Nerd Font**: Terminal font with Powerline glyph support (e.g., JetBrainsMono Nerd Font, Meslo, FiraCode, etc.) to render the `` arrow separator. The installer will offer to install this for you if missing.

---

## Installation

### One-line Automated Install

```bash
git clone https://github.com/chahine/agy-statusline.git
cd agy-statusline
bash bin/install.sh
```

The installer will:
1. Check dependencies (`jq`, `git`, and `agy`).
2. Auto-detect installed Nerd Fonts or offer to install **JetBrainsMono Nerd Font** (via Homebrew or direct archive download).
3. Back up any existing `~/.gemini/statusline.sh` to `~/.gemini/statusline.sh.bak`.
4. Install `statusline.sh` to `~/.gemini/statusline.sh`.
5. Register the status line command in `~/.gemini/antigravity-cli/settings.json`.
6. Provide specific instructions for configuring your terminal emulator font.

---

## Terminal Font Configuration

To render the Powerline arrows (``) and git branch symbols (`⎇`) crisply, ensure your terminal is set to use a Nerd Font:

- **macOS Terminal.app**: `Settings (⌘,)` → `Profiles` → `Font` → `Change...` → Select `JetBrainsMono Nerd Font`
- **iTerm2**: `Settings (⌘,)` → `Profiles` → `Text` → `Font` → Select `JetBrainsMono Nerd Font` (or enable Non-ASCII font)
- **VS Code / Cursor / Antigravity Terminal**: `Settings (⌘,)` → search `terminal.integrated.fontFamily` → set to `'JetBrainsMono Nerd Font'`
- **Ghostty**: Add `font-family = "JetBrainsMono Nerd Font"` to `~/.config/ghostty/config`
- **Alacritty**: In `~/.config/alacritty/alacritty.toml`, set `[font.normal] family = "JetBrainsMono Nerd Font"`
- **Kitty**: In `~/.config/kitty/kitty.conf`, set `font_family JetBrainsMono Nerd Font`

---

## Uninstallation

To remove the status line and restore your previous configuration:

```bash
cd agy-statusline
bash bin/uninstall.sh
```

---

## License

[MIT](LICENSE) © [Chahine Mouhamad](https://github.com/chahine)
