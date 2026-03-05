# Configuration Guide

Complete reference for szPaner zone configuration.

## Table of Contents

- [Config File Location](#config-file-location)
- [Basic Syntax](#basic-syntax)
- [Zone Properties](#zone-properties)
- [Pane Properties](#pane-properties)
- [Layout Strings](#layout-strings)
- [Complete Examples](#complete-examples)
- [Best Practices](#best-practices)

## Config File Location

szPaner looks for config in this order:
1. `~/.config/szpaner/zones.conf` (preferred)
2. `~/szpaner.conf` (alternative)

On first TPM install, `~/.config/szpaner/zones.conf` is auto-created with examples.

## Basic Syntax

```
zone "zone-name" {
    # Zone-level properties
    property "value"

    pane "pane-name" {
        # Pane-level properties
        property "value"
    }
}
```

**Rules:**
- Zone and pane names must be quoted
- Use curly braces `{}` for blocks
- Comments start with `#`
- Properties can use quotes or not: `property "value"` or `property value`

## Zone Properties

### `working_dir`

Default working directory for all panes in this zone.

```
zone "myproject" {
    working_dir "/Users/you/projects/myapp"

    pane "editor" {
        execute "nvim"
    }
    # Opens nvim in /Users/you/projects/myapp
}
```

**Notes:**
- Pane-level `working_dir` overrides zone-level
- Use absolute paths
- Tilde `~` expansion works

### `layout`

Tmux layout string for pixel-perfect pane recreation.

```
zone "saved-layout" {
    layout "c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"

    pane "pane0" { execute "echo left" }
    pane "pane1" { execute "echo right" }
}
```

**How to get layout strings:**
1. Arrange panes manually in tmux
2. Press `Prefix+S` to save (auto-captures layout)
3. Or manually: `tmux list-windows -F "#{window_layout}"`

**When present:**
- Layout string takes precedence over manual `split` and `size`
- Panes created instantly, layout applied exactly
- **Fastest and most accurate method**

**When absent:**
- Falls back to manual split creation (see `split` and `size`)

### `on_start`

Command to run after zone is created.

```
zone "dev" {
    on_start "echo 'Development zone started'"

    pane "editor" { execute "nvim" }
}
```

**Notes:**
- Runs in the first pane
- Executes after all panes are created and commands sent
- Good for initialization scripts

### `on_detach`

Command to run when client detaches from this window.

```
zone "servers" {
    on_detach "pkill -f 'npm run dev'"

    pane "server" { execute "npm run dev" }
}
```

**Notes:**
- Uses tmux hooks (`client-detached`)
- Good for cleanup tasks
- Only runs when detaching, not when killing window

## Pane Properties

### `execute`

Command to run in this pane.

**Single command:**
```
pane "editor" {
    execute "nvim"
}
```

**Multiple commands:**
```
pane "setup" {
    execute "export API_KEY=secret123"
    execute "cd backend"
    execute "npm run dev"
}
```

**Notes:**
- Commands run in order
- Each command is sent with Enter (C-m)
- Can use shell features: pipes, redirects, etc.
- For interactive programs (nvim, ssh), last command should be the program

**Examples:**
```
pane "ssh" {
    execute "ssh user@prod.example.com"
}

pane "logs" {
    execute "tail -f /var/log/app.log | grep ERROR"
}

pane "multi" {
    execute "source venv/bin/activate"
    execute "python manage.py runserver"
}
```

### `working_dir`

Working directory for this pane (overrides zone-level).

```
zone "fullstack" {
    working_dir "/Users/you/projects/myapp"

    pane "frontend" {
        working_dir "/Users/you/projects/myapp/frontend"
        execute "npm run dev"
    }

    pane "backend" {
        working_dir "/Users/you/projects/myapp/backend"
        execute "go run main.go"
    }
}
```

**Notes:**
- Pane-level overrides zone-level
- Each pane can have its own directory
- Paths are evaluated when pane is created

### `split`

Split direction for this pane (manual split mode only).

**Values:**
- `right` or `left` - Horizontal split (side-by-side)
- `down` or `bottom` - Vertical split (top-bottom)

**Default:** `right`

```
zone "three-panes" {
    pane "editor" {
        # First pane, no split needed
    }

    pane "terminal" {
        split "right"  # Splits to the right of editor
    }

    pane "logs" {
        split "down"  # Splits below terminal
    }
}
```

**Notes:**
- Only used when zone has NO `layout` property
- Ignored if layout string present
- Determines split direction, not target pane (splits from pane 0)

### `size`

Size of the pane as percentage (manual split mode only).

```
pane "editor" {
    size 60%  # Takes 60% of space
}

pane "terminal" {
    size 30%  # Takes 30% of remaining space
    split "right"
}
```

**Notes:**
- Only used when zone has NO `layout` property
- Can be written as `60%` or `60`
- Percentage is relative to the split being made
- Ignored if layout string present

### `split_from`

**(Future feature - parsed but not yet implemented)**

Target pane to split from.

```
pane "main" {
    # First pane
}

pane "sidebar" {
    split "right"
    split_from "main"
}

pane "bottom" {
    split "down"
    split_from "main"
}
```

## Layout Strings

### What Are They?

Tmux layout strings encode exact pane positions and sizes:
```
"c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"
```

**They contain:**
- Checksum (`c25d`)
- Window dimensions (`159x41`)
- Pane tree structure (`{...}`)
- Each pane's position and size

### How to Get Them

**Method 1: Save current window (recommended)**
```
Prefix+S
Enter zone name
```
Layout string automatically captured.

**Method 2: Manual extraction**
```bash
tmux list-windows -F "#{window_layout}"
```

**Method 3: Copy from tmux**
```
:display-message "#{window_layout}"
```

### When to Use

**Use layout strings when:**
- You want pixel-perfect recreation
- You've manually arranged panes
- You have complex layouts (3+ panes)
- You want fastest spawning

**Use manual splits when:**
- Simple 2-pane layouts
- You want flexible sizing (adapts to terminal size)
- You're writing config by hand

### Example Comparison

**With layout string (exact):**
```
zone "saved" {
    layout "c25d,159x41,0,0{79x41,0,0,0,79x41,80,0,1}"

    pane "pane0" { execute "nvim" }
    pane "pane1" { execute "htop" }
}
# Result: Exact 79x41 and 79x41 panes, always
```

**Without layout string (flexible):**
```
zone "manual" {
    pane "editor" {
        execute "nvim"
        size 50%
    }

    pane "monitor" {
        execute "htop"
        split "right"
    }
}
# Result: Adapts to current window size
```

## Complete Examples

### 1. Simple Development Zone

```
zone "dev" {
    pane "editor" {
        execute "nvim"
        size 60%
    }

    pane "server" {
        execute "npm run dev"
        split "right"
    }

    pane "logs" {
        execute "tail -f logs/app.log"
        split "down"
    }
}
```

**Result:** Editor (60% left), server (40% top-right), logs (bottom-right)

### 2. SSH Server Monitoring

```
zone "servers" {
    pane "prod" {
        execute "ssh admin@prod.example.com"
        size 50%
    }

    pane "staging" {
        execute "ssh admin@staging.example.com"
        split "right"
        size 50%
    }

    pane "local" {
        execute "htop"
        split "down"
    }
}
```

### 3. Full-Stack Development

```
zone "fullstack" {
    working_dir "/Users/you/projects/myapp"
    on_start "echo 'Starting fullstack environment...'"

    pane "editor" {
        execute "nvim"
        size 60%
    }

    pane "frontend" {
        working_dir "/Users/you/projects/myapp/frontend"
        execute "npm run dev"
        split "right"
    }

    pane "backend" {
        working_dir "/Users/you/projects/myapp/backend"
        execute "go run main.go"
        split "down"
    }

    pane "db" {
        execute "psql myapp_dev"
        split "down"
    }
}
```

### 4. Saved Layout (Prefix+S generated)

```
# Saved zone: mywork (2026-03-06)
zone "mywork" {
    layout "9e3a,255x64,0,0{127x64,0,0,0,127x64,128,0[127x32,128,0,1,127x31,128,33,2]}"

    pane "pane0" {
        working_dir "/Users/you/projects/current"
        execute "nvim src/main.rs"
    }

    pane "pane1" {
        working_dir "/Users/you/projects/current"
        execute "cargo watch -x run"
    }

    pane "pane2" {
        working_dir "/Users/you/projects/current"
        execute "git status"
    }
}
```

**Perfect recreation of saved state.**

### 5. Database Administration

```
zone "db-admin" {
    pane "prod-db" {
        execute "psql -h prod.db.example.com -U admin production"
        size 50%
    }

    pane "dev-db" {
        execute "psql -h localhost -U dev development"
        split "right"
    }

    pane "queries" {
        working_dir "/Users/you/sql-scripts"
        execute "nvim queries.sql"
        split "down"
    }
}
```

### 6. Docker Development

```
zone "docker-dev" {
    working_dir "/Users/you/projects/dockerapp"
    on_start "docker-compose up -d"
    on_detach "docker-compose down"

    pane "editor" {
        execute "nvim"
        size 60%
    }

    pane "logs" {
        execute "docker-compose logs -f"
        split "right"
    }

    pane "shell" {
        execute "docker-compose exec app bash"
        split "down"
    }
}
```

### 7. Multi-Service Monitoring

```
zone "monitoring" {
    pane "nginx" {
        execute "tail -f /var/log/nginx/access.log"
    }

    pane "app" {
        execute "tail -f /var/log/myapp/app.log"
        split "right"
    }

    pane "db" {
        execute "tail -f /var/log/postgresql/postgresql.log"
        split "down"
    }

    pane "system" {
        execute "htop"
        split "down"
    }
}
```

### 8. Python Data Science

```
zone "jupyter" {
    working_dir "/Users/you/notebooks"

    pane "jupyter" {
        execute "source venv/bin/activate"
        execute "jupyter lab"
        size 70%
    }

    pane "terminal" {
        execute "source venv/bin/activate"
        execute "ipython"
        split "right"
    }

    pane "files" {
        execute "ls -la"
        split "down"
    }
}
```

## Best Practices

### 1. Use Layout Strings for Complex Layouts

**Don't:**
```
zone "complex" {
    pane "one" { size 33% }
    pane "two" { split "right"; size 50% }
    pane "three" { split "down"; size 25% }
    pane "four" { split "right"; size 40% }
}
```

**Do:**
```
# Create manually, then: Prefix+S
zone "complex" {
    layout "abc123,..."
    pane "one" { execute "..." }
    pane "two" { execute "..." }
    pane "three" { execute "..." }
    pane "four" { execute "..." }
}
```

### 2. Use Zone-Level working_dir

**Don't:**
```
zone "myapp" {
    pane "one" {
        working_dir "/Users/you/projects/myapp"
        execute "nvim"
    }
    pane "two" {
        working_dir "/Users/you/projects/myapp"
        execute "npm run dev"
    }
}
```

**Do:**
```
zone "myapp" {
    working_dir "/Users/you/projects/myapp"

    pane "one" { execute "nvim" }
    pane "two" { execute "npm run dev" }
}
```

### 3. Name Zones Descriptively

**Don't:**
```
zone "a" { ... }
zone "temp" { ... }
zone "x1" { ... }
```

**Do:**
```
zone "frontend-dev" { ... }
zone "api-debug" { ... }
zone "db-admin" { ... }
```

### 4. Use Multiple Execute for Setup

**Don't:**
```
pane "app" {
    execute "source venv/bin/activate && cd backend && python manage.py runserver"
}
```

**Do:**
```
pane "app" {
    execute "source venv/bin/activate"
    execute "cd backend"
    execute "python manage.py runserver"
}
```

### 5. Comment Your Zones

```
# Frontend development - React + Vite
zone "frontend" {
    working_dir "~/projects/myapp/frontend"

    # Main editor pane
    pane "editor" {
        execute "nvim src/App.tsx"
    }

    # Dev server with HMR
    pane "vite" {
        execute "npm run dev"
        split "right"
    }
}
```

### 6. Use on_detach for Cleanup

**For background services:**
```
zone "backend" {
    on_detach "pkill -f 'python manage.py runserver'"

    pane "server" {
        execute "python manage.py runserver"
    }
}
```

**For docker:**
```
zone "containers" {
    on_start "docker-compose up -d"
    on_detach "docker-compose down"

    pane "logs" {
        execute "docker-compose logs -f"
    }
}
```

## Troubleshooting

### Zone Not Found

**Symptom:** "Zone 'xyz' not found"

**Solutions:**
- Check spelling: `sz` lists available zones
- Check config location: `~/.config/szpaner/zones.conf`
- Reload tmux: `tmux source-file ~/.tmux.conf`
- Check syntax: look for missing quotes or braces

### Commands Not Executing

**Symptom:** Pane opens but command doesn't run

**Solutions:**
- Check quotes: `execute "nvim"` not `execute nvim`
- Check PATH: command available in shell?
- For complex commands, use multiple `execute` lines
- Check working_dir is valid

### Layout Looks Wrong

**Symptom:** Panes sizes don't match saved layout

**Solutions:**
- Terminal size different? Layouts are pixel-based
- Layout string might be stale: save again with `Prefix+S`
- For flexible layouts, use manual splits instead of layout strings

### Duplicate Zone Name

**Symptom:** "Zone already exists"

**Solutions:**
- When saving with `Prefix+S`, plugin auto-adds suffix: `myzone-2`
- Or manually rename in config file

## Advanced Tips

### Testing Zones

Before saving to config:
```bash
# Edit config
vim ~/.config/szpaner/zones.conf

# Reload tmux config
tmux source-file ~/.tmux.conf

# Test zone
Prefix+Z → type zone name
```

### Quick Edits

From inside tmux:
```
:split-window -h "vim ~/.config/szpaner/zones.conf"
```

### Viewing Parsed Config

```bash
cd ~/.tmux/plugins/szpaner
bash -c 'source scripts/parse-config.sh && parse_config_file ~/.config/szpaner/zones.conf && print_config'
```

### Backup Your Zones

```bash
cp ~/.config/szpaner/zones.conf ~/.config/szpaner/zones.conf.backup
```

Or use git:
```bash
cd ~/.config/szpaner
git init
git add zones.conf
git commit -m "My zones"
```

---

**Happy zone crafting!**

For more help, see [README.md](README.md)
