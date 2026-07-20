# 019-PP-PLAN: Master Blueprint (Epics and Beads)

**What this is:** the granular execution blueprint for the GSB upgrade initiative, broken into epics and individual beads, produced from a real engineering audit of every GSB product against `016-AT-PLAN` (the cited plan) and `017-PP-OKRS` (the success definition). Four engineers audited the actual code: `qmd-team-intent-kb` (retrieval/eval/freshness/govern/store), `intentional-cognition-os` (ICO kernel: spool/seam/receipts/completeness), `bobs-big-brain-plugin` (the governed-brain MCP surface + threat), and the live `~/.teamkb` data. Every bead cites the file it touches, the success criterion (O#) it serves, and the citation (`018-RL-RSRC` key) that grounds it. Beads are hand-rolled here for review before creation; titles are plain-English imperative sentences per the naming rule.

Written dash-free. Forbidden absolute-integrity claim words do not appear as GSB claims.

---

## 0. The audit correction: GSB is more built than the plan assumed

The single most important output of the audit is that `016-AT-PLAN` under-credited the shipped code. This reshapes the blueprint from "build" to "operationalize what exists, then fill the real holes."

- **Receipts Tier 1 is substantially built, not "P1 to build."** `qmd-team-intent-kb/packages/store/signed-merge-anchor.ts` already does Ed25519 per-actor signing with DAG parent-binding and a verifier. `audit-anchor.ts` already detects `HISTORY_TRUNCATED` and `HISTORY_REWRITTEN` (the two "Kleppmann holes" the plan attributed to the anchors substrate are already closed there). The gap is that **none of it is wired to a CLI, cron, or CI call site**, and the anchor git repo has no remote. So "git-push-the-anchor" has nothing to push until the append job runs.
- **The real query gold set already exists.** `eval/datasets/governed-brain-v1.ts` is 42 hand-labeled queries (14 lexical, 28 semantic) with real `qmd://` citations. It is simply orphaned from CI (CI runs a synthetic corpus instead). This is the sharpest, cheapest fix on the eval axis.
- **A merge-govern second gate already exists.** `apps/curator/src/merge/merge-gate.ts` re-governs a Dolt-branch union (never trusts a prior verdict, commutativity guarantee). It is the federation second-gate mechanism, already built for the single-brain clone-merge case, and dormant (no CLI trigger).
- **The two "silent hole" bugs live on the ICO side, not the GSB anchors side,** and an ICO epic (`intentional-cognition-os-l13`, filed 2026-07-17) already targets most of it. We extend `l13`, not restart it.
- **A binding decision record conflicted with the plan, and is now reconciled.** `qmd-team-intent-kb/000-docs/038-AT-DECR` rejected the cross-encoder reranker and picked EmbeddingGemma-300M dense-only, the opposite of `016` Axis 1 (reranker-first) and using a license `016` flags as a trap. This was reconciled by `qmd-team-intent-kb/000-docs/044-AT-DECR` (the Wave-0 decision): ship the reranker first (Apache/MIT), defer the dense arm to a measured P2 gate, EmbeddingGemma is out. `044` supersedes only the retrieval-arm and embedder elements of `038`; everything else in `038` stands. Bead A1 (below) is therefore satisfied, and the retrieval beads (B1/B2) are unblocked.
- **The genuinely new, highest-value finding: the completeness invariant is convention-only, with a concrete non-adversarial crash-consistency hole.** `promotion.ts:354` writes the wiki file, `:366` writes the receipt in a separate try-block; a crash between leaves an unreceipted file that `emitSpool` will ingest. Same pattern in all five compiler passes. No DB trigger, no restricted role, ~14 files open the SQLite DB directly for write. Enforcement is 100% "everyone calls the right function."

**Net:** Waves 1 and 2 are lighter than the plan implied on receipts and eval (wire dormant code), and heavier on the completeness invariant (a real, unenforced, crash-reachable hole that must close before any "every fact has a receipt" claim).

---

## The organizing thesis: grounded, not circular

Read the beads below and one principle ties the load-bearing ones together. Every knowledge system is an improvement machine: it compiles, governs, retrieves, evaluates, and calibrates in loops. The failure mode that kills such a machine is not a bad loop, it is a machine whose loops only confirm each other while none touches reality. A metric checked against another metric. A CI ratchet that passes on a synthetic corpus while the real recall regresses. A green audit over a corpus a side-door write bypassed. Consistent everywhere, verified nowhere.

What keeps an improvement machine honest is not more loops, it is grounding. Three things no arrangement of loops can supply: anchors (measurements that cannot be argued with), frozen rules the optimizer is never allowed to tune, and a definition of "better" that comes from outside the machine, chosen by people. GSB is an engineered instance of exactly this. The beads that matter most are the ones that make its anchors real:

- **Anchors** (measurements that cannot be argued with): the receipt is the anchor for durability (F1 git-witness, G1/G2 completeness: the corpus is derived from the admission log, not described by it); the real-query gold set is the anchor for retrieval (C1: gate on it, never on synthetic).
- **Frozen rules the optimizer cannot tune**: the seam firewall (B2, the model proposes but never writes durable state or gates promotion); the held-out gold set; the forbidden-words honesty lint.
- **"Better" chosen from outside**: `017-PP-OKRS` (humans define success) and human-set deterministic GOVERN policy, never model-learned.
- **Paired counter-metrics and independent audit** (the loop watching the loop): the shipped tier-creep-guard pattern; the model-free receipt verifier (B3); the grounding audit (C5, new).

This is why the "operationalize the dormant code" framing matters: the anchor mechanisms are largely built (signed anchors, the verifier, the gold set), but until they are wired, pushed, and gated they are ungrounded, exactly the circular machine that fails later and more expensively with more green lights on the way down. The blueprint's job is to make GSB grounded, not merely sophisticated. Cite `[imp-grounding]` in `018-RL-RSRC` for the improvement-theory lineage of this framing.

## The epics

Legend per bead: `[repo]` `(extends: <existing-bead-or-none>)` `serves: O#` `cite: [key]` `effort: S/M/L` `priority: P#`.

### EPIC A. Reconcile the retrieval-backend decision (blocks all retrieval work)

Rationale: an architectural-conflict resolution, not a coding task. Per the estate rule "architectural changes need explicit approval first." Nothing in Epic B ships until this lands.

- **A1. Bring the reranker-vs-dense-only conflict between 016-AT-PLAN and 038-AT-DECR to an explicit new decision. STATUS: DONE (`044-AT-DECR`).** `[qmd-team-intent-kb]` `(extends: 038-AT-DECR)` `serves: O1` `cite: [ret-scifact][ret-clinical]` `effort: S` `priority: P0`. What/why: `038-AT-DECR` (binding) picked EmbeddingGemma dense-only and rejected the reranker; `016` prioritizes the reranker P0 and flags EmbeddingGemma's Gemma license as a trap. Ship neither until reconciled. Acceptance: a new dated DECR that supersedes or amends `038`, states which of {reranker-first, dense-only, both, neither} ships, and resolves the embedder license question (Apache/MIT: Qwen3-Embedding-0.6B or BGE-M3, not Gemma). **Resolved by `qmd-team-intent-kb/000-docs/044-AT-DECR`: reranker-first, dense deferred to a measured P2 gate, EmbeddingGemma out on its gated license, dense embedder (if ever gated in) is Apache/MIT only. Supersedes only the retrieval-arm and embedder parts of `038`.**

### EPIC B. Retrieval: a read-path reranker with the seam firewall landed alongside

- **B1. Add a local cross-encoder reranker above the fused BM25/FTS5 result set, called from brain_search only.** `[qmd-team-intent-kb + bobs-big-brain-plugin]` `(extends: qmd-team-intent-kb-0t9)` `serves: O1` `cite: [ret-scifact][ret-clinical][ret-bm25crag]` `effort: M` `priority: P0`. What/why: RRF today fuses two lexical arms; nothing rescales the fused top-k, and rerank is the primary measured lift. Rescore fused top-50 to top-8 with an Apache-2.0 CPU cross-encoder (bge-reranker-v2-m3 or Qwen3-Reranker-0.6B). Acceptance: `adapter.query()` gains an optional rerank stage; `brain_search` calls it before truncation; a new eval stratum shows measured nDCG@10 lift per segment; reranker output content-addressed by (content-hash, model-id, version).
- **B2. Make it impossible for a rerank or embedding score to reach a govern or promotion decision (type-level firewall), landed in the SAME PR as B1.** `[qmd-team-intent-kb + intentional-cognition-os]` `(extends: none)` `serves: O4` `cite: (Hickey reviewer constraint)` `effort: M` `priority: P0`. What/why: `EvaluationContext`/`RuleResult` already carries a generic `score?: number` hook; a future `semantic_score` rule reusing it is the path of least resistance and the exact seam violation. Acceptance: a branded `DeterministicScore` type every `PolicyRule` must return, produced only by functions with no import path to any retrieval/embedding module; a dependency-cruiser rule fails the build if `policy-engine` imports a retrieval package; a unit test asserts a compile-derived score cannot type-check as a govern input.
- **B3. Add the three seam-independence CI gates (delete-Compile, swap-model, verify-receipts-model-free).** `[qmd-team-intent-kb + bobs-big-brain-plugin]` `(extends: none)` `serves: O4` `cite: (Hickey)` `effort: M` `priority: P1`. What/why: these are both the safety net and the article's proof artifact; none exist today. Acceptance: three CI jobs: delete the qmd+FTS5 modules and confirm govern/audit/store still build+test green; swap the reranker model id with zero governed-state migration; run the receipt verifier with no ML dependency loaded. Scaffold now (pass trivially), exercise for real once B1 lands.
- **B4. Add a conditional dense + RRF arm, measured before shipped.** `[qmd-team-intent-kb + bobs-big-brain-plugin]` `(extends: qmd-team-intent-kb-0t9.3)` `serves: O1` `cite: [ret-bm25crag][ret-scifact]` `effort: L` `priority: P2`. What/why: papers disagree on whether dense helps once rerank exists; ship only on a positive delta. Acceptance: a bi-encoder (per A1's decision) candidate generator behind a flag, embeddings content-addressed, A/B measured against reranked-BM25 on `governed-brain-v1`, ship only on a positive semantic-stratum delta with no exact-term regression.

### EPIC C. Eval: make the real query set the CI gate, not the synthetic one

- **C1. Wire governed-brain-v1 into a scheduled CI job against a snapshotted brain export.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O1, M1` `cite: [eval-atma][eval-groupmem]` `effort: M` `priority: P1`. What/why: the labeled 42-query set exists but is orphaned from CI (`describe.skipIf` on cold runners); CI runs synthetic instead, so the real number is never a tracked gate. This is the single highest-leverage eval fix. Acceptance: a scheduled job restores a frozen/redacted snapshot into a throwaway index, runs `governed-brain-v1` through `adapter.query()`, fails/reports on stratified Recall@10/nDCG@10 regression past a committed floor.
- **C2. Build the answer/groundedness eval layer (Layer 3).** `[qmd-team-intent-kb]` `(extends: none)` `serves: O1, M1` `cite: [eval-probe][eval-readiness]` `effort: L` `priority: P1`. What/why: only Layers 1 (govern) and 2 (retrieval) exist; a retrieval win could still ship an ungrounded synthesis with nothing to catch it. Acceptance: a new `eval-surface` module scoring RAGAS-style faithfulness/groundedness on a 50-100 item fixture, segmented, wired as its own CI job. Honest scope: attests the answer is supported by admitted facts, not that the fact is true.
- **C3. Extend govern-decision (or add a sibling) to score dedup and supersession/promotable, not disclosure alone.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O2` `cite: [gov-ssgm][gov-neusymms]` `effort: M` `priority: P1`. What/why: today's govern eval scores secret/PII/path detection only; the plan's Layer 1 wants dup/policy/secret-PII/promotable scored together. Acceptance: labeled dedup + contradiction/supersession cases added; a precision/recall report including those classes.
- **C4. Segment every retrieval metric by exact-term vs conceptual, and tag every external-facing number with its dataset.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O1, M1` `cite: [ret-piserini]` `effort: S` `priority: P1`. What/why: `stratified-report.ts` already segments; this is a discipline bead so the article never cites a synthetic number as the real brain's. Acceptance: report output labels the source dataset; a lint fails if an article draft cites a metric without a dataset tag.
- **C5. Audit that every improvement loop in GSB traces to a ground-truth anchor, and that no loop is purely self-confirming.** `[umbrella + qmd-team-intent-kb + intentional-cognition-os]` `(extends: none)` `serves: O1, O2, O3, M1` `cite: [imp-grounding]` `effort: M` `priority: P1`. What/why: the loops-to-graphs failure mode is a network of loops that confirm each other while none touches reality (a rubric grading a rubric, CI on synthetic, a green audit over a bypassed corpus). No bead today checks the whole machine for this. Enumerate every improvement loop (compile, govern, retrieval-eval, calibration, feedback-sweep, and later federation) and, for each, name its anchor (the ground-truth it settles against) and its frozen rule (what the loop is forbidden to tune). Flag any loop whose only input is another loop's output. Acceptance: a living doc (000-docs entry, cross-linked from `016`/`017`) lists each loop with its anchor and frozen rule; the retrieval-eval loop's anchor is the real `governed-brain-v1` gold set (not synthetic, per C1); the calibration/feedback loops are shown to settle against a real-world signal (Umami content performance or human regrade) rather than only against each other; any loop that cannot name a real anchor is filed as a defect, not shipped as a metric.

### EPIC D. Freshness: recompile on push, not on a 24-hour timer

- **D1. Trigger an incremental index update synchronously after promoteCandidate() commits.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O5` `cite: [fresh-etl][fresh-serverless]` `effort: M` `priority: P0`. What/why: `IndexLifecycleManager.update()` exists but is never called from the write path; a promoted fact is invisible to `brain_search` until the nightly batch. Acceptance: a successful promotion enqueues or directly calls a doc-scoped index update; a test proves a promoted-then-searched-immediately memory is retrievable in the same run.
- **D2. Expose an index-staleness gauge (last-index-time vs last-promotion-time).** `[qmd-team-intent-kb]` `(extends: none)` `serves: O5` `cite: [fresh-etl]` `effort: S` `priority: P0`. What/why: without it, a broken incremental hook silently degrades to nightly-only. Acceptance: a staleness-seconds field on `checkHealth()`; the nightly canary asserts it stays under a threshold.
- **D3. Keep nightly full reindex as an explicit reconciliation backstop and document it as such.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O5` `cite: [fresh-serverless]` `effort: S` `priority: P1`. Acceptance: `nightly.yml`/runbook language states its reconciliation role once D1 ships.

### EPIC E. Govern: give contradiction-reconcile a first-class ordered place, operationalize mergeGovern

- **E1. Add a contradiction-detection rule that runs before any future near-duplicate rule, never after a reject short-circuit.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O2` `cite: [gov-memclaw]` `effort: M` `priority: P0`. What/why: the literal MemClaw ordering bug does not manifest today (dedup is exact-hash), but the pipeline has no contradiction stage, so adding fuzzy dedup later will short-circuit before reconcile. Fix the ordering now while it is cheap. Acceptance: a `contradiction_check` rule type; a tested invariant that no reject-action rule can short-circuit past it.
- **E2. Promote detectSupersession() from a post-hoc annotation to an admission-time govern signal.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O2` `cite: [gov-ssgm]` `effort: M` `priority: P1`. What/why: today two contradictory memories can both stay active with only a similarity link; SSGM wants this decided before consolidation. Acceptance: the supersession outcome is recorded in the same audit transaction as promotion (verify atomicity); an eval case scores whether true contradictions get flagged.
- **E3. Wire mergeGovern into a real CLI subcommand and call the signed merge anchor at the end.** `[qmd-team-intent-kb]` `(extends: compile-then-govern-8da.9, 8da.7)` `serves: O2, O7` `cite: [fed-governai]` `effort: M` `priority: P1`. What/why: the second-gate library exists and is tested but has zero operational trigger; this is the direct on-ramp to federation. Acceptance: `curator-cli merge-govern` produces the reconciled state plus a signed merge-anchor referencing both parent chain heads; runbook documented.

### EPIC F. Receipts: operationalize the dormant anchor mechanism and git-witness it

- **F1. Wire appendAnchor() into a scheduled job (or every N promotions) and commit anchors.jsonl to a non-force-pushable git ref.** `[qmd-team-intent-kb + ~/.teamkb]` `(extends: intentional-cognition-os-l13.8)` `serves: O3` `cite: [rec-apex][rec-taf]` `effort: S` `priority: P0-adjacent`. What/why: the anchor log format + truncation/rewrite detection are done; the missing piece is calling it and pushing the output where the writer does not solely control it. `~/.teamkb/audit` is a local git repo with 725 commits and no remote today. Acceptance: a CLI/cron append; a push to a branch-protected remote after each append; a documented recovery procedure for detected divergence (an alert, not a manual diff); a test proving a local rewrite-before-push is caught after the fact.
- **F2. Switch the required provenance-integrity CI gate from verifyAuditChain() to verifyAnchors().** `[qmd-team-intent-kb]` `(extends: none)` `serves: O3` `cite: [rec-apex]` `effort: S` `priority: P0-adjacent`. What/why: the CI gate should exercise the strongest verifier that exists; today it runs the weaker linear-only one while the truncation/rewrite-aware one sits unused. Acceptance: `provenance-integrity.ts` calls `verifyAnchors` where an anchor log exists, falls back only in the bootstrap case.
- **F3. Wire appendSignedMergeAnchor() into the merge-govern CLI so every merge emits a Tier 1 signed parent-bound receipt.** `[qmd-team-intent-kb]` `(extends: compile-then-govern-8da.7)` `serves: O3` `cite: [rec-apex]` `effort: M` `priority: P1`. What/why: the Ed25519 signing primitive is fully built with zero call sites. Acceptance: `merge-govern` signs and appends using a key loaded from SOPS; key generation/rotation runbook exists; the honesty ledger states the "not non-repudiation" limit in the same doc.
- **F4. Add an OpenTimestamps proof for each anchor hash.** `[~/.teamkb]` `(extends: intentional-cognition-os-l13.8)` `serves: O3` `cite: [rec-dht]` `effort: S` `priority: P1`. What/why: existence-time proof trusting neither producer nor host, orthogonal to the git push. Acceptance: an `.ots` receipt written alongside each anchor; a documented `ots verify` succeeds.
- **F5. Write the substrate-boundary doc: what the ICO chain proves (COMPILE) vs what the INTKB chain proves (GOVERN admission).** `[intentional-cognition-os + umbrella]` `(extends: intentional-cognition-os-l13.8, qmd-team-intent-kb reconciliation)` `serves: O3` `cite: (Kleppmann)` `effort: S` `priority: P1`. What/why: the reconciliation is not "pick a winner" (the chains record different things); it is "declare the layer boundary" so no reader assumes ICO's chain means the corpus is receipted. Acceptance: a doc states it plainly; the forbidden-words honesty lint is extended to flag any claim that conflates the two.
- **F6. Build the end-to-end provenance walk: ICO compile-trace to spool manifest SHA-256 to INTKB admission record.** `[intentional-cognition-os + qmd-team-intent-kb]` `(extends: none)` `serves: O3` `cite: (Kleppmann)` `effort: M` `priority: P1`. What/why: three artifacts each attest a piece but nothing walks all three as one path; this is the actual completeness-across-the-seam proof. Acceptance: a command takes an INTKB memory_id, walks to its spool candidate id (UUID v5), confirms the manifest SHA-256, confirms an ICO compile trace exists, reports PASS/FAIL per fact.

### EPIC G. The completeness invariant (highest-value, must close before any receipts claim)

- **G1. Make the corpus write path crash-safe: file-write and receipt-write are one atomic unit, or an unreceipted file is detectably quarantined.** `[intentional-cognition-os]` `(extends: none)` `serves: O2, O3` `cite: (Kleppmann completeness invariant)` `effort: M` `priority: P1 (highest value)`. What/why: `promotion.ts:354` writes the wiki file, `:366` writes the receipt in a separate try-block; a crash between leaves an unreceipted file `emitSpool` will ingest. Same pattern in all five compiler passes. "Fails closed" is not true anywhere; it fails silent-incomplete. Acceptance: either receipt-first-in-transaction with staged-then-renamed content, or a startup reconciliation pass that quarantines any `wiki/`/`outputs/` file with no matching trace/promotion row; a fault-injection test (kill between file-write and receipt-write) leaves a state the reconciliation catches.
- **G2. Add a substrate-level guard against direct curated_memories writes bypassing the gate.** `[qmd-team-intent-kb]` `(extends: none)` `serves: O2, O3` `cite: (Kleppmann)` `effort: M` `priority: P0-adjacent`. What/why: one INSERT call site (good) but ~14 files open the DB directly for write and no trigger/role/permission enforces sole-writer. Acceptance: a reconciliation job comparing `curated_memories` row-count/hash-set against what `audit_events` accounts for, flagging any row with no matching admission event; a test that a raw-handle INSERT is caught within one run cycle. Adopt the `batch-deprecate-gcp` read-only-SQL + write-via-MCP pattern as the required template for any bulk-edit script (consider a lint rule).
- **G3. Chain the daily ICO trace files so whole-day deletion is detectable by file-walk alone.** `[intentional-cognition-os]` `(extends: intentional-cognition-os-l13.7)` `serves: O3` `cite: (Kleppmann)` `effort: S` `priority: P1`. What/why: complements `l13.7`'s SQLite cross-check with an offline-auditable link (first line of day N carries prev_hash = last line of day N-1). Acceptance: deleting a mid-chain day file is detected by `verifyAuditChain` alone; make `l13.7`'s tail-truncation coverage explicit and tested.
- **G4. Document and codify the multi-process-same-writer-code-path model.** `[qmd-team-intent-kb + bobs-big-brain-plugin]` `(extends: none)` `serves: O2` `cite: (Kleppmann)` `effort: S` `priority: P2`. What/why: `governed-brain.cjs` is spawned per Claude and per Grok session, each opening `teamkb.db`; WAL + busy_timeout anticipate this but the "N processes, 1 logical writer" invariant is unstated. Acceptance: a doc (or `005-AT-ARCH` addendum) states it, citing the WAL/busy_timeout choice.
- **G5. Decide and document whether ICO wiki/ needs sole-writer enforcement or is explicitly pre-admission scratch space.** `[intentional-cognition-os]` `(extends: intentional-cognition-os-l13.2/l13.4)` `serves: O2` `cite: (Hickey seam)` `effort: S` `priority: P2`. Acceptance: doc states the boundary; if wiki/ is scratch, `emitSpool` docstring and 000-docs say so.

### EPIC H. Threat model: authenticated write-time provenance

- **H1. Add an HMAC origin token to brain_capture in both modes, computed over (source-channel, content).** `[bobs-big-brain-plugin + qmd-team-intent-kb schema]` `(extends: none)` `serves: O6` `cite: [threat-smsr]` `effort: M` `priority: P1`. What/why: SMSR shows write-time HMAC cut unsigned-injection success 93-100% to 0%. Acceptance: every candidate carries a non-forgeable origin token verified before promotion; a hand-crafted candidate with a missing/invalid token is rejected, not silently promoted (schema addition to `MemoryCandidate` is a cross-repo dependency).
- **H2. Persist the origin token into the durable receipt (AuditEvent), not just the transient candidate.** `[bobs-big-brain-plugin + qmd-team-intent-kb]` `(extends: none)` `serves: O6` `cite: [threat-smsr]` `effort: M` `priority: P1`. What/why: the honest claim is the receipt carries the token, enabling post-hoc attribution/rollback; today `AuditEvent` has no such field. Acceptance: the receipt carries the token or its hash; `brain_audit_verify` can surface presence in verbose mode without becoming a second info-disclosure oracle (respect the R8 concern).
- **H3. Define and enforce an authorized-channel allowlist that refuses admission from unrecognized channels (team mode first).** `[bobs-big-brain-plugin]` `(extends: none)` `serves: O6` `cite: [threat-untrusted]` `effort: S` `priority: P1`. What/why: the plan requires refuse, not log. Acceptance: a candidate whose channel is not allowlisted gets a distinct 4xx, not a silent quarantine; a test asserts it.
- **H4. Decide and document honestly whether local mode needs its own channel-attestation story, or is explicitly out of scope.** `[bobs-big-brain-plugin]` `(extends: none)` `serves: O6, M3` `cite: [threat-mempoison]` `effort: S` `priority: P1 (honesty-blocking)`. What/why: local mode has no write-gate by design, so the plan's write-gate claim is currently true only in team mode; ship the scope decision before the claim ships in copy. Acceptance: a decision note states the boundary.
- **H5. Name the residual (L2/L3 poison, authenticated-insider) wherever the write-gate ships.** `[bobs-big-brain-plugin + umbrella]` `(extends: none)` `serves: O6, M3` `cite: [threat-mempoison]` `effort: S` `priority: P1`. What/why: containment + attribution, not prevention. Acceptance: `AGENTS.md` and the brain skills carry the defensible sentence naming the residual.

### EPIC I. Federation design (strategic, design-only, gated behind Waves 1-2)

- **I1. Write the federation design spec, reusing mergeGovern as the second-gate mechanism.** `[intentional-cognition-os + qmd-team-intent-kb + plugin]` `(extends: compile-then-govern-8da.9)` `serves: O7` `cite: [fed-memclaw][fed-topologies]` `effort: M (design only)` `priority: P2`. Acceptance: a design doc naming which existing modules are reused (merge-gate, signed-merge-anchor, spool tenantId) vs net-new (trust-weight config, per-source receipt-hash reference).
- **I2. Design the MERGE RECEIPT schema (reference the source brain's receipt hash).** `[plugin + qmd-team-intent-kb]` `(extends: none)` `serves: O7` `cite: [fed-traceability]` `effort: M (design)` `priority: P2`. Acceptance: design doc specifies the receipt shape, where the source-brain hash is verified before trust, how the verifier walks a cross-brain reference without loading the source DB.
- **I3. Design the second deterministic gate that re-scans policy/secret/PII on promoted facts (never inherits the source verdict).** `[plugin + qmd-team-intent-kb]` `(extends: none)` `serves: O7` `cite: [fed-gatemem]` `effort: M (design)` `priority: P2`.
- **I4. Design trust-weighted cross-brain dedup/contradiction resolution (trimmed-mean).** `[qmd-team-intent-kb]` `(extends: none)` `serves: O7` `cite: [fed-aggregation][fed-repair]` `effort: S (design)` `priority: P2`.
- **I5. Design scoped-read enforcement across brain boundaries (raw spool never crosses).** `[plugin]` `(extends: none)` `serves: O7` `cite: [fed-memclaw]` `effort: S (design)` `priority: P2`.
- **I6. Record the rejected peer topology as an explicit non-goal.** `[umbrella]` `(extends: none)` `serves: O7` `cite: [fed-torra]` `effort: S` `priority: P2`. Acceptance: the design docs carry a "rejected: peer sync" section citing the reason (N-squared ungoverned boundaries).

### EPIC J. The article and the honesty rail (the outward deliverable)

- **J1. Draft the competitive article (Tier 3 case study), leading with the seam and completeness, not the reranker.** `[startaitools]` `(extends: none)` `serves: M1, M4` `cite: (all of 018)` `effort: L` `priority: after Wave 1 measured`. Acceptance: every factual claim traces to a measured GSB number or an `018` citation; the "who decides what is durable, and can you prove it" spine; Cerebras as the honest foil; federation as the closer.
- **J2. Run the forbidden-words lint on the article source and confirm the honesty ledger names what remains.** `[startaitools + umbrella]` `(extends: none)` `serves: M2, M3` `cite: (none)` `effort: S` `priority: with J1`. Acceptance: the lint passes on the draft; the ledger section names non-repudiation-local out of scope, L2/L3 and authenticated-insider residual, no diagrams, internal-fixture govern metrics.

---

## Wave sequencing (traced to priorities and dependencies)

**Wave 0 (unblock).** A1 (reconcile the retrieval decision) is **DONE** (`044-AT-DECR`: reranker-first, dense deferred, EmbeddingGemma out). Epic B is unblocked.

**Wave 1 (P0 / P0-adjacent, correctness and the receipts floor).**
- G2 (substrate guard) + G1 (crash-safe write path) + F1 (wire+git-push the anchor) + F2 (CI uses verifyAnchors) + G3 (chain the ICO trace files). This cluster is the "before any receipts claim" gate.
- E1 (contradiction ordering) protects the gate before fuzzy dedup ever lands.
- B1 (reranker) + B2 (seam firewall, same PR) once A1 resolves.
- D1 (recompile on push) + D2 (staleness gauge).

**Wave 2 (P1, prove it and harden).**
- C1 (real query set in CI) + C2 (groundedness layer) + C3 (govern eval scope) + C4 (dataset tagging) + C5 (grounding audit: every loop names its anchor).
- B3 (seam-independence gates) + E2 (supersession at admission) + E3 (merge-govern CLI) + F3 (signed merge anchor wired) + F4 (OpenTimestamps) + F5 (substrate-boundary doc) + F6 (end-to-end walk).
- H1 to H5 (write-time provenance + honest scoping).
- G4, G5 (documentation of the writer model + wiki boundary).

**Wave 3 (P2, strategic and the article).**
- B4 (conditional dense arm, measured).
- I1 to I6 (federation design).
- J1, J2 (the article, on measured claims).

---

## Traceability (bead to success criterion)

- **O1 retrieval measured:** A1, B1, B4, C1, C4, C5.
- **O2 govern sole and correct:** C3, C5, E1, E2, E3, G1, G2, G4, G5.
- **O3 receipts complete and git-witnessed:** C5, F1, F2, F3, F4, F5, F6, G1, G3.
- **O4 seam holds:** B2, B3.
- **O5 freshness composes:** D1, D2, D3.
- **O6 poisoning honest:** H1, H2, H3, H4, H5.
- **O7 federation provable:** E3, I1, I2, I3, I4, I5, I6.
- **Meta (article/brand):** C1, C2, C4, C5, J1, J2.
- **Grounding invariant (cross-cutting, `[imp-grounding]`):** C5 is the standing audit; its frozen-rule and anchor instances are B2 (seam firewall), C1 (real-query anchor), F1 + G1 + G2 (receipt/completeness anchors), and `017` (targets chosen from outside).

Every bead in this blueprint is grounded in a file the audit read, a success criterion in `017`, and (where a mechanism, not a doc) a citation in `018`. Beads that extend an existing epic (`intentional-cognition-os-l13`, `compile-then-govern-8da`, `qmd-team-intent-kb-0t9`, `038-AT-DECR`) are marked so we do not duplicate open work. Hand to the per-repo bead process for creation after review.

---

## Status addendum — Wave 1 SHIPPED (2026-07-20)

Status note only; the plan above is unchanged. All listed PRs are merged as of
this note; the per-track CI and review-lane evidence lives on each PR itself
(check runs + the two MiniMax lane comments), which is the recorded gates
surface for this program — this doc intentionally carries pointers, not
copies.

| Track | Where it landed | Outcome |
|---|---|---|
| B2 seam firewall | registrar PR #294 (carried d239caa) | Branded `DeterministicScore` + dep-cruiser barrier + two-way `@ts-expect-error` proofs vs the real `RerankScore` |
| B1 reranker | registrar PR #294 | Built + **measured: ship gate MISS** — semantic Δ structurally zero (20/28 semantic queries retrieve ≤1 fused candidate: candidate *generation* is the wall, not ranking); lexical nDCG −0.026; ~2.1–4.6 s/doc CPU. Stays behind the explicit opt-in flag; plugin NOT wired; `bbb-reranker` installed but disabled. Committed artifact: registrar `eval-results/governed-brain-v1-rerank.json` |
| C1 eval anchor | registrar PR #292 | Frozen-snapshot harness + committed floor (overall R@10 0.5595 / lexical 1.0000 / semantic 0.3393) + daily `bbb-eval-governed` timer with Slack-on-regression |
| F1 anchor witness | estate + PR #290 docs | Private `bobs-big-brain-anchors` remote, force-push/deletion-blocking ruleset (GH013-proven), auto-push proven end-to-end (govern → anchor `6675c3a` → remote tip match); divergence runbook 045-OD-RNBK |
| F2 anchor cross-check | registrar PR #290 | Provenance integrity consumes fork-classified anchor verdicts (never the raw `ok`); truncation AND true re-hash-forward fail closed while intra-chain sees nothing |
| G2 substrate guard | registrar PR #289 | `verify-corpus-accounting` (accepted class exactly `promoted`); planted raw-INSERT bypass detected; nightly gate requires ≥1 accounted row |
| E1 contradiction ordering | registrar PR #288 | `contradiction_check` flag-only rule; structural two-phase pipeline — a reject rule cannot skip the contradiction flag |
| D1+D2 freshness | registrar PR #293 | Promote-then-searchable via post-commit refresher + derived dirty signal (migration v10); `stalenessSeconds` in health + nightly canary threshold |
| G1+G3 receipts floor | compiler PR #176 | Receipts precede visibility (tmp→receipts→rename, six writers) + `ico audit reconcile` quarantine + cross-day trace chaining (mid-chain day-file deletion detectable) |

**Measured consequence for later waves:** the Wave-3 dense-arm bead's gate
condition ("a measured conceptual-slice gap surviving the reranker") is now
met with committed evidence; the dense arm remains deferred per the ratified
Wave-0 decision (registrar 044-AT-DECR: dense behind a measured P2 gate) and
the Wave-3 bead deferral (registrar store, deferred until 2026-09-01).
Wave 2 (B3, C2, C3, C5, E2, E3, F3–F6, H1–H5, G4, G5) starts on this floor.
