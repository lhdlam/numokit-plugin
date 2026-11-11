---
name: "numokit:publish"
description: Publish finished numokit artifacts to the team's shared Obsidian vault — frontmatter for filtering, wikilinks between the artifacts of one PR, unapproved drafts quarantined under _draft with a banner, and a regenerated project index. One-way, and never without confirmation.
category: Development
tags: [numokit, obsidian, vault, documentation, publish]
---

Invoke the `publish-vault` skill using the Skill tool, passing the scope the user gave (a kind such as
`plan`, a filename, or a glob). No argument → publish everything under `$NUMOKIT_ROOT`.

numokit artifacts are written locally, where only the person who ran the command can see them. This
command pushes the finished ones to a **shared Obsidian vault** so the rest of the team can read them.

**One-way.** The vault is the published copy, never the working copy. The skill only writes outward and
never reads back, so anything edited directly in the vault is overwritten on the next publish — the
skill says so in its report, and the team needs to hear it.

**It does not guess who the customer is.** The destination is `<customer>/<project>/`, read from
`.numokit-vault` in the repo root or asked for. That top folder is also where the drive's own
permissions sit, so filing an artifact under the wrong customer leaks one customer's documents to
another; the skill asks rather than infers.

Before anything is copied it **scans every artifact for secrets**, connection strings, absolute paths
from someone's machine, and personal data. Anything it finds is reported with `file:line` and that
artifact is **held back** — never silently scrubbed, since the content belongs to the user.

An artifact still marked `> Review: PENDING` is published into `_draft/` **and** carries a warning
callout, because a member reading an unreviewed judgement as a conclusion is the worst failure this
command has. Approved artifacts go to the normal folders.

It then **stops and shows the full table** — what goes where, what would be overwritten, what is held
back and why, and which vault files are now orphaned (it never deletes from a shared store). Only an
explicit go-ahead writes anything.

Each published copy gains YAML frontmatter (customer, project, kind, status, PR, source, published
date) so Obsidian can filter and sort, plus wikilinks to the other artifacts of the same PR. The
`published` date is a **deliberate exception** to the clean-code ban on date stamps: it is archive
metadata on the vault copy only, and a later run must not strip it.
