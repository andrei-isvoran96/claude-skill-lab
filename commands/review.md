<!--
Customize for your project — find/replace these tokens after copying:
  <BASE_BRANCH>   your integration branch (e.g. main, development, develop)
-->

You have finished writing code. Now invoke a fresh, unbiased code review.

First, check if a previous review history file exists at `.claude/review-history.txt`. If it does, read its contents — you will include it in the reviewer prompt so previously addressed findings are not re-flagged.

Then run the following command using Bash to spawn an independent Claude reviewer. **Dynamically build the prompt** as follows:

1. Start with the base prompt (the system instructions below)
2. If review history exists, append it as a "PREVIOUSLY FLAGGED AND FIXED" section
3. Pipe the git diff into the final command

```
REVIEW_HISTORY=""
if [ -f .claude/review-history.txt ]; then
  REVIEW_HISTORY=$(cat .claude/review-history.txt)
fi

if [ -n "$REVIEW_HISTORY" ]; then
  CONTEXT="

IMPORTANT — PREVIOUSLY FLAGGED AND ALREADY FIXED:
The following issues were flagged in prior reviews and have already been addressed. Do NOT re-flag these. Only report NEW issues not covered below.

${REVIEW_HISTORY}"
else
  CONTEXT=""
fi

(git diff <BASE_BRANCH> -- . ':!*.lock' ':!*.lockb' | head -8000) | claude -p "You are a senior code reviewer. Review the following diff thoroughly and critically. Look for:
- Bugs and logic errors
- Security vulnerabilities
- Performance issues
- Edge cases and error handling gaps
- Code quality and readability concerns

Do NOT assume the author's intent. Only evaluate what the code actually does. Be specific — reference file names and line numbers.

If the code looks good, say so briefly. If there are issues, list them by severity (critical / warning / nitpick).
${CONTEXT}"
```

After the review output is returned:

1. **Display it to the user in full.** Do not summarize or filter the review — show it exactly as received.

2. **Save a summary of the findings** to `.claude/review-history.txt` for future reviews. Write ONLY the issue titles/descriptions (one per line, prefixed with severity). Do NOT include the full review text — keep it concise. Append to the existing file (don't overwrite). Example format:
```
=== Review 2026-04-09 ===
- [critical] SSRF bypass in thumbnail proxy — scheme not validated
- [warning] Blob URL memory leak in DriveThumbnail on unmount
- [nitpick] params: any violates no-any coding standard
```
