---
name: intake
description: Extract the durable findings from this session and write them into the project's own docs - AGENTS.md, docs/adr, a work trail - following the conventions that project already uses. Use at the end of a session that settled something; when the user says "intake this", "capture this", or "write this up"; or before context runs out on work whose reasoning exists nowhere but the conversation.
---

# Intake

A session ends and its reasoning dies with it. The code survives and the commits
survive, but *why* this approach beat the other one, which constraint forced the
design, and what cost an hour to discover live only in the transcript. Intake moves
that into the project's documentation before it is lost.

## Why this exists

`handoff` and `intake` both read the conversation and both write a document. They
differ in who reads the result next.

| | written for | lands in | lifespan |
|---|---|---|---|
| `handoff` | the next agent continuing this work | the OS temp dir | one session |
| `intake` | the project itself | the repo's own docs | permanent |

Reach for `handoff` when work is unfinished and someone resumes it tomorrow. Reach
for `intake` when something was **settled** and the project should remember it.

Writing into the permanent record sets the bar: every line added is a line every
future agent loads on every future session. Intake earns that load or writes nothing.

## Phase 1 — Read the project's conventions first

The project already has a documentation shape. Find it and follow it. Inventing a
parallel structure beside a working one is the most common way this skill does harm.

Establish, by looking rather than assuming:

- Which of `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` exists, and which is canonical. When
  one is canonical the others are usually short pointers to it — keep them that way.
- Whether `docs/adr/` exists, and its numbering and filename style. Match the existing
  width exactly: a repo numbering `001-` gets `006-`, not `0006-`.
- Whether a running work log exists (`docs/trail.md` and similar) and whether it is
  gitignored. A local-only trail stays local-only.
- Whether the repo is under git at all.

`MISSION.md`, `NOTES.md`, `RESOURCES.md`, `GLOSSARY.md` and `lessons/` belong to the
`teach` skill and carry its formats. Leave them to `teach`; if the session produced
teaching material, say so in the report and let the user run `teach`.

When the project has no agent docs at all, propose the single smallest file that fits
what you found and let the user approve it. A bare repo does not need a doc suite.

## Phase 2 — Harvest candidates

Re-read the session and list every candidate finding. Cast wide here; Phase 3 cuts.

Look for the moments that carry reasoning:

- A decision, with the alternative that lost and the reason it lost.
- A constraint discovered by hitting it — a validator that rejects a key, an API that
  refuses a shape, a tool that corrupts under a condition.
- A fact established by running something, that no file states.
- A trap that cost real time, and the signal that identifies it next time.
- A belief the current docs encode that turned out to be wrong.

## Phase 3 — Keep only what is load-bearing

A finding is **load-bearing** when knowing it changes what someone does next. Apply
these three tests to each candidate, and drop it the moment one fails.

**Would its absence cause a mistake?** If a future agent would arrive at the same
place without the note, the note is decoration.

**Can it be looked up cheaply?** The environment is a source of truth — code, config,
`git log`, `--help`, the directory layout. A doc that restates a cheap lookup is a
**cache** that goes stale and misleads. Cache only what cannot be found by looking:
the unwritten convention, the reason behind a choice, the gotcha no config confesses.

**Was it verified here?** Write what this session actually executed and observed.
A conclusion reasoned from a diff, believed from a summary, or carried in from another
project or machine is not yet a fact — either verify it now, or record it as an open
question in the user's words rather than as settled.

What survives all three is usually a handful of items. Two load-bearing lines beat a
page of true ones: the page becomes **sediment**, and the next reader cores through it.

## Phase 4 — Route each finding

| Finding | Goes to |
|---|---|
| An architectural decision and its rationale | `docs/adr/NNNN-*.md`, status **Proposed** |
| A durable rule, guardrail, command, or convention a future agent must follow | the canonical agent guide |
| Session-scoped progress, what was tried, what remains | the work trail, when one exists |
| A correction to something a doc currently claims | edit that doc in place |
| A fact about the user or this machine rather than this project | the user's memory directory, not the repo |
| Teaching material — a concept the user is learning | nothing; report it and suggest `teach` |

Route by what a finding *is*, not by where it is convenient to put it. When two targets
fit, pick the one whose readers need it and reference it from the other.

Read [`TARGETS.md`](TARGETS.md) for each target's format and rules before writing to it.

## Phase 5 — Write

Integrate into the existing document. A finding belongs under the heading that already
covers its subject, in that document's established voice and person.

Add a new ADR per decision. Extend the agent guide and the trail in place.

Keep prose in the project's register. Where the project states reasons, state the
reason; where it states rules, state the rule.

When the repo is not under git, show the intended change and wait for approval before
writing — there is nothing to revert to.

## Phase 6 — Report the diff

Print `git diff` limited to the files touched, then a one-line summary per finding:
what it was, where it went, why there.

Name every target file that already carried uncommitted changes before this run, so
the user knows which parts of the diff are theirs and which are yours.

Leave the changes uncommitted. The user commits.

## Anti-patterns — banned

- Narrating the session. A durable doc justifies itself structurally: it states the
  constraint and the decision, never "in this session we found that".
- Importing an incident from another project, machine, or agent instance that this
  project has no record of.
- Recording a claim this session did not verify as though it were established.
- Restating what the code, config, or `git log` already says.
- Rewriting or reordering existing content to accommodate an addition.
- Filing a decision the user has not actually made as `Accepted`.

## Output contract

Report, in this order:

1. The conventions found in Phase 1, in one line — what is canonical, what exists.
2. Candidates harvested, and the count dropped in Phase 3 with the test each failed.
3. The diff, per file.
4. Findings routed elsewhere: memory, `teach`, or nothing.
5. Open questions recorded as unverified, if any.

When nothing survives Phase 3, write nothing and say so. A session that settled
nothing durable is a normal outcome, and an empty intake is a correct result.
