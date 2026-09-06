# Skills

Repo-managed agent skills, shared across three tools: Claude Code, Codex, and agy
(Antigravity). This repo is the source of truth — edit here, then re-run the
bootstrap script to push the change out to all three.

## Layout

```text
skills/                       canonical skill, read verbatim by Claude and agy
  <name>/
    SKILL.md
codex/                        Codex-only overrides, layered on top of skills/<name>/
  EXCLUDE                     skills deliberately not installed into Codex
  <name>/
    SKILL.md                  only when Codex needs different frontmatter
    agents/openai.yaml        Codex-only interface metadata
```

### Why Codex needs an overlay

Claude and agy read the canonical `SKILL.md` unchanged, so they are symlinked and
cannot drift. Codex can't be:

- Its frontmatter validator **rejects unknown keys**. The allowed set is
  `name, description, allowed-tools, license, metadata` — so `argument-hint` and
  `disable-model-invocation` both fail there. Skills using them need a Codex copy
  with those keys stripped and the trigger conditions folded into `description`
  instead, since Codex reads only name and description.
- It additionally reads `agents/openai.yaml` with
  `interface: {display_name, short_description, default_prompt}`.

So Codex gets a real copy of `skills/<name>/` with `codex/<name>/` copied over it.
A skill with no entry under `codex/` is installed to Codex as-is.

Validate a Codex copy with:

```bash
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/<name>
```

## Install

```bash
./scripts/bootstrap.sh          # Linux / macOS
```

```powershell
.\scripts\bootstrap.ps1         # Windows (junctions, no admin needed)
.\scripts\bootstrap.ps1 -WhatIf # dry run
```

This links `~/.claude/skills/<name>` and `~/.gemini/skills/<name>` to the repo, and
copies into `~/.codex/skills/<name>` with the overlay applied. Anything already at
those paths that isn't a link into this repo is moved aside to a
`.backup-<timestamp>` folder first.

Override the destinations with `CLAUDE_HOME`, `GEMINI_HOME`, `CODEX_HOME`
(`-ClaudeHome`, `-GeminiHome`, `-CodexHome` on Windows).

Because Codex is a copy rather than a link, **re-run bootstrap after every edit** —
that is the only step that syncs it.

## Install from this repo with `npx`

```bash
npx skills add nprithviraj24/.config -g -y                 # all skills
npx skills add nprithviraj24/.config@learn-by-building -g -y  # just one
npx skills check
npx skills update
```

Note: this installs the canonical `skills/` copies only — it does not apply the
Codex overlay. Use the bootstrap script if you want working Codex skills.

## The skills

| Skill | What it does | Tools |
|---|---|---|
| `adversarial-review` | Stress-test a design, plan, or diagnosis that only confidence is holding up. Grounds every assumption in executed evidence and reports ranked findings. | all three |
| `diagnose` | Disciplined debugging loop for hard bugs and performance regressions: reproduce → minimise → hypothesise → instrument → fix → regression-test. | all three |
| `duet` | Argue a position out with Codex before acting on it. Spawns a pinned Codex thread, makes it refute you, reports only the disagreements. | Claude, agy |
| `eli5-grownup` | Explain an unfamiliar topic to a smart adult who knows nothing about *this* topic and everything else about the world. Words first, then a rendered comic-strip graphic. | all three |
| `grill-me` | Interview the user relentlessly about a plan until every branch of the decision tree is resolved. | all three |
| `handoff` | Compact the current conversation into a handoff document another agent can pick up cold. | all three |
| `intake` | Extract what a session settled - decisions, constraints, hard-won facts - and write it into the project's own docs, following the conventions already there. | all three |
| `improve-codebase-architecture` | Find deepening opportunities in a codebase, informed by its domain language and ADRs. | all three |
| `learn-by-building` | Turn the agent from a code generator into a teaching partner — checkpoints, predictions, break-it challenges. | all three |
| `teach` | Teach a topic across sessions in a stateful local learning workspace. | all three |

`duet` is Claude/agy only by design: it spawns Codex as the *opposing* model, so
running it inside Codex would have Codex argue with itself. It's listed in
`codex/EXCLUDE`.

## Add a new skill

1. Create `skills/<name>/SKILL.md`.
2. If it uses `argument-hint` or `disable-model-invocation`, add
   `codex/<name>/SKILL.md` without those keys.
3. Optionally add `codex/<name>/agents/openai.yaml`.
4. Re-run the bootstrap script.
