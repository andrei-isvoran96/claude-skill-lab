# CLAUDE.md template

Drop this at the **project root** as `CLAUDE.md`. Claude Code auto-loads it into every session for that project.

Keep it short and surprising. See [design-principles.md](design-principles.md) §7 for the rule.

---

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Architecture

<one paragraph: what is this project, who is it for, what's the high-level shape>

<service-by-service breakdown table — what each service does, where its code lives, how they communicate>

### Cross-service communication
- <how does service A talk to service B>
- <what's the auth model between them>
- <any non-obvious protocol choices (SSE, websockets, polling)>

### Internals worth knowing

<For each major service, a few bullets about non-obvious things — patterns
they follow, where the "interesting" code lives, what's load-bearing.>

## Common Commands

<group by service. include the exact docker exec / npm / cargo / whatever
invocation. don't paraphrase.>

### Build & run
```bash
<exact commands>
```

### <Service-name>
```bash
<service-specific commands>
```

### Logs
```bash
<how to tail logs>
```

## Development loop

<this is the most-valuable section if your project has any non-obvious "what
do I need to restart after editing X" rules. spell out the path → action
mapping in a table. CLAUDE.md will save you from a hundred "why didn't my
change apply" rounds.>

### After <language A> changes
- <when does a restart matter>
- <which container(s) to restart>
- <which hot-reload paths bypass the restart>

### Always-run-after-edit linters
```bash
<the lint command for each language>
```

## Environment gotchas

<the small things that bite new contributors. examples:
 - DB host is `mysql` (Docker DNS), not 127.0.0.1
 - MySQL port is 3307 on the host (not 3306)
 - Tests use a separate DB; main DB is not wiped by `artisan test`
 - Sanctum stateful domains are configured per-env>

## Branch strategy

<one diagram of how branches flow. e.g.:>

```
main ← production (tagged releases)
 └── development ← integration branch
      ├── feature/<issue#>-<title>
      └── bug/<issue#>-<title>
```

**Always branch from <BASE_BRANCH>, never from main.**

## Coding standards

<one short paragraph per major language. examples:
 - PHP: PSR-12 via Pint. Type hints on all parameters/returns. Services over facades.
 - TypeScript: Strict, no `any`. React 19 patterns. Tailwind for styling.
 - API: RESTful under `/api/`. All input validated via Form Requests.>

## Storage

<where do uploads go? signed URLs? S3-compatible service?>
```

---

## What NOT to put in CLAUDE.md

- File trees that mirror what `ls` would show.
- Lists of which tables exist (Claude can read your migrations).
- Tutorial content for the frameworks you use ("Laravel uses Eloquent…" — Claude knows).
- Aspirations / roadmap. CLAUDE.md is operational, not strategic.
- Long debugging postmortems. Those belong in commit messages or `docs/`, not in every session's preamble.

Every line you add to CLAUDE.md is read into every Claude session for this project. If a line isn't earning its keep on >50% of sessions, cut it.
