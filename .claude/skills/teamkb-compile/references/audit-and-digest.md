# Audit record + digest

Two artifacts close every run: an append-only **audit record** (`decisions.jsonl`) and a human-readable
**digest** (`/tmp/teamkb-compile/digest-<DATE>.md`). The audit record is the methodology-tracking pattern
`/blog-backfill` uses for calibration, applied to memory compilation; the digest is what a human reads
(emailed by the cron wrapper).

## 1. Audit record — `methodology/decisions.jsonl`

Append **one** JSON line per run (never edit existing lines). Schema:

```json
{
  "date": "2026-06-25",
  "window": { "start": "2026-06-25", "end": "2026-06-26" },
  "mode": "auto",
  "run_at": "2026-06-28T03:30:11Z",
  "candidates_proposed": 13,
  "candidates": [
    { "title": "Retrieval stays BM25-on-qmd until the eval clears 0.85",
      "category": "decision", "annotation": "new",
      "disposition": "promoted", "citation": "qmd://kb-decisions/retrieval-bm25.md", "reason": null },
    { "title": "brain-save must search before capturing",
      "category": "convention", "annotation": "covered",
      "disposition": "skipped-covered", "citation": null, "reason": "already stored (qmd://...)" },
    { "title": "Some near-duplicate lesson",
      "category": "pattern", "annotation": "new",
      "disposition": "duplicate", "citation": null, "reason": "dedupe: matches existing memory ..." }
  ],
  "govern": { "ingested": 11, "promoted": 9, "rejected": 1, "duplicates": 1, "flagged": 0, "indexUpdated": true },
  "brain_before": { "total": 142 },
  "brain_after":  { "total": 151 },
  "audit_verify": "intact"
}
```

Field notes:
- **`disposition`** per candidate is one of:
  `promoted` · `skipped-covered` (search-before-save found it) · `duplicate` · `rejected` · `flagged` ·
  `would-capture` / `would-skip-covered` (digest mode — nothing was actually written).
- **`mode: "digest"`** → `govern` is `null`, `brain_after == brain_before`, dispositions are
  `would-*`. No durable writes happened.
- **`run_at`** is the wall-clock at run time (stamp it from `date -u +%FT%TZ` — don't hardcode).
- **`audit_verify`** is the `brain_audit_verify` verdict in auto mode (`"intact"` / a tamper note); `null`
  in digest mode.

## 2. Digest — `/tmp/teamkb-compile/digest-<DATE>.md`

Write markdown the cron wrapper emails verbatim. Keep it skimmable.

### digest mode — "here's what I'd capture"

```markdown
# teamkb-compile digest — 2026-06-25 (mode: digest, NO writes)

Window: 2026-06-25 00:00 .. 2026-06-26 00:00 · 13 candidates · 11 new / 2 already-covered

> Review mode: nothing was written to the brain. Flip the cron to TEAMKB_COMPILE_MODE=auto when these look right.

## decision
- **Retrieval stays BM25-on-qmd until the eval clears 0.85** — _(new)_ Governed-brain retrieval is BM25... 
  - source: qmd-team-intent-kb 000-docs/038-AT-DECR

## troubleshooting
- **Governance content_length reads parameters['min'], not minLength** — _(new)_ ...

## convention
- **brain-save must search before capturing** — _(already covered — would skip)_ ...
```

### auto mode — "here's what I captured"

```markdown
# teamkb-compile run — 2026-06-25 (mode: auto)

Window: 2026-06-25 00:00 .. 2026-06-26 00:00 · 13 proposed → 9 promoted, 1 rejected, 1 duplicate, 2 skipped-covered
Brain: 142 → 151 memories · audit chain: intact ✓

## promoted (9)
- **Retrieval stays BM25-on-qmd until the eval clears 0.85** (decision) — qmd://kb-decisions/retrieval-bm25.md
- ...

## rejected / duplicate / flagged (2)
- **Some near-duplicate lesson** (pattern) — duplicate: matches existing memory <id>
- ...

## skipped (already covered) (2)
- **brain-save must search before capturing** (convention)
```

## Calibration use

`decisions.jsonl` is the calibration substrate: over time it answers "is the distiller too eager (lots of
rejected/duplicate) or too timid (mostly empty days)?" and "what categories dominate?" — the same way
blog-backfill's `decisions.jsonl` drives `/blog-calibrate`. Keep it append-only so the history is honest.
