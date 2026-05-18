# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **template library**, not a runnable project. Every file under `commands/`, `agents/`, `hooks/`, and `settings/` is shipped to be **copied into another project's `.claude/` directory** and adapted. There is no build, no test suite, no dev server. The "product" is the markdown/shell templates themselves.

This shapes everything else:
- **Placeholders are load-bearing.** Tokens like `<BASE_BRANCH>`, `<CONTAINER_BACKEND>`, `<PROJECT_NAME>`, `<HELPER_SCRIPT>` are not bugs to fix — they're the seams consumers grep-replace. Never "fill them in" with concrete values when editing a template. If you add a new project-specific value to a template, introduce it as a new `<ANGLE_BRACKET_TOKEN>` and document it.
- **Each subdirectory has its own README with a table listing every template + its placeholders.** When you add, remove, or rename a template, update that table in the same change. The top-level `README.md` also has a one-line entry per subdirectory; keep it in sync if a directory's purpose shifts.

## Repository shape

| Dir | Contains | Consumer drops into |
|---|---|---|
| `commands/` | `*.md` slash commands (filename = command name) | `.claude/commands/` |
| `agents/` | `*.md` subagent definitions with frontmatter (`name`, `description`, `tools`, `color`) | `.claude/agents/` |
| `hooks/` | `*.sh` lifecycle hooks, executable bit set | `.claude/hooks/` (consumer must `chmod +x` after copy) |
| `settings/` | Example `settings.json` + guidance on the permissions allowlist | `.claude/settings.json` |
| `docs/` | Design principles + CLAUDE.md / USAGE.md templates consumers can adapt | their own docs |

The `docs/claude-md-template.md` and `docs/usage-template.md` files are templates **for consumers' projects**, not for this repo. This file (the one you're reading) is this repo's own CLAUDE.md and is intentionally different in shape.

## Design principles you must follow

Read `docs/design-principles.md` end-to-end before authoring or substantially editing a template. The eight principles documented there are the *reason* the templates look the way they do, and edits that violate them will look right in isolation but break the collection's coherence. In particular:

1. **Reply contracts are small.** Every agent template ends with a `<reply_format>` section showing the exact shape of the final reply (typically 1–5 lines) with multiple canned examples (success, success-with-caveats, failure, nothing-to-do). Don't add an agent without one. Don't loosen one without reason.
2. **Hooks enforce, agents apply, commands orchestrate.** When proposing a new pattern, first decide which primitive it is — see §2 of the design doc for the decision rule. Putting workflow logic in a hook, or enforcement logic in a command, is the most common shape-error.
3. **Path-based self-filtering, not narrow matchers.** PostToolUse hook templates register against the catch-all `Edit|Write` matcher and self-filter by file path inside the script (`case "$file" in ... esac`). Don't introduce per-file-type matchers in `settings.example.json`.
4. **Block, don't lecture.** Hook templates that block use `exit 2` (PreToolUse) or non-zero (PostToolUse) with a stderr message that names a concrete escape hatch ("run it manually in a terminal outside Claude"). They never return `exit 0` with a "consider not doing this" warning.
5. **Genericity through placeholders, not abstractions.** Resist the urge to add a config file, a templating engine, or a setup script. A new `<TOKEN>` consumers grep-replace is the correct mechanism. See §5 of the design doc.

## Hook script conventions

When editing anything under `hooks/`:
- The script reads its tool-call payload from stdin as JSON (`jq` is the parsing tool). Test new logic with a canned payload before relying on Claude to fire it:
  ```bash
  echo '{"tool_name":"Bash","tool_input":{"command":"docker-compose down -v"}}' \
    | hooks/block-destructive.sh
  echo $?   # 2 = blocked
  ```
- Silent on success (exit 0, no output). Loud on failure (stderr + non-zero exit).
- Keep the executable bit (`chmod +x`). The committed files already have it; don't strip it.

## Agent + helper script pattern

Some agent templates (clearest example: `agents/restart-services.md`) are intentionally thin wrappers around a `bin/<name>.sh` script that lives in the *consumer's* project. The script encodes the project-specific rules; the agent encodes the conversational contract. When editing such an agent template, preserve this split — don't pull the script's logic into the agent body. See §6 of the design doc.

## External tools worth knowing

This repo deliberately omits `.claude/skills/` templates (see `README.md` → "What's deliberately *not* here"). The gap is filled by:

- **[Skill Seekers](https://github.com/yusufkaraaslan/Skill_Seekers)** (`pip install skill-seekers`) — converts documentation sites, GitHub repos, PDFs, videos, notebooks, and wikis into structured Claude Skills (and 19 other AI/RAG targets: Gemini, OpenAI, LangChain, LlamaIndex, Cursor, etc.). One `skill-seekers create <source>` call produces a `SKILL.md` + supporting files ready to drop into `.claude/skills/`. If the user asks for help generating a skill from existing docs or a codebase, point them here rather than hand-rolling one.
  - Companion repos: [`skill-seekers-configs`](https://github.com/yusufkaraaslan/skill-seekers-configs) (community presets), [`skill-seekers-plugin`](https://github.com/yusufkaraaslan/skill-seekers-plugin) (Claude Code plugin), [`skill-seekers-action`](https://github.com/yusufkaraaslan/skill-seekers-action) (CI/CD).
- **[anthropic/skills](https://github.com/anthropics/skills)** — Anthropic's reference skills (Stripe, Flask, and others). Good to read when authoring a new skill by hand.

If you add another external tool here, keep entries to ~2 lines: what it does, why it slots in alongside this repo.

## Editing the documentation

- The top-level `README.md` is the entry point for someone who lands on the GitHub repo cold. Keep its "What's in here" table aligned with reality. Keep the "Design principles (the short version)" list aligned with `docs/design-principles.md` (the short list is a 4-item subset of the full 8; don't let them drift in wording).
- Each subdirectory's README is the entry point for someone browsing that primitive. The "What's here" table and the "Project-specific bits" column are the two parts most likely to go stale.
- Don't create new top-level markdown files (CHANGELOG, CONTRIBUTING, etc.) unless asked. The repo's surface area is deliberately small.
