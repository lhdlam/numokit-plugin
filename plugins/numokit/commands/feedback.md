---
name: "numokit:feedback"
description: Take the customer's review comments on a PR, judge each one, fix what needs fixing behind a human gate, verify, then draft a short bilingual (English/Japanese) reply answering every comment — including those deliberately not changed. Never posts without approval.
category: Development
tags: [numokit, feedback, review, pull-request, bilingual, github]
---

Invoke the `address-feedback` skill using the Skill tool, passing the pull request URL the user gave
(or `owner/repo#number`). No argument → ask for it.

This is the other half of `/numokit:review-pr`: that one sends a review out, this one takes the
customer's review back in, acts on it, and answers.

The skill collects **both** the overall review comments and the inline per-line ones — missing the
inline set loses most of the technical feedback — then splits any comment carrying several points
into separate items, since a merged item gets a half answer.

**Feedback is input to judge, not an order to execute.** Each item is classified on its merits: fix
it, explain it (when the customer has misread the code, the reply explains with evidence and the code
is left alone), ask for clarification, flag that it conflicts with the spec or with something the
customer already signed off, or suggest a separate ticket. Anything touching data loss, auth or
permissions stops for the user outright. Following a mistaken request politely still damages the
product.

It then **stops at a human gate** with the full classification table before editing anything; the user
can reclassify any item. After approval it fixes each approved point as a separate change, runs the
tests, and reports what actually passed — an item it could not verify is never written up as "Fixed".

The reply is a short bilingual comment, English then 日本語, written **for the customer**: business
keigo, and particular care where the answer is a polite disagreement. **Every comment gets a status**
— Fixed / 修正済み, Kept as is / 現状維持, Question / ご確認依頼, Needs your decision / ご判断依頼,
Suggest separate ticket / 別チケットのご提案 — because silently skipping one reads as being ignored.

**It never posts on its own.** The draft is shown for approval alongside internal notes (test results,
unverified items); only an explicit go-ahead runs `gh pr comment`. A draft is saved either way.
