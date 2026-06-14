---
name: git-wisdom
description: Git conflict resolution protocol and wisdom for merge/rebase/cherry-pick operations
type: skill
---

# Git Wisdom

## Rules for Git Operations

### MERGE / REBASE / CHERRY-PICK — CONFLICT RESOLUTION PROTOCOL

1. **NEVER run `git commit` during active merge/rebase/cherry-pick**
2. **NEVER run `git merge --continue`, `git rebase --continue`, or `git cherry-pick --continue`**
3. After resolving conflicts and `git add <resolved-files>`, **STOP immediately**
4. Tell the user: "Conflicts resolved and staged. Please review, test, then run --continue manually."
5. The user MUST manually verify before continuing

### CONFLICT ANALYSIS REQUIREMENT

When resolving conflicts, understand THREE sides:
- **BASE**: The common ancestor commit (original state before divergence)
- **OURS**: The current branch being checked out
- **THEIRS**: The branch being merged/rebased/cherry-picked onto ours

For each conflict block, answer before resolving:
1. What semantic change was attempted in OURS?
2. What semantic change was attempted in THEIRS?
3. What was the original intent in BASE?
4. Which resolution preserves BOTH intents safely?
5. Is there a third option that supersedes both branches?

### DECISION PRIORITIES

- Prefer explicit over implicit
- Preserve observability (logs, metrics, error handling, tracing)
- Never drop error handling added in either branch
- Never drop tests added in either branch
- When in genuine doubt, ASK the user which behavior to keep
- If both branches add conflicting error handling, keep the MORE defensive one
- If refactoring and feature changes conflict, prefer preserving the feature change

### POST-RESOLUTION CHECKLIST

After staging resolved files, remind the user to:
1. Run tests (if available)
2. Review the staged diff: `git diff --cached`
3. Continue manually when satisfied

## General Git Hygiene

- Prefer `git rebase` over `git merge` for feature branches
- Write commit messages in imperative mood: "Add feature" not "Added feature"
- Keep commits focused and atomic
- Use `git add -p` to stage changes selectively
