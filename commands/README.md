# Slash commands

User-typed `/foo` commands. Drop these into your project at `.claude/commands/<name>.md` — the filename (minus `.md`) is the command name. Use `$ARGUMENTS` to read whatever the user typed after the command.

## What's here

| File | Purpose | Project-specific bits |
|---|---|---|
| [`commit.md`](commit.md) | Create a new branch from a base branch, stage, commit, push | `<BASE_BRANCH>` |
| [`pr.md`](pr.md) | Open a PR from the current branch | `<BASE_BRANCH>` |
| [`issue.md`](issue.md) | Pick up a GitHub issue → create a properly-named branch | `<BASE_BRANCH>` |
| [`review.md`](review.md) | Spawn an independent Claude reviewer on the current diff | `<BASE_BRANCH>` |
| [`clear-review.md`](clear-review.md) | Reset the `/review` history file | none |
| [`plan-review.md`](plan-review.md) | Draft a plan + run up to 3 rounds of unbiased peer review | none |
| [`lint.md`](lint.md) | Run N linters in parallel | linter commands |
| [`health.md`](health.md) | Check N services in parallel (containers + HTTP probes) | service names, ports |

## How a slash command file works

- Plain markdown — Claude reads it and follows the steps.
- `$ARGUMENTS` is interpolated to whatever the user typed after `/cmd`.
- No frontmatter required (some examples here have none).
- Filename ⇒ command name. `lint.md` becomes `/lint`.

Once you drop the file into `.claude/commands/`, Claude Code picks it up on the next prompt.

## Conventions used across these files

- **Short reply contracts.** Each command's "format" section tells Claude exactly what shape the final reply should take (typically a single status line + at most a small table). Verbose tool output stays inside tool calls.
- **Parallel where possible.** Multiple independent Bash calls are issued in a single turn. The command explicitly says "issue these N calls in ONE turn" because Claude defaults to sequential.
- **Refuse-and-stop is a valid outcome.** If preconditions aren't met (closed issue, dirty tree, missing branch name), the command stops cleanly rather than improvising.

## Customizing for your project

Every file has placeholders in `<ANGLE_BRACKETS>`. Grep-replace them after copying. Most common:

- `<BASE_BRANCH>` — your integration branch (`main`, `development`, `develop`, `master`)
- `<CONTAINER_BACKEND>`, `<CONTAINER_FRONTEND>`, etc. — Docker container names
- `<LANG_LINTER>` — the Bash command to invoke each linter
