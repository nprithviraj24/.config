## Configurations

Personal configuration and tooling repo.

Current areas in this repo:

- `gnome/` for desktop settings and notes
- `scripts/` for bootstrap and setup automation
- `shell/` for Bash helpers
- `skills/` for repo-managed agent skills
- `tmux/` for tmux configuration
- `vscode/` for editor settings and snippets
- `yolo/` for older project-specific files that still need sorting

## Bootstrap

Use the bootstrap scripts to wire repo-managed skills into Claude:

```powershell
.\scripts\bootstrap.ps1
.\scripts\bootstrap.ps1 -WhatIf
```

```bash
./scripts/bootstrap.sh
```

The Windows script creates junctions under `$HOME\.claude\skills` so the repo stays the source of truth without requiring administrator privileges.
