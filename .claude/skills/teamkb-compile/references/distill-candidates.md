# Compile: distill the day into governed-memory candidates

This is the **compile** step — Karpathy's "the LLM maintains the wiki," scoped to one day. The
`memory-distiller` agent reads the gathered signal doc and proposes durable **memory candidates**. It is
*only* the proposal; the deterministic govern step (next phase) disposes.

## Dispatch

Dispatch via the **Task** tool, handing the agent the signal-doc **path** (not the contents — let the
agent `Read` it, so the main thread stays light):

> You are the **memory-distiller** for the governed second brain. Read the signal doc at
> `/tmp/teamkb-compile/signals-<DATE>.txt`. Follow
> `~/.claude/skills/teamkb-compile/references/distill-candidates.md` exactly. Return a JSON array of
> durable memory candidates (or `[]`). Output **only** the JSON — no prose, no code fence.

Write the returned array to `/tmp/teamkb-compile/candidates-<DATE>.json`.

## What a candidate is

A **durable** unit of team knowledge that a teammate would benefit from finding 30 days from now. Not a
status update, not a raw commit, not "fixed the build." Distill the *lesson*, *decision*, or *fact* —
self-contained, so a reader with no memory of today understands it.

## Candidate JSON schema

```json
{
  "title": "Short, specific, searchable (≤ ~80 chars)",
  "content": "The fact in full, self-contained. State the what AND the why. Include the concrete detail (file/flag/command/path) that makes it actionable. 1–6 sentences.",
  "category": "decision | pattern | convention | architecture | troubleshooting | onboarding | reference",
  "source": "Provenance: repo + PR#/bead-id/decision-record/session that this came from",
  "filePaths": ["optional/relevant/path.ts"],
  "rationale": "One line: why this is durable (what makes it pass the 30-day test)"
}
```

Only `title`, `content`, `category`, `filePaths` are passed to `brain_capture`. `source` and `rationale`
feed the digest + audit record (and your own honesty check).

## Category guide

| Category | Use for |
|---|---|
| `decision` | A choice made **with rationale** — ratified decisions, "we're going X not Y", architecture/tooling calls. Decision records (`AT-DECR`) and PR "why" sections are gold here. |
| `pattern` | A reusable technique/approach that emerged and would be reused. |
| `convention` | A naming / structure / workflow rule the team adopted. |
| `architecture` | A structural fact about how a system is built / where state lives. |
| `troubleshooting` | A gotcha **and its fix** — a debugging lesson worth not relearning. |
| `onboarding` | How to get started with or operate something. |
| `reference` | A durable fact/pointer that doesn't fit the above. |

## Hard rules

1. **Conservative by default.** Most days yield **few** candidates; many routine days yield **zero**.
   A small honest set beats a padded one. Volume of commits ≠ durable knowledge. (Same anti-inflation
   discipline `/blog-backfill` applies to tiers.) Returning `[]` is a correct, common answer.
2. **One candidate per durable item.** Don't bundle three decisions into one; don't split one into three.
3. **Never emit a secret.** Session transcripts can contain `.env` dumps, API keys, tokens, passwords,
   bearer/`scrypt$` values, connection strings. **Never** put any of these in a candidate — not even
   "for context." If a lesson is *about* a secret, state the lesson abstractly (e.g. "rotate the X token
   after pasting it in chat") with **no secret value**. (The govern secret-scan is a backstop, not your
   excuse.)
4. **Prefer distilled sources over raw commits.** PR bodies, decision records, and bead close-reasons are
   already distilled — weight them. Use raw commits/transcripts for rationale and gotchas, not as content
   to dump verbatim.
5. **Self-contained content.** No "see above," no unexplained pronouns, no today-only context.
6. **De-dupe within the batch.** If two signals describe the same durable item, emit one candidate.
7. **Skip the ephemeral.** Routine merges, dependency bumps, version-tag commits, "wip", formatting,
   and anything already obvious in a CLAUDE.md/README → no candidate.
8. **Cross-project is fine.** The brain spans all repos; a candidate can come from any project's signals.

## Output

A single JSON array (possibly empty). **No** markdown fence, **no** commentary — just the array, so the
orchestrator can parse it directly.

## Worked examples

**Strong candidate** (from a decision record + PR):
```json
{
  "title": "Retrieval stays BM25-on-qmd until the eval clears the 0.85 gate",
  "content": "Governed-brain retrieval is BM25-on-qmd (brain_search → qmd search), model-free. The lean sqlite-vec + EmbeddingGemma-300M semantic backend builds ONLY when the Recall@10 eval drops below ~0.85 on a real labeled set AND a user logs a genuine recall miss. Building it sooner is the premature optimization the council ruled out.",
  "category": "decision",
  "source": "qmd-team-intent-kb 000-docs/038-AT-DECR + epic 0t9",
  "filePaths": ["packages/qmd-adapter/src/native"],
  "rationale": "Standing architecture gate that will be re-litigated repeatedly without a durable record"
}
```

**Strong candidate** (from a debugging session — a gotcha + fix):
```json
{
  "title": "Shell redirect target dir must pre-exist before a script that mkdirs it",
  "content": "When a script's own `mkdir -p /tmp/x` is what creates its output dir, an OUTER shell redirect `script.sh > /tmp/x/out.txt` still fails: the shell opens the redirect before the script runs. Create the dir in the caller first, or have the caller not depend on the script's mkdir.",
  "category": "troubleshooting",
  "source": "governed-second-brain session 2026-06-28 (gather-signals.sh smoke test)",
  "rationale": "Non-obvious ordering bug that wastes 10 minutes each time it recurs"
}
```

**NOT a candidate** (routine — return nothing for these):
- "Merged dependabot PR bumping zod to 4.4.3" → dependency bump, ephemeral.
- "Closed 6 beads in the topology epic" → status, no transferable lesson.
- "Refactored 40 files to the new import style" → volume, not knowledge (the *convention* might be — but
  only if it was newly decided today and isn't already in a CLAUDE.md).
