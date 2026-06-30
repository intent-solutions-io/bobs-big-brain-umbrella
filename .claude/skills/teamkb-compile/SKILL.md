---
name: teamkb-compile
description: |
  Nightly "compile the day's work into the governed brain." Gathers the team's daily work
  signals (git commits, merged PRs, closed beads, decision records, Claude session transcripts)
  across ~/000-projects for a date window, lets Claude COMPILE them into durable governed-memory
  candidates (decisions, patterns, gotchas, conventions), then runs the deterministic GOVERN path
  (brain_capture -> brain_govern: dedupe / policy / secret-scan / promotion) with a SHA-256
  hash-chained receipt per decision. The model proposes; deterministic code disposes. Ships
  digest-first (emails a review digest, no durable writes) then flips to auto-promote. Side-effecting
  in auto mode — invoke it explicitly or via the nightly cron wrapper. Trigger with "/teamkb-compile".
allowed-tools: 'Read, Write, Edit, Glob, Grep, Bash(command:*), Task, mcp__governed-brain__brain_search, mcp__governed-brain__brain_capture, mcp__governed-brain__brain_govern, mcp__governed-brain__brain_status, mcp__governed-brain__brain_audit_verify'
version: 1.0.0
author: Jeremy Longshore <jeremy@intentsolutions.io>
license: Proprietary
tags:
- brain
- governance
- automation
- compile
- second-brain
- backfill
argument-hint: '[YYYY-MM-DD [YYYY-MM-DD]] [--auto | --digest]'
model: opus
compatibility: 'Designed for Claude Code. Runs locally on the box that owns ~/.teamkb (the brain). Requires the governed-brain MCP server (governed-second-brain-plugin local mode) — the cron wrapper passes it via --mcp-config. Requires qmd on PATH for the post-promote index refresh.'
disable-model-invocation: true
---
# teamkb-compile

## Overview

The governed brain (`~/.teamkb`) only stays current when a human runs `/brain-save`. Nothing
auto-captures the team's daily work, so the brain drifts behind reality. This skill closes that gap:
a nightly pass that turns *"what we did today"* into governed memories.

It is the lightweight, day-scoped analog of `/blog-backfill` — same proven shape (a scheduled Claude
that turns the day's git/PR/beads/decision/transcript signals into a durable artifact, with an audit
trail) — but the output is **governed memories**, not blog posts.

**The pipeline, in one line:** *gather the day → Claude compiles candidates → deterministic code governs
them → receipts + audit record → digest or auto-promote.*

```
gather (git+PRs+beads+decisions+transcripts)
   │
   ▼
COMPILE  ── memory-distiller agent ──▶  candidate memories (decision/pattern/gotcha/convention)
   │                                      (the model PROPOSES — Karpathy's LLM-wiki compile step)
   ▼
GOVERN   ── brain_capture → brain_govern ──▶  dedupe / policy / secret-scan / promotion
   │                                            (deterministic code DISPOSES, one hash-chained receipt each)
   ▼
AUDIT    ── decisions.jsonl record  +  digest email (digest mode) | govern summary (auto mode)
```

### Why this is the wedge, not a dump

Andrej Karpathy's "LLM Wiki" (raw → the LLM compiles → wiki) is the second-brain pattern everyone is
copying — and **ICO already is that pattern**. The differentiator is the second half: *who decides what
becomes durable memory.* In the LLM-Wiki pattern the model is judge and jury. Here the model only
**proposes**; **deterministic code** (dedupe / policy / secret-scan / promotion) **disposes**, and every
decision leaves a SHA-256 hash-chained receipt. So this nightly job must run the deterministic **govern**
step — not just write whatever the model produced. The govern step *is* the point.

## Modes — digest-first, then auto

A single switch (argument `--auto`/`--digest`, or env `TEAMKB_COMPILE_MODE=auto|digest`) picks the mode.
**Default is `digest`.**

| Mode | Durable brain writes? | What it does | When |
|------|:---:|---|---|
| `digest` (default) | **No** | gather → distill → annotate each candidate as *new* vs *already-covered* (read-only `brain_search`) → **email a review digest** ("here's what I'd capture") → write a `decisions.jsonl` record. **No `brain_capture`/`brain_govern`.** | First few days of any new deployment — lets a human judge distillation quality before trusting it to write. |
| `auto` | **Yes** | gather → distill → search-before-save → `brain_capture` each genuinely-new candidate → `brain_govern` once (dedupe/policy/promote + receipts) → summary (promoted/rejected/duplicate/flagged) → `decisions.jsonl` record. | After the digest output has been reviewed and behaves. |

**The rollout is self-managing — nobody flips a switch.** The cron wrapper (`~/bin/teamkb-compile-daily.sh`)
starts in `digest`, banks clean digest nights, and **auto-graduates itself to `auto`** after a soak
(default 3 nights), persisting the decision. The skill supports both modes at any time; an explicit
`--auto`/`--digest` or `TEAMKB_COMPILE_MODE` still overrides. See `references/scheduling.md`.

## Arguments

`$ARGUMENTS`:
- *(none)* — date window defaults to **yesterday** (00:00–24:00 local), mode from `TEAMKB_COMPILE_MODE` env (else `digest`).
- `YYYY-MM-DD` — single day.
- `YYYY-MM-DD YYYY-MM-DD` — inclusive start / exclusive-end-of-day range.
- `--auto` / `--digest` — force the mode (overrides the env var).

Examples: `/teamkb-compile` · `/teamkb-compile 2026-06-27` · `/teamkb-compile 2026-06-20 2026-06-27 --auto`

## Prerequisites

- Runs on the box that **owns `~/.teamkb`** (the brain). Interactive sessions on that box have the
  `governed-brain` MCP if the plugin is enabled; the **cron wrapper supplies it explicitly** via
  `--mcp-config ${CLAUDE_SKILL_DIR}/scripts/brain-mcp-config.json --strict-mcp-config` (the plugin is
  not in `enabledPlugins`, so headless `claude -p` would otherwise have no `brain_*` tools).
- `qmd` on `PATH` so the govern step can refresh the search index after a promotion. If absent, capture
  + govern + the audit receipt still complete; only fresh-search visibility waits.
- All project repos cloned under `/home/jeremy/000-projects/` (no cloning needed). `gh` authenticated for
  PR data; `bd` for closed-bead history.

## Instructions

**Phase markers (MANDATORY for cron diagnosability)** — before each phase below, emit one Bash echo so
the cron wrapper's log can be bisected by phase without parsing transcripts:

```bash
echo "[phase: <name>] <one-line context>"
```

Allowed `<name>` values in order: `setup`, `gather`, `distill`, `govern`, `audit`, `digest`. The
`<one-line context>` is free text — the target date, the candidate count, the mode, an artifact path.

---

### Phase 0 — Setup

Emit `[phase: setup] ...`. Then:

1. **Resolve the date window and mode.** Parse `$ARGUMENTS` per the table above. Compute `DATE`
   (`YYYY-MM-DD`, the start day) and `NEXT_DATE` (exclusive end). Resolve `MODE` (`auto` or `digest`):
   explicit `--auto`/`--digest` wins, else `$TEAMKB_COMPILE_MODE`, else `digest`. Echo the resolved
   window + mode.
2. **Sanity-check the brain.** Call **`brain_status`**. If it errors with `native-store-unavailable`,
   STOP — the box can't reach the brain (wrong host, or `better-sqlite3` missing); report and exit. The
   status's current counts are your before-snapshot for the audit record.

### Phase 1 — Gather the day's work

Emit `[phase: gather] ...`. Read **`references/gather-signals.md`** for the exact pattern, then run
the gather helper:

```bash
${CLAUDE_SKILL_DIR}/scripts/gather-signals.sh "$DATE" "$NEXT_DATE" > "$SIGNALS"
```

(`SIGNALS=/tmp/teamkb-compile/signals-$DATE.txt`, created by the script.) It collects, across
`~/000-projects` for the window: git commits (all repos), merged PRs, closed beads, changed decision
records (`000-docs/*-AT-DECR-*`), and Claude session transcripts (via the vendored
`scan-session-transcripts.py`). **If the signal doc is empty / shows no activity, exit clean (no-op)** —
do not invent memories from nothing. Log `"No activity for <window> — nothing to compile."`

### Phase 2 — Compile: distill candidates (the model PROPOSES)

Emit `[phase: distill] ...`. **Dispatch the `memory-distiller` agent** (defined in
`agents/memory-distiller.md`) via the **Task** tool, handing it the signal doc. Read
**`references/distill-candidates.md`** for the full briefing, the candidate JSON schema, the category
enum, and the hard rules (one candidate per durable item; durable lessons not raw commits; **never emit a
secret/token/credential**). The agent returns a JSON array of candidates. If it returns `[]` (a routine
day with nothing durable), that is a valid outcome — proceed to a "0 candidates" digest/summary and the
audit record. **Do not inline-distill** unless the Task tool itself errors.

### Phase 3 — Govern (deterministic code DISPOSES)

Emit `[phase: govern] ...`. Read **`references/govern-candidates.md`** for the exact flow.

**For every candidate, first do search-before-save:** call **`brain_search`** with
`{ query: "<title> <key terms>", scope: "all" }`. Summarize what the brain already knows from the
`qmd://` hits and mark the candidate **`covered`** (clearly already stored) or **`new`**. An empty
result is *no known coverage* → `new` (not a block).

**Then branch on MODE:**

- **`digest`** — make **no** durable writes. Carry the `new`/`covered` annotation into the digest. Done.
- **`auto`** — for each `new` candidate call **`brain_capture`** `{ title, content, category, filePaths? }`
  (spools the proposal). After all captures, call **`brain_govern`** **once** (it drains the whole spool
  through dedupe → policy/secret-detection → promotion and writes one hash-chained receipt per decision).
  Record its returned counts (`promoted`, `rejected`, `duplicates`, `flagged`, `indexUpdated`). A
  rejection/duplicate/flag is the governance pipeline **working as designed** — capture the reason, never
  work around it.

### Phase 4 — Audit record

Emit `[phase: audit] ...`. Append **one** JSON line to
`${CLAUDE_SKILL_DIR}/methodology/decisions.jsonl` per the schema in **`references/audit-and-digest.md`**
(date, window, mode, candidate count, per-candidate disposition, govern counts, brain before/after).
Append-only — never edit existing lines.

### Phase 5 — Digest / summary

Emit `[phase: digest] ...`. Read **`references/audit-and-digest.md`** for the format. **Write** the
digest to `/tmp/teamkb-compile/digest-$DATE.md` (markdown). The **cron wrapper owns delivery** — it reads
this file and emails it + pushes an ntfy status (single notification owner, exactly like
`/blog-backfill`). When run interactively you'll just see it on screen; also print the path.

- **`digest` mode** — write the review digest: "here's what I'd capture" — each candidate's title,
  category, one-line content, and `new`/`covered` annotation, grouped by category, with a header line
  (date, window, candidate count). No brain writes happened.
- **`auto` mode** — write the run summary: N promoted (with `qmd://` citations), N rejected/duplicate/
  flagged (with reasons), and the brain before/after totals. Call **`brain_audit_verify`** and include
  the verdict (chain + anchors intact?) at the foot.

## Output

| Artifact | Location |
|---|---|
| Signal doc (transient) | `/tmp/teamkb-compile/signals-<DATE>.txt` |
| Distilled candidates (transient) | `/tmp/teamkb-compile/candidates-<DATE>.json` |
| Audit record (append-only) | `${CLAUDE_SKILL_DIR}/methodology/decisions.jsonl` |
| Human digest / run summary (markdown) | `/tmp/teamkb-compile/digest-<DATE>.md` (cron wrapper emails it) |
| Governed memories (auto mode) | `~/.teamkb` (promoted via `brain_govern`; cited `qmd://...`) |

## Error Handling

| Situation | Response |
|---|---|
| `brain_status` → `native-store-unavailable` | Not on the brain's host (or `better-sqlite3` missing). Stop; do not fabricate. |
| Empty signal doc / no activity | Exit clean (no-op). Never invent memories. |
| `memory-distiller` returns `[]` | Valid — emit a "0 candidates" digest/summary + audit record. |
| Task tool errors | Inline-distill as a fallback (only after a real tool error), per `references/distill-candidates.md`. |
| `brain_govern` rejects / dedupes a candidate | Governance working as designed. Record the reason in the audit line. |
| `qmd` not on `PATH` | Govern + receipt still complete; the post-promote index refresh is skipped (logged by `brain_govern`). |
| A candidate may contain a secret | Drop it before capture. Do not rely on the pipeline's secret-scan as the only gate. |

## Guardrails

- **Never** capture content containing secrets, tokens, or credentials (session transcripts may contain
  them — the distiller is told to strip; the govern secret-scan is a backstop, not the primary gate).
- One candidate per **durable** item. Routine "got stuff done" days legitimately produce few or zero
  candidates — a small honest set beats a padded one (the same anti-inflation discipline `/blog-backfill`
  uses for tiers).
- A govern rejection/duplicate is the system working — surface it, don't route around it.
- `decisions.jsonl` is append-only.

## Scheduling

Runs **locally** — Claude Routines run in Anthropic's cloud, which **cannot reach** the brain (the INTKB
API binds the tailnet-only IP and the data is local `~/.teamkb`). The cron wrapper
`~/bin/teamkb-compile-daily.sh` fires `claude -p "/teamkb-compile"` nightly **~03:30**, before the 04:30
`teamkb-backup.timer`, so the night's new memories land in that night's backup. See
`references/scheduling.md`.

## Resources

**Reference files:** [gather-signals](references/gather-signals.md) ·
[distill-candidates](references/distill-candidates.md) · [govern-candidates](references/govern-candidates.md) ·
[audit-and-digest](references/audit-and-digest.md) · [scheduling](references/scheduling.md).

**Agent:** [memory-distiller](agents/memory-distiller.md).

**Scripts:** [gather-signals.sh](scripts/gather-signals.sh) ·
[scan-session-transcripts.py](scripts/scan-session-transcripts.py) ·
[brain-mcp-config.json](scripts/brain-mcp-config.json).

**Cron wrapper (owns scheduling + email/ntfy):** `~/bin/teamkb-compile-daily.sh` (see
[scheduling](references/scheduling.md)).

**Audit trail:** [decisions.jsonl](methodology/decisions.jsonl) (append-only).

## Related

- `/brain-save` (governed-second-brain plugin) — the single-item write path this skill batches nightly.
- `/brain` — cited queries against the brain.
- `/blog-backfill` — the scheduled-Claude pattern this skill is modeled on.
