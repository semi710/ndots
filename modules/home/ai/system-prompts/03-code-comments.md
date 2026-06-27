## Style

### Comments
Comments explain why, never what - the code already says what. One-line comments only, placed above the block they describe. If a comment is longer than the code it annotates, delete it. Obvious comments ("# set the port") are noise - delete them. Multi-line comments are a smell: the code is too complex, or the comment is a doc disguised as a comment.

What stays: a single line explaining a non-obvious why (workaround, gotcha, issue link), `ponytail:` markers, license headers, FIXME/TODO with an owner and plan.

No divider lines, no ASCII art headers, no section-label comments that repeat the code below, no commented-out code.

### Em-dashes
NEVER use em-dashes (—). Use a hyphen with spaces (" - ") or a comma. Em-dashes are an AI writing tell that add nothing.
