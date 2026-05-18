# Settings

Claude Code's project-level settings live in `.claude/settings.json`. This folder has an example file plus notes on how to think about the permissions allowlist.

## What's here

| File | Purpose |
|---|---|
| [`settings.example.json`](settings.example.json) | A full `settings.json` showing: pre-approved Bash patterns, hook wiring, plugin enablement |
| [`permissions-allowlist.md`](permissions-allowlist.md) | How to decide what belongs on the allowlist (and what doesn't) |

## Two files, not one

Claude Code reads two files from `.claude/`:

| File | Committed? | Scope |
|---|---|---|
| `settings.json` | ✅ yes — shared with the team | Everyone's Claude follows these rules |
| `settings.local.json` | ❌ no — gitignored by Claude Code | Your personal overrides, allow rules you don't want to force on teammates |

Put the team-wide rules (hooks, the "obviously safe" allowlist) in `settings.json`. Put your personal allow rules (commands you've individually approved a hundred times that probably shouldn't be team-wide) in `settings.local.json`.

The `fewer-permission-prompts` skill (built into Claude Code) scans your recent transcripts for repeated approvals and proposes additions — let it write to `settings.local.json` first, promote to `settings.json` only if the rule genuinely belongs to everyone.

## Installation

```bash
mkdir -p .claude
cp claude-skill-lab/settings/settings.example.json .claude/settings.json
# edit to remove patterns you don't want, add ones you do
```
