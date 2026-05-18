<!--
Customize for your project — find/replace these tokens after copying:
  <BASE_BRANCH>   your integration branch (e.g. main, development, develop)
-->

Stage, commit, and push changes to a new branch based on `origin/<BASE_BRANCH>`.

## Arguments

This command accepts a **branch name** as `$ARGUMENTS`. Example: `/commit bug/207-fix-disappearing-flow-lines`

## Steps

1. **Validate the branch name.** If `$ARGUMENTS` is empty or blank, ask the user to provide a branch name and stop. Do NOT proceed without one.

2. **Fetch the latest `<BASE_BRANCH>` from origin:**
   ```
   git fetch origin <BASE_BRANCH>
   ```

3. **Check for staged/unstaged changes.** Run `git status` and `git diff` (both staged and unstaged) to understand what will be committed. If there are NO changes to commit (no modified, added, or deleted tracked files), inform the user and stop.

4. **Create the branch from `origin/<BASE_BRANCH>`:**
   ```
   git checkout -b $ARGUMENTS origin/<BASE_BRANCH>
   ```
   If the branch already exists locally, inform the user and ask whether to switch to it or abort.

5. **Verify the changes carried over.** Run `git status` on the new branch to confirm the working tree changes are present. Show the user a summary of what will be committed.

6. **Stage the relevant files.** Only stage files that are related to the work — do NOT stage untracked files that look unrelated (test artifacts, temporary files, `.env` files, credentials, etc.). When in doubt, ask the user which files to include.

7. **Draft a commit message** by analyzing the staged diff:
   - Follow conventional commits format (`fix:`, `feat:`, `refactor:`, `docs:`, `chore:`, etc.)
   - Keep the subject line under 72 characters
   - Add a body explaining the "why" if the change is non-trivial
   - Use a HEREDOC to pass the message:
     ```
     git commit -m "$(cat <<'EOF'
     fix: short description

     Longer explanation if needed.
     EOF
     )"
     ```

8. **Push the branch to origin:**
   ```
   git push -u origin $ARGUMENTS
   ```

9. **Report success** with the branch name and a summary of what was committed.
