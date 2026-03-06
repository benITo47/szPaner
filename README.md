<p align="center">
  <img src="szPaner_logo.gif" alt="szPaner Logo" width="600"/>
</p>

# szPaner

**Lightweight tmux workspace manager. Pure bash. Zero dependencies.**

Press `Prefix+S` to save your current layout. Press `Prefix+Z` to restore it. Done.

## Why szPaner?

**Standing on the shoulders of giants.**

Tools like [tmuxinator](https://github.com/tmuxinator/tmuxinator) and [tmuxp](https://github.com/tmux-python/tmuxp) are excellent, mature workspace managers. They've proven the value of tmux session management.

szPaner takes a different approach:

- 🪶 **Pure bash** - No Ruby, Python, or external dependencies
- 💾 **Save layouts** - Capture current window with `Prefix+S`
- 🎯 **Native tmux** - Uses tmux commands, not external CLI
- 🔌 **TPM ready** - One line in `.tmux.conf`

**If you want:** mature, feature-rich → use tmuxinator/tmuxp
**If you want:** lightweight, tmux-native → try szPaner

## Quick Start

**Install via TPM:**

Add to `~/.tmux.conf`:
```tmux
set -g @plugin 'benito47/szpaner'
```

Press `Prefix + I` to install. Done.

**Usage:**
```
Prefix+S          Save current window as zone
Prefix+Z          Spawn zone (prompts for name)
:sz <zone>        Spawn zone via command
:sz               List available zones
```

**Example workflow:**

1. Arrange panes how you want (nvim left, server top-right, logs bottom-right)
2. `Prefix+S` → name it "dev"
3. Tomorrow: `Prefix+Z` → "dev" → instant recreation

## Config

Edit `~/.config/szpaner/zones.conf`:

```
# Saved layout (from Prefix+S)
zone "dev" {
    layout "c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"

    pane "editor" {
        working_dir "~/projects/myapp"
        execute "nvim"
    }

    pane "server" {
        execute "npm run dev"
    }
}

# Manual layout
zone "simple" {
    pane "left" {
        execute "nvim"
        size 60%
    }

    pane "right" {
        execute "htop"
        split "right"
    }
}

# With hooks
zone "docker" {
    on_start "docker-compose up -d"
    on_detach "docker-compose down"

    pane "logs" {
        execute "docker-compose logs -f"
    }
}
```

**See [CONFIG.md](CONFIG.md) for complete reference.**

## How It Works

**Layout strings** (from `Prefix+S`):
- Captures exact pane positions and sizes
- Pixel-perfect recreation
- Fast spawning

**Manual splits** (with `split` and `size`):
- Flexible, adapts to terminal size
- Good for simple 2-pane layouts

Choose what fits your workflow.

## Installation

### Via TPM (recommended)

```tmux
# In ~/.tmux.conf
set -g @plugin 'benito47/szpaner'
```

Press `Prefix + I`. Config auto-created at `~/.config/szpaner/zones.conf`.

**Optional:** For `tmux <zone>` from terminal:
```bash
~/.tmux/plugins/szpaner/install.sh
```

### Manual

```bash
git clone https://github.com/benito47/szpaner.git ~/.tmux/plugins/szpaner

# Add to ~/.tmux.conf
run-shell ~/.tmux/plugins/szpaner/szpaner.tmux

# Reload
tmux source-file ~/.tmux.conf
```

## Config Locations

1. `~/.config/szpaner/zones.conf` (preferred)
2. `~/szpaner.conf` (alternative)

## Requirements

- tmux 2.1+
- bash 4.0+

## Zone Naming

✅ Valid: `dev`, `my-project`, `work_env`
❌ Invalid: `new`, `attach`, `kill` (tmux keywords)

Use: letters, numbers, hyphens, underscores

## Contributing

PRs welcome. Keep it simple.

## License

MIT

---

**Stop editing YAML. Start saving layouts.**

`Prefix+S` → **done.**
