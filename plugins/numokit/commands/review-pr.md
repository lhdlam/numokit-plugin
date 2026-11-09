---
name: "numokit:review-pr"
description: Review a pull request from its link — check what the PR says it does against what the diff actually does and against the spec, then draft a short bilingual (English/Japanese) review comment with evidence for every point. Never posts without approval.
category: Development
tags: [numokit, review, pull-request, bilingual, github]
---

Invoke the `review-pr` skill using the Skill tool, passing the pull request URL the user gave (or
`owner/repo#number`). No argument → ask for it.

The skill reads the PR with `gh`, treats the **PR's own description as the stated requirement**, and
compares it three ways: does the diff do what the PR claims, does the diff do anything the
description never mentions (undisclosed changes), and does any of it contradict the spec. It also
checks for unannounced breaking changes, missing error paths, absent tests and clean-code violations —
but only reports what it can point at.

The comment is written **for the customer to read**, not as an internal dev note — the user sends it
to the client through the PR. That shapes everything: a neutral professional register, Japanese in
business keigo (です・ます with ご確認ください and cushioning phrases, never plain form or bare
imperatives), problems raised as things to confirm rather than accusations, and **internal style nits
kept out of it** — lint, naming and missing comments are reported to the user separately, since the
client cares whether the product works and can be handed over, not about house style.

Output is a **short bilingual comment**, English then 日本語, ready to paste:

- Every point cites a `file:line` in the diff or a line of the PR description. Anything it cannot
  evidence is dropped or demoted to a **question**, never stated as a finding.
- Hard ceiling of seven points, one to two sentences each — a review nobody finishes reading is a
  review that did not happen.
- The Japanese half mirrors the English half point for point; it is a translation, not extra content.
- The comment language is **always en/jp** regardless of the `lang` setting, which governs only how
  the skill talks to the user.
- Findings are split by audience: delivery-affecting issues (undisclosed changes, spec deviations,
  unannounced breaking changes, missing tests) go in the comment; internal style issues are shown to
  the user instead. When it is unsure which side a point belongs on, it keeps it internal and asks.

**It never posts on its own.** The drafted comment is shown for approval first; only on an explicit
go-ahead does it run `gh pr comment`. Silence is not consent. A draft is saved to
`pr-review-<owner>-<repo>-<number>.md` either way.

If `gh` cannot reach the PR, it says so and stops rather than reviewing from nothing. An empty or
threadbare PR description is itself reported as a finding — there is no stated claim to verify.
