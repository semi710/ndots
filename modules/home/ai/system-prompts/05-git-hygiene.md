## Git Hygiene

### Commit Practices
- Prefer `git rebase` over `git merge` for feature branches
- Write commit messages in imperative mood: "Add feature" not "Added feature"
- Keep commits focused and atomic
- Use `git add -p` to stage changes selectively
- **Follow the project's established commit conventions** - always check `git log` for the specific project's standards before writing a commit message
- **NEVER commit anything without explicit user approval** - "go" means approval to make changes, NOT to commit. Always ask "should I commit?" separately
- **NEVER push to remote without explicit user approval** - committing locally does NOT imply permission to push. Always ask "should I push to [remote]?" separately

### Workflow
- Pull with rebase: `pull.rebase = true`
- Use diff3 conflict style for clearer merges
- Enable rerere to remember conflict resolutions
