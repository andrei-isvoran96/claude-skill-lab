<!--
Customize for your project — find/replace these tokens after copying:
  <HANDOFF_DIR>   directory under .claude/ where handoff briefs live (default: .claude/handoffs)
                  if you keep the default, no edits needed
-->

Write a structured handoff brief from the **current session** to a file, then print the exact one-liner the user can paste into a fresh `claude` session to continue the work without re-loading the whole conversation. Use this when the context window is filling up but the work isn't done.

## Arguments

This command accepts an **optional short slug** as `$ARGUMENTS` to name the handoff. Examples:
- `/handoff` — uses a timestamp slug
- `/handoff auth-refactor` — uses `auth-refactor` as the slug (so multiple in-flight handoffs can coexist)

The slug is sanitized (lowercase, non-alphanumeric → `-`, truncated to 40 chars).

## Steps

1. **Build the slug and target path.**
   - If `$ARGUMENTS` is empty, slug = current UTC timestamp in `YYYYMMDD-HHMM` form.
   - Otherwise, sanitize `$ARGUMENTS`: lowercase, replace any run of non-alphanumeric chars with `-`, trim leading/trailing `-`, truncate to 40 chars.
   - Target file: `<HANDOFF_DIR>/<slug>.md` (default `.claude/handoffs/<slug>.md`).
   - Also maintain a stable pointer at `<HANDOFF_DIR>/latest.md` (overwrite each run) so the resume one-liner is the same every time.
   - `mkdir -p <HANDOFF_DIR>` if needed.

2. **Capture the operational state of the working tree.** Run these in parallel:
   ```
   git status --short
   git diff --stat
   git log --oneline -5
   git branch --show-current
   ```
   You'll reference these in the brief so the fresh session knows what's modified, what's committed, and where it sits.

3. **Draft the brief.** It must be short enough to be cheap to load into a fresh context, complete enough that the new session doesn't need to ask "what was I doing?". Use this exact skeleton — fill every section, write `(none)` if a section genuinely doesn't apply:

   ```markdown
   # Handoff — <slug>

   *Written <UTC timestamp> from session on branch `<branch>`.*

   ## Goal
   <1–2 sentences: what is the user ultimately trying to accomplish in this thread of work? Not "what we did in this session" — the underlying objective.>

   ## Current state
   - <bullet per concrete change made or decision taken so far>
   - <include file paths the user has touched, e.g. `src/auth/middleware.ts:42`>

   ## Working tree
   ```
   <paste the `git status --short` output verbatim>
   ```
   Branch: `<current branch>`. Recent commits:
   ```
   <paste the `git log --oneline -5` output>
   ```

   ## Where we left off
   <1–3 sentences: the immediate next step. Be specific — "add the failing-case test for X in path/to/test.ts" beats "continue with tests".>

   ## Key context the fresh session needs
   - <non-obvious facts discovered this session: hidden constraints, API quirks, broken assumptions corrected>
   - <decisions already made and *why* — so the new session doesn't relitigate them>

   ## Already tried, don't repeat
   - <approaches that looked promising but failed, with one-line reason — so the new session doesn't burn context rediscovering>

   ## Open questions for the user
   - <things the user needs to weigh in on before fresh Claude can proceed; if none, write `(none)`>
   ```

4. **Write the brief** to both `<HANDOFF_DIR>/<slug>.md` and `<HANDOFF_DIR>/latest.md` (identical content; `latest.md` is just the stable-name copy).

5. **Warn about uncommitted state.** If `git status --short` shows any unstaged or untracked files that aren't covered in the brief's "Working tree" section, mention them explicitly in the final reply so the user knows their WIP only exists on disk (not in any commit) and won't be carried by `git` into a new clone.

6. **Print the resume one-liner.** The reply ends with the exact command the user runs in a **new terminal** (after `/exit` or in a separate tab):

   ```
   claude "Read <HANDOFF_DIR>/latest.md and continue from the 'Where we left off' section. Confirm you've read it before taking any action."
   ```

   If the user passed a slug, also show the slug-specific variant in case they want to resume a non-latest handoff later:
   ```
   claude "Read <HANDOFF_DIR>/<slug>.md and continue from the 'Where we left off' section. Confirm you've read it before taking any action."
   ```

## Reply format

Three lines plus the one-liner. No more.

```
✓ handoff written: <HANDOFF_DIR>/<slug>.md (<N> lines)
  branch: <branch>  |  WIP: <N modified, N untracked>  (or "WIP: clean")

Resume in a new terminal with:
  claude "Read <HANDOFF_DIR>/latest.md and continue from the 'Where we left off' section. Confirm you've read it before taking any action."
```

On failure (can't write file, not in a git repo, etc.), report the error in one line and stop.

## Notes

- This command does NOT exit the current session, kill processes, or commit anything. It only writes a file and prints a command. The user decides when to actually switch sessions.
- The brief is for **the next Claude session**, not for the user to read. Write it accordingly: dense, factual, no narrative flourishes, no "we" or "I" — third-person task description.
- Do NOT include the entire conversation transcript in the brief — that defeats the purpose. The brief is a *distillation*. If you find yourself writing more than ~80 lines, you're including too much.
- Add `<HANDOFF_DIR>/` to `.gitignore` if the briefs shouldn't be shared with the team. (They usually shouldn't — they're scratch notes between sessions.)
