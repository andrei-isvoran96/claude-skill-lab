<!--
Customize for your project — find/replace these tokens after copying:
  <BASE_BRANCH>   your integration branch (e.g. main, development, develop)
-->

Create a pull request from the current branch towards `origin/<BASE_BRANCH>`.

## Steps

1. **Validate the current branch.** Run `git branch --show-current`. If the current branch is `main` or `<BASE_BRANCH>`, warn the user and stop — PRs should come from feature/bug branches.

2. **Fetch latest and check remote tracking:**
   ```
   git fetch origin <BASE_BRANCH>
   ```

3. **Check if the branch is pushed to origin.** Run `git status` to see if the branch tracks a remote. If not, push it first:
   ```
   git push -u origin $(git branch --show-current)
   ```

4. **Gather context for the PR.** Run these in parallel:
   - `git log --oneline origin/<BASE_BRANCH>..HEAD` to see all commits on this branch
   - `git diff origin/<BASE_BRANCH>...HEAD --stat` to see changed files
   - `git diff origin/<BASE_BRANCH>...HEAD` (piped through `head -6000`) to see the full diff

5. **Draft the PR title and body** by analyzing ALL commits and changes (not just the latest commit):
   - **Title**: short, under 70 characters, conventional format (e.g. `fix: prevent edges disappearing when deleting branched node`)
   - **Body**: use the template below
   - If the branch name contains an issue number (e.g. `bug/207-...`), include `Fixes #207` in the body

6. **Create the PR** using `gh pr create`:
   ```
   gh pr create --base <BASE_BRANCH> --title "the title" --body "$(cat <<'EOF'
   ## Summary
   <1-3 concise bullet points describing what changed and why>

   ## Test plan
   <Bulleted checklist of manual or automated verification steps>
   EOF
   )"
   ```

7. **Report the PR URL** to the user so they can review it.
