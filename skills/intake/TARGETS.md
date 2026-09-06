# Targets

Format and rules per destination. Read the section for a target before writing to it.

---

## `docs/adr/NNNN-slug.md` — architectural decisions

One decision per file. Match the directory's existing number width and separator
exactly; look at the newest file rather than assuming. Number sequentially from the
highest existing.

Nygard format, these five headings and no others:

```markdown
# N. Title as a statement, not a question

Date: YYYY-MM-DD

## Status

Proposed

## Context

The forces in play: the constraint, the requirement, the thing that stopped working.
Written so it stands alone in two years, in the present tense, without reference to
the session that discovered it. Alternatives that were genuinely considered belong
here, each with the reason it lost.

## Decision

What was chosen, stated actively: "We keep X in Y and copy Z at install time."

## Consequences

What becomes easier, what becomes harder, and what now has to be maintained by hand.
The costs are the point of the section — an ADR with only benefits is unfinished.
```

Status is **Proposed** on intake. The user promotes it to Accepted.

An ADR is warranted when the decision constrains future work and a reasonable person
would otherwise undo it. A choice with no live alternative is not an ADR; it is a line
in the agent guide.

Where the project keeps ADRs under a different template, follow that one.

---

## The canonical agent guide — durable rules

Usually `AGENTS.md`. When `CLAUDE.md` or `GEMINI.md` is a pointer to it, they stay
pointers: add nothing to them beyond the pointer itself.

Where `CLAUDE.md` is itself canonical (it carries real content and no `AGENTS.md`
exists), treat it as the guide.

Belongs here:

- A command the project needs run a specific way, and what breaks otherwise.
- A guardrail: a path to leave alone, an operation that must not run, a file that is
  append-only.
- An architectural fact that is not visible from any one file.
- A convention that is followed but written nowhere.

Add under the heading that already covers the subject. Only add a heading when the
finding fits none, and match the surrounding heading depth and voice.

State each as a rule with its reason attached, in one or two lines:

> `overrides.jsonl` is append-only — it holds manual tags and provenance, and is the
> only file here that cannot be regenerated.

The reason is what makes the rule survive; a bare rule gets rationalised away.

An ADR and a guide line often come in pairs: the ADR carries the reasoning, the guide
carries the resulting rule and links to it.

---

## The work trail — session-scoped progress

Only when the project already has one. Common names: `docs/trail.md`, `PROGRESS.md`,
`docs/worklog.md`.

Check whether it is gitignored. A trail declared local-only stays out of commits, and
the report should say so.

Append a dated entry; never edit earlier entries. Match the existing entry shape. When
the file is empty or new, use:

```markdown
## YYYY-MM-DD

- What changed, and the state it left things in.
- What was tried and rejected, with the reason.
- What remains open, phrased so it can be picked up cold.
```

This is the one target where "what happened" is the point. Even here, prefer the
outcome and its reason over narration of the steps.

---

## The user's memory directory — facts about the person or the machine

`~/.claude/projects/<encoded-cwd>/memory/`, when a finding is true beyond this repo:
a hardware quirk, a tool that must be invoked a particular way on this machine, a
standing preference about how work should be done.

One fact per file:

```markdown
---
name: <short-kebab-case-slug>
description: <one-line summary, used to decide relevance during recall>
metadata:
  type: user | feedback | project | reference
---

<the fact. For feedback and project, follow with **Why:** and **How to apply:** lines.
Link related memories with [[their-name]].>
```

Then add one line to `MEMORY.md`: `- [Title](file.md) — hook`. `MEMORY.md` is an index
only; memory content never goes in it.

Check for an existing file covering the same ground and update that one instead of
creating a near-duplicate. Skip anything the repo already records — code structure,
git history, the contents of `AGENTS.md`.

---

## Owned by `teach` — leave alone

`MISSION.md`, `NOTES.md`, `RESOURCES.md`, `GLOSSARY.md`, `lessons/`.

These carry `teach`'s formats and its record of what the user has learned. When the
session produced material that belongs in one, name it in the report and suggest
running `teach`; write nothing into them.
