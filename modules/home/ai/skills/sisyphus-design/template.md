# Design Document Template

Every design document follows the sections below in this order. Do not add top-level sections. Appendices for supplementary material (diagrams, schemas) are allowed.

## Meta

- **Consumer**: who implements from this design
- **Scope**: itemized list of what this covers
- **Out of scope**: what this explicitly excludes
- **Detail level**: what this specifies vs. what it leaves open (default: component-level behavior)

## Context

What problem is being solved. Every sentence traces to a specific input requirement.

The critical path: which component or decision must be correct above all else, and why.

If the standard approach is insufficient: what is specific about this problem that requires a different approach.

Constraints discovered during research.

## Decision Log

| # | Decision | Choice | Alternative | What's Lost |
|---|----------|--------|-------------|-------------|

Critical path decisions get expanded blocks:

**D[n]: [Decision Name]**
- Options compared, with concrete examples
- Why this option wins - traced to an input requirement

## Design

One subsection per component:

**[Component Name]**
- **Responsibility**: one sentence
- **Behavior**: what happens (not how)
- **Interfaces**: what it takes in and produces, and for whom (omit if not meaningful)
- **Edge cases**: what happens when things go wrong

Then an **Interactions** subsection:

- Critical path flow: what calls what, in what order, with what data
- One concrete example traced end-to-end with state before and after each step
- Additional examples if one cannot exercise all components

## Known Limitations

For each limitation:
- The limitation
- Whether mitigations were explored, and if so, why they were rejected
- Why the limitation is accepted

Omit this section if no limitations exist.
