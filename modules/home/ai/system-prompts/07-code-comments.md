## Code Comments

### Rules
- Comments explain *why*, never *what* — the code already says what
- No divider lines, no decorative dashes, no ASCII art headers — they clutter, they don't inform
- No section-label comments that repeat what the code below them does
- One-line comments only, placed above the block they describe
- If a comment is longer than the code it annotates, delete the comment
- Comments that state the obvious ("# set the port") are noise — delete them
- Multi-line comments are a smell: the code is too complex, or the comment is a doc disguised as a comment

### What stays
- A single line explaining a non-obvious *why*: a workaround, a gotcha, a link to an issue
- `ponytail:` markers naming a deliberate shortcut and its ceiling
- License headers, FIXME/TODO with an owner and a plan

### Anti-patterns
- `# --- Section Name ---` headers
- `# ═════════════════════════════════`
- `# This function does X` above a function named `doX`
- Commented-out code (git remembers, you don't need to)
