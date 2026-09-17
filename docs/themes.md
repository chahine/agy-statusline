# Theme & Styling Gallery

`agy-statusline` offers extensive visual customization, including 5 handcrafted 24-bit Truecolor palettes, 6 separator styles, 4 font glyph modes, and flexible time formats.

---

## 1. Color Themes

Configure your active theme via `~/.config/agy-statusline/config.json` or by setting the `AGY_STATUSLINE_THEME` environment variable.

### Tokyo Night (`tokyo-night`) — Default
High-contrast vibrant dark theme optimized for modern dark terminal emulators.

| Element | ANSI Color | Hex Preview |
|:---|:---|:---|
| **Model** | `\033[1;38;2;0;229;255m` | `#00e5ff` (Electric Cyan) |
| **Tier** | `\033[1;38;2;255;214;0m` | `#ffd600` (Luminous Gold) |
| **Directory** | `\033[1;38;2;255;133;0m` | `#ff8500` (Vivid Tangerine) |
| **Git Branch** | `\033[1;38;2;217;70;239m` | `#d946ef` (Electric Orchid) |
| **Separators** | `\033[38;2;110;120;145m` | `#6e7891` (Muted Slate) |
| **Track** | `\033[38;2;50;60;75m` | `#323c4b` (Dark Slate) |
| **Agent Norm** | `\033[1;38;2;0;230;118m` | `#00e676` (Bright Neon Green) |
| **Agent Run** | `\033[1;38;2;255;61;0m` | `#ff3d00` (Hot Red-Orange) |

```text
 3.8 Flash Med |  Pro │  agy-statusline │  main* │ ● Idle
󰍛 Context ██░░░░░░░░ 20% │  Usage █████░░░░░ 50% ( 1h 24m) |  ███░░░░░░░ 30% ( 3d 12h)
```

---

### Catppuccin Mocha (`catppuccin`)
Soft, eye-pleasing pastel color palette inspired by Catppuccin Mocha.

| Element | ANSI Color | Hex Preview |
|:---|:---|:---|
| **Model** | `\033[1;38;2;137;180;250m` | `#89b4fa` (Blue) |
| **Tier** | `\033[1;38;2;249;226;175m` | `#f9e2af` (Yellow) |
| **Directory** | `\033[1;38;2;250;179;135m` | `#fab387` (Peach) |
| **Git Branch** | `\033[1;38;2;203;166;247m` | `#cba6f7` (Mauve) |
| **Separators** | `\033[38;2;108;112;134m` | `#6c7086` (Overlay0) |
| **Track** | `\033[38;2;69;71;90m` | `#45475a` (Surface1) |
| **Agent Norm** | `\033[1;38;2;166;227;161m` | `#a6e3a1` (Green) |
| **Agent Run** | `\033[1;38;2;243;139;168m` | `#f38ba8` (Red) |

```text
 3.8 Flash Med |  Pro │  agy-statusline │  main* │ ● Idle
󰍛 Context ██░░░░░░░░ 20% │  Usage █████░░░░░ 50% ( 1h 24m) |  ███░░░░░░░ 30% ( 3d 12h)
```

---

### Nord (`nord`)
Arctic, cold-bluish palette based on Nord colors.

| Element | ANSI Color | Hex Preview |
|:---|:---|:---|
| **Model** | `\033[1;38;2;136;192;208m` | `#88c0d0` (Frost Cyan) |
| **Tier** | `\033[1;38;2;235;203;139m` | `#ebcb8b` (Aurora Yellow) |
| **Directory** | `\033[1;38;2;208;135;112m` | `#d08770` (Aurora Orange) |
| **Git Branch** | `\033[1;38;2;180;142;173m` | `#b48ead` (Aurora Purple) |
| **Separators** | `\033[38;2;76;86;106m` | `#4c566a` (Polar Night 3) |
| **Track** | `\033[38;2;59;66;82m` | `#3b4252` (Polar Night 1) |
| **Agent Norm** | `\033[1;38;2;163;190;140m` | `#a3be8c` (Aurora Green) |
| **Agent Run** | `\033[1;38;2;191;97;106m` | `#bf616a` (Aurora Red) |

```text
 3.8 Flash Med |  Pro │  agy-statusline │  main* │ ● Idle
󰍛 Context ██░░░░░░░░ 20% │  Usage █████░░░░░ 50% ( 1h 24m) |  ███░░░░░░░ 30% ( 3d 12h)
```

---

### Solarized Dark (`solarized`)
Precision palette engineered by Ethan Schoonover.

| Element | ANSI Color | Hex Preview |
|:---|:---|:---|
| **Model** | `\033[1;38;2;42;161;152m` | `#2aa198` (Cyan) |
| **Tier** | `\033[1;38;2;181;137;0m` | `#b58900` (Yellow) |
| **Directory** | `\033[1;38;2;203;75;22m` | `#cb4b16` (Orange) |
| **Git Branch** | `\033[1;38;2;211;54;130m` | `#d33682` (Magenta) |
| **Separators** | `\033[38;2;88;110;117m` | `#586e75` (Base01) |
| **Track** | `\033[38;2;7;54;66m` | `#073642` (Base02) |
| **Agent Norm** | `\033[1;38;2;133;153;0m` | `#859900` (Green) |
| **Agent Run** | `\033[1;38;2;220;50;47m` | `#dc322f` (Red) |

```text
 3.8 Flash Med |  Pro │  agy-statusline │  main* │ ● Idle
󰍛 Context ██░░░░░░░░ 20% │  Usage █████░░░░░ 50% ( 1h 24m) |  ███░░░░░░░ 30% ( 3d 12h)
```

---

### Light (`light`)
Crisp high-contrast daylight theme for light terminal backgrounds.

| Element | ANSI Color | Description |
|:---|:---|:---|
| **Model** | `\033[1;38;2;0;115;150m` | Deep Teal |
| **Tier** | `\033[1;38;2;175;95;0m` | Dark Amber |
| **Directory** | `\033[1;38;2;190;60;0m` | Brick Orange |
| **Git Branch** | `\033[1;38;2;125;35;180m` | Plum Purple |
| **Separators** | `\033[38;2;140;150;165m` | Slate Gray |
| **Track** | `\033[38;2;210;215;225m` | Light Gray Track |
| **Agent Norm** | `\033[1;38;2;0;135;60m` | Forest Green |
| **Agent Run** | `\033[1;38;2;200;25;25m` | Crimson |

```text
 3.8 Flash Med |  Pro │  agy-statusline │  main* │ ● Idle
󰍛 Context ██░░░░░░░░ 20% │  Usage █████░░░░░ 50% ( 1h 24m) |  ███░░░░░░░ 30% ( 3d 12h)
```

---

## 2. Separator Styles

Configure via `"separator"` in `config.json` or `AGY_STATUSLINE_SEPARATOR`:

| Style | Main Separator | Sub Separator | Preview Example |
|:---|:---:|:---:|:---|
| `bar` *(default)* | ` │ ` | ` \| ` | `3.8 Flash Med \| Pro │ agy-statusline │ main │ ● Idle` |
| `pipe` | ` \| ` | ` \| ` | `3.8 Flash Med \| Pro \| agy-statusline \| main \| ● Idle` |
| `slant` | `  ` | `  ` | `3.8 Flash Med  Pro  agy-statusline  main  ● Idle` |
| `bubble` | `  ` | `  ` | `3.8 Flash Med  Pro  agy-statusline  main  ● Idle` |
| `slash` | ` / ` | ` / ` | `3.8 Flash Med / Pro / agy-statusline / main / ● Idle` |
| `minimal` | `  ` | `  ` | `3.8 Flash Med  Pro  agy-statusline  main  ● Idle` |

---

## 3. Glyph Modes

Configure via `"glyphs"` in `config.json` or `AGY_STATUSLINE_GLYPHS`:

| Mode | Model | Plan | Dir | Git | Context | Usage | Clock |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `nerd` *(default)* | ` ` | ` ` | ` ` | ` ` | `󰍛 ` | ` ` | ` ` |
| `unicode` | `⚡ ` | `✦ ` | `📁 ` | `⎇ ` | `🧠 ` | `⚡ ` | `🕒 ` |
| `ascii` | `[M] ` | `[P] ` | `[D] ` | `[B] ` | `[C] ` | `[U] ` | `[T] ` |
| `none` | *(none)* | *(none)* | *(none)* | *(none)* | *(none)* | *(none)* | *(none)* |

---

## 4. Time Formats

Configure countdown timer rendering via `"time_format"` in `config.json` or `AGY_STATUSLINE_TIME_FORMAT`:

- **`relative` (default)**: Shows countdown duration remaining (`4h 55m`, `2d 18h`).
- **`absolute`**: Shows target clock time when quota bucket unlocks (`17:25`).
- **`both`**: Shows both relative duration and target time (`4h 55m · 17:25`).

---

## 5. Critical Context Alert ($\ge 95\%$)

When context window usage reaches $95\%$ or higher, the percentage indicator dynamically switches to high-visibility inverted coral red to alert against context window truncation:

```text
󰍛 Context ██████████  96%! 
```

---

## 6. Complete `config.json` Reference

Location: `~/.config/agy-statusline/config.json`

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
