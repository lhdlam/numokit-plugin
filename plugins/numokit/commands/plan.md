---
name: "numokit:plan"
description: Analyse an incoming dev task, measure its blast radius, cross-check it against the spec and raise any deviation, then produce plan-<slug>.md for a human to approve before any code is written.
category: Development
tags: [numokit, plan, impact, spec, scope]
---

Invoke the `plan-change` skill using the Skill tool, passing everything the user typed after the
command — a free-text task description, or a git branch/tag that already carries the change.

The skill is read-only: it writes no source files. It scopes the task (git diff when a ref is given,
otherwise by locating the modules and documents the description points at, asking rather than
guessing), then measures the blast radius across six buckets — modules/files, public API contracts,
schema/data, shared code, existing tests, docs/spec — rating each High/Medium/Low with a real citation
(`SRS §4.2`, `app/auth.ts:31`), or "cần xác minh" when the evidence is thin.

With the **codebase-memory** MCP in the session it locates code through the knowledge graph —
`search_graph` from the words in the task description, `get_code_snippet` to read the symbol rather
than the whole file, `trace_path` for callers, `check_index_coverage` before citing a path. Without it,
or where the index does not reach, it greps as before: **the graph is an accelerator, never a
dependency**, and dynamic boundaries are grepped and marked "cần xác minh" regardless. Citations record
whether the evidence came from the graph or from grep.

It cross-checks task vs docs vs implementation three ways and raises every mismatch into
`open-questions.md` rather than deciding alone, then writes `plan-<slug>.md`.

**The finished plan is then audited by the `numokit:plan-reviewer` subagent.** A plan is written by the
same agent that analysed the task, so it carries that agent's blind spots: impact it never thought to
look for is also impact it does not know it missed, and a question it could not answer looks like a
question nobody can answer.

This peer review differs from the one in `/numokit:review` in a way that matters. There the second
agent never sees the first verdicts, so it is genuinely independent. Here **the plan itself is the
thing under review** and cannot be hidden, so the risk inverts: not being primed by a conclusion, but
being *persuaded by a well-written plan*. The reviewer is therefore required to open every cited source
itself before calling anything correct, and to measure the blast radius independently **before** it
looks at the plan's own table. Citations that merely look well-formed are the easiest thing to
fabricate, and that is where it earns its keep.

It triages the plan's open questions three ways — **already answered in the sources** (answer and
citation supplied, so the approver never has to answer it), **genuinely needs a human** (with where it
searched), and **malformed** — plus the ambiguities the plan should have asked about and did not. A
question whose answer sits in the spec wastes the approver's time and erodes trust in the questions
that remain.

Findings are folded back in: fabricated citations are removed or re-sourced, understated risk is raised,
missed impact is added with credit stated, answered questions move out of the waiting list. A
disagreement over severity is not settled by the skill — it takes the more conservative reading and
escalates. A clean peer review lowers risk; it is never reported as proof the plan is right.

Every question ends up with a status, and the plan should not be marked `APPROVED` while an
implementation step depends on one still waiting on a human. The plan ends in `> Review: PENDING` and
the skill stops. Without a subagent-capable platform the review cannot run — the plan then says so
rather than the skill playing both roles.

No argument → ask for the task. Once APPROVED, continue with `/numokit:fixbug`, `/numokit:refactor`,
or implement the proposed steps. On Claude Code the gate hook refuses `fixbug` and `refactor` while
any `plan-*.md` is still PENDING.
