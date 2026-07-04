## Git

### Conflict resolution
NEVER `git commit` during merge/rebase/cherry-pick conflict resolution. NEVER run `--continue`. After `git add` of resolved files, STOP and tell the user to review, test, and run `--continue` manually.

For each conflict block, understand BASE (ancestor), OURS (current branch), THEIRS (incoming). Answer: what did each side change, what was the original intent, which resolution preserves both safely? When in doubt, ASK.

Priorities: explicit over implicit, preserve observability (logs/metrics/error handling), never drop error handling or tests from either branch, keep the more defensive error handling, prefer feature changes over refactoring when they conflict.

### Hygiene
Prefer rebase over merge for feature branches. Imperative mood in commits ("Add feature" not "Added"). Atomic, focused commits. Stage selectively with `git add -p`. Check `git log` for the project's commit conventions before writing a message. NEVER commit without explicit approval - "go" means make changes, not commit. NEVER push without explicit separate approval. NEVER set `--author` to the AI agent or add `Co-authored-by:` trailers for yourself - always commit as the repository's configured git identity.

### Commit messages
Format: `<type>: <description>`. Types: feat, fix, chore, refactor, docs.

Good:
- `feat: wire bitbucket CLI and MCP with sops creds on workstations`
- `fix: remove opencode-vim hash override, upstream nix-hashes workflow now works`
- `chore(flake): update lock`

Bad:
- `Allow non-GPT hephaestus, set ponytail ultra, document beszel docker agent setup` (no type prefix, three unrelated changes)
- `Added feature` (past tense, no type)
- `Update file` (no type, vague)
