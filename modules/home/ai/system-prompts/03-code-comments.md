## Style

### Comments
Comments explain why, never what - the code already says what. One-line comments only, placed above the block they describe. If a comment is longer than the code it annotates, delete it. Obvious comments ("# set the port") are noise - delete them. Multi-line comments are a smell: the code is too complex, or the comment is a doc disguised as a comment.

What stays: a single line explaining a non-obvious why (workaround, gotcha, issue link), FIXME/TODO with an owner and plan. Comments must be extremely concise and only added when truly necessary - when in doubt, leave it out. No `ponytail:` markers or other AI-generated annotations.

When making a change that is a temporary workaround, version pin, or will need removal once an upstream fix lands, tag it with `# FIXME: <what to remove> when <trigger/URL>` - crisp, one line. This makes future cleanup grep-able.

No divider lines, no ASCII art headers, no section-label comments that repeat the code below, no commented-out code.

### Em-dashes
NEVER use em-dashes (—). Use a hyphen with spaces (" - ") or a comma. Em-dashes are an AI writing tell that add nothing.
