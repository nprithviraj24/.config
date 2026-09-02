# 1. One canonical skill, with a Codex overlay

Date: 2026-09-02

## Status

Accepted

## Context

The same agent skills are used from three tools: Claude Code (`~/.claude/skills`),
Codex (`~/.codex/skills`), and agy / Antigravity (`~/.gemini/skills`). All three
discover skills by scanning that directory for `<name>/SKILL.md`; none has a
registry or manifest.

Until now the three copies were maintained by hand, which meant an edit had to be
made three times and nothing detected when it wasn't. That is the problem this repo
exists to solve.

A single canonical copy, symlinked into all three, would be the obvious fix. It does
not work, because Codex differs in two ways:

- Its frontmatter validator rejects unknown keys. The allowed set is
  `name, description, allowed-tools, license, metadata`, so Claude's `argument-hint`
  and `disable-model-invocation` both fail there. Codex reads only `name` and
  `description`, so a skill using those keys needs a variant with them stripped and
  the trigger conditions folded into `description`.
- It reads an additional `agents/openai.yaml` carrying
  `interface: {display_name, short_description, default_prompt}`, which the other two
  tools have no equivalent for.

Claude and agy, by contrast, read the identical file — including
`disable-model-invocation`, which agy honours the same way Claude does.

Three complete copies in the repo were considered. Every destination would then be a
plain symlink, which is simpler to reason about, but it reintroduces the exact
drift the repo is meant to eliminate — the duplication just moves from the home
directory into version control, where nothing checks that the copies still agree.

## Decision

Keep one canonical skill in `skills/<name>/`, written for Claude and agy, and put
Codex's differences in a parallel `codex/<name>/` overlay that is copied over a
duplicate of the canonical tree at install time.

`~/.claude` and `~/.gemini` are **symlinked** to `skills/<name>/`. `~/.codex` gets a
**real copy** with the overlay applied, because the content genuinely differs.

The overlay holds only what actually diverges: a replacement `SKILL.md` for the two
skills whose frontmatter Codex rejects, and `agents/openai.yaml` per skill. A skill
with no `codex/` entry installs to Codex unchanged. `codex/EXCLUDE` lists skills that
should not reach Codex at all.

## Consequences

The divergence is now visible and small — `codex/` is a precise inventory of every
way Codex differs, rather than a difference buried in three near-identical trees.
Adding a skill that needs no Codex-specific handling means touching one directory.

Claude and agy can never drift, since they read the repo file directly. Editing the
skill in place from either tool edits the repo.

Codex can drift, because a copy is a snapshot. **Bootstrap must be re-run after every
edit**, and that is the only step that syncs Codex. This is the cost of the decision
and the reason the READMEs state it twice.

A canonical `SKILL.md` and its Codex counterpart can silently disagree in the body,
since only the frontmatter is supposed to differ. Nothing currently enforces that;
today it is checked by diffing the two when either changes.

`npx skills add` installs the canonical copies only and does not apply the overlay,
so skills installed that way are Claude/agy-correct but may fail Codex validation.
The bootstrap script is the supported path for a Codex install.
