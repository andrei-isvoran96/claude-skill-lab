#!/usr/bin/env bash
# PostToolUse hook: run a project-wide typechecker on every TS/TSX edit.
# tsc --noEmit has no per-file mode, so any edit triggers a full check.
# Silent on success; prints errors to stderr on failure.
#
# CUSTOMIZE FOR YOUR PROJECT:
#   <PATH_PREFIX>   the relative path under the repo root this hook engages on
#                   (e.g. "frontend/" or "apps/web/")
#   <CONTAINER>     (optional) Docker container name if running tsc via docker exec
#   <TYPECHECKER>   the command to run; defaults to `npx tsc --noEmit`
#
# Example wiring for Next.js in Docker:
#   PATH_PREFIX="frontend/"
#   CONTAINER="myapp-frontend"
#   TYPECHECKER="npx tsc --noEmit"
#
# This pattern works for any project-wide checker:
#   - Mypy:      `mypy <package>`              (PATH_PREFIX=src/, ext=py)
#   - Flow:      `flow check`                  (PATH_PREFIX=app/, ext=js)
#   - Cargo:     `cargo check --all-targets`   (PATH_PREFIX=src/, ext=rs)
#   - Go vet:    `go vet ./...`                (PATH_PREFIX=cmd/, ext=go)
#
# These are usually too slow for per-edit checks (>30s). Use the lint-on-edit
# pattern for per-file linters instead and reserve this for stricter,
# project-wide validators that catch cross-file issues.
#
set -uo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0

# ─── CUSTOMIZE: path filter ──────────────────────────────────────────────────
PATH_PREFIX="<PATH_PREFIX>"

case "$file" in
  "$PROJECT_ROOT/$PATH_PREFIX"*.ts|"$PROJECT_ROOT/$PATH_PREFIX"*.tsx) ;;
  *) exit 0 ;;
esac

# ─── CUSTOMIZE: typechecker invocation ───────────────────────────────────────
if ! output=$(docker exec <CONTAINER> npx tsc --noEmit 2>&1); then
  printf '%s\n' "$output" >&2
  exit 1
fi
exit 0
