# szPaner

**Spawn Zone Paner** - A tmux plugin for creating predefined pane layouts with ease.

## Concept

- **Zones**: Sets of predefined panes with custom commands
- **Spawn**: Create zones instantly with `tmux ConfName`
- **Features**: SSH connections, arbitrary scripts, custom layouts
- **TPM Compatible**: Works with Tmux Plugin Manager

## Current Status: Basic Prototype

The prototype creates a 3-pane dev layout:
```
┌─────────────┬─────────┐
│             │  Pane 1 │
│   Pane 0    │ (server)│
│  (editor)   ├─────────┤
│             │  Pane 2 │
│             │ (logs)  │
└─────────────┴─────────┘
```

## Quick Start

### Manual Test
```bash
./demo.sh
```

This creates a demo session with 3 panes ready for commands.

### Direct Usage
```bash
./scripts/spawn-zone.sh my-session
```

### TPM Installation (future)
```tmux
set -g @plugin 'your-username/szpaner'
```

## What Works Now

- ✅ Creates 3-pane layout (60% left, 40% right split vertically)
- ✅ Sends example commands to each pane
- ✅ Works with new or existing tmux sessions
- ✅ Auto-selects the main pane

## Next Steps

- [ ] Config file support (YAML/JSON)
- [ ] Multiple zone definitions
- [ ] SSH connection handling
- [ ] Custom layouts
- [ ] Better command execution timing
- [ ] Full TPM integration
