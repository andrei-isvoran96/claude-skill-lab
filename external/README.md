# External tools

Pointers to third-party tools that complement this repo. Nothing here is shipped — these are projects you install separately. The bar for inclusion is **"fills a gap this repo deliberately leaves"** (see the top-level `README.md` → "What's deliberately *not* here").

Keep entries focused. If a tool needs more than a short section to explain, it probably belongs in its own repo, not in this index.

## What's here

| Tool | Fills the gap of | Install |
|---|---|---|
| [Skill Seekers](#skill-seekers) | Skill generation from docs/repos/PDFs (this repo ships no skills) | `pip install skill-seekers` |
| [anthropic/skills](#anthropicskills) | Reference skills to read when authoring by hand | clone the repo |

---

## Skill Seekers

> https://github.com/yusufkaraaslan/Skill_Seekers

Converts documentation sites, GitHub repositories, PDFs, videos, notebooks, and wikis into structured Claude Skills. Same prep pipeline also exports to 19 other AI/RAG targets (Gemini, OpenAI, LangChain, LlamaIndex, Haystack, Pinecone, ChromaDB, FAISS, Qdrant, Cursor, Windsurf, Cline, IBM Bob, etc.) — "one prep, every target."

### Why it pairs with this repo

This repo ships templates for commands, agents, hooks, and settings — but deliberately not skills, because the useful ones are either Anthropic-published or project-specific (see the top-level README). Skill Seekers fills that gap from the *generation* side: instead of hand-authoring a `SKILL.md`, point it at the upstream source.

### Typical usage

```bash
pip install skill-seekers

# 1. Build a structured knowledge asset from any source
skill-seekers create https://docs.react.dev/
skill-seekers create facebook/react
skill-seekers create ./my-project
skill-seekers create path/to/whitepaper.pdf

# 2. Package for Claude (produces a ZIP + SKILL.md)
skill-seekers package output/react --target claude

# 3. Drop the unpacked result into your project
unzip output/react/react-claude-skill.zip -d .claude/skills/react/
```

After step 3, the skill is auto-loaded by Claude Code on the next session for that project.

### When to suggest it

- User wants to give Claude expertise in a library/framework whose docs are online.
- User has internal docs (wiki, PDFs, a private repo) they want Claude to know cold.
- User is about to hand-write a long `SKILL.md` from scratch — stop them and run this first; edit the output instead of starting blank.

### When *not* to suggest it

- The "skill" is really a workflow Claude should execute (use a **slash command** from `commands/` instead).
- The "skill" is really a noise-keeper for a verbose tool call (use a **subagent** from `agents/` instead).
- The expertise is one paragraph of project conventions (put it in `CLAUDE.md`).

### Ecosystem

| Repo | What |
|---|---|
| [`Skill_Seekers`](https://github.com/yusufkaraaslan/Skill_Seekers) | Core CLI + MCP server |
| [`skill-seekers-configs`](https://github.com/yusufkaraaslan/skill-seekers-configs) | Community presets (Django, React, etc.) |
| [`skill-seekers-plugin`](https://github.com/yusufkaraaslan/skill-seekers-plugin) | Claude Code plugin |
| [`skill-seekers-action`](https://github.com/yusufkaraaslan/skill-seekers-action) | GitHub Action for CI/CD-driven skill builds |
| [`skillseekersweb`](https://github.com/yusufkaraaslan/skillseekersweb) | Web UI + browseable preset catalog |
| [`homebrew-skill-seekers`](https://github.com/yusufkaraaslan/homebrew-skill-seekers) | macOS Homebrew tap |

---

## anthropic/skills

> https://github.com/anthropics/skills

Anthropic's reference skill collection (Stripe, Flask, and others). Read these when you're authoring a `SKILL.md` by hand and want to see the canonical shape — frontmatter conventions, how a good skill segments knowledge, what level of detail belongs in the file vs. supporting docs.

Not a tool to install; a corpus to read.

---

## Adding to this index

Two-line rule of thumb:
1. The tool must fill a gap this repo *intentionally* leaves (not a gap we should close ourselves).
2. The section should be short enough that someone scanning the file can decide in 30 seconds whether they need it.

Update both this file and the "What's in here" table in the top-level `README.md` in the same change.
