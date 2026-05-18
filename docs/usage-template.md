# USAGE.md template

A page that lives at `.claude/USAGE.md` in your project, explaining to your **teammates** what tooling lives in this repo's `.claude/` directory and how to use it. Different from `CLAUDE.md` — that's Claude's preamble, this is human-readable docs.

Adapt this skeleton:

---

```markdown
# Claude Code workflow — <PROJECT_NAME>

How to use the Claude Code tooling that lives in this repo. Everything below is committed under `.claude/` and `bin/`, so any teammate's Claude picks it up automatically once they pull <BASE_BRANCH>.

If you've never used Claude Code: install the CLI, run `claude` from the repo root, and read `CLAUDE.md` first — it has the project conventions Claude follows by default.

---

## TL;DR cheat sheet

| When you want to… | Use |
|---|---|
| Pick up a GitHub issue and start a properly-named branch | `/issue <num>` |
| Sanity-check that all services are up | `/health` |
| Run all project linters before committing | `/lint` (or `/lint --fix`) |
| Apply uncommitted code changes to running containers | `restart-services` agent |
| Diagnose a runtime error without dumping 500 log lines | `log-investigator` agent |
| Run only the tests affected by your uncommitted changes | `test-changed` agent |
| Add a database migration matching project conventions | `migration-writer` agent |
| Take a DB snapshot before a risky op | `db-snapshot` agent |

Slash commands (`/foo`) you type yourself. Agents are invoked by Claude on your behalf — just describe the goal ("restart what's needed", "run the affected tests") and Claude will route to the right agent.

---

## Slash commands

<list each one with a one-paragraph description, an example invocation, and
1-3 bullets about what it does and what it won't do>

---

## Subagents

<one section per agent. for each:
 - what triggers Claude to invoke it
 - the one-line reply format it returns
 - what it refuses to do
 - color code (optional, for visual scanning)>

---

## Auto-running hooks

<table of hooks: name, when it fires, what it does, timeout. mention the
escape hatch — "run it manually in a terminal outside Claude" — for any
blocking hook.>

---

## Permissions allowlist

<list of pre-approved Bash patterns from settings.json with a one-line
explanation of why each is on the list>

To add new patterns: edit `.claude/settings.json` directly, or use the `fewer-permission-prompts` skill which scans your transcripts for repeated approvals and proposes additions.

---

## Typical session flow

```
1. /issue <num>                  # branch and read the spec
2. <code, hooks lint on save>
3. <"apply my changes">          # → restart-services agent
4. <"run the affected tests">    # → test-changed agent
5. /lint                         # sanity check
6. /commit <branch-name>
7. /pr
```

If something breaks at step 3 or 4: tell Claude the symptom → `log-investigator`.
If you're about to do something destructive: "snapshot the DB first" → `db-snapshot`.

---

## Maintenance

- New slash commands → add a `.md` file under `.claude/commands/`. Filename (minus `.md`) is the command name.
- New subagents → add a `.md` file under `.claude/agents/` with frontmatter (`name`, `description`, `tools`, `color`).
- New hooks → edit `.claude/settings.json` and drop the script under `.claude/hooks/`. Make it executable. Have it self-filter by path. Test with a canned JSON payload before committing.
```
