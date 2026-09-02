# BRIEF.md format

The brief is the highest-leverage file in a duet. Both agents read it every round, and
neither can tell the difference between "we disagree" and "we read the question
differently." Spend the effort here.

Keep it under a page. Concrete beats complete.

```markdown
# Brief: <the decision, as a question>

## Decision to make
One or two sentences. A question with at least two defensible answers.
If there is only one defensible answer, there is nothing to argue about — say so and stop.

## Context
What a competent engineer needs to know and cannot get from the repo in five minutes.
Link to files by path and line rather than pasting them; Codex reads the repo directly.

## Constraints
Things that are fixed and not up for argument — deadlines, dependencies, decisions already
made and not being reopened. Be explicit: an unstated constraint reads as an oversight, and
Codex will spend a round attacking it.

## Options on the table
- **A** — one line
- **B** — one line

## Out of scope
What this duet is not deciding. Prevents the argument sprawling into adjacent design.

## How we will know we are right
The evidence, test, or observation that would settle this. If nothing could settle it,
say that — it means the disagreement is about values, not facts, and it is the user's
call rather than an argument either agent can win.
```

## Writing it

Draft it, then **show it to the user and get it corrected before the first Codex round**.

Two failure modes to check for before you spend a round:

- **A question with one defensible answer.** You will get manufactured objections that
  waste the round and read like real ones.
- **A hidden constraint.** If the user has already ruled something out, write it under
  Constraints. Otherwise the strongest refutation Codex produces will be one you have to
  throw away.
