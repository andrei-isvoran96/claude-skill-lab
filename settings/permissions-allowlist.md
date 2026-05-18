# Permissions allowlist — what to allow and what not to

Claude Code prompts you for permission before running any tool that isn't in the allow list. Approve enough of them and the workflow feels fast; approve too many and the prompts have stopped being a safety net.

This page is the rubric I use to decide.

## The principle

Only allow what is **read-only AND idempotent AND project-scoped**. If a pattern fails any of those three, it should keep prompting.

| Criterion | Why |
|---|---|
| **Read-only** | A `git log` can't break anything. A `git push` can. |
| **Idempotent** | Running the same `docker-compose ps` ten times changes nothing. Running `composer install` ten times is fine 99% of the time and accidentally re-resolves deps 1%. |
| **Project-scoped** | `npm list` in this project is fine. A blanket `Bash(npm *)` allows installing arbitrary packages globally. |

If you find yourself wanting to allow a command that fails one of these, it should go in `.claude/settings.local.json` (your personal file) instead of `.claude/settings.json` (the team-shared file) so you own the risk individually.

## Safe-to-allow patterns

These come up constantly and never cause problems:

```jsonc
// Diagnostic Docker reads — pure introspection
"Bash(docker-compose logs *)",
"Bash(docker compose logs *)",
"Bash(docker-compose ps *)",
"Bash(docker compose ps *)",
"Bash(docker-compose top *)",
"Bash(docker compose top *)",
"Bash(docker stats *)",
"Bash(docker inspect *)",

// Read-only git
"Bash(git status *)",
"Bash(git diff *)",
"Bash(git log *)",
"Bash(git branch *)",
"Bash(git show *)",
"Bash(git rev-parse *)",
"Bash(git ls-files *)",

// Read-only GitHub
"Bash(gh issue view *)",
"Bash(gh pr view *)",
"Bash(gh pr list *)",
"Bash(gh issue list *)",
"Bash(gh repo view *)",
"Bash(gh run view *)",

// Framework introspection (Laravel example — adapt for your stack)
"Bash(docker exec myapp-backend php artisan list *)",
"Bash(docker exec myapp-backend php artisan route:list *)",
"Bash(docker exec myapp-backend php artisan config:show *)",
"Bash(docker exec myapp-backend php artisan migrate:status *)",
"Bash(docker exec myapp-backend composer show *)",

// Linters in check-only mode
"Bash(docker exec myapp-backend vendor/bin/pint --test *)",
"Bash(docker exec myapp-essentia ruff check .)",
"Bash(docker exec myapp-frontend npx tsc --noEmit)"
```

## Deliberately NOT on the allowlist

Even if you'll approve these every single time, **keep them prompting**:

| Command | Why no |
|---|---|
| `php artisan migrate:fresh` | Drops your dev DB |
| `php artisan cache:clear` | Mutating; rarely the right call mid-session |
| `php artisan tinker --execute=*` | Can do literally anything |
| `npm install *` (with arg) | Can install arbitrary packages |
| `composer require *` | Same |
| `git push *` | Communicates with the outside world |
| `gh pr create *` | Creates a visible artifact |
| `gh pr merge *` | Self-explanatory |
| `docker-compose down -v` | Wipes named volumes |
| `rm *` / `rm -rf *` | Self-explanatory |
| `curl *` / `wget *` | Network egress |

For commands that mutate but you trust by *exact form*, the safer pattern is:
```jsonc
"Bash(npx tsc --noEmit)"              // exact — no wildcard
"Bash(docker-compose restart backend)"  // exact — no wildcard
```
…rather than `Bash(npx *)` or `Bash(docker-compose *)`.

## Per-tool vs per-Bash-pattern

Allow rules can target any tool:

```jsonc
"WebFetch(domain:docs.aws.amazon.com)",      // any URL on this host
"mcp__github__list_issues",                  // a specific MCP tool, all inputs
"Read",                                       // all Read calls (rarely a good idea — Read can hit secrets)
```

For sensitive files (`.env`, `credentials.json`, `~/.ssh/`) you can also explicitly **deny**:

```jsonc
"deny": [
  "Read(./**/.env*)",
  "Read(./**/*credentials*)",
  "Read(./**/*.key)"
]
```

Deny rules override allow rules. If you want Claude to read most files but not your env, an explicit deny is more reliable than relying on Claude's discretion.

## Promoting from `local` to shared

A typical workflow:

1. Claude prompts you for something — you approve once.
2. Three days later, Claude prompts you for it again. The skill `fewer-permission-prompts` (built into Claude Code) notices and offers to add it to `.claude/settings.local.json`.
3. Once it's been in `settings.local.json` for a while and you haven't regretted it, promote it to `settings.json` so your teammates benefit.

The lag between steps 2 and 3 is the point: things that feel safe to *you* aren't always safe to ship to the team's Claude.
