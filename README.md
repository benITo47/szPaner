# szPaner

**Spawn Zone Paner** - A tmux plugin for creating predefined pane layouts with ease.

## Concept

- **Zones**: Sets of predefined panes with custom commands
- **Spawn**: Create zones instantly with `tmux ConfName`
- **Features**: SSH connections, arbitrary scripts, custom layouts
- **TPM Compatible**: Works with Tmux Plugin Manager

## Installation

### Via TPM (Recommended)

1. Add to `~/.tmux.conf`:
```tmux
set -g @plugin 'benito47/szpaner'
```

2. Install with `Prefix + I`

3. **For `tmux zoneName` support**, add to your shell config (`~/.bashrc` or `~/.zshrc`):
```bash
export PATH="$PATH:~/.tmux/plugins/szpaner/bin"
```

That's it! Reload your shell and you're ready.

### Manual Installation

```bash
git clone https://github.com/benito47/szpaner.git ~/.tmux/plugins/szpaner

# Add to ~/.tmux.conf
run-shell ~/.tmux/plugins/szpaner/szpaner.tmux

# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:~/.tmux/plugins/szpaner/bin"
```

## Usage

### From Outside tmux
```bash
tmux dev          # Spawn 'dev' zone
tmux servers      # Spawn 'servers' zone
```

### From Inside tmux
```
:sz dev           # Spawn 'dev' zone in current session
:sz               # List available zones
```

### Create Your First Config

```bash
mkdir -p ~/.szpaner
cat > ~/.szpaner/zones.conf << 'EOF'
zone "dev" {
    pane "editor" {
        command "nvim"
        size 60%
    }

    pane "server" {
        command "npm run dev"
        split "right"
    }

    pane "logs" {
        command "tail -f logs/app.log"
        split "down"
    }
}
EOF
```

Then: `sz dev`

## What Works Now

- ✅ Custom config format (tmux-style, zero dependencies)
- ✅ Multiple zone definitions in one file
- ✅ Dynamic pane creation with splits
- ✅ Command execution (any command, including SSH)
- ✅ Simple `sz` command interface
- ✅ Respects tmux base-index settings
- ✅ Config file discovery (~/.szpaner/zones.conf)

## Config File Locations

szPaner looks for config in this order:
1. `~/.szpaner/zones.conf`
2. `~/.config/szpaner/zones.conf`
3. `./zones.conf`
4. `./examples/dev.conf`

## Zone Naming Rules

- ✅ Use: letters, numbers, hyphens, underscores
- ❌ Avoid: tmux keywords (`new`, `attach`, `kill`, `ls`, `split`, etc.)
- Examples: `dev`, `servers`, `my-project`, `work_env`

The parser will reject zone names that conflict with tmux commands.

## Next Steps

- [ ] Better split/layout logic
- [ ] Working directory per pane
- [ ] Full TPM integration
- [ ] Layout presets (main-vertical, tiled, etc.)
