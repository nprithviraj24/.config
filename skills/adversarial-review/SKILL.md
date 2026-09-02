---
name: adversarial-review
description: Adversarial review protocol for designs, plans, and diagnoses that confidence alone is holding up. Manufactures independent perspectives, grounds every assumption in executed evidence, and reports ranked findings with concrete failure scenarios. Use when the user asks to poke holes in, stress-test, sanity-check, or red-team a design or plan; before an architectural decision gets locked in; when a root-cause diagnosis is about to be acted on; when you produced the artifact yourself and nobody else has looked at it; or when the user invokes $adversarial-review or /adversarial-review.
---

# Adversarial Review

> **The design is a hypothesis to be disproven, not a conclusion to defend.** If you — or an earlier turn of this session — produced it, that is a reason for *more* suspicion, not less.

Run this when something is about to get locked in and confidence is doing work that evidence should be doing.

## Why this exists

Agent output is fluent by construction. The same process produces the same confident prose whether or not the content is correct, so **fluency carries no signal about correctness** — a sound design and a broken one read identically. "This looks right" is therefore measuring the wrong thing, and it is the criterion most reviews quietly stop on.

Re-reading does not fix it. The context that produced an artifact re-runs the reasoning that produced it, reaches the same conclusion, and now has the added weight of having already committed to it. **Self-review converges on agreement, not on truth.**

So the artifact needs the two things the producing context cannot supply on its own: a reviewer that did not build it, and evidence that was executed rather than inferred. Everything below is machinery for obtaining those two things reliably, instead of when someone remembers to ask.

## The central mechanism: independence

**This is the part that actually does the work.** A single context re-reviewing its own output reproduces its own blindspots — it re-runs the reasoning that built the design and finds it agreeable. The job is to obtain perspectives **not produced by the reasoning that built the design**.

Two rules make that real:

1. **Each reviewer gets the artifact and one adversarial lens — nothing else.** Narrow scope is what makes a reviewer find things; a reviewer asked to "look at everything" pattern-matches to approval.
2. **Withhold the justifications.** The "here's why we chose this" narrative is precisely what anchors a reviewer into agreement. It is available *after* a finding is formed, never before.

### Levels

| Level | When | How |
|---|---|---|
| **Quick** | Tiny / low-stakes | No subagents. Adopt each lens fresh and argue against your prior self. Weakest form — independence here is simulated, not real. Say so. |
| **Standard** *(default)* | Most designs | Spawn independent subagents, each given *only* the artifact + one adversarial lens. |
| **Exhaustive** | The user explicitly opts into maximum rigor | Fan out finders → independent skeptics verify each finding → synthesize. The findings themselves get reviewed. |

**State which level you are running and why, before starting.** Quietly picking Quick and presenting the result as rigor is exactly the failure this rule exists to prevent.

## The seven passes

| # | Pass | What it forces |
|---|---|---|
| 0 | **Locate & restate** | Pin down exactly what is under review. Can't restate it crisply? That is finding #1 — stop there. |
| 1 | **Enumerate assumptions** | Every one, especially the *implicit* ones. Hunt the quiet phrases: "this won't change", "this case is rare", "this can't happen". |
| 2 | **Ground each one** | Tag every assumption `VERIFIED` (name the evidence) / `UNVERIFIED` / `UNKNOWABLE`. |
| 3 | **Adversarial lenses** | Premise & framing, correctness, failure modes, grounding, operability & cost, second-order effects, security & trust boundaries. |
| 4 | **Steelman, then break** | Build the strongest honest case for each decision, then attack it. A decision defensible only by strawmanning the alternatives is a red flag. |
| 5 | **Blindspot sweep** | The meta pass: what category was not considered *at all*? Whose perspective is missing? What question is being quietly avoided? |
| 6 | **Calibrate & synthesize** | Findings ranked by impact, each with a concrete failure scenario, explicit confidence, and a "still unsure about…" list. |

### Pass 2 carries the most weight

**Grounding means executing, not reading.** Run the query. Check the installed version. Execute the code path. Read the actual log line. Reproduce the failure.

"I read the code and it appears to…" is `UNVERIFIED` — label it that way and state what would verify it. `UNKNOWABLE` is a legitimate tag, not an escape hatch: a load-bearing assumption that is unknowable **is itself a finding**.

### Pass 6 is non-negotiable

**Never end on false reassurance.** A review that concludes "no significant issues" without a populated assumption ledger has not been run — it has been skipped. If the honest answer is that the design holds up, say so *and* name what you could not check.

## Anti-patterns — banned

- **Rubber-stamping** — "looks solid" is unavailable to you unless every load-bearing assumption is `VERIFIED`.
- **Nitpick inflation** — a long list of trivia is not rigor. It buries the one finding that matters and lets everyone feel reviewed.
- **Confident-but-unchecked critiques** — your objections are held to the same evidence bar as the design. An ungrounded objection gets tagged `UNVERIFIED` like anything else.
- **Anchoring on your own prior justification** — if you catch yourself explaining why you were right, stop. Switch lenses and attack.

## Output contract

1. **Level run, and why.**
2. **Assumption ledger** — each assumption with its tag and, for `VERIFIED`, the evidence (command run, output seen, file and line).
3. **Findings, ranked by impact.** Each one: what breaks, the concrete failure scenario, your confidence.
4. **Still unsure about…** — required. Non-empty unless every load-bearing assumption is `VERIFIED`.
5. **Recommendation** — proceed / proceed with these changes / do not proceed.

A failure scenario names inputs or state and the wrong outcome they produce. *"This could be fragile"* is not one. *"If two writers hit the queue in the same 50 ms window, the second silently overwrites the first's offset and those events are lost"* is.
