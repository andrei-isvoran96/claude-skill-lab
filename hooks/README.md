# Hooks

Hooks run automatically around Claude's tool calls. You don't invoke them manually; they're enforcement that fires on the lifecycle events `PreToolUse` (before Claude runs a tool) and `PostToolUse` (after).

## What's here

| File | Lifecycle | Purpose | Project-specific bits |
|---|---|---|---|
| [`block-destructive.sh`](block-destructive.sh) | PreToolUse on `Bash` | Block commands that wipe data, force long rebuilds, or rewrite shared git history | Protected branch names, container/volume names |
| [`lint-on-edit.sh`](lint-on-edit.sh) | PostToolUse on `Edit`/`Write` | Run a linter on the just-edited file (silent on success, blocking on failure) | Path prefix, linter command |
| [`typecheck-on-edit.sh`](typecheck-on-edit.sh) | PostToolUse on `Edit`/`Write` | Run a project-wide typechecker on every `.ts`/`.tsx` edit | Path prefix, typechecker command |

## Wiring up

Hooks are registered in `.claude/settings.json` like this (see [`../settings/settings.example.json`](../settings/settings.example.json) for the full file):

```jsonc
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/block-destructive.sh", "timeout": 10 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/lint-on-edit.sh",       "timeout": 30 },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/typecheck-on-edit.sh",  "timeout": 120 }
        ]
      }
    ]
  }
}
```

Notes:
- The matcher is a regex over tool names. `Edit|Write` matches both file-mutating tools.
- `$CLAUDE_PROJECT_DIR` is set by Claude Code to the project root.
- `timeout` is in seconds.
- Multiple hooks can register against the same matcher — they run in order. PreToolUse hooks short-circuit on `exit 2`.

## Installation

```bash
mkdir -p .claude/hooks
cp claude-skill-lab/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
# then add the matchers above to .claude/settings.json
```

## Key design rules these hooks follow

### Path-based self-filtering

Each PostToolUse hook is registered against the catch-all matcher `Edit|Write`, then **self-filters** by file path inside the script:

```bash
case "$file" in
  "$PROJECT_ROOT/backend/"*.php) ;;   # this hook engages
  *) exit 0 ;;                         # not for us, bail silently
esac
```

This means you don't need separate matchers in `settings.json` per file type. The matcher fires for every edit, each hook decides whether it cares. Adding a new lint-on-edit hook = drop a new `.sh` into `.claude/hooks/` and append one entry to `settings.json`.

### Silent on success, loud on failure

Successful hooks exit `0` with no output. Failing hooks print to stderr and exit non-zero. Claude shows the stderr to itself (and to the user via the conversation), so the path-to-fix is obvious.

### Hooks enforce; they don't suggest

If the hook decides the action is wrong, it **blocks** (exit 2 for PreToolUse, non-zero for PostToolUse). It does not print a "consider doing X" suggestion and let the action through. The blocked-command stderr always names an escape hatch ("if you really mean it, run it yourself in a terminal outside Claude") so the user has a clear path forward.

### Validate against canned inputs before committing

Each script reads its tool-call payload from stdin as JSON. To test a hook without firing Claude, build a fake payload:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"docker-compose down -v"}}' \
  | .claude/hooks/block-destructive.sh
echo $?    # should be 2 for a blocked command
```

This is fast iteration and avoids the "I changed the hook but the matcher is wrong" guessing game.
