# claude-skill-lab

A personal collection of **reusable Claude Code patterns** — slash commands, subagents, hooks, and settings — distilled from real projects. Drop-in templates with the project-specific bits parameterized so you can adapt them quickly.

> Most of what's here was originally written for a single monorepo (Laravel + Next.js + Flask in Docker). The bits that were truly project-specific have been factored out; what remains is the **shape** of each pattern with placeholders (`<PROJECT_NAME>`, `<CONTAINER_NAME>`, `<BASE_BRANCH>`, etc.) that you fill in for your project.

## What's in here

| Directory | What | When to grab from here |
|---|---|---|
| [`commands/`](commands/) | Slash commands (`.claude/commands/*.md`) | You want a `/foo` shortcut that runs a multi-step workflow |
| [`agents/`](agents/) | Subagent definitions (`.claude/agents/*.md`) | You want Claude to delegate a noisy task (long logs, build output, test runs) to a side conversation so the main context stays clean |
| [`hooks/`](hooks/) | Tool-call lifecycle hooks (`.claude/hooks/*.sh`) | You want to **block** dangerous commands, or auto-run a linter/typechecker after every file edit |
| [`settings/`](settings/) | `settings.json` examples + permission allowlist patterns | You want fewer permission prompts without blanket-allowing Bash |
| [`external/`](external/) | Pointers to third-party tools that fill gaps this repo deliberately leaves (e.g. skill generation) | You're looking for capabilities outside the patterns shipped here |
| [`docs/`](docs/) | The meta-patterns and templates behind everything else | You want to understand *why* things are shaped the way they are, or write your own variants |

## How to use it

1. **Browse** the folder that matches what you want.
2. **Copy** the file into your project's `.claude/` directory (mirroring the same subfolder name).
3. **Find/replace** the placeholders. Each file has a "Customize" section at the top listing every token you need to change.
4. **For shell scripts**: `chmod +x` after copying.

Example: if you want the parallel-linter slash command:
```bash
cp claude-skill-lab/commands/lint.md  <your-repo>/.claude/commands/lint.md
# then edit the file to replace <CONTAINER_BACKEND>, <CONTAINER_FRONTEND>, etc.
```

## What's deliberately *not* here

- **Project-specific knowledge** (architecture diagrams, table schemas, route maps). That belongs in your project's `CLAUDE.md`, not in a generic library.
- **Skills** (`.claude/skills/`). The ones in the source repo were either Anthropic-published (Stripe, Flask, etc.) or project-specific. If you want skill examples, look at [`anthropic/skills`](https://github.com/anthropics/skills) on GitHub.
- **Plugins.** Out of scope here.

## Design principles (the short version)

The patterns in this repo share four habits — see [`docs/design-principles.md`](docs/design-principles.md) for the full version:

1. **Reply contracts are small.** Agents return 1–5 lines. Verbose output stays inside their tool calls. The main conversation never has to scroll through a 500-line test log.
2. **Hooks enforce, agents apply.** A hook blocks a class of mistakes silently; an agent encodes a recipe Claude can choose to run. They're complementary, not interchangeable.
3. **Path-based routing beats config.** Every PostToolUse hook self-filters by file path (`case "$file" in ...`), so you can keep a single catch-all matcher in `settings.json` and let each script decide whether to engage.
4. **Genericity through placeholders, not abstractions.** A script with five `<TOKEN>`s you grep-replace beats a templating engine. The point is to ship, not to build a framework.

## License

MIT. Take what you want.

## Credit

Patterns refined while building [ArmaTune](https://armatune.com). The repo's `.claude/` directory is the source-of-truth implementation; this lab is the genericized export.
