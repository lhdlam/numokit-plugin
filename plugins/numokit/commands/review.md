---
name: "numokit:review"
description: Review code that was just written against what the customer asked for — scored twice, once by this agent and once by an independent peer-review subagent that never sees the first verdicts, with every disagreement flagged for a human. A verdict per requirement (Đạt | Thiếu | Lệch | Thừa | Không kiểm được), each backed by a citation from both the requirement and the code. Read-only.
category: Development
tags: [numokit, review, requirements, acceptance, peer-review, self-check]
---

Invoke the `review-requirements` skill using the Skill tool, passing the code scope the user named —
a branch/tag, a PR number, or nothing (which reviews the working tree diff).

The skill answers one question: **did the code that was just written do what the customer asked?**
It is read-only — a report, not an editing session.

**It scores every requirement twice.** An agent that just wrote the code knows what it *meant* to
build, so it reads the diff through that intention and sees requirements met that are not. So the skill
also runs the `requirement-reviewer` subagent, which never sees the first set of verdicts and reads the
diff itself. The subagent is launched **right after the requirement list exists and before any verdict
is formed** — both so the brief cannot carry a conclusion, and so it works in parallel rather than
adding wall-clock time. Duplicating the work here is the point, not waste.

Neither reading wins a disagreement: the skill takes the **more conservative** verdict
(`Đạt < Không kiểm được < Lệch/Thiếu`), marks the requirement as disputed, records what each side
said with its evidence, and puts those items in front of the human first — two independent readings
reaching different conclusions is the strongest available signal that the spot is genuinely ambiguous.
Agreement is reported as lower risk, never as a guarantee. Anything the peer caught and the first pass
missed is folded in with the credit stated. `--no-peer` skips it, and the report then says so, because
a reader needs to know the result rests on a single reading.

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
