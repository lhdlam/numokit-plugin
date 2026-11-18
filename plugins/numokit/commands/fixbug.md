---
name: "numokit:fixbug"
description: Diagnose and fix a bug — locate the root cause in code and spec with citations, ask the developer clarifying questions at a hard human gate, then fix the cause and add a regression test that is red before the fix and green after.
category: Development
tags: [numokit, bug, fix, debug, regression]
---

Invoke the `fixbug` skill using the Skill tool, passing everything the user typed after the command
as the bug description. No argument → ask for it.

The skill runs a guarded debug workflow: it locates the root cause in code + spec with a source
reference for every claim and says so plainly when it cannot locate one; **then it asks the developer
clarifying questions, presents the proposed fix and its blast radius, and STOPS** — no code is edited
before the user answers and approves. After approval it fixes the root cause with a minimal diff,
always adds a regression test named after the behaviour it protects, verifies by running that test
plus the module's tests, and reports the real output. A bug is never declared fixed on a red run.

With the **codebase-memory** MCP it locates the fault through the knowledge graph (`search_graph`,
`get_code_snippet`, `trace_path` for the blast radius it shows at the gate), checking
`check_index_coverage` before citing. Without it the behaviour is unchanged — **the graph is an
accelerator, never a dependency.** Two things always go to grep: the error messages, log lines and
displayed strings a bug report is usually written in, since the graph indexes structure rather than
string contents; and dynamic boundaries, where an empty graph result is indistinguishable from "nothing
calls this" and so is still marked "cần xác minh".

If the real fault is a stale or contradictory spec it edits no code and routes to `open-questions.md`.
It never green-washes: no weakened assertions, no skips, no `noqa`/`@ts-ignore` to hide the failure.
Generated code carries no comments and no invented identifier codes. Output also includes
`bug-fix-<slug>.md` (`> Review: PENDING`).
