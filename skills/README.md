# Skills

This directory stores repo-managed agent skills.

Each skill lives in its own folder and should include a `SKILL.md` file:

```text
skills/
  learn-by-building/
    SKILL.md
```

## Use These Skills On Another Machine

These repo-managed skills are local folders. They are not installed with `npx skills add`.

To use them on another machine:

1. Clone this repo.
2. Link the repo skill folders into your local Claude skills directory.

### Windows

Run the bootstrap script from the repo root:

```powershell
.\scripts\bootstrap.ps1
```

This creates junctions under `$HOME\.claude\skills` without requiring administrator privileges.

Dry run:

```powershell
.\scripts\bootstrap.ps1 -WhatIf
```

### Linux or macOS

Run the shell bootstrap script from the repo root:

```bash
./scripts/bootstrap.sh
```

If you prefer to link one skill manually:

```bash
mkdir -p "$HOME/.claude/skills"
ln -sfn "$PWD/skills/learn-by-building" "$HOME/.claude/skills/learn-by-building"
```

## Install Skills From This Repo With `npx`

Install all skills from this repo globally:

```bash
npx skills add nprithviraj24/.config -g -y
```

Install a specific skill:

```bash
npx skills add nprithviraj24/.config@learn-by-building -g -y
```

Check for updates or list what is installed:

```bash
npx skills check
npx skills update
```

Note: the repo must be public (or the machine must have GitHub access) for `npx skills add` to clone it.

## Add A New Repo-Managed Skill

1. Create a new folder under `skills/`.
2. Add a `SKILL.md` file inside it.
3. Re-run the bootstrap script on Windows or Linux/macOS.
