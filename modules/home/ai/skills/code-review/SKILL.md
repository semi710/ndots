---
name: code-review
description: Reviews the diff between HEAD and a fixed point you name along two independent axes - Standards (repo conventions) and Spec (what the issue asked for) - and posts findings as draft-only Bitbucket comments visible to you until you publish. Use when reviewing a branch, a PR, work in progress, or anything since X.
type: skill
---

# Code Review

Reviews `git diff <fixed-point>...HEAD` along two axes that are never
merged and never re-ranked. A change can pass one axis and fail the
other: convention-perfect code implementing the wrong thing passes
Standards and fails Spec; exactly-what-the-ticket-asked code that
breaks conventions does the reverse. A blended verdict lets the
passing axis hide the failing one.

Do not invoke `/code-review` again or spawn additional agents: perform
this review directly.

## Starting rules

1. Require a fixed point (commit, branch, tag, `main`, `HEAD~5`). If
   none is given, ask for one rather than guessing.
2. Verify the ref resolves and the diff is non-empty before reviewing
   anything, so a typo'd branch name fails in front of the user.
3. The diff is three-dot `<fixed-point>...HEAD` from the merge-base.
   Staged and working-tree changes are invisible: commit first, then
   review, then amend or add a fixup.
4. Run the two axes as separate passes. Complete one axis fully before
   starting the other; do not let one axis's findings shape the other.

## Standards axis - is it built right?

- Primary source is the repo's own documentation: `CODING_STANDARDS.md`,
  `CONTRIBUTING.md`, `docs/`, `AGENTS.md`. **The repo always overrides**
  the baseline below.
- The smell baseline is the floor: twelve Fowler code smells from
  *Refactoring* ch.3, each a labelled judgement call ("possible Feature
  Envy"), never a hard violation, each stated as what it is -> how to
  fix: Mysterious Name, Duplicated Code, Feature Envy, Data Clumps,
  Primitive Obsession, Repeated Switches, Shotgun Surgery, Divergent
  Change, Speculative Generality, Message Chains, Middle Man, Refused
  Bequest.
- Skip anything a linter/formatter in this repo already enforces.
- Every finding cites the standards file and the rule, or the named
  smell plus the quoted hunk.

## Spec axis - is the right thing built?

Find the spec in this order:

1. Issue references in the commit messages (`#123`, `Closes #45`,
   GitLab `!67`), fetched through the repo's issue tracker.
2. A spec path the user passes as an argument.
3. A spec file under `docs/`, `specs/`, or `.scratch/` matching the
   branch or feature name.
4. Ask the user.

With no spec at all, skip this axis and report "no spec available" -
never invent requirements from the code. Findings report missing or
partial requirements, scope creep, and requirements implemented
wrongly, each quoting the spec line it checks against.

## Reporting

- Two separate blocks, `## Standards` and `## Spec` - never one merged
  list.
- Close with the worst issue per axis and refuse to name a single
  overall winner.
- Findings are leads, not verdicts: cite before acting, and do not
  re-run this skill in a loop until clean - it will not converge.

## Posting to Bitbucket - drafts only

When the diff belongs to a Bitbucket PR, every comment this skill
creates MUST be a draft visible only to the user, never a published
one. The user vets the findings and makes them visible themselves.

- Inline findings: `bitbucket_add_comment_inline` with
  `state: "PENDING"`, attached to the cited file and line
  (`lineType: "ADDED"` unless the hunk is a removal).
- Summary (the two report blocks plus the worst-issue-per-axis
  closing): `bitbucket_add_comment` with `state: "PENDING"`.
- Never set `state: "OPEN"` and never call `bitbucket_publish_review`,
  `bitbucket_approve_pull_request`, or `bitbucket_merge_pull_request`.
- End the report by telling the user: findings are saved as drafts -
  review them, then publish with `bitbucket_publish_review` (optionally
  with `APPROVED` or `NEEDS_WORK`) when you want them visible to
  everyone.
