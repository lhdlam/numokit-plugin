---
name: "numokit:spec-sync"
description: Detect where the code has drifted from the spec documents — in both directions — and report each finding with citations from both sides for a human to adjudicate. Read-only.
category: Development
tags: [numokit, spec, drift, docs, audit]
---

Invoke the `spec-sync` skill using the Skill tool, passing the scope the user gave (a module,
directory or feature). With no argument it asks for a scope rather than sweeping the whole system,
since an unreadably large report helps nobody.

The skill extracts the behaviours the documents mandate and the behaviours the code actually
implements, then compares them **both ways** — docs→code misses unimplemented requirements, code→docs
misses undocumented "ghost features". Every finding carries a reference from each side
(`[SRS §4.2]` ↔ `[app/auth.ts:31]`) and is classified: docs ≠ code, docs-only, code-only, or
ambiguous docs.

With the **codebase-memory** MCP it reads the code side through the knowledge graph —
`get_architecture` for the shape of the scope, then `search_graph` and `get_code_snippet` per symbol,
with `check_index_coverage` before any citation. Without it, nothing changes: **the graph is an
accelerator, never a dependency.**

The code→docs direction is where trusting the graph alone would hurt most. Ghost features attached to
Qt signals, route strings, i18n keys or a DI container do not appear in the graph at all, so a scope
containing them is grepped as well and the finding marked "cần xác minh". Every code-side citation
records whether it came from the graph or from grep.

It never decides which side is right and never edits either one — that adjudication belongs to a
human. Output is `spec-drift.md` (`> Review: PENDING`), with every High finding also recorded in
`open-questions.md` so it does not get lost.
