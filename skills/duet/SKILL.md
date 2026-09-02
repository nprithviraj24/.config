---
name: duet
description: Argue a design, plan, or diagnosis out with Codex before committing to it. Spawns a pinned Codex thread, makes it refute your position across rounds, and reports only the disagreements.
disable-model-invocation: true
argument-hint: "What should we argue out?"
---

The user wants a second, independent model to attack a position before they act on it.
You hold one side. Codex holds the other. The user judges.

Codex is a different model with different training and no history in this conversation.
That independence is the entire value, and it only pays out if you prompt Codex to
**refute**. A second model agreeing with you is worth nothing.

## Layout

State lives in `.duet/` in the current working directory:

```
.duet/
  BRIEF.md               the question under argument
  .thread                pinned Codex thread id
  .cwd                   pinned Codex working root
  .inputs                fingerprint of the repo + brief being argued about
  rounds/NNN-claude.md   your position for round NNN
  rounds/NNN-codex.md    Codex's refutation
  rounds/NNN-codex.jsonl raw event log (thread id lives on line 1)
  DECISION.md            written at the end
```

Add `.duet/` to `.gitignore` if it isn't there. Ask before committing any of it.

## Invariants

Break these and the skill produces confident nonsense:

- **You own every write.** Codex runs `-s read-only`; never give it write access.
  This stops *Codex* racing you. It does **not** stop a second Claude session racing you
  over the same `.duet/` — `.thread`, `.cwd` and the event logs are shared mutable state.
  `duet-round.sh` takes an exclusive `flock` per root and exits 7 rather than interleave.
- **Never `--last`.** It resumes the most recent Codex session *globally*. The user runs
  Codex in other panes; `--last` will silently hijack the wrong thread and the failure
  looks exactly like Codex losing the plot.
- **A passing thread-id check does not mean the round is sound.** The script pins the
  working directory alongside the thread id because `codex exec resume` takes no `-C` and
  inherits the shell's cwd; without that, a resume launched from elsewhere reads a
  different `.duet/` while the id assert passes cleanly. Right thread, wrong repo.
- **Never summarise Codex's position in place of quoting it.** When you report a
  disagreement, quote the line. You are an interested party in this argument.

## Round 0 — the brief

Draft `.duet/BRIEF.md` from the user's question plus what you can read of the repo. Follow
[BRIEF-FORMAT.md](./BRIEF-FORMAT.md).

**Show it to the user and get it corrected before spending a single Codex round.** A vague
brief produces two agents talking past each other, and you will not be able to tell that
from a real disagreement.

## Rounds

Each round, write your position first, then let Codex attack it.

1. Write `.duet/rounds/NNN-claude.md`: your position, your reasoning, and — honestly — the
   part you are least sure about. Do not write advocacy. If you hide the weak joint, Codex
   wastes the round finding it and the user learns nothing.

2. Build the prompt file, then run the round:

```bash
cat > /tmp/duet-prompt.txt <<'EOF'
Read .duet/BRIEF.md and the *.md files in .duet/rounds/.
Ignore .jsonl and .err files there — they are raw logs, not positions.

Your job is to REFUTE the position in the most recent NNN-claude.md.
Argue the strongest case against it. Be concrete: name the input, the state, or the
sequence that breaks it. If you cannot break it, say so plainly and say what evidence
changed your mind — do not manufacture an objection.

Then give your own position on the brief, and mark anything you are guessing about
as a guess.
EOF

~/.claude/skills/duet/scripts/duet-round.sh NNN /tmp/duet-prompt.txt "$PWD/.duet/rounds/NNN-codex.md"
```

   Run it from the duet root, or set `DUET_ROOT=/path/to/root`.

   **Constrain the prompt.** Left open-ended, Codex will run web searches and spawn its
   own sub-reviewers, burn several minutes, and can end on a tool call having produced no
   answer at all. Name the files to read, and say: no web search, no sub-agents, answer
   directly from the files.

   The script spawns on round 1, resumes the pinned thread afterwards, and asserts the
   thread id Codex echoes back matches the pinned one. Handle its exit codes:

   - **3 — thread is gone.** Delete `.duet/.thread`, re-run as a fresh spawn, and seed the
     prompt with BRIEF.md *plus every prior round file*. Then **tell the user context was
     lost**. A re-seeded Codex arguing against a position it cannot remember holding looks
     identical to a Codex that changed its mind.
   - **4 — thread mismatch.** Stop. Do not retry. Report it. Something else is writing to
     `.duet/.thread`.
   - **6 — Codex failed for some other reason** (auth, rate limit, crash). The thread is
     probably still valid. Fix the cause and retry the same round. **Do not delete
     `.thread`** — exit 3 is the only signal that the thread is actually gone.
   - **7 — another round is running** in this root. Wait; do not force it.
   - **5 — no recoverable output.** Codex ended without a final message and the event log
     held nothing usable. Read the round's `.jsonl` to see what it actually did before you
     spend another round; a run that ends on a tool call has usually gone hunting rather
     than answering.
   - If `.duet/.thread` is missing but you believe a thread exists, recover the id with
     `agents find <keyword from the brief>` before spawning a duplicate.

3. Check what the script printed before you read anything:

   - **`output is PARTIAL`** — Codex ran a tool after its last message and never answered.
     That text is an interim note, not a position. Do not score it, do not count it toward
     convergence. Re-run the round with a tighter prompt.
   - **`WARNING — repo or brief changed`** — the two sides are arguing about different
     inputs. Codex reasons from what it saw in an earlier round but reads the *current*
     files, and both the thread and cwd checks still pass. Say this out loud when you
     report the round; a disagreement here may be an artefact of the drift rather than a
     real objection.

4. Read `NNN-codex.md` and report to the user **only the deltas**, in this shape:

   - **Conceded** — where Codex is right and you were wrong. Lead with this.
   - **Contested** — where you still disagree, with both positions quoted, one line each.
   - **New** — considerations neither of you had raised.

   Do not paste Codex's output wholesale. The user asked for an argument, not a transcript.

## Stopping

Two rounds by default. Hard stop at three. Exit early the moment a round produces no new
Contested or New items.

Agent debates asymptote fast and then agree politely forever; a third round that produces
only agreement is a signal you have converged, not a reason to run a fourth.

Then write `.duet/DECISION.md`:

- What the user is doing, and why
- **What stayed contested, and what evidence would settle it**

Never resolve a genuine disagreement by picking one side and calling it consensus. An
unresolved disagreement recorded honestly is the most valuable line in the file.
