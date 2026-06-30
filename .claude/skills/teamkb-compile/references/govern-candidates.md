# Govern: the deterministic system disposes (the differentiator)

This is the half that separates the Governed Second Brain from Karpathy's LLM-Wiki: the model proposed
candidates; now **deterministic code decides** what becomes durable memory, and writes a SHA-256
hash-chained **receipt** for each decision. The nightly job must run this — not just dump the model's
output. **The govern step is the point.**

Mirrors `/brain-save`'s write path exactly, batched over the day's candidates.

## Step 1 — Search-before-save (always, both modes; read-only)

For **each** candidate, call:

```
brain_search { query: "<title> + key content terms", scope: "all" }
```

Summarize the `qmd://` hits. Mark the candidate:
- **`covered`** — the brain clearly already stores this fact. (The inbox does **not** dedupe at intake;
  only promotion dedupes — so this pre-save search is what keeps the inbox from piling up.)
- **`new`** — no clear coverage. An **empty** result (qmd not on PATH, or empty brain) means *no known
  coverage* → `new`. It is **not** a block.

Carry the `new`/`covered` annotation into the audit record and the digest.

## Step 2 — Branch on MODE

### `digest` mode → STOP here (no durable writes)

Do **not** call `brain_capture` or `brain_govern`. The digest (Phase 5) reports each candidate with its
`new`/`covered` annotation ("here's what I'd capture"). This is the safe first-few-days rollout.

### `auto` mode → capture then govern

1. **Capture each `new` candidate** (skip `covered` ones):
   ```
   brain_capture { title, content, category, filePaths? }
   ```
   This appends the proposal to the local spool. `category` must be one of:
   `decision | pattern | convention | architecture | troubleshooting | onboarding | reference`
   (omit → defaults to `reference`). It returns a `candidateId`.

2. **Govern once, after all captures:**
   ```
   brain_govern   // no args
   ```
   It drains the **whole** spool in one deterministic pass — dedupe → policy/secret-detection →
   promotion — appends **one hash-chained audit event per decision**, and refreshes the qmd index.
   Calling it once after N captures is correct and efficient (it is not per-candidate).

   It returns counts:
   ```json
   { "ingested": N, "promoted": p, "rejected": r, "duplicates": d, "flagged": f, "indexUpdated": true|false }
   ```

3. **Record every outcome.** `promoted` memories get a `qmd://` citation; `rejected` / `duplicates` /
   `flagged` each have a reason from the deterministic policy. **A rejection/duplicate/flag is the
   pipeline working as designed** — record the reason in the audit line; never edit the candidate to
   force it through.

## Why one `brain_govern` for the batch

`brain_govern` drains the entire spool, so the night's captures are governed together: cross-candidate
dedupe sees the whole batch at once, and the audit chain advances once per decision in a single coherent
pass. (If you governed per-candidate you'd pay the index refresh N times for no benefit.)

## Secrets — defense in depth

The distiller is told never to emit a secret, and govern's **policy/secret-detection** is a deterministic
**backstop** that flags/rejects candidates that smell like comp/PII/secrets. Treat the backstop as a
safety net, not the primary gate — if you ever see a secret in a candidate, **drop it before capture**.

## qmd absent

If `qmd` is not on `PATH`, `brain_govern` still completes capture + policy + promotion + the audit
receipt; only the post-promote **index refresh** is skipped (`indexUpdated: false`, with a note). The new
memory won't appear in `brain_search` until qmd is installed and govern re-runs. This is non-fatal — log
it and continue.

## Verify (optional, recommended in auto mode)

After the night's writes, call `brain_audit_verify` to confirm the SHA-256 chain **and** the external
anchor log are intact (it catches a silent history rewrite the chain alone would miss). Include the
verdict in the summary.
