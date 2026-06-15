## Git Hygiene

### Commit Practices
- Prefer `git rebase` over `git merge` for feature branches
- Write commit messages in imperative mood: "Add feature" not "Added feature"
- Keep commits focused and atomic
- Use `git add -p` to stage changes selectively
- **Follow the project's established commit conventions** — always check `git log` for the specific project's standards before writing a commit message
- **NEVER commit anything without explicit user approval** — even if changes look trivial, always ask "should I commit?" first

### Workflow
- Pull with rebase: `pull.rebase = true`
- Use diff3 conflict style for clearer merges
- Enable rerere to remember conflict resolutions
