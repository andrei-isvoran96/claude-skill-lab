<!--
Customize for your project — find/replace these tokens after copying:
  <BASE_BRANCH>   your integration branch (e.g. main, development, develop)
-->

Pick up a GitHub issue: fetch its title/body/labels, create a properly-named branch from `origin/<BASE_BRANCH>`, check it out, and surface the issue body as context.

## Arguments

This command accepts a GitHub issue **number** as `$ARGUMENTS`. Example: `/issue 207`

## Steps

1. **Validate the argument.** If `$ARGUMENTS` is empty, not a positive integer, or contains anything other than digits, ask the user to pass a numeric issue number and stop. Do NOT call `gh` with bogus input.

2. **Fetch the issue.** Run a single `gh` call to pull everything you need:
   ```
   gh issue view $ARGUMENTS --json number,title,body,labels,state,url
   ```
   If `gh` errors (issue doesn't exist, repo not configured, not authenticated), surface the error verbatim and stop.

3. **Refuse to work on a closed issue.** If `state` is `CLOSED`, warn the user, print the URL, and stop unless they explicitly say "open it anyway" — closed issues usually mean the work was already done or rejected.

4. **Pick the branch prefix from labels.**
   - If any label name (case-insensitive) contains `bug`, `fix`, or `defect` → prefix is `bug`
   - Otherwise → prefix is `feature`
   - If the labels list is empty, default to `feature` and mention this in the final report so the user can correct it if needed.

5. **Build the slug from the title.**
   - Lowercase
   - Replace any run of non-alphanumeric chars with a single `-`
   - Trim leading/trailing `-`
   - Truncate to 40 characters max, then trim trailing `-` again
   - Example: `"Fix: edges disappear when deleting branched node"` → `fix-edges-disappear-when-deleting-branche`

   The branch name is then `<prefix>/<num>-<slug>`. Example: `bug/207-fix-edges-disappear-when-deleting-branche`.

6. **Sync `<BASE_BRANCH>` and create the branch.** Run sequentially:
   ```
   git fetch origin <BASE_BRANCH>
   git checkout -b <branch-name> origin/<BASE_BRANCH>
   ```
   If the branch already exists locally:
   - If we're already on it, just `git pull --ff-only origin <BASE_BRANCH>` (best-effort, may fail if there are commits — that's fine, just report) and skip to step 7.
   - Otherwise ask the user whether to switch to it (`git checkout <branch-name>`) or abort. Do NOT delete or force-recreate the branch on your own.

7. **Print issue context.** Display the issue's title and body so the user can read the spec without leaving the terminal:
   ```
   #<num> — <title>
   labels: <comma-separated label names>
   url:    <html_url>

   <body>
   ```
   Truncate the body to ~80 lines if it's enormous; mention truncation if you do.

8. **Report success** with the branch name and a one-line "ready to work" message. Do NOT auto-start coding — the user picks the next step.

## Notes

- Never push the branch in this command. `/commit` does that.
- Never modify the issue (no `gh issue edit`, no comments). Read-only.
- Keep all `gh` and `git` output inside tool calls; the user only needs the formatted issue context and the final branch name.
