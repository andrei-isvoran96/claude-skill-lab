Clear the review history file used by `/review` to track previously flagged issues.

Run the following command using Bash:

```
rm -f .claude/review-history.txt && echo "Review history cleared."
```

Confirm to the user that the review history has been cleared and the next `/review` will start fresh.
