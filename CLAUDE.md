# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains a standardized Zellij configuration for all engineers in the organization. It provides a pre-configured terminal workspace with custom themes, plugins, and productivity enhancements.

## Installation

Copy all files to your Zellij config directory:

```bash
# Backup existing config (optional)
mv ~/.config/zellij ~/.config/zellij.backup

# Clone and install
git clone <repo-url> zellij_config
cp -r zellij_config/* ~/.config/zellij/
```

After installation, launch Zellij normally: `zellij`

## Configuration Overview

### File Structure

```text
config.kdl              # Main configuration with keybindings and plugins
layouts/default.kdl     # Default layout with custom status bar
themes/claude.kdl       # Claude light and dark themes
plugins/                # Pre-downloaded plugin binaries
  ├── zjstatus.wasm     # Custom status bar
  └── zellij-vertical-tabs.wasm
scripts/                # Status bar scripts
  ├── claude_tokens.sh  # Claude Code token usage
  ├── cpu.sh            # CPU monitoring
  └── ram.sh            # RAM monitoring
```

### Key Features

**Keybindings**: Vim-like navigation with modal editing

- `Ctrl+p` - Pane mode (navigate/create/close panes)
- `Ctrl+t` - Tab mode (manage tabs)
- `Ctrl+n` - Resize mode
- `Ctrl+h` - Move mode
- `Ctrl+s` - Scroll mode
- `Ctrl+o` - Session mode
- `Alt+l` - Launch lazygit in floating pane
- `Alt+g` - Git branch manager

**Plugins**:

- `zjstatus` - Custom status bar showing tokens, CPU, RAM, time
- `autolock` - Auto-locks when inside vim/neovim/git/fzf
- `zellij-forgot` - Searchable keybind reminder (`Alt+?`)
- `zellij-load` - System resource monitor
- `zj-git-branch` - Git branch switcher

**Theme**: `claude-dark` - Custom warm color scheme optimized for long coding sessions

**Status Bar**: Shows Claude Code token usage, CPU/RAM stats, and current time

### Scripts

Status bar scripts require:

- `bunx ccusage` for Claude token tracking (install: `bun install -g @anthropic-ai/ccusage`)
- macOS `vm_stat` for RAM monitoring
- Standard `ps` for CPU monitoring

Scripts update every 5 minutes (300s) with caching to minimize overhead.

## Customization

### Adjusting Script Paths

If deploying to non-macOS systems, update script paths in [layouts/default.kdl](layouts/default.kdl):

- Line 58: `command_claude_command`
- Line 64: `command_cpu_command`
- Line 70: `command_ram_command`

### Modifying Theme

Edit [themes/claude.kdl](themes/claude.kdl) to adjust colors. The theme uses warm earth tones optimized for readability.

### Plugin Configuration

Plugins auto-download from GitHub releases on first use. Plugin configurations are in [config.kdl](config.kdl) lines 275-309.

## Testing Changes

```bash
# Test with specific config
zellij --config /path/to/config.kdl

# Test with specific layout
zellij --layout /path/to/layouts/default.kdl

# Kill and restart current session
zellij kill-session <session-name>
```

## Troubleshooting

- **Scripts not working**: Ensure executable permissions (`chmod +x scripts/*.sh`)
- **Plugins not loading**: Check plugin URLs and network access
- **Theme not applied**: Verify `theme "claude-dark"` is set in config.kdl
