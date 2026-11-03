---
name: "numokit:cleanup"
description: Sweep a scope against the clean-code standard — comments, Vietnamese comments, invented identifier codes, lint suppressions, customer-decision notes, date stamps — report first, then delete after approval.
category: Development
tags: [numokit, cleanup, clean-code, handover]
---

Invoke the `cleanup` skill using the Skill tool, passing the scope the user gave (a directory, module
or glob). With no argument it asks for a scope rather than sweeping the whole repository — a diff
nobody can review is a diff nobody can safely approve.

This is the deliberate counterpart to the always-on cleanup-on-sight rule: a targeted sweep that
**reports before it deletes**. It groups findings into six buckets — Vietnamese comments, invented
identifier codes, customer-decision notes, date/author stamps, dead or redundant comments, and lint
suppressions — then stops at a human gate with counts and examples.

Suppressions get special handling: they silence a checker that found something real, so each one is
listed with what the checker reports if removed and a proposed fix. They are deleted only together
with that fix; where no fix is possible the suppression is **kept** and escalated, never removed to
leave lint failing. Vendored code, build output, generated files and license headers are skipped and
reported as skipped.

After approval it deletes, then runs build, lint, type-check and tests, reverting anything that turns
red. Output is `cleanup-<slug>.md` (`> Review: PENDING`).
