Draft an implementation plan for the user's request, then run up to 3 rounds of unbiased review by a fresh `Plan` subagent, revising between rounds.

The user's request: $ARGUMENTS

## Procedure

### Step 1 — Draft the initial plan

Spawn a `Plan` subagent to produce the first draft. Give it **only** the user's request above (no prior conversation). Ask for a step-by-step implementation plan: critical files, changes per file, architectural tradeoffs, test strategy, and any open questions.

Store the returned plan as `PLAN_V1`.

### Step 2 — Round 1 review (always run)

Spawn a **fresh** `Plan` subagent as reviewer. It must not see your drafting reasoning or the parent conversation — only what you put in its prompt. CLAUDE.md is auto-loaded, so the reviewer already knows the architecture, commands, and coding standards.

The reviewer prompt must include:

1. **The user's original request** (verbatim: `$ARGUMENTS`)
2. **The full plan text** (`PLAN_V1`)
3. **Instruction to verify claims against the real code** — Read/Grep the codebase to check that referenced files, services, and patterns actually exist and are the right home for the changes. Do not judge on vibes.
4. **Review rubric**:
   - Correctness: will this actually solve the user's request?
   - Missing edge cases or error paths
   - Scope: anything added beyond what was asked? Anything required but missing?
   - Architectural fit: matches existing patterns?
   - Testability and test coverage
   - Adherence to the project's `CLAUDE.md` coding standards
5. **Required output contract** — the reviewer MUST start its response with one of exactly two tokens on the first line:
   - `APPROVED` — no substantive issues, plan is ready to execute
   - `NEEDS_CHANGES` — followed by itemized issues (severity: critical/warning/nitpick, with file:line references where applicable)

   Nitpick-only findings still count as `APPROVED` — only critical/warning issues warrant `NEEDS_CHANGES`.

### Step 3 — Decide whether to iterate

- If round 1 returns `APPROVED` → **stop**. Output the final plan and a one-line note that it was approved on the first review.
- If round 1 returns `NEEDS_CHANGES` → revise the plan (produce `PLAN_V2`) addressing each critical/warning issue. Then run **round 2**.

### Step 4 — Round 2 (only if round 1 said NEEDS_CHANGES)

Spawn another **fresh** `Plan` subagent. Same rubric as round 1, but include an additional section:

> **Prior concerns and how this revision addresses them:**
> [Short bulleted list: each prior critical/warning issue + one sentence on how `PLAN_V2` resolves it.]
>
> Verify that each prior concern is actually resolved in the plan below — do not take the author's word for it. Independently assess the revised plan on its own merits as well.

Do **not** paste the previous reviewer's full critique (anchoring bias). Only the distilled concerns + resolutions.

- If round 2 returns `APPROVED` → stop.
- If `NEEDS_CHANGES` → produce `PLAN_V3` and run round 3.

### Step 5 — Round 3 (only if round 2 still said NEEDS_CHANGES)

Same as round 2 but with the round-2 concerns + resolutions. This is the last round regardless of outcome. If round 3 still flags issues, surface them to the user rather than silently accepting the plan.

## Final output to the user

Report:

1. **Final plan** (the latest version — V1, V2, or V3 depending on where we stopped).
2. **Review changelog** — one short paragraph per round: what the reviewer flagged and what changed in response. If we stopped at round 1, just say "Approved on first review."
3. **If round 3 still flagged NEEDS_CHANGES**: surface the remaining concerns clearly so the user can decide whether to accept the plan, push further, or change direction.

## Rules

- Each reviewer subagent is spawned fresh via the `Agent` tool with `subagent_type: "Plan"`. Never reuse a reviewer across rounds — each round gets a new unbiased reader.
- Never pass your parent-conversation transcript or your own drafting reasoning into the reviewer prompt.
- The reviewer is read-only (Plan agent has no Edit/Write). Do not ask it to rewrite the plan — that is your job based on its feedback.
- Do not downgrade the output contract. The reviewer must start with `APPROVED` or `NEEDS_CHANGES` so the loop condition is machine-checkable.
