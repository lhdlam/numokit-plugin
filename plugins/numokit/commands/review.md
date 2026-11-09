---
name: "numokit:review"
description: Review code that was just written against what the customer asked for — a verdict per requirement (Đạt | Thiếu | Lệch | Thừa | Không kiểm được), each backed by a citation from both the requirement and the code. Read-only.
category: Development
tags: [numokit, review, requirements, acceptance, self-check]
---

Invoke the `review-requirements` skill using the Skill tool, passing the code scope the user named —
a branch/tag, a PR number, or nothing (which reviews the working tree diff).

The skill answers one question: **did the code that was just written do what the customer asked?**
It is read-only — a report, not an editing session.

It first finds the requirements in a **real source**, preferring an APPROVED `plan-<slug>.md` (its
scope was already agreed), then requirement documents, then a description the user pastes in. With no
source it stops and asks rather than reviewing against nothing — and it never infers requirements from
the code under review, which would make every change pass by construction.

Each requirement then gets a verdict backed by **both sides** — the requirement's source and a
`file:line`:

- **Đạt** — implemented, with the exact line shown. This is the hardest verdict to earn, not the
  easiest: "looks fine" is Không kiểm được.
- **Thiếu** — not implemented.
- **Lệch** — implemented differently from what was asked.
- **Thừa** — code doing things no requirement mentions (scope creep).
- **Không kiểm được** — not enough source to judge, and what is missing is named.

**It never softens a requirement to match the code.** If a requirement itself looks wrong or stale it
is still scored as written, and the doubt is raised separately for a human to settle.

It also sweeps the diff for clean-code violations, error paths left unhandled, unannounced breaking
changes, and missing tests. Output is `review-<slug>.md` (`> Review: PENDING`). Fixing anything is a
separate, gated step: `/numokit:fixbug` or implementing the rest.
