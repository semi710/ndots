# Design Checklist

Evaluate a design document against its input requirements. Do not revise - only diagnose.

## For Fresh Evaluators

You have no prior context about this design. Read the design file and the original requirements, then evaluate. The design file contains the approved Decision Log - treat those decisions as part of the input for coverage questions (Q7-Q10).

## Fix Types

- **ACKNOWLEDGE**: state a limitation - no structural change, one sentence of prose
- **SPECIFY**: add a missing behavioral detail - prose, no new components
- **REDESIGN**: change components, interactions, or state model - structural change

## Procedure

0. Before questions:
   a. Verify scope declaration exists. If missing: FAIL immediately, stop.
   b. (Evaluator only - skip during self-check.) Sketch the simplest design meeting input requirements - component names and one-line responsibilities only. Derive from the input, not from the design's scope declaration. Any mechanism in the actual design not in this baseline needs explicit justification tracing to a specific input requirement or approved decision. Flag unjustified additions.
   c. Verify scope declaration: each in-scope item must trace to a specific input requirement. Flag scope inflation.

1. For each question, find ALL failing instances - not just the first.
2. Output each finding as:
   ```
   [n] Qm FAIL | concepts: [X, Y] | description | fix: ACKNOWLEDGE/SPECIFY/REDESIGN
   ```
3. For Q17 (model disagreement), output FLAG instead of FAIL - these are inherent uncertainty, not defects.
4. Do not flag limitations already acknowledged in Known Limitations.
5. After all findings, cluster by root cause:
   ```
   ROOT CAUSE [r]: description - findings: [n1, n2, n3]
   ```
6. Output only: numbered findings list, then root cause clusters. Nothing else.

## Questions

**Consistency (output vs. output)**

Q1. Two claims or commitments that contradict each other?

Q2. Implicit dependency between parts - removing one section silently breaks another?

Q3. Priority ordering that shifts or contradicts itself?

Q4. Term or distinction that only makes sense against something absent from the output?

Q5. For every named entity, is its relationship to every entity it interacts with explicit?

Q6. For each operation, does it specify what happens - not just that it happens?

**Coverage (output vs. input)**

Q7. Input requirement not addressed?

Q8. Input constraint violated?

Q9. Assumption not stated in input? For each problem the design claims to solve, quote the specific phrase from the original requirement or approved decision log establishing it as a problem. No phrase = self-invented problem - flag it.

Q10. Where input is ambiguous, does the design acknowledge ambiguity and state which interpretation it chose?

**Attack (output vs. extreme conditions)**

Q11. Small, realistic scenario that causes the design to fail?

Q12. The single most critical assumption - if reversed, does the design still hold?

Q13. At what scale does the design break? Is that scale realistic?

**Minimality (output vs. simplicity)**

Q14. Parts removable without affecting whether the goal is met? Check every granularity level.

Q15. For each mechanism, is its problem already solved by another part, the runtime, or the environment?

Q16. For each mechanism, name the simplest alternative (including "do nothing" and "defer to the environment"). If the design does not discuss why it chose this mechanism over the simpler one, fail it.

**Boundary (output vs. limits)**

Q17. Judgment where a differently-prompted model might reasonably disagree?

Q18. Common domain failure mode not addressed? Only check within declared scope. If explicitly out-of-scope, do not flag.

**Scope (output vs. input intent)**

Q19. Feature, capability, or requirement the input did not ask for or directly imply? What specific input phrase justifies each? (If already flagged under Q9 or procedure step 0c, do not duplicate - report under the more specific question.)
