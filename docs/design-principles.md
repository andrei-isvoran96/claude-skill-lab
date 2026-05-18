# Design principles

The patterns in this repo aren't independent recipes — they share a small set of habits that, once you internalize, you'll reach for instinctively. This page is the explanation of *why* each pattern is shaped the way it is.

## 1. Reply contracts are small

Every agent and slash command in this lab specifies the **exact shape** of its final reply, with examples. A typical contract:

```
✓ backend 12/12 ✓, frontend 7/7 ✓ (3.4s)
```

or, on failure:

```
✗ backend 9/12 (3 failed):
  • Tests\Feature\Flow\FlowExecutionTest::test_creates_run — Expected 200, got 422
    at app/Http/Controllers/Api/FlowController.php:84
```

That's it. The 200 lines of vitest output that produced the conclusion stay inside the agent's Bash tool calls — your main context never sees them.

**Why this matters:** Claude's context window is the most expensive resource in the workflow. A bare `php artisan test` dump can fill 5-10% of a session's context with stack traces you don't need. Routing the run to a subagent with a tight reply contract gets you the same answer (passed/failed/which) without the noise. After ten such delegations in a session, you have more context left for actual work.

**The implementation rule:** every agent's body has a `<reply_format>` section with three or four canned examples (success, success-with-caveats, failure, nothing-to-do). Without it, the agent will paste whatever the underlying tool wrote.

## 2. Hooks enforce. Agents apply. Commands orchestrate.

Three primitives, three jobs:

| Primitive | Lifecycle | Job |
|---|---|---|
| **Hooks** (PreToolUse / PostToolUse) | Fire automatically around every tool call | Stop or audit specific *classes* of action |
| **Agents** | Spawned on demand into a child conversation | Execute a *recipe* that's expensive or noisy |
| **Slash commands** | User-typed, run in the main conversation | Orchestrate a *workflow* of tool calls in the user's context |

You can sometimes pick wrong:

- *"I want to auto-lint after every edit."* → Hook (you want it to fire on every edit, not when Claude remembers to).
- *"I want a one-liner that summarizes a test run."* → Agent (verbose output, tight summary).
- *"I want a one-liner that picks up a GitHub issue and creates a branch."* → Command (it's a workflow, the user invokes it).

The give-away: if the action should fire **automatically every time**, it's a hook. If the action's whole value is **keeping noise out of the main conversation**, it's an agent. If the action is a **named workflow the user invokes**, it's a command.

## 3. Path-based self-filtering > narrow matchers

Claude Code hooks accept a regex matcher in `settings.json`. The temptation is to write a specific matcher per hook:

```jsonc
// DON'T do this
{
  "matcher": "Edit",
  "hooks": [
    { "command": ".claude/hooks/lint-php.sh",        "matcher_extra": "*.php" },
    { "command": ".claude/hooks/lint-python.sh",     "matcher_extra": "*.py" },
    { "command": ".claude/hooks/typecheck-ts.sh",    "matcher_extra": "*.ts" }
  ]
}
```

The `matcher_extra` doesn't exist. Even if it did, splitting filter logic between JSON config and shell scripts makes the system harder to reason about.

The pattern this lab uses instead: one catch-all matcher, each script self-filters by path:

```jsonc
{
  "matcher": "Edit|Write",
  "hooks": [
    { "command": ".claude/hooks/lint-php.sh"        },
    { "command": ".claude/hooks/lint-python.sh"     },
    { "command": ".claude/hooks/typecheck-frontend.sh" }
  ]
}
```

```bash
# inside lint-php.sh
case "$file" in
  "$PROJECT_ROOT/backend/"*.php) ;;
  *) exit 0 ;;
esac
```

**Why this matters:** all filter logic lives in one place per language (the script). Adding a new file-type hook is just `drop a .sh + add one line to settings.json`. The hook's filter rule is testable in isolation against canned JSON input — no need to fire Claude to see if the matcher works.

## 4. Block, don't lecture

Hooks are enforcement. When `block-destructive.sh` decides a `docker-compose down -v` is wrong, it returns exit 2 and prints a one-line reason. It does *not* return exit 0 with a "consider not doing this" warning that Claude can override.

The stderr message includes an explicit escape hatch:

```
BLOCKED by .claude/hooks/block-destructive.sh:
  docker-compose down -v wipes named volumes — all dev data lost.

If this is genuinely intentional, run the command manually in your terminal outside Claude.
```

**Why this matters:** if the hook is overrideable from inside the conversation, the very class of mistake it's meant to prevent will happen anyway — Claude will helpfully retry "with the right flag" the moment it thinks the original failed for technical reasons. A clean exit 2 with a stated escape hatch is the only pattern I've found that actually sticks. The escape hatch matters too: the user needs a clear, low-friction path forward, otherwise the hook becomes resentment-inducing instead of protective.

## 5. Genericity through placeholders, not abstractions

The templates in this repo are full of `<ANGLE_BRACKET_TOKENS>`. They aren't a templating language — they're grep-replace markers.

You could imagine a more "sophisticated" version where you write `claude-skill.config.json` with your container names, base branch, and linter commands, and a setup script renders the templates. I think that's strictly worse:

- A grep-replace pass takes 30 seconds and you're done.
- A config-driven system has its own configuration syntax to learn and its own bugs.
- The thing you're customizing is a Claude prompt — not a build artifact you regenerate often. You'll edit it once when you copy it, then forget it.

**Why this matters:** these are *learning artifacts* meant to be read and adapted, not *libraries* meant to be installed and forgotten. Keeping them as plain markdown/shell with obvious holes preserves their educational value. The point is to ship something you understand, not something elegant.

## 6. Agent and helper script, side by side

Several of these agents (`restart-services` most clearly) are thin wrappers around a `bin/<name>.sh` script:

- The **script** encodes the rules (what to restart when which files change).
- The **agent** is the conversational interface — it invokes the script in `--quiet` mode and relays the one-line summary.

This is deliberate. The script is:

- **Testable** — you can run it directly, `bin/restart-after-changes.sh --dry-run`, no Claude involved.
- **Reusable by humans** — teammates without Claude can run it.
- **The single source of truth** — when the rules change, you edit one place.

The agent is then very thin: its `<workflow>` is just "run the script with `--quiet`, relay the output." It exists almost entirely to enforce the *reply contract* (small summary, no verbose paste), not to encode the rules.

**Why this matters:** mixing rules and conversational logic in the agent body makes both worse. Rules become opaque (you can't read the agent prompt to predict what it'll do, because it improvises). Conversational logic becomes brittle (the agent will paste rule output verbatim when it shouldn't). Splitting them keeps both parts small and review-able.

## 7. CLAUDE.md is for facts the code can't tell you

Every Claude Code session auto-loads `CLAUDE.md` from the project root. The temptation is to put *everything* in it — every convention, every command, every architecture diagram.

The discipline: CLAUDE.md should contain things Claude cannot infer from the code itself. Good candidates:

- "PHP opcache is on with `validate_timestamps=Off` — edited PHP files won't be picked up until you restart the container." (A surprising operational fact.)
- "Always branch from `development`, never from `main`." (A team convention.)
- "`/api/v1/*` routes resolve under `/api/*` — the v1 is filename-only." (A non-obvious quirk.)

Bad candidates (Claude can figure these out by reading the code):

- "Controllers are in `app/Http/Controllers/`." (Just look.)
- "We use Laravel 12." (Look at composer.json.)
- "The User model has a `name` column." (Look at the migration.)

A CLAUDE.md full of *facts* Claude can infer for itself trains Claude to skim it instead of read it. Keep it short, keep it surprising, keep it the kind of thing a new hire would actually need to be told.

## 8. The `Co-Authored-By` line is a tradeoff

The commit/PR commands in this lab don't add a `Co-Authored-By: Claude <noreply@anthropic.com>` trailer. Some teams add it for transparency; others find it noisy.

If you want it, append:

```bash
git commit -m "$(cat <<'EOF'
fix: short description

Body.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

The arguments for adding it: surfaces AI-assisted work, lets reviewers calibrate scrutiny, helps your future self remember which commits were AI-driven.

The arguments against: bloats git log, draws unnecessary attention to a single tool in a workflow that uses many.

There's no right answer. Pick a side, document the convention in CLAUDE.md, and stick to it.
