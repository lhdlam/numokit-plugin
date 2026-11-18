---
name: "numokit:refactor"
description: Refactor with a safety net — measure the blast radius, pin current behaviour with characterisation tests, stop at a human gate, then transform in small steps that are verified one at a time. Behaviour must not change.
category: Development
tags: [numokit, refactor, safety, characterisation-test]
---

Invoke the `refactor` skill using the Skill tool, passing the refactoring goal the user gave. No
argument, or a vague goal like "make it cleaner" → ask for something concrete rather than inventing a
definition of done.

The skill holds one line firmly: **refactor means observable behaviour does not change.** If
behaviour has to change that is a feature change and belongs in `/numokit:plan`.

It measures the blast radius (calling out any public API contract it touches), then builds the safety
net — listing the tests that already cover the area and writing characterisation tests for the gaps,
which pin what the system does today even where that looks wrong. It refuses to start on a suite that
is already red. **It then stops at a human gate**, presenting the goal, the blast radius, what the net
covers and — stated plainly — what it still cannot cover.

With the **codebase-memory** MCP both halves get faster: `search_graph` and `trace_path` for the blast
radius, and `trace_path` backwards from the symbol to find which tests actually cover it, which beats
guessing from test filenames. Without the graph it works exactly as before — **an accelerator, never a
dependency.** One result it will not take at face value is the graph reporting *no* test coverage:
tests reached through fixtures, parametrization or dynamic names are invisible to it, so a claimed gap
is grepped before any characterisation test is written on the strength of it.

After approval it applies one transformation at a time, running the net after each; a red step is
reverted rather than patched over. Bugs noticed along the way are recorded, never fixed inline, so the
diff stays reviewable. Output is `refactor-<slug>.md` (`> Review: PENDING`).
