<p align="center">
  <img src="szPaner_logo.gif" alt="szPaner Logo" width="600"/>
</p>

# szPaner

**The lightweight tmux workspace manager you've been looking for.**

Pure bash. Zero dependencies. Works with tmux, not against it.

## Why szPaner?

**vs tmuxinator, tmuxp, and other workspace managers:**

| Feature | szPaner | tmuxinator | tmuxp |
|---------|---------|------------|-------|
| **Language** | Pure Bash | Ruby | Python |
| **Dependencies** | tmux only | Ruby + gems | Python + packages |
| **Installation** | TPM one-liner | gem install + config | pip install + config |
| **Integration** | Native tmux commands | External CLI | External CLI |
| **Save current layout** | ✅ Press Prefix+S | ❌ Manual editing | ❌ Manual editing |
| **Layout precision** | ✅ Layout strings | ❌ Approximate | ✅ YAML config |
| **Commands to learn** | 0 (just tmux) | tmuxinator CLI | tmuxp CLI |
| **Config format** | tmux-like | YAML | YAML |
| **Works inside tmux** | ✅ Prefix+Z | ❌ External only | ❌ External only |

**The szPaner advantage:**

- 🪶 **Lightweight** - No runtime dependencies beyond bash and tmux
- 🎯 **Native** - Uses tmux's own commands and keybindings
- ⚡ **Fast** - Bash parser, direct tmux calls, no overhead
- 💾 **Save layouts** - Capture your current window with Prefix+S
- 🎨 **Pixel-perfect** - Layout strings recreate exact pane sizes
- 🔌 **TPM ready** - One line in .tmux.conf, that's it
- 🧠 **Familiar** - tmux-like config syntax, not YAML/JSON

## Quick Start

### 1. Install via TPM

Add to `~/.tmux.conf`:
```tmux
set -g @plugin 'benito47/szpaner'
```

Press `Prefix + I` to install.

**Done!** Config auto-created at `~/.config/szpaner/zones.conf`

### 2. Create your first zone

```
Prefix+Z
```
Type: `dev` (spawns example dev zone)

### 3. Save your current layout

Arrange panes however you want, then:
```
Prefix+S
```
Type: `mywork`

**Boom.** Your layout is saved. Recreate it anytime with `Prefix+Z` → `mywork`

## Usage

### Inside tmux (main workflow)

```
Prefix+Z          - Spawn zone (prompts for name)
Prefix+S          - Save current window as zone
:sz <zone>        - Spawn zone via command
:sz               - List available zones
:sz-save          - Save zone via command
```

### Outside tmux (optional)

Run `install.sh` once for terminal integration:
```bash
~/.tmux/plugins/szpaner/install.sh
```

Then:
```bash
tmux dev          - Spawns 'dev' zone in new session
tmux mywork       - Spawns 'mywork' zone
```

## Example Workflow

**The magic of Prefix+S:**

1. Working on a project, you've got:
   - Left pane: nvim with 3 files open
   - Top right: `npm run dev`
   - Bottom right: `tail -f logs/app.log`
   - Panes perfectly sized after 10 minutes of tweaking

2. Press `Prefix+S`, name it "frontend"

3. Tomorrow: `Prefix+Z` → "frontend" → **instant recreation**

No YAML editing. No manual configuration. Just save and restore.

## Config Example

```
zone "dev" {
    layout "c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"

    pane "editor" {
        working_dir "~/projects/myapp"
        execute "nvim"
    }

    pane "server" {
        working_dir "~/projects/myapp"
        execute "npm run dev"
    }
}

zone "servers" {
    pane "prod" {
        execute "ssh prod.example.com"
        size 50%
    }

    pane "staging" {
        execute "ssh staging.example.com"
        split "right"
    }

    pane "logs" {
        execute "tail -f /var/log/app.log"
        split "down"
    }
}
```

**See [CONFIG.md](CONFIG.md) for complete configuration guide.**

## How It Works

### Layout Strings (The Secret Sauce)

When you press `Prefix+S`, szPaner captures tmux's layout string:
```
"c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"
```

This encodes:
- Exact pane positions
- Exact pane sizes
- Split directions
- Pane relationships

When spawning, tmux applies this layout instantly. **Pixel-perfect recreation.**

### Backward Compatible

No layout string? No problem. Falls back to manual splits:
```
zone "simple" {
    pane "left" {
        size 60%
    }

    pane "right" {
        split "right"
    }
}
```

Works like traditional workspace managers.

## Config Locations

szPaner looks for config in this order:
1. `~/.config/szpaner/zones.conf` (preferred)
2. `~/szpaner.conf` (alternative)

Example zones auto-created on first install.

## Features

✅ **Save current window** - Prefix+S captures layout, commands, dirs
✅ **Layout strings** - Pixel-perfect pane recreation
✅ **Auto-capture** - Working directories and running commands
✅ **Pure bash** - No Ruby, Python, or external dependencies
✅ **Native tmux** - Uses tmux commands you already know
✅ **TPM integration** - One-line install
✅ **Inside tmux** - Spawn zones without leaving tmux
✅ **Outside tmux** - Optional `tmux <zone>` wrapper
✅ **Multiple sessions** - Spawn same zone multiple times
✅ **Respects base-index** - Works with any tmux config
✅ **Zero overhead** - Fast bash parser, direct tmux calls

## Philosophy

**Other tools:**
- "Edit this YAML file with your layout"
- "Install Ruby/Python first"
- "Learn our CLI commands"
- "Exit tmux to spawn sessions"

**szPaner:**
- "Press Prefix+S to save what you have"
- "It's already installed (via TPM)"
- "Use tmux commands you know"
- "Work inside or outside tmux"

**Simplicity wins.**

## Requirements

- tmux 2.1+ (for layout strings)
- bash 4.0+
- That's it.

## Installation (detailed)

### Via TPM (recommended)

1. Add to `~/.tmux.conf`:
```tmux
set -g @plugin 'benito47/szpaner'
```

2. Install: `Prefix + I`

3. Inside-tmux commands work immediately

4. **Optional:** For `tmux <zone>` from terminal:
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

# Optional: terminal integration
~/.tmux/plugins/szpaner/install.sh
```

## Zone Naming

✅ **Valid:** `dev`, `my-project`, `work_env`, `servers123`
❌ **Invalid:** `new`, `attach`, `kill` (tmux keywords)

Use: letters, numbers, hyphens, underscores

## Advanced Usage

**Multiple execute commands:**
```
pane "setup" {
    execute "export API_KEY=secret"
    execute "cd backend"
    execute "npm run dev"
}
```

**Zone-level hooks:**
```
zone "myproject" {
    on_start "echo 'Welcome!'"
    on_detach "pkill -f 'npm run dev'"

    pane "server" { ... }
}
```

**Per-pane working directories:**
```
zone "fullstack" {
    working_dir "~/projects/myapp"

    pane "frontend" {
        working_dir "~/projects/myapp/frontend"
        execute "npm run dev"
    }

    pane "backend" {
        working_dir "~/projects/myapp/backend"
        execute "go run ."
    }
}
```

**See [CONFIG.md](CONFIG.md) for complete reference.**

## Comparison: Config Complexity

**tmuxinator (`~/.tmuxinator/dev.yml`):**
```yaml
name: dev
root: ~/projects/myapp
windows:
  - editor:
      layout: main-vertical
      panes:
        - nvim
        - npm run dev
        - tail -f logs/app.log
```

**szPaner (`~/.config/szpaner/zones.conf`):**
```
zone "dev" {
    working_dir "~/projects/myapp"

    pane "editor" { execute "nvim" }
    pane "server" { execute "npm run dev"; split "right" }
    pane "logs" { execute "tail -f logs/app.log"; split "down" }
}
```

**Or just press Prefix+S and don't write config at all.**

## Contributing

Found a bug? Want a feature? PRs welcome!

This is a **simple** tool. Let's keep it that way.

## License

MIT

## Credits

Created because tmuxinator felt too heavy and YAML felt too far from tmux.

Built with tmux's own philosophy: **do one thing well.**

---

**Stop editing YAML. Start saving layouts.**

`Prefix+S` → **done.**
