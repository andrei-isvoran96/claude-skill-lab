#!/usr/bin/env bash
# PreToolUse hook: block Bash commands that would wipe data, force a long
# rebuild, or rewrite shared git history. Returns exit 2 with a stderr
# message that Claude relays to the caller; the caller can run the command
# manually outside Claude if they really mean it.
#
# CUSTOMIZE FOR YOUR PROJECT — search for "PROJECT-SPECIFIC" markers below.
#
# Test before committing:
#   echo '{"tool_name":"Bash","tool_input":{"command":"docker-compose down -v"}}' \
#     | .claude/hooks/block-destructive.sh ; echo $?     # → 2
#
set -uo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
[ "$tool" = "Bash" ] || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

block() {
  printf 'BLOCKED by .claude/hooks/block-destructive.sh:\n  %s\n' "$1" >&2
  printf '\nIf this is genuinely intentional, run the command manually in your terminal outside Claude.\n' >&2
  exit 2
}

# Skip for commands that take freeform text payloads — their args contain commit
# messages, PR bodies, issue comments, etc. that legitimately reference the
# patterns below as documentation. Without this exemption, the hook fires
# whenever a commit message describes one of the blocked operations.
if echo "$cmd" | grep -qE '^[[:space:]]*(git[[:space:]]+(commit|tag|notes)|gh[[:space:]]+(pr|issue|release)[[:space:]]+(create|edit|comment|merge|review))\b'; then
  exit 0
fi

# Patterns below anchor to command-start positions: start of input, start of a
# line, or right after a shell separator (;, &&, ||, |). This prevents false
# positives where a destructive pattern appears as a string literal inside
# another command's arguments (e.g. `test_case "docker-compose down -v" ...`).
START='(^|[;&|]+[[:space:]]*|[[:space:]]*\n[[:space:]]*)'

# ─── PROJECT-SPECIFIC: docker-compose volume wipe ────────────────────────────
# Block if your project uses named docker volumes that hold state you care about.
# Drop this rule if you don't use docker-compose.
if echo "$cmd" | grep -qzE "${START}docker[-[:space:]]+compose[[:space:]]+down\b[^|;&\"']*(\s|^)-v\b"; then
  block "docker-compose down -v wipes named volumes — all dev data lost. Use 'docker-compose down' (no -v) to stop without losing data, or take a snapshot first."
fi

# ─── PROJECT-SPECIFIC: framework "drop and recreate everything" ──────────────
# Customize for your stack:
#   Laravel:        artisan migrate:fresh
#   Django:         manage.py flush  /  manage.py reset_db
#   Rails:          rake db:drop  /  rake db:reset
#   Prisma:         prisma migrate reset
#   Knex:           knex migrate:rollback --all && migrate:latest
# This pattern is NOT anchored to command-start because it appears naturally
# inside `docker exec <container> php artisan migrate:fresh`. Documentation
# false positives (commit messages, PR bodies) are caught by the
# data-bearing-command exemption above.
if echo "$cmd" | grep -qE 'artisan[[:space:]]+migrate:fresh\b'; then
  block "artisan migrate:fresh drops and recreates all tables, destroying every row in dev. Take a snapshot first via the db-snapshot agent."
fi

# ─── PROJECT-SPECIFIC: full docker image prune ───────────────────────────────
# Block on `docker system prune -a` / `--all` — wipes ALL unused images.
# For a typical multi-service stack this forces a ~10-min rebuild of every service.
if echo "$cmd" | grep -qzE "${START}docker[[:space:]]+system[[:space:]]+prune\b[^|;&\"']*(-a|--all)\b"; then
  block "docker system prune -a removes ALL unused images and forces a long rebuild of every service. Use 'docker image prune' (untagged only) or run manually if you genuinely need a full prune."
fi

# ─── git force-push to protected branches ────────────────────────────────────
# Generic enough to apply to most projects. Customize PROTECTED_BRANCHES and
# the regex of allowed feature-branch prefixes for your project.
PROTECTED_BRANCHES='main|master|development|develop|release'
ALLOWED_PREFIXES='feature|bug|fix|release|hotfix|chore|docs|refactor|task'

if echo "$cmd" | grep -qzE "${START}git[[:space:]]+push\b"; then
  is_force=0
  echo "$cmd" | grep -qE '(--force(-with-lease)?\b|\s-f\b)' && is_force=1
  echo "$cmd" | grep -qE "\\s\\+($PROTECTED_BRANCHES)\\b" && is_force=1

  if [ "$is_force" -eq 1 ]; then
    # Explicit mention of a protected branch as a ref — always block.
    if echo "$cmd" | grep -qE "(\\s|:|\\+|/)($PROTECTED_BRANCHES)(\\s|:|$)"; then
      block "force-push to a protected branch ($PROTECTED_BRANCHES) is destructive — rewrites shared history other branches are based on. Open a PR instead."
    fi

    # On a protected branch with no explicit non-protected ref — would default to pushing
    # the current (protected) branch.
    current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if echo "$current" | grep -qE "^($PROTECTED_BRANCHES)$"; then
      if ! echo "$cmd" | grep -qE "\\s($ALLOWED_PREFIXES)/[a-zA-Z0-9_.-]+"; then
        block "force-push while on protected branch ($current) with no explicit alternate ref — would push to origin/$current. Switch to a feature/bug branch first, or specify a non-protected ref explicitly."
      fi
    fi
  fi
fi

exit 0
