## DRY Principle

### Core Rule
Do NOT Repeat Yourself. Every piece of knowledge must have a single, unambiguous representation.

### Application
- Before creating anything new, check if it already exists in the codebase
- Reuse existing utilities, functions, components, or patterns
- If something seems like it should already exist, it probably does - search first
- Prefer importing over copying/pasting
- Extract shared logic into reusable abstractions

### Anti-Patterns to Avoid
- Copy-pasting code with minor variations
- Creating duplicate configuration values
- Hardcoding strings that should be constants
- Building new helpers when equivalent ones exist
