# Decision-model trial: classifying stale GCP-era memories (2026-10-03)

**Question.** Can a small, cheap, calibrated classifier (the new "decision model" category: Jev, Cloudflare Clef,
GLiNER2.5-Decide) replace slow LLM-agent skimming for the stale-term review queue (835 active memories that mention
GCP/Firebase/Netlify/Vertex)? Bead context: truth-maintenance epic `compile-then-govern-39z`.

## Method

- **Sample:** 198 rows stratified from the queue (60 prescriptive-command, 30 historical-marker, 17 authoritative,
  30 product-path, 61 other), full text (first 3,500 chars).
- **Labels:** two independent labeler passes (different agents per pass) read the full text and quoted verbatim evidence
  (all 396 quotes verified as substrings). Test: *would an engineer following this document today provision or depend on
  GCP for our infrastructure?* Classes: ARCHIVE_STALE, KEEP_HISTORICAL, KEEP_PRODUCT, KEEP_CURRENT.
- **Agreement:** 91.4% four-class (kappa 0.88); 95.5% archive-vs-rest (kappa 0.90). 17 disagreements adjudicated by the
  operator under the test above (2 became ARCHIVE_STALE). Gold: 65 archive-stale / 58 historical / 52 current / 23 product.
  Caveat: both labelers are one model family, so agreement measures consistency, not ground truth. A human spot-check of
  40 rows is still owed.

## Results

| Model | 4-class accuracy | ARCHIVE_STALE | Notes |
|---|---|---|---|
| Always the biggest class | 0.33 | n/a | floor |
| Embedding (local EmbeddingGemma, 768-d) + logistic regression, 5-fold x2 | 0.75 | AUROC 0.92; P=1.00 at p>=0.9 but recall 0.15 | ECE 0.09 |
| TF-IDF + logistic regression | 0.745 | AUROC 0.93 | ECE 0.18 raw, 0.12 Platt |
| TF-IDF + embeddings | **0.77-0.78** | AUROC 0.93; P=1.00 at p>=0.9, recall 0.05-0.17 | ECE 0.08 raw |
| GLiNER2.5-Decide (340M), zero-shot, label names | 0.21 | recall 0.03 | ECE 0.23 |
| GLiNER2.5-Decide, zero-shot, described labels | 0.24 | recall 0.06 | ECE 0.17 |
| Cloudflare Clef-flash (9B) | not run | | needs ~7.5 GB RAM and a 5.8 GB download; dev box disk was at 99-100% and Buzz has ~5 GB free; Workers AI would send private text off-box |

n = 198, so accuracy has roughly +/-6 points of sampling error. 5-fold CV, not a held-out set.

## Conclusions

1. **Zero-shot decision models do not fit this task.** GLiNER2.5-Decide is a specialist for short intent-routing text;
   deciding what a long runbook is *for* is a reasoning-style judgment, which is where the Jev/Clef comparisons show the
   weakest results for these models. Do not use zero-shot decision models for memory-staleness gating.
2. **A trained local baseline is useful as an advisory queue-sorter, not as a decider.** ~77% four-class accuracy, and when
   it is very confident about ARCHIVE_STALE (p>=0.9) it was right every time on this sample, though that covers only a small
   share of true cases. Use it to order human review, never to archive on its own (the brain's policy engine is model-free by
   design; a classifier here is advisory or upstream of the spool).
3. **Label-quality is the real lever.** The two labelers disagreed on 17 rows, nearly all on the definitional gray area:
   point-in-time reports about GCP-era systems (KEEP_HISTORICAL) vs operate-it-now docs (ARCHIVE_STALE). Settle that policy
   before more modeling.
4. **Clef/Jev remain unevaluated here.** Revisit Clef-flash on a box with room, or with a fine-tune on the gold set.

## Environment lessons

- `gliner2` does not declare `transformers` or `peft`; install them explicitly.
- Buzz has no `ensurepip`; `uv` installs to a user-local dir. A detached job needs a transient systemd unit
  (`sudo systemd-run --unit=... -p MemoryMax=3G -p CPUQuota=300%`); a backgrounded process dies with the SSH session.
- The dev box root disk reached 100% during the session (another session ran its own recovery). Do not start multi-GB
  installs on it; Buzz has ~260 GB free.
- All trial files were shredded from Buzz after the run; no process or service was left.

Related: `024-AT-RPRT` (reranker re-measure on Buzz), `023-AT-RPRT` (reference-import triage).
