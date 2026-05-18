#!/usr/bin/env bash
# PostToolUse hook: run a linter on the just-edited file.
# Silent on success; prints output to stderr and exits non-zero on failure.
#
# CUSTOMIZE FOR YOUR PROJECT:
#   <PATH_PREFIX>   the relative path under the repo root this hook engages on
#                   (e.g. "backend/" or "essentia-service/" or "packages/api/")
#   <FILE_EXT>      the file extension this hook engages on (e.g. "php", "py", "rb", "go")
#   <LINTER_CMD>    the command to run; %FILE% is replaced with the file path
#   <CONTAINER>     (optional) Docker container name if linting via docker exec;
#                   omit the `docker exec` prefix entirely if your linter runs on the host
#   <CONTAINER_PATH_PREFIX>   the path inside the container that maps to your host code
#                             (e.g. "/var/www/html/" for Laravel, "/app/" for Flask)
#
# Example wiring for Laravel + Pint:
#   PATH_PREFIX="backend/"
#   FILE_EXT="php"
#   LINTER_CMD='docker exec myapp-backend vendor/bin/pint "/var/www/html/$rel"'
#
# Example wiring for Python + Ruff:
#   PATH_PREFIX="api/"
#   FILE_EXT="py"
#   LINTER_CMD='docker exec myapp-api ruff check --fix "/app/$rel"'
#
# Example wiring for host-side Prettier on TS:
#   PATH_PREFIX="frontend/"
#   FILE_EXT="ts"
#   LINTER_CMD='npx prettier --write "$file"'
#
set -uo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
file=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')

[ -z "$file" ] && exit 0

# ─── CUSTOMIZE: path + extension filter ──────────────────────────────────────
PATH_PREFIX="<PATH_PREFIX>"   # e.g. "backend/"
FILE_EXT="<FILE_EXT>"         # e.g. "php"

case "$file" in
  "$PROJECT_ROOT/$PATH_PREFIX"*.$FILE_EXT) ;;
  *) exit 0 ;;
esac

# Relative path under the project's source directory — used to translate
# host paths to container paths if linting via docker exec.
rel="${file#"$PROJECT_ROOT/$PATH_PREFIX"}"

# ─── CUSTOMIZE: actual linter invocation ─────────────────────────────────────
# Replace this with your linter. Examples in the header comment above.
if ! output=$(docker exec <CONTAINER> <LINTER_CMD> 2>&1); then
  printf '%s\n' "$output" >&2
  exit 1
fi
exit 0
