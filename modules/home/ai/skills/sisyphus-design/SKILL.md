---
name: sisyphus-design
description: Produce high-quality design documents through research, divergent thinking, and iterative refinement
disable-model-invocation: true
source: "https://github.com/arkbriar/sisyphus-design (ported to omp: ask/task tools)"
---

# Design Skill

Design requirement: from the user arguments passed with this invocation.

If no arguments provided, use ask to ask for the design requirement before proceeding.

Read before starting:
- [template.md](template.md) - document structure for drafting
- [checklist.md](checklist.md) - evaluation criteria for review

## Phase 0: Research & Diverge (no human)

For trivial requirements (single flag, simple rename, obvious-one-solution), skip Phase 0 and Phase 1 - go directly to Phase 2. Present a single approach and identify the consumer as part of the decision presentation.

1. Investigate: spawn a fresh research agent (task tool). It receives the design requirement and returns a structured summary: existing patterns found, constraints discovered, relevant prior art. Use web search whenever the domain is unfamiliar, prior art may exist, or something is unclear. Keep the main context clean - only bring back the summary.
2. Think from first principles: what is this system fundamentally trying to do? What are the core constraints? Strip away conventional framing and reason from the ground up.
3. Identify the critical path: the component or decision that, if wrong, makes the system fail regardless of how good everything else is.
4. Generate 2-3 fundamentally different approaches that diverge on the critical path. Reuse obvious choices elsewhere.
5. For each approach: one-sentence core idea, key trade-off, when it fails.

## Phase 1: Interrogate (human)

Use ask to present concisely:
1. **Consumer**: who implements from this design. Their first unanswered question.
2. **Critical path**: the component or decision from Phase 0. Why this is the critical path.
3. **Approaches**: the 2-3 from Phase 0 with trade-offs.
4. **Recommended approach**: which one and why, based on the analysis.
5. **Discriminating questions**: only questions whose answer would change the recommendation.

Wait for answers. User confirms, redirects, or asks follow-ups.

## Phase 2: Decisions (human)

1. Present the decisions as conversation text per the Decision Log format in [template.md](template.md), including expanded blocks for critical path decisions and the end-to-end example trace (what data enters, what choices apply, what comes out - component-level state detail comes in Phase 3).
2. Use ask to collect feedback - approve, reject, or comment. Keep the question short; do not repeat the decisions.
3. Revise if rejected. All open questions must be answered before proceeding. If the user or the decisions reveal the requirement is more complex than initially assessed (especially if the trivial shortcut was used), return to Phase 0 for proper research.

## Phase 3: Draft & Refine (no human)

1. Draft the design using [template.md](template.md). Write to `design/<name>.md`. Derive `<name>` as `YYYY-MM-DD-<topic>` (e.g., `2026-03-19-auth`). If that file already exists, append `-2`, `-3`, etc. Where the input is ambiguous, state the ambiguity and chosen interpretation in the design. Carry the Phase 2 example trace into the Interactions section, updating it to match final component names.
2. Self-check against [checklist.md](checklist.md), skipping procedure step 0b (baseline sketch - the author cannot objectively evaluate their own design against a baseline). Fix all issues found.
3. Spawn a fresh evaluator agent (task tool). The agent must:
  - Have NO context about the design's history, decisions, or prior findings
  - Read the design file and [checklist.md](checklist.md)
  - Read the original design requirement and the Phase 0 research summary (pass both in the agent prompt). The approved decision log is already in the design file's Decision Log section.
  - Output findings per checklist format
4. Fix root cause clusters first. Then do a nit pass on remaining SPECIFY/ACKNOWLEDGE findings - a pile of small issues is still a quality problem.
5. Convergence check - open a finding ledger for this refinement loop:
  - Each finding = question number + concepts touched + concrete gap description
  - Two findings match if same question and same concepts
  - Track resolved vs new findings each cycle
  - Stop if: 0 REDESIGN FAILs, or 3 evaluator cycles reached
  - Otherwise: loop back to step 3
  - At stop: outstanding REDESIGN FAILs become Known Limitations in the design.
6. Present the design file to the user.

## Phase 4: Review (human)

User reads the design file and provides comments.

## Phase 5: Refine from Comments (no human)

Open a new finding ledger. Same loop as Phase 3, seeded with human comments as mandatory fixes.
Human comments override evaluator findings when they concern the same component or concept.

## Phase 6: Deliver

Present:
- Path to the final design file
- Change summary: redesigns made, recurring fixes, novel FAILs remaining
- Finding summary from the most recent non-empty refinement loop
- Q17 FLAGs as known uncertainties

## Rules

- Phases execute in order. No skipping unless the trivial-requirement shortcut applies.
- Never add a component to fix a finding unless the finding traces to a specific input requirement or an approved decision. If it does not, add to out-of-scope or acknowledge in Known Limitations.
- Never mitigate environmental limitations with mechanism. Acknowledge in prose.
- After decisions are approved, the design must be directive. No hedging, no presenting unchosen alternatives as viable options. The consumer implements from this - tell them what to build, not what you considered.
- All design content goes in the file, not conversation output.
- Research agents: spawn a fresh agent whenever investigation is needed. Keep research results out of the main design context - only bring back the summary.
- All spawned agents (research, evaluator) MUST explicitly use the current model. Do not let the runtime downgrade.
