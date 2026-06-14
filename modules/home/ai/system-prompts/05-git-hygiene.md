## Git Hygiene

### Commit Practices
- Prefer `git rebase` over `git merge` for feature branches
- Write commit messages in imperative mood: "Add feature" not "Added feature"
- Keep commits focused and atomic
- Use `git add -p` to stage changes selectively

### Workflow
- Pull with rebase: `pull.rebase = true`
- Use diff3 conflict style for clearer merges
- Enable rerere to remember conflict resolutions
