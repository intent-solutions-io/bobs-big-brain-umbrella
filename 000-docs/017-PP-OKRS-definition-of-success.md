# 017-PP-OKRS: Definition of Success

**What this is:** a clear, measurable definition of what success looks like for the Bob's Big Brain / Governed Second Brain (GSB) upgrade initiative, derived from the cited research plan (`016-AT-PLAN`). Written before the master blueprint so every epic and bead in `019-PP-PLAN` can be traced to a success criterion here. Objectives are outcomes; key results are measurable and falsifiable. Honesty is a success criterion, not a footnote: a claim we cannot measure or cite is a failure, not a feature.

Written dash-free on purpose (the voice bans em and en dashes). Forbidden absolute-integrity claim words do not appear as GSB claims.

---

## North star

GSB is the only knowledge system where a deterministic gate, not the model, decides what becomes durable; where every durable fact carries a completeness-guaranteed, tamper-evident receipt; where multiple brains federate through a gate that emits cross-brain provenance; and where every public claim is measured on our own data or cited to a 2026 paper. We do not win on retrieval sophistication. We win on who decides what is durable, and on being able to prove it.

Success is reached when a skeptical engineer can read the competitive article, check every number against our own eval or a citation, try to break the completeness and seam claims, and fail.

---

## The measurable objectives

### O1. Retrieval is competitive AND measured (not asserted)

- **KR1.1** A real-query gold set of 30 to 50 queries drawn from actual `brain_search` / `audit_events` logs exists, hand-labeled with the correct `qmd://` answer docs, versioned in-repo.
- **KR1.2** Every retrieval number is reported segmented by exact-term vs conceptual query class, never as one blended figure.
- **KR1.3** The local cross-encoder reranker beats the tuned-BM25 baseline on the conceptual slice by a measured margin (working target: +3 to +8 nDCG@10 on conceptual, roughly 0 on exact-term, with a verified non-regression on exact-term). The number we publish is the one our eval produces.
- **KR1.4** A dense + RRF arm ships to production only if it beats reranked-BM25 on the gold set. Until then it stays behind the measurement gate and BM25 stays the primary arm.

### O2. Govern is the sole, correct, measured admission gate

- **KR2.1** The completeness invariant holds and is tested: the deterministic gate is provably the sole writer of the durable corpus, and any write that cannot emit a receipt fails closed (a side-door-write test proves it).
- **KR2.2** The gate-ordering bug is fixed and tested: a near-duplicate check can never silently reject a contradictory-but-valid write.
- **KR2.3** GOVERN admission-gate precision and recall are reported against a hand-annotated fixture, with dedup and temporal supersession measured as first-class metrics, not folded into a blended accuracy.

### O3. Receipts are complete and git-witnessed

- **KR3.1** Every durable fact has a receipt (completeness enforced at the substrate, per O2).
- **KR3.2** The per-day trace chains are linked into one sequence, so whole-day-file deletion is detectable.
- **KR3.3** The anchor row-count and chain head are wired into the verifier, so tail-truncation is detectable.
- **KR3.4** The anchor checkpoint is pushed to a non-force-pushable git ref on each anchor: the receipts ladder reaches Tier 1 (git-witnessed), and the honest claim "any fact admitted before witnessed checkpoint C cannot be altered without detection" holds.
- **KR3.5** The two audit substrates (ICO kernel traces and the teamkb anchors) are reconciled: one is declared the source of truth and the other is provably derived.
- **KR3.6** Receipt verification runs with no model loaded (model-free integrity check), and the exact per-tier claim (Tier 0 local, Tier 1 git-witnessed, Tier 2 externally anchored) is documented and survives an adversarial reviewer.

### O4. The seam holds under change

- **KR4.1** Three seam-independence CI gates pass and are required checks: delete-Compile (system still stores, governs, audits, and answers via BM25 with the reranker and embeddings removed), swap-model (embedder and reranker replaced wholesale with zero governed-state migration), verify-receipts-model-free.
- **KR4.2** A type-level firewall makes it impossible for a Compile-derived score (a rerank score or embedding) to be an input to a Govern or promotion decision.
- **KR4.3** The embedding store is a rebuildable cache: dropping it entirely loses nothing governed, and it is content-addressed by (content-hash, model-id, version).

### O5. Freshness composes with receipts

- **KR5.1** An on-push incremental recompile fires per changed input and re-runs COMPILE plus GOVERN over only the delta, emitting an admission receipt per changed fact; the nightly full pass is demoted to a reconciliation backstop.
- **KR5.2** An index-staleness gauge (max age of un-indexed promoted facts) is exposed as a first-class metric.
- **KR5.3** Delta visibility latency is measured on our own stack and stated as our number; we claim direction and architecture, never a borrowed latency figure.

### O6. The poisoning defense is honest (containment and attribution, not prevention)

- **KR6.1** Write-time origin provenance (an HMAC over source-channel plus content) is bound into every admission receipt, and the gate refuses any durable write from an unauthenticated channel (the unauthenticated-injection class is blocked, verified).
- **KR6.2** A receipts-rollback drill exists and is measured: given a poisoned write, the mean time to identify it via the chain and unwind it is recorded.
- **KR6.3** The residual is named, never hidden: authenticated-insider poison, compositional (L2), and dormant (L3) poison are documented as out-of-scope. We never claim the gate "prevents memory poisoning."

### O7. Federation is designed and provable

- **KR7.1** A promotion-through-a-second-gate design exists: only already-governed facts cross a brain boundary, one at a time, through a merge gate that re-scans policy and secret/PII, dedups and reconciles contradictions across brains, and trust-weights per source brain.
- **KR7.2** Merge receipts reference the source brain's receipt hash, so for any fact the master brain can reconstruct which source brain admitted it, under which verdict, unaltered since.
- **KR7.3** A compromised source brain is demonstrably a tagged, attributable, revocable slice, not a silent rewrite of the master's norms.
- **KR7.4** The topology is hub-and-spoke growing to person to team to org, never peer.

---

## Meta-success: the article and the brand

- **M1** Every factual claim in the competitive article traces either to a measured GSB number from our own eval, or to a cited 2026 paper in `018-RL-RSRC`.
- **M2** Zero forbidden absolute-integrity claim words appear as GSB claims (the repo lint passes on the article source).
- **M3** The honesty ledger in the article names what still remains (non-repudiation-local out of scope, L2/L3 and authenticated-insider poison residual, no diagrams, internal-fixture govern metrics).
- **M4** The article leads with the seam and completeness, not the reranker.

---

## What success is NOT (failure modes to refuse)

- Publishing a retrieval win measured on synthetic fixtures instead of real queries.
- Claiming "govern prevents poisoning" (it contains and attributes; it does not prevent).
- Shipping a Merkle transparency log or per-record signatures for a single-writer threat model (ceremony that adds no guarantee).
- Letting a reranker or embedding score gate promotion (complects the seam permanently).
- Any "self-improving memory" framing (that is promotion-by-model dressed as a feature).
- A green audit over a corpus a side-door write bypassed (the completeness invariant silently broken).

---

## Definition of done for the initiative

Waves 1 and 2 of `019-PP-PLAN` are shipped and measured; the three-layer eval harness gates CI; the receipts ladder is at git-witnessed Tier 1 with completeness enforced at the substrate; the seam-independence gates are required checks; and the competitive article is published with every claim measured or cited. Federation and the Tier 2 transparency work are designed and scheduled, not necessarily shipped, at initiative close.
