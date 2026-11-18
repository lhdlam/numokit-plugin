---
name: "numokit:impact"
description: Measure the blast radius of a code change — which modules, public APIs, schema, shared code, tests and docs it reaches, each rated with a real citation. Read-only.
category: Development
tags: [numokit, impact, blast-radius, analysis]
---

Invoke the `impact` skill using the Skill tool, passing what the user named — a git branch/tag, a
file or function path, or a description of an intended change. With no argument it measures the
working tree diff.

The skill is read-only. It builds a seed set of the symbols whose behaviour actually changes
(`file:line`), walks callers outward layer by layer and says explicitly where it stopped and why,
then rates six buckets — modules/files, public API contracts, schema/data, shared code, existing
tests, docs/spec — High/Medium/Low. Reach through dynamic boundaries (DI, reflection, event buses,
route strings) is flagged "cần xác minh" rather than claimed safe, and severity is never softened.

When the session has the **codebase-memory** MCP it walks that outward reach through the knowledge
graph — `search_graph` to locate each seed symbol, `trace_path` to follow real call relationships layer
by layer rather than grepping for matching names, `get_architecture` for shared code — and checks
`check_index_coverage` on every path before citing it. Without the graph, or where the index does not
reach, it greps exactly as before: **the graph is an accelerator, never a dependency.**

The one thing it refuses to trust is an empty graph result at a dynamic boundary (Qt signal/slot, DI,
`getattr`, i18n keys, route strings). The graph cannot see those edges, so "nothing found" there looks
identical to "nothing calls this" — it greps anyway and still marks the area "cần xác minh". Every
citation records whether it came from the graph or from grep.

It closes with a direct verdict: does this break compatibility, does it need a data migration, what
is the single highest risk, and which areas a human must confirm. Output is `impact-<slug>.md`
(`> Review: PENDING`). It changes no code — use `/numokit:fixbug` or `/numokit:refactor` for that.
