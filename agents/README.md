# Subagents

Subagents are short-lived sub-conversations with their own context. They run their tool calls in isolation and return a tight summary, so verbose output (build logs, full test runs, migration diffs) never lands in your main session.

## What's here

| File | Role | Project-specific bits |
|---|---|---|
| [`restart-services.md`](restart-services.md) | After code edits, apply the minimum docker/build/migrate commands needed to make changes visible in running containers | docker-compose service names; path-based rules in the helper script |
| [`log-investigator.md`](log-investigator.md) | Diagnose a runtime symptom by tailing the right logs; return 5 lines (finding/evidence/where/likely/next) | symptom→service map |
| [`test-changed.md`](test-changed.md) | Run only the tests affected by uncommitted changes; one-line summary | test framework commands; file→test mapping rules |
| [`migration-writer.md`](migration-writer.md) | Hand-write database migrations matching project conventions | ORM choice (template here is Laravel; adapt for Prisma, Alembic, Knex, etc.) |
| [`db-snapshot.md`](db-snapshot.md) | mysqldump-to-file before risky DB ops | DB engine + container name (template here is MySQL in Docker) |

## How a subagent file works

- Frontmatter sets `name`, `description`, `tools`, optional `color`.
- The `description` is what Claude reads to decide when to invoke it — make it specific. Lead with the verb of the job ("Diagnoses…", "Hand-writes…", "Runs…") and end with a one-liner about when to delegate to it.
- The body is the agent's system prompt. Structure I've found works well:
  - `<role>` — one paragraph: what is this agent's one job?
  - `<critical_rules>` — numbered, sharply-worded "never X / always Y" rules
  - `<workflow>` — the steps the agent should follow
  - `<reply_format>` — the *exact* shape of the final reply, with examples
  - `<edge_cases>` — known gotchas
  - `<what_not_to_do>` — bulleted "don't" list, including "do not spawn other subagents"

The reply-format section is the most important part. Specifying the exact shape of the reply is what prevents the agent from dumping 200 lines of build output into your main context.

## Customizing

Same as commands — every file has placeholders in `<ANGLE_BRACKETS>`. Common ones:

- `<PROJECT_NAME>` — used in role descriptions
- `<CONTAINER_*>` — Docker container names
- `<BASE_BRANCH>` — your integration branch
- `<HELPER_SCRIPT>` — path to a `bin/` script the agent wraps (only some templates)

## Pattern: agent + helper script

Several of these agents (`restart-services` in particular) are thin wrappers around a shell script that lives at `bin/<name>.sh` in the repo. The script encodes the rules; the agent is the conversational interface and the place to enforce reply discipline. This is deliberate:

- **The script is testable** — you can run it directly outside Claude.
- **The script is reusable** — humans on the team can run it without Claude.
- **The agent stays thin** — its only logic is "run the script with these flags, relay the one-line output".

Where a template depends on a helper script, the README/agent body calls it out. The script itself is out of scope for this lab (too project-specific to template), but the agent prompt gives you the shape it needs.
