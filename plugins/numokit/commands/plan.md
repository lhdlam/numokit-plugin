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
`open-questions.md` rather than deciding alone, then writes `plan-<slug>.md` ending in
`> Review: PENDING` and stops.

No argument → ask for the task. Once APPROVED, continue with `/numokit:fixbug`, `/numokit:refactor`,
or implement the proposed steps. On Claude Code the gate hook refuses `fixbug` and `refactor` while
any `plan-*.md` is still PENDING.
