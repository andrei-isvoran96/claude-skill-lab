<!--
Customize for your project — find/replace these tokens after copying:

  <LINTER_NAME_1>, <LINTER_NAME_2>, <LINTER_NAME_3>
    Short identifiers (pint, ruff, tsc, eslint, prettier, gofmt, ...)

  <LINTER_CHECK_CMD_*>
    The check-only command. Examples:
      docker exec myapp-backend  vendor/bin/pint --test
      docker exec myapp-essentia ruff check .
      docker exec myapp-frontend npx tsc --noEmit
      npm  run lint
      cargo clippy --all-targets -- -D warnings

  <LINTER_FIX_CMD_*>
    The auto-fix variant for linters that support it; use a no-op if N/A.

  <CONTAINER_*>
    Only needed if your linters run inside Docker; otherwise drop the
    "container not running" branch in step 4.

The skeleton below assumes three linters. Add/remove rows as needed.
-->

Run all project linters in parallel and report per-lane pass/fail. Pre-commit sanity check.

## Arguments

Optional. If `$ARGUMENTS` is `--fix`, run the auto-fixers for linters that support fix mode. Otherwise run in check-only mode.

## Steps

1. **Run all linters in parallel** — issue all Bash calls in a single turn so they execute concurrently. Do NOT run them sequentially.

   **Check-only mode (default):**
   - <LINTER_NAME_1>: `<LINTER_CHECK_CMD_1>`
   - <LINTER_NAME_2>: `<LINTER_CHECK_CMD_2>`
   - <LINTER_NAME_3>: `<LINTER_CHECK_CMD_3>`

   **Fix mode (when `$ARGUMENTS` is `--fix`):**
   - <LINTER_NAME_1>: `<LINTER_FIX_CMD_1>`
   - <LINTER_NAME_2>: `<LINTER_FIX_CMD_2>`
   - <LINTER_NAME_3>: `<LINTER_FIX_CMD_3>`

2. **Capture exit codes per linter.** Each Bash call's exit status is the truth — `0` = pass, anything else = fail. Don't grep the output for "error" strings; trust the exit code.

3. **Format a compact per-lane report.** One line per linter, plus a summary. Keep raw linter output OUT of the final reply unless the linter failed — then include only the relevant error excerpts (truncate to ~10 lines per failed lane).

   **All passing:**
   ```
   ✓ <LINTER_NAME_1>   passed
   ✓ <LINTER_NAME_2>   passed
   ✓ <LINTER_NAME_3>   passed
   ✓ all linters green (3/3)
   ```

   **Some failing — show only the failing linters' output, truncated:**
   ```
   ✗ <LINTER_NAME_1>   3 style issues:
       <file>
       <file>
       <file>
   ✓ <LINTER_NAME_2>   passed
   ✗ <LINTER_NAME_3>   2 type errors:
       <file>:42:18 — Type 'string' is not assignable to type 'number'
   ✗ 2/3 failed — fix above OR re-run with `/lint --fix` for the ones that support it
   ```

   **Fix mode and the auto-fixers ran:**
   ```
   ✓ <LINTER_NAME_1>   fixed 3 files
   ✓ <LINTER_NAME_2>   fixed 2 files
   ✓ <LINTER_NAME_3>   passed
   ✓ all linters green (auto-fixes applied — review with `git diff` and stage when satisfied)
   ```

4. **Container-not-running errors.** If a `docker exec` call fails because the container isn't running (`Error response from daemon: Container ... is not running`), surface that distinctly — don't lump it in with linter failures:
   ```
   ✗ <LINTER_NAME_1>   container <CONTAINER_NAME> is not running — run /health to diagnose
   ```
   (Remove this step if you don't run linters in Docker.)

## Notes

- N Bash calls in ONE turn = they run concurrently. N calls across N turns = they run sequentially and waste time. Always parallelize.
- The fix-mode output mutates files. After running with `--fix`, the user must `git diff` and stage the changes themselves — this command does NOT touch git.
- This is a sanity check, not a coverage tool. It does not run tests.
