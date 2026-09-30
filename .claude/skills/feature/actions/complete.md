# Complete Action

1. Stage and commit remaining changes on the feature branch. Split in several commits if it is needed.
2. Push the branch and open a PR into main (`gh pr create`). Wait for the `build-and-test` check to go green (`gh pr checks --watch`). If it fails, stop and fix. Nothing is marked completed yet.
3. Reset current-feature.md on the feature branch:
   - Change H1 back to `# Current Feature`
   - Clear Goals and Notes sections (keep placeholder comments)
   - Add feature summary to the END of History
4. Commit the reset: `chore: reset current-feature.md after completing [feature]`, push, and wait for CI to go green again
5. Merge the PR on GitHub (`gh pr merge --merge --delete-branch`), which also deletes the remote branch
6. Switch to main, pull, and delete the local feature branch
