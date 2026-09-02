---
name: handoff
description: Compact the current conversation into a handoff document another agent can pick up cold. Use when the user asks for a handoff, wants to hand work to another agent or session, says they are running low on context or wrapping up, or invokes $handoff. Ask what the next session will be used for if it is not obvious.
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
