# 016-AT-PLAN: Cited Development Plan (Retrieval, Govern, Receipts, Threat, Freshness, Eval, Federation)

**What this is:** the research-grounded upgrade plan for Bob's Big Brain / Governed Second Brain (GSB), assembled to be the build basis for the competitive article against Cerebras's "How We Built Our Enterprise Knowledge Base." Every upgrade traces to a verified 2026 paper. Produced by a multi-agent pass: a six-axis harvest-and-adversarial-verify research workflow (13 agents), five canon-and-frontier reviewer consultations (Reimers, an HF practitioner, Hickey, Huyen, Kleppmann), and a federation research agent. Honesty brand is load-bearing: receipts attest integrity, provenance, and ordering, never truth. The four absolute-integrity claim words the trust model bans (per 009-AT-DECR) do not appear as GSB claims.

Written dash-free on purpose (the voice bans em and en dashes).

---

## 0. Executive summary

**The corrected baseline (Huyen, from reading the real `qmd-team-intent-kb` repo).** GSB was under-selling itself. It is NOT "BM25-only": `qmd-adapter` already RRF-fuses a qmd BM25 binary with a native FTS5 index, and there is already an eval surface (recall@k, dedup-catch-rate, provenance-integrity, govern precision/recall, a CI retrieval ratchet, signed `gate-result/v1` bundles). The real gaps are narrower and sharper than the honesty ledger claimed:

- We have LEXICAL hybrid; we are missing the DENSE/semantic arm (one signal, not an architecture).
- Nightly-not-on-push is a train/serve skew: the index the retriever reads lags the governed store by up to 24 hours.
- Govern catches DISCLOSURE (secrets/PII), not adversarial-clean-content POISONING.
- The eval runs on SYNTHETIC fixtures, not the real `brain_search` distribution.

**The strategy every reviewer converged on independently: match-and-neutralize on retrieval, win on provenance, completeness, and federation.** Retrieval mechanics (dense + RRF + reranker) are commodity: anyone bolts them on in a week, including us. The moat nobody can copy is that every durable fact is admitted by deterministic code below the spool and carries a hash-chained receipt, and that multiple brains can federate through a second gate that emits cross-brain provenance. Do not lead the article with the reranker. Lead with the seam.

**Seven axes, sequenced into three waves.** P0 wave: govern gate-ordering fix, cross-encoder reranker, event-driven freshness. P1 wave: write-time provenance, three-layer eval harness, govern vocabulary, self-signed checkpoints. P2 wave: transparency log + external anchor, conditional dense/RRF arm. Federation is the strategic differentiator that runs alongside.

---

## 1. Strategy

Cerebras built a strong COMPILE + retrieval layer (Postgres + pgvector 3072-dim HNSW, LLM distillation, hybrid lexical+vector+IDF+recency, Reciprocal Rank Fusion, cross-encoder rerank, synthesis with citations, plus a deterministic SIGNAL-threshold admission gate and access-auditing). They beat us on retrieval sophistication. We do not fight on their ground.

We win on the domain their architecture does not occupy: deterministic POLICY admission below the spool (their gate filters signal, not policy), admission receipts with write-time provenance (their audit is ACCESS audit, a description beside the corpus, not an admission record the corpus is derived from), freshness that composes with those receipts on the same push, and safe multi-brain federation through a gate that emits cross-brain provenance. The one-word invariant against them is COMPLETENESS: their access-audit describes what it says it showed you; GSB's corpus is derived from the admission log, so every fact has a receipt because admission is the only write path.

---

## 2. The seven upgrade axes

### Axis 1. Retrieval: single-stage BM25 becomes a two-stage retriever (reranker first)

**Upgrade.** Keep BM25 as a first-class, tuned arm. Add Stage 2 rerank FIRST: a local cross-encoder (bge-reranker-v2-m3 or Qwen3-Reranker-0.6B, Apache-2.0, CPU, no external API) rescores BM25 top-50 to top-8. Then, conditionally, add Stage 1 dense candidate generation: a local bi-encoder run in parallel with BM25, fused via RRF. This runs ABOVE the spool on already-durable facts; it touches neither the admission gate nor the receipts.

**Practitioner ship-list (Reimers + HF-practitioner).** Embedder: Apache-2.0 only, Qwen3-Embedding-0.6B (32K context, GGUF ~400MB, MRL-truncatable to 512-dim) or BGE-M3 (1024-dim, 8192 context, MIT). Avoid the license traps: Jina rerankers are CC-BY-NC (non-commercial), EmbeddingGemma ships a gated Gemma license: neither ships in a product. Store: sqlite-vec or a flat exact cosine over a few thousand vectors (the compiled wiki is small). Do NOT stand up pgvector/HNSW at wiki scale: flat exact search is sub-10ms, exact, zero index maintenance, and the simplicity is a genuine claim over Cerebras. Embed once at PROMOTION (admin-gated, rare, ~$0), query-embed at search (~10-30ms CPU). Cost is RAM on an OOM-sensitive box, not dollars.

**Papers.** SciFact multi-stage (2026-05-12): cross-encoder rerank is the "primary driver" of final performance; RRF hybrid did NOT consistently beat the best dense retriever and can dilute strong rankings on harder queries. Clinical-notes ANOVA (2026-05-01, peer-reviewed): rerank and hybrid-ensemble significantly beat standalone BM25 AND standalone dense. From-BM25-to-Corrective-RAG (2026-04-02): two-stage hybrid+rerank Recall@5 0.816, beating every single-stage method; separately BM25 beat dense on precise numeric text. Pi-Serini (2026-05-11): tuned BM25 at depth + a capable model beats dense-retriever agents (83.1% acc), which licenses KEEPING and TUNING BM25, though it used a frontier model so it does not license skipping dense/rerank on a local model.

**Honest claim.** The reranker is the real, large, reliable win. Dense+RRF is a CONDITIONAL add (improves semantic/multi-hop recall, can hurt exact-terminology/numeric precision). BM25 stays a defended co-equal baseline, not an apology.

**Priority.** Reranker P0. Dense+RRF arm P2 (measure before ship).

### Axis 2. Govern: name the seam, adopt symbolic lifecycle rules, fix gate ordering

**Upgrade.** (a) Fix gate STAGE ORDERING so a near-duplicate check never silently rejects a contradictory-but-valid write (run dedup after or jointly with contradiction/supersession detection). (b) Adopt explicit symbolic lifecycle rules (dedup, contradiction-reconcile, access-based promotion, time-based pruning) as the deterministic rule set below the spool. (c) Reframe the govern step in docs/UI with the frontier-named property "decouple memory evolution from execution," gating consistency + temporal decay + access PRIOR to consolidation.

**Papers.** SSGM (2026-03-12, most-cited in set): decouple memory evolution from execution, gate consistency + decay + access before consolidation (design-thesis claim only, conceptual). NeuSymMS (2026-05-17): a CLIPS symbolic engine doing dedup/reconcile/promote/prune below an LLM extractor (feasibility claim only). MemClaw/ArgusFleet (2026-06-23): a synchronous near-duplicate gate prematurely rejected contradictory writes before the async contradiction detector ran (the ordering bug); also 100% depth-4 derivation-chain reconstruction with writer identity; concedes a batch-visibility gap. AGL-1 (2026-07-03): seven governance domains, receipts occupy provenance-management, distinct from identity-aware retrieval (positioning only).

**Priority.** Gate-ordering fix P0 (correctness bug). Vocabulary + symbolic rules + positioning P1.

### Axis 3. Receipts: a two-part integrity ladder above the hash chain

**Kleppmann's correction (load-bearing): the smallest real upgrade is one `git push`, not a Merkle tree.** A hash chain on one box has zero adversarial value: the writer holds every input to recompute a forged history. It becomes real only when a checkpoint crosses a boundary the writer does not solely control. GSB already has the checkpoint (`~/.teamkb/audit/anchors.jsonl` records chainHead/chainedRows/anchorHash per anchor) but never witnesses it. Push it to a NON-FORCE-PUSHABLE git ref and the honest claim unlocks: "any fact admitted before witnessed checkpoint C cannot be altered without detection." Then OpenTimestamp the anchor hash for existence-time proof that trusts neither us nor GitHub. That beats the Merkle ceremony for our single-writer threat model.

**Two concrete bugs in the current chain (Kleppmann).** Whole-day-file deletion and tail-truncation both verify CLEAN. Fix: link the daily trace chains into one sequence (first line of each day carries prev_hash = last line of prior day), and wire the anchor row-count and head into the verifier so truncation/deletion is detectable. Also: two audit substrates exist (ICO kernel `audit/traces/*.jsonl` with a verifier but no anchors; GSB `anchors.jsonl` with anchors but no verifier found). Declare which is source of truth and make the other provably derived.

**Do NOT build (Kleppmann).** A CT/Merkle transparency log at single-auditor scale, per-record signatures with keys on the same box (worse than silence: they fake non-repudiation while a box-owner owns the key), and any consensus/CRDT layer. The workflow's Aegon/APEX/TAF/DTL citations are real and are the reference for a LATER Tier 2 (third-party inclusion proofs) IF the product ever needs many independent auditors: cite them as the ladder's top rung, do not build it now.

**The ladder, stated exactly.** Tier 0 local hash chain (today, after the truncation fix): rewrite-detection + ordering, "tamper-evident" only, never the absolute-integrity forms the trust model bans. Tier 1 self-signed checkpoints: producer-verifiable state evolution between checkpoints (LIMIT: producer-signed, does NOT prove the producer could not forge before signing: not non-repudiation). Tier 2 externally-anchored epoch root (git-tag/OpenTimestamps): third-party tamper-evidence without trusting the producer. Non-repudiation stays explicitly OUT of scope: reaching it costs joint user+server signatures + fork-detecting gossip (VCT) or hardware attestation (Aegon), neither of which we add.

**Papers.** Aegon (2026-04-08), APEX (2026-05-08, grounds Tier 1 checkpoints), TAF (NDSS 2026, hinge: git/TUF-alone insufficient under a full-host-control adversary), DTL (2026-05-28, microsecond receipts + log-size proofs = cheap), DHT-Backed Merkle (root-only external anchoring), VCT (2026-06-22, the cost of a guarantee GSB never claims, cited to keep non-repudiation out of scope).

**Priority.** git-push-the-anchor + truncation fix + substrate reconciliation: P0-adjacent (Kleppmann says do before publishing any receipts claim). Self-signed checkpoints P1. Transparency log + external anchor P2.

### Axis 4. Threat model: bind write-time provenance into the receipt

**Upgrade.** Bind cryptographic write-time provenance into the receipt: each admitted fact carries an authenticated origin token (HMAC/signature over source-channel + content), and the gate REFUSES any durable write whose origin is not an authorized channel.

**Huyen's honest framing (critical).** Govern today catches disclosure, not adversarial-clean-content poisoning. So "govern prevents poisoning" is theater. The honest claim: receipts give post-hoc ATTRIBUTION + ROLLBACK (the chain proves which write poisoned you and unwinds it) and the admin-only write-gate kills anonymous writes: that is CONTAINMENT + ATTRIBUTION, not prevention.

**Papers.** SMSR (2026-06-10): no provenance-free retrieval filter certifies against adaptive injection; write-time HMAC cut unsigned-injection success 93-100% to 0% across 3,150 trials; ~8% authenticated-adversary residual needs a query-time voting component GSB does not implement. From-Untrusted-Input (2026-06-03): durable memory is a distinct attack surface prompt-injection defenses miss. MemPoison (2026-07-16): write-time defenses suppress single-record (L1) but not compositional (L2) or dormant/triggered (L3) poison: the honesty anchor for named residual.

**The defensible sentence.** "GSB governs the write channel every memory-poisoning attack must traverse, records an origin-attested receipt for each admission, and deterministically blocks the unauthenticated-write class that prompt-injection defenses miss entirely, while leaving authenticated-insider, compositional (L2), and dormant (L3) poison as named, out-of-scope residual risk."

**Priority.** P1.

### Axis 5. Freshness: nightly batch becomes event-driven incremental recompile on push

**Upgrade.** Replace nightly-batch re-compile with an event-driven incremental re-compile on the SAME git push that is already GSB's external anchor. A local-first post-commit/post-receive hook (no Kafka) diffs changed inputs, re-runs COMPILE + GOVERN over only the delta, appends the resulting receipts. Keep nightly full-corpus as a reconciliation backstop. Huyen's substrate note: do the incremental single-doc upsert inside the existing promotion path (`promotion-service.ts`), and expose an index-staleness gauge.

**Foil differentiator (press this).** On the same push, GSB re-emits an ADMISSION receipt per changed fact. Freshness and receipts COMPOSE. Cerebras audits access and its gate filters signal, so it cannot make that claim.

**Papers.** Measuring-Retrieval-Freshness (2026-02-13): freshness is a first-order determinant of RAG accuracy. Serverless-Architecture-Patterns (2026): incremental delta updates driven by syncing repos/trackers on change (borrow the pattern, not the AWS infra). Real-Time-RAG-CRM (2026-02-24): event-driven cut propagation to 3.1s, 75-150x faster than batch, holding quality (their number on their stack, existence-proof not a GSB promise).

**Priority.** P0.

### Axis 6. Eval: a decoupled three-layer harness wired to a CI/release gate

**Upgrade.** Score GSB's three layers as SEPARATE numbers, never a blended accuracy, and gate a build "ready" only if each clears its threshold: (1) GOVERN admission-gate precision/recall (dup/policy/secret-PII/promotable) vs a hand-annotated fixture, dedup + supersession first-class; (2) RETRIEVAL nDCG@k / Recall@k on a hand-built query-to-gold corpus with a MANDATORY BM25 control arm any dense/hybrid/rerank arm must beat; (3) ANSWER RAGAS-style groundedness/faithfulness on a 50-100 item fixture.

**Reimers + Huyen (the gate that matters most): build the query set from REAL `brain_search`/`audit_events` logs, hand-labeled with `qmd://` answers.** Our citation URIs ARE the ground-truth labels: a labeling advantage almost nobody has. SEGMENT every metric by exact-term vs conceptual. The article's numbers come from THAT, not synthetic fixtures (keep synthetic as the deterministic CI floor). Honest expected win: +3 to +8 nDCG@10 overall, concentrated in the conceptual slice, roughly 0 on exact-term where BM25 stays primary. No borrowed numbers.

**Papers.** A-TMA (2026-07-02): measure bank/retrieval/answer separately because QA accuracy hides bank-level failure. PROBE (2026-05-18): a composite gate correlates with human acceptability at rho 0.72 vs 0.47 for NDCG@10 alone. LLM-Readiness-Harness (2026-03-28): multi-metric CI gates auto-reject unsafe variants. GroupMemBench (2026-05-14): a BM25 baseline matches or exceeds most memory systems when ingestion is clean; the bottleneck is admission, not retrieval (defends the BM25 floor, mandates the control arm).

**Priority.** P1 (proves the keystone; gates every other upgrade).

### Axis 7. Federation: team brains promote into a master brain through a second gate

**The idea (Jeremy).** Multiple brains (per person, per team) federate up into a master brain. The 2026 literature independently arrived at this exact architecture and named its failure modes.

**Design: promotion, not sync.** Never copy a team brain's store up. Promote individual already-governed facts, one at a time, through a SECOND deterministic gate at the master. Raw spool never crosses. The merge gate runs four deterministic checks: (1) cross-brain dedup + contradiction resolution (temporal supersession), (2) re-scan policy/secret/PII (do not inherit the source verdict), (3) trust-weight per source brain (trimmed-mean merge held poisoning damage to 13.6% vs 44.2% naive at a 25% poison rate), (4) scoped reads on every path. The master appends a MERGE RECEIPT referencing the source brain's receipt hash: for any fact it can prove which source brain, under which verdict, admitted by code, unaltered since.

**Why Compile-only cannot safely copy it.** Mem0/Zep/Letta/Cognee are all racing into team/multi-scope memory, but the model does the merge with no gate: their isolation is metadata filters. The decisive evidence: a documented "Trust Laundering" attack where a poisoned document loses provenance in a shared store and reappears as trusted system context; four safety classifiers produced ZERO detections across 510 checkpoints. A model-merges-the-brains architecture cannot see it. A deterministic gate at the merge boundary IS information-flow control (the fix that worked, blocked 97%). GSB turns a compromised team brain into a tagged, attributable, revocable slice instead of a silent norm-rewrite.

**Topology: hub-and-spoke now, evolving to person -> team -> org. Never peer** (peer = N-squared ungoverned boundaries). Maps onto the existing split with zero new concepts: local mode = spoke, team mode (`TEAMKB_API_URL`/`tenantId`) = hub, master = the hub with one more promotion boundary. This is also the technical substrate for the Bench/cohort: each subcontractor runs a personal brain that promotes into the org brain.

**Papers.** MemClaw/ArgusFleet (2606.24535, four merge failure modes: leakage/stale-propagation/contradiction-persistence/provenance-collapse; 100% depth-4 provenance). The Misattribution Gap (2605.22842, Trust Laundering; 0/510 classifier detections; info-flow-control blocks 97%). SuperLocalMemory (2603.02240, local-first + per-agent provenance + trust, no LLM in the defense path: closest to GSB). Federated Memory Aggregation (trimmed-mean, 13.6% vs 44.2%). Memory-Poisoning Propagation & Repair (3e84c6, evidence graph AUC 0.94, propagation cut 78%). Temporal Traceability (bdfcfb, source-brain attribution 91%). Controlled Benchmarking of Memory Topologies (a96ec0, promote-only-validated-facts crystallization policy). GateMem (2606.18829, no method achieves utility+access-control+forgetting together: case for re-scan at each boundary). GovernAI (multi-tenant policy+lineage+audit, 45% fewer violations). Ethical-AI-Governance (0b3f4b, governance at BOTH local and federation levels). Adaptive-Semantic-Compression (bf91f4, the "cluster brain" hub vocabulary). Fed-SE (2512.08870, local-evolution/global-aggregation). Federated Transfer Learning (ba94b4, tenant-aware trust). Torra (2603.20357, peer interaction is itself a poisoning vector: argues against peer). TFX-MARL (c2232e6, trust from provenance+consistency+compliance).

**Priority.** Strategic. Not a Wave-1 build, but the single strongest article section and the growth-path substrate. Design now, build after Waves 1-2 harden the single-brain gate + receipts it rests on.

---

## 3. Sequenced build order

**Wave 1 (P0).** (1) Govern gate-ordering fix (MemClaw) plus the receipts truncation-hole fix + git-push-the-anchor + substrate reconciliation (Kleppmann) as the correctness/integrity floor. (2) Cross-encoder reranker (SciFact, clinical ANOVA, financial two-stage), local-only, never touches the gate. (3) Event-driven incremental recompile on push (freshness synthesis + serverless + CRM).

**Wave 2 (P1).** (4) Write-time provenance HMAC into the receipt (SMSR). (5) Three-layer eval harness + CI gate built on REAL `brain_search` queries (A-TMA, PROBE, Readiness, GroupMemBench). (6) Govern vocabulary + symbolic lifecycle rules (SSGM, NeuSymMS, AGL-1). (7) Self-signed checkpoints, Tier 1 (APEX).

**Wave 3 (P2).** (8) Transparency log + external epoch anchor, Tier 2 (Aegon, TAF, DTL, DHT-Backed): only if the many-auditor threat model ever applies. (9) Dense + RRF conditional retrieval arm (financial two-stage, SciFact dilution caveat): measure-before-ship against the reranked-BM25 baseline. (10) Federation MVP: promotion-through-a-second-gate + merge receipts, hub-and-spoke.

---

## 4. Cross-cutting reviewer constraints (the load-bearing ones)

**The seam firewall (Hickey, most-costly-to-get-wrong).** The reranker and embeddings are READ-PATH ONLY, a rebuildable cache ABOVE the spool. A rerank/embedding score must NEVER flow into a promotion or admission decision: enforce it as a TYPE-LEVEL impossibility (Govern function signatures reject any Compile-derived score), not a code-review hope. Embeddings are content-addressed by (content-hash, model-id, version): dropping the entire embedding store loses nothing governed. Lifecycle/decay is deterministic-symbolic; an LLM "trust-scorer" gating promotion is itself a poisoning target and is forbidden. The Merkle/transparency log attests governed transitions ONLY (no retrieval/compile events). Add three seam-independence CI gates that double as the article's proof: delete-Compile (system still stores/governs/audits/answers via BM25), swap-model (replace embedder+reranker with zero governed-state migration), verify-receipts-model-free (audit verification runs with no model loaded).

**The completeness invariant (Kleppmann, the single most important thing).** Every "every fact has a receipt" claim rests on the deterministic admission gate being the SOLE writer of the corpus. One side-door write (manual INSERT, migration, second process, Dolt import bypassing the gate) makes receipts silently incomplete: green audit, under-counted corpus, undetectable later. Enforce at the substrate (corpus writable only by the gate process; a write that cannot emit a receipt fails closed) BEFORE publishing any "receipts" claim.

**Don't sell the reranker; sell the seam (Hickey + all).** The through-line: "the model proposes, the deterministic kernel owns durable state, we can prove the kernel was not tampered with, and we retrieve better without letting the model touch durable state." Never "self-improving memory" (that is the promotion-by-model trap dressed as a feature).

---

## 5. Honesty ledger after these upgrades

**Shrinks (residual named):** retrieval (BM25 tuned + reranker added, dense gated behind measurement; residual: no production dense until the harness proves it, L2 lexical-composition exposure remains); freshness (incremental on push, receipts compose; residual: the 3.1s/75-150x is an external number, we claim direction not latency, and non-push ingest still waits for nightly); external anchor (Tier 2 root-only anchor + inclusion proofs; residual: value assumes someone audits, and we substitute git-tag/OpenTimestamps for the literature's distributed-ledger anchoring, which we never claim); local integrity (Tier 1 producer-verifiable evolution + write-time origin provenance).

**Honestly remains:** non-repudiation-local (out of scope, top rung, VCT/hardware cost cited); authenticated-adversary + L2/L3 poisoning (named residual, we do NOT claim the gate prevents poisoning); batch-visibility for non-push ingest paths; no diagrams; GOVERN metrics are internal-fixture numbers (no public governed-KB admission benchmark exists).

**Net vs the foil.** Cerebras beats us on retrieval sophistication and we do not claim to pass them there. We win on deterministic POLICY admission, admission receipts with write-time provenance and completeness, freshness that composes with receipts, and safe multi-brain federation. Every one is now grounded in a cited 2026 result.

---

## 6. Citations corpus (verified 2026, `[key] Title . url . what-it-supports`)

Retrieval / govern / receipts / threat / freshness / eval (adversarially verified in the workflow, 23):

- `[ret-scifact]` A Multi-Stage Hybrid Retrieval Framework with Cross-Encoder Re-Ranking . https://www.semanticscholar.org/paper/8d06b6ebc6ccaaee66897559f66149d9f49b57fa . reranker is primary driver; RRF can dilute.
- `[ret-clinical]` Optimising clinical information extraction: RAG techniques in clinical notes . https://www.semanticscholar.org/paper/753233eb3033d44f67eee29c13405a9b18a38964 . peer-reviewed ANOVA: rerank+hybrid beat sparse-only AND dense-only.
- `[ret-bm25crag]` From BM25 to Corrective RAG (text-and-table) . https://www.semanticscholar.org/paper/2d0b4b34f319de8da4296b1853d2f4903d71a75c . two-stage Recall@5 0.816; BM25 beat dense on numeric text.
- `[ret-piserini]` Rethinking Agentic Search with Pi-Serini . https://www.semanticscholar.org/paper/3cfce98315b0a42f4cdf9aa39fdc80d06907bbd6 . tuned BM25 + capable model beats dense agents; defends keeping BM25.
- `[gov-ssgm]` Governing Evolving Memory in LLM Agents (SSGM) . https://arxiv.org/abs/2603.11768 . decouple evolution from execution, gate before consolidation.
- `[gov-neusymms]` NeuSymMS: Hybrid Neuro-Symbolic Memory . https://arxiv.org/abs/2605.17596 . symbolic rule engine for dedup/reconcile/promote/prune.
- `[gov-memclaw]` Governed Shared Memory for Multi-Agent LLM Systems (MemClaw) . https://arxiv.org/abs/2606.24535 . gate-ordering bug; 100% depth-4 provenance; batch-visibility concession.
- `[gov-agl1]` AGL-1: The Enterprise AI Governance Layer . https://arxiv.org/abs/2607.03516 . seven governance domains; receipts = provenance management.
- `[rec-aegon]` Aegon: Auditable AI Content Access . https://www.semanticscholar.org/paper/b416c4cf39f00afd9dc0e87f579efd73889c3b3c . CT-style Merkle-over-ledger + AI-stage provenance.
- `[rec-apex]` Auditable Zero-Trust Sensor-Cloud Repositories (APEX) . https://www.semanticscholar.org/paper/11037d3ea33f16a9092262c5149469cf54f71c75 . hash chain + periodic signed checkpoints. Grounds Tier 1.
- `[rec-taf]` Enhancing Legal Document Security with TAF (NDSS) . https://www.semanticscholar.org/paper/789a2e2142448115fb0f34314e5b6b87b30296dc . git/TUF-alone insufficient under full-host-control adversary.
- `[rec-dtl]` Decentralised Trust Layers for the Web . https://www.semanticscholar.org/paper/6acf2262c0a7c88445b0904ba20782f0d7a1c59e . microsecond receipts + log-size proofs: cheap.
- `[rec-dht]` DHT-Backed Ancestor-Assisted Merkle Verification . https://www.semanticscholar.org/paper/d65676ef3b6df522c43da2238f9a8021496777e1 . anchor only the epoch root-of-roots externally.
- `[rec-vct]` VCT: Verifiable Transcript System for LLM Conversations . paperId 4976e16e3de4dc50b0b8157c17dc6778a9ab99a1 . the cost of a guarantee GSB never claims (non-repudiation, kept out of scope).
- `[threat-smsr]` SMSR: Certified Defence Against Runtime Memory Poisoning . https://arxiv.org/abs/2606.12703 . write-time HMAC 93-100%->0%; ~8% authenticated residual.
- `[threat-untrusted]` From Untrusted Input to Trusted Memory . https://arxiv.org/abs/2606.04329 . durable memory is a distinct attack surface.
- `[threat-mempoison]` MemPoison: Persistent Memory Threats and Structural Blind Spots . https://arxiv.org/abs/2607.14651 . L2/L3 poison survives write-time defenses (residual anchor).
- `[fresh-etl]` Measuring Retrieval Freshness in Continuous ETL-Driven RAG . https://www.semanticscholar.org/paper/9c69b1e1f8f46d9f8ecd947534ed829c5395e67f . freshness is first-order for accuracy.
- `[fresh-serverless]` Serverless Architecture Patterns for Enterprise AI Agents . https://www.semanticscholar.org/paper/e95908388432d0a927e6317443c19e74cee22680 . incremental delta updates on change.
- `[fresh-eventdriven]` Real-Time RAG-Based CRM . https://www.semanticscholar.org/paper/3bdf1bb52430a41f053278a2efa8b89c168a0005 . event-driven 3.1s, 75-150x vs batch (their stack).
- `[eval-atma]` A-TMA: Decoupling State-Aware Memory Failures . https://www.semanticscholar.org/paper/59a6b3f56ec0268d2a36b2e5b5b9eef608668869 . measure bank/retrieval/answer separately.
- `[eval-probe]` PROBE: Release-Gate Evaluation for Regulated Enterprise RAG . https://www.semanticscholar.org/paper/05a112d952e24a00d6a5ae03268ff956be064a2a . composite gate rho 0.72 vs 0.47 NDCG.
- `[eval-readiness]` LLM Readiness Harness: CI Gates for LLM/RAG . https://www.semanticscholar.org/paper/81b7fc8a239364c0ccd1748df4f51a0fa6ef4563 . multi-metric CI gates; readiness is not one metric.
- `[eval-groupmem]` GroupMemBench: LLM Agent Memory in Multi-Party Conversations . https://www.semanticscholar.org/paper/469cd86992948b1b4d4286d1bbf5a7e2a779ff33 . BM25 floor matches most memory systems; bottleneck is admission.

Federation (14):

- `[fed-memclaw]` Governed Shared Memory (MemClaw/ArgusFleet) . https://arxiv.org/abs/2606.24535 . four merge failure modes; 100% depth-4 provenance; sub-tenant scope bug.
- `[fed-gatemem]` GateMem: Benchmarking Memory Governance in Multi-Principal Shared Memory . https://arxiv.org/abs/2606.18829 . no method achieves utility+access-control+forgetting together.
- `[fed-misattribution]` The Misattribution Gap: Memory Poisoning Looks Like Model Failure . https://arxiv.org/abs/2605.22842 . Trust Laundering; 0/510 classifier detections; info-flow-control blocks 97%.
- `[fed-superlocal]` SuperLocalMemory: Privacy-Preserving Multi-Agent Memory . https://arxiv.org/abs/2603.02240 . local-first + per-agent provenance + trust, no LLM in defense path.
- `[fed-aggregation]` Federated Memory Aggregation for Poisoning-Resilient Collaboration . https://www.semanticscholar.org/paper/330969e9f72ac375c36d77eb1277e0994ee880fc . trimmed-mean merge, 13.6% vs 44.2% at 25% poison.
- `[fed-repair]` Memory Poisoning Propagation and Repair in Multi-Agent Environments . https://www.semanticscholar.org/paper/3e84c6dbe0f008725472b85ae20fd9baa7222699 . evidence graph AUC 0.94, propagation cut 78%.
- `[fed-traceability]` Temporal Traceability and Source Attribution of Memory Poisoning . https://www.semanticscholar.org/paper/bdfcfb8925deb3542afb11366cf01cee0d7cff15 . source-brain attribution 91%.
- `[fed-topologies]` Controlled Benchmarking of Memory Topologies . https://www.semanticscholar.org/paper/a96ec007ce6b034623afb6778eb67f99350b0c8d . promote-only-validated-facts crystallization policy.
- `[fed-governai]` GovernAI: Policy-Driven Governance for Multi-Tenant AI . https://www.semanticscholar.org/paper/6543c27b4830c20ee79e0feb5a7226526eb19816 . declarative policy + tenant access + lineage + audit, 45% fewer violations.
- `[fed-ethical]` Ethical AI Governance for Federated Multi-Agent Ecosystems . https://www.semanticscholar.org/paper/0b3f4bb14032d516863cbe76526d17a1b2ddd8bf . governance at both local and federation levels.
- `[fed-clusterbrain]` Adaptive Semantic Compression for Hierarchical LLM-Agents . https://www.semanticscholar.org/paper/bf91f479d860cf62a17c1e2b3d01dccb09fb3ae3 . "cluster brain" hub vocabulary.
- `[fed-fedse]` Fed-SE: Federated Self-Evolution for Multi-Environment Agents . https://arxiv.org/abs/2512.08870 . local-evolution / global-aggregation.
- `[fed-transfer]` Federated Transfer Learning for Secure Multi-Tenant Data . https://www.semanticscholar.org/paper/ba94b4c61c77287b3ef3cc3c2d75e0b51f1019e3 . tenant-aware dynamic trust.
- `[fed-torra]` Memory Poisoning and Secure Multi-Agent Systems (Torra) . https://arxiv.org/abs/2603.20357 . peer interaction is itself a poisoning vector (argues against peer topology).
- `[fed-tfxmarl]` Zero-Shot Policy Transfer via Trusted Federated Explainability (TFX-MARL) . https://www.semanticscholar.org/paper/c2232e68cc1fba2d5fe166c86a8315e81f41440e . trust from provenance+consistency+compliance.

---

## 7. What this means for the article

The Cerebras piece is a strong COMPILE + retrieval writeup that even ships a deterministic SIGNAL-threshold gate (the closest anyone has come to govern) and access-auditing. Credit both; that disarms sour-grapes and shows we read it. Then the spine: who decides what is durable (the LLM, or the code), and can you prove it. The article does not fight on retrieval. It shows the seam, the completeness invariant (their audit describes the corpus, ours is derived from the admission log), and the federation move nobody else can make safely. Publish the retrieval numbers from OUR real-query eval, not borrowed ones. Keep every forbidden word out. The product is stronger because the plan is cited; the article is honest because the ledger names what still remains.

**Companion artifacts:** the full synthesized workflow output (per-axis kept/dropped citation adjudications) is at the workflow transcript dir; the reviewer verdicts (Reimers, HF-practitioner, Hickey, Huyen, Kleppmann) and the federation research memo are the source material for sections 2, 4, and 7.
