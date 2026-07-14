# 010-AT-RISK — e06 adopt-list gap analysis + risk assessment

**What this is:** an adversarial, code-grounded gap + risk assessment of the `compile-then-govern-e06`
adopt list (the work ratified by [`009-AT-DECR`](009-AT-DECR-wiki-memory-positioning-and-adopt-decisions.md)
off the [`008-AT-CMPR`](008-AT-CMPR-wiki-memory-category-competitive-teardown.md) teardown). It exists
so the e06 beads carry the risks *before* implementation, and so the dependency graph reflects the
real sequencing. Companion to 008 (what) and 009 (decisions); **this = what could go wrong and what's
missing.**

**Method:** a 49-agent workflow — 4 blueprint readers (umbrella `003/005/007`, ICO
`007-PP-PLAN-master-blueprint`/`003-AT-ARCH`/`020-AT-DIAG`, INTKB `001-AT-ARCH-repo-blueprint`/
`000-PP-PLAN-mega-blueprint` + the policy-engine/audit code, the bd/plugin system) → **10 adversarial
lenses** attacking the plan (threat-model · audit-integrity · ops/DR · cost · complexity · adoption ·
standards · sequencing · eval · legal) → **refute-default verification** of every high/critical gap →
synthesis. 51 raw gaps → 16 high-severity confirmed → the 14-item register below. Every claim traces
to a file:line, a bead, or a ratified decision.

> **Headline.** The single most important gap: **the external anchor — the entire trust root of the
> e06 receipts spine — is not yet durable.** It lives at `~/.teamkb/audit/anchors.jsonl` (+ its `.git`),
> which is **outside backup Tier-A scope** (verified: `TIER_A_PATHS` captures `brain/audit`, a
> *different* dir), fires **only on `brain_govern`, not `brain_transition`**, and has **no off-host
> remote on a default install** — so a restore silently loses tamper-evidence and the circular-trust
> fix `e06.1` promises is incomplete. Compounding it: `009-AT-DECR` D5's exception-manifest wording
> keys the 155 known breaks on **index-range/date** rather than **exact per-row hash tuples** — a
> laundering surface that turns a forged in-window edit into a `KNOWN_MIGRATION_ARTIFACT` (see §4 + the
> D5 amendment); and the store's own `provenance-integrity` eval hard-codes `chainAnomalies===0`
> (red-forever on the live brain, wired to no CI). **Overall posture:** the primitives largely exist
> (anchor, 4-reason verifier, policy pipeline, eval harness), so e06 is mostly *wiring / gating /
> honest-exception-carrying*, **not greenfield** — but `e06.1` must be the strictly-serial root, and
> **three P0/P1 prerequisites (anchor-backup, flock, qmd-reindex) were unowned** until this pass.

---

## 1. Risk register

Severity is post-verification (refute-default). "Affected beads" are the e06 children now carrying the
mitigation in their `bd show … Design` field.

| ID | Severity | Risk | Beads |
|---|---|---|---|
| **R1** | high | Exception manifest keyed on index-range/date **launders future tampering** into `KNOWN_MIGRATION_ARTIFACT` | e06.2, e06.1 |
| **R2** | high | Signed exception manifest is defeated if **not externally anchored in the same commit** as the chain head | e06.2, e06.1 |
| **R3** | med | External anchor is local-only git with **no remote**, and fires **only on govern, not transition** — circular-trust fix incomplete on default install | e06.1, e06.2 |
| **R4** | high | **Anchor log is outside backup scope**; restore silently loses tamper-evidence | e06.1, e06.2 |
| **R5** | high | `provenance-integrity` eval is **red-by-construction** against the 155 carried breaks and runs in **no** workflow | e06.2, e06.7, e06.9 |
| **R6** | high | Standalone verifier will **re-implement the frozen canonical serialiser** and drift on the next `hash_version` | e06.1 |
| **R7** | med | 3-state verifier risks a **new chain walker** when `audit-verify.ts` already discriminates 4 reasons | e06.2 |
| **R8** | med | `'TAMPER DETECTED'` banner + raw `breaks[]` **leak on the read surface** an outsider hits | e06.2, e06.9 |
| **R9** | med | Team-mode `brain_capture` lets a member **set candidate `tenantId`/`author` verbatim**; tenancy-guard is a no-op on the empty-allowlist default | e06.3, e06.9 |
| **R10** | med | e06.3 boundary scanner **doesn't scan `metadata.filePaths`/`category`**; a split/encoded secret becomes a public leak once e06.9 ships | e06.3, e06.9 |
| **R11** | med | e06.9 public showcase justified by **viral distribution at n=2 with no audience**, and drags the two P0s onto the critical path | e06.9, e06.1 |
| **R12** | low | e06.5 cost model is an **estimate with no ceiling/debounce**, and the $ figure is anchored to the **wrong provider** (Anthropic vs live DeepSeek, ~50×) | e06.5 |
| **R13** | med | e06.5 on-push compile shares `~/.teamkb` with nightly compile + backup under **zero mutual exclusion** | e06.5, e06.1 |
| **R14** | low | e06.6 makes public "audited/governed" claims ahead of the e06.3/e06.4/e06.8 numbers, and the **forbidden-words doc-lint it promises doesn't exist** | e06.6, e06.3 |

**Key mitigations (full text in each bead's `Design`):**

- **R1 — byte-pin, never range-key.** Pin each of the 155 exceptions by exact tuple
  `{id, entry_hash, prev_entry_hash, hash_version, seq}` captured at manifest-signing time. The 3-state
  verifier returns `KNOWN_MIGRATION_ARTIFACT` **only** on byte-match of the row's *current* stored hash
  against the recorded tuple; any drift re-flips to `tamper-signature`. Never key on index range
  (24–2345) or date. (`audit-verify.ts` discrimination is content-derived, so a range whitelist is the
  *only* laundering surface.) → amends 009-AT-DECR D5, §4 below.
- **R2 — anchor the manifest with the head.** Commit/OTS-stamp the manifest in the **same** external
  anchor operation as the chain head; freeze at exactly 155 entries (hard count-assert); any future
  break needs a **new** council-approved, separately-anchored manifest version carrying
  `prev-manifest-hash` — never an in-place signed append (else the amnesty list is a silent re-hash
  channel).
- **R4 — put the trust root in Tier-A.** Add `~/.teamkb/audit/` (anchors.jsonl + its `.git`) to
  `teamkb-backup.sh` `TIER_A_PATHS` and to the per-run restore round-trip (assert via `verifyAnchors`,
  not just DB table-counts). → new bead **e06.11 (P0)**, blocks e06.1.
- **R5 — fix the eval + wire it.** Update `packages/eval-surface/src/provenance-integrity.ts:59` to
  consume the 3-state verdict (`KNOWN_MIGRATION_ARTIFACT` breaks do not fail; only tamper-signature
  breaks do) **and** wire it into CI/nightly. Latent today; detonates the moment e06.7/e06.9 use it.
- **R6/R7 — reuse, don't fork.** Standalone verifier: import the frozen serialiser
  (`audit-chain.ts:129`, exported) *or* scope to anchor-level checks (`verifyAnchors`, no per-row
  serialiser). 3-state result = a **post-processor** over existing `verifyAuditChain` `breaks[]`, not a
  new walk. `CHAIN_FORK` must **not** collapse to `verified`.
- **R8 — redact the read surface.** Replace the hard-coded `'⚠ TAMPER DETECTED'` in
  `bobs-big-brain-plugin/src/local-server.ts:170` with the newcomer-safe 3-state summary; any
  internet-facing verifier returns counts only, never the raw `breaks[]`/`anchorBreaks[]`.
- **R9/R10 — server-stamp identity + widen the scanner.** `apps/api` `candidate-service.ts intake()`
  must overwrite `tenantId`/`author` from the bearer identity (fail-closed tenancy-guard); extend
  `scanDisclosureFields` to `metadata.filePaths` + `category`. Both gate e06.9's ship.
- **R13 — one flock.** Serialize all `~/.teamkb` writers before on-push compile enters the live path.
  → new bead **e06.12 (P1)**, blocks e06.5.

---

## 2. Corrected dependency DAG

Blueprint refs: `002-AT-DECR-epic1-deterministic-merge-gate.md` · `qmd-team-intent-kb/packages/store/src/audit-anchor.ts`.

```
           e06.1 [P0] external anchor -> live single-writer path
           + standalone dep-light verifier  (ROOT unblocker)
             |        |            |            |
             v        v            v            v
         e06.2[P0] e06.6[P1]   e06.10[P3]   (+ new: audit/ backup-scope P0)
        155-breaks  brand      standards
        3-state    reposition  envelope
          |  \        |          ^
          |   \       |          | (also needs e06.2 manifest)
          v    \      v          |
        e06.10  `---> e06.9 [P2/GTM] <---- e06.3
                      public showcase
                      (also demand-gate: 1st diligence/adopter)

   PARALLEL P1 legs (share no code with anchor spine):
     e06.3 govern-eval    e06.4 Recall@10 (needs qmd reindex first)
     e06.5 freshness (needs flock)    e06.7/e06.8 (P2, feed autonomous loop)

   ADDED edges vs original:  e06.2->e06.1 ; e06.6->e06.1,e06.3 ;
                             e06.9->e06.6 ; e06.10->e06.2
   NEW prereq beads (root of their leg):
     e06.11 [P0] anchor-log backup-scope   -> blocks e06.1
     e06.12 [P1] flock all ~/.teamkb writers -> blocks e06.5
     e06.13 [P1] qmd retrieval reindex       -> blocks e06.4
```

**True ready-set after wiring** (`bd ready`): `e06.3, e06.7, e06.8, e06.11, e06.12, e06.13`. The
receipts + brand critical path is now strictly serial from **e06.11 → e06.1 → {e06.2, e06.6, e06.10} →
e06.9**.

---

## 3. Data-flow — which bead touches which stage

Blueprint refs: `005-AT-ARCH` · `intentional-cognition-os/packages/kernel/src/spool.ts` ·
`qmd-team-intent-kb/packages/policy-engine/src/pipeline.ts` · `…/store/src/audit-anchor.ts`.

```
  brain/raw          ICO 6-pass compile        spool-<UTC>.jsonl
  (source-of-  ==>   (probabilistic, model) ==> + manifest SHA-256
   truth)            e06.5 freshness/delta      == TRUST BOUNDARY ==
  e06.8 faithful     e06.5 (byte-stable UUIDv5)  (deterministic below)
       |                                              |
       v                                              v
  ...................................  INTKB govern: 8 rules, NO model
                                       PolicyPipeline.evaluate()
                                       e06.3 per-check precision/recall
                                              |
                                              v
                                       curated_memories + audit_events
                                       hash-chain (v1/v2) + appendAnchor
                                       e06.2 155-breaks 3-state
                                       e06.1 anchor->live path (+every write)
                                              |
                              +---------------+----------------+
                              v                                v
                    git-export -> qmd BM25 index      audit/anchors.jsonl
                    brain_search (qmd:// cite)        + .git  <-- NOT backed up!
                    e06.4 Recall@10                   brain_audit_verify
                                                      e06.1 standalone verifier
                                                      e06.10 DSSE/in-toto shape
```

---

## 4. The 155-breaks exception — safe vs unsafe classification (D5 amendment)

Blueprint refs: `qmd-team-intent-kb/packages/store/src/audit-verify.ts` · `002-AT-DECR`.

```
  verifyAuditChain break  ->  e06.2 3-state classify
  --------------------------------------------------
  UNSAFE (009 D5 wording): key on idx 24-2345 / date
    attacker edits ANY row in-window  ->  break "expected"
    ->  laundered to KNOWN_MIGRATION_ARTIFACT  [FALSE-NEG]

  SAFE (mandate this instead):
    manifest pins each of 155 by exact tuple
    { id, entry_hash, prev_entry_hash, hash_version, seq }
    signed + externally anchored (same commit as chain head)
    ------------------------------------------------
    current stored hash == recorded tuple ? -> DOCUMENTED_EXCEPTION
    any drift from recorded broken-hash    ? -> TAMPER_SIGNATURE
    reason==CHAIN_FORK (own hash intact,           -> NOT auto-green;
      prev->real earlier row)                         needs anchor
                                                        chainedRows match
    else                                            -> VERIFIED
    NEVER re-hash (D5 unanimous) ; freeze manifest at 155 entries
```

> **Amendment to `009-AT-DECR` D5 (step 3).** The ratified wording enumerated the exception "by indices
> 24–2345 + the two dates." This gap pass (R1) found that keying on an index-*range* is a laundering
> surface — a forged edit to any row *in* the window still produces an "expected" break and is
> whitelisted. The council's *intent* (discriminate benign migration from tampering) is preserved and
> made sound by keying on the **exact per-row hash tuple** instead. This is an implementation
> correction, not a reversal; the never-re-hash policy is unchanged. See the amendment note in
> `009-AT-DECR`.

---

## 5. Load-bearing invariants (persisted to bd memory)

These 5 are now stored via `bd remember --key …` (auto-injected at every `bd prime`), so a future
session / ultracode run does not re-derive them:

1. **`gsb-spool-is-the-trust-boundary`** — the spool (`brain/spool/*.jsonl`, content-stable UUID-v5 +
   manifest SHA-256) is the deterministic/probabilistic seam; nothing below it calls a model.
2. **`gsb-audit-chain-never-rehash-155-breaks`** — tamper-*evident* not tamper-proof; the 155 breaks
   are a known hash-version migration artifact; D5 carry-with-exception, never re-hash; **byte-pin**
   the manifest.
3. **`gsb-forbidden-words-honesty-invariant`** — forbidden as GSB claims: tamper-proof / immutable /
   non-repudiation(local) / blockchain; retrieval BM25-only; anchor git-only today; deterministic ≠
   correct.
4. **`gsb-live-brain-and-anchor-locations`** — the whole brain is `~/.teamkb` (dev-box VPS, not prod);
   the anchor log at `~/.teamkb/audit/` is the trust root and is *outside* current DR scope.
5. **`gsb-provenance-eval-red-by-construction`** — `provenance-integrity.ts:59` hard-codes
   `chainAnomalies===0`, red-forever, wired to no CI; e06.2 must fix + wire it.

---

## 6. Blueprint index (referenced across the beads)

| Repo | Blueprints referenced |
|---|---|
| umbrella `governed-second-brain` | `002-AT-DECR` (merge-gate + forbidden words + trust boundary), `005-AT-ARCH` (data/state map), `007-AT-SMAP` (topology), `README.md` |
| ICO `intentional-cognition-os` | `007-PP-PLAN-master-blueprint` (§6.3 staleness), `003-AT-ARCH` (deterministic/probabilistic boundary), `010-AT-DBSC` (`compilations.stale`), `packages/kernel/src/{uuid.ts,spool.ts}`, `epics/epic-06-knowledge-compiler.md` |
| INTKB `qmd-team-intent-kb` | `001-AT-ARCH-repo-blueprint`, `000-PP-PLAN-mega-blueprint`, `038-AT-DECR` (retrieval ADR), `packages/store/src/{audit-anchor.ts,audit-chain.ts,audit-verify.ts}`, `packages/policy-engine/src/{pipeline.ts,rules/index.ts}`, `packages/eval-surface/src/provenance-integrity.ts`, `apps/api/…/candidate-service.ts` |
| plugin `bobs-big-brain-plugin` | `src/local-server.ts` (the `brain_*` MCP surface + the `TAMPER DETECTED` string), `bin/init.mjs` |

---

## 7. Ultracode / bd integration (how future runs pick this up)

- The corrected DAG, the 3 ASCII diagrams, and the per-bead mitigations live **in the beads** (`bd show
  <id>` → Design), so they travel with the work — not just in this doc.
- The 5 invariants are in **bd memory** (`bd memories` / auto-injected at `bd prime`).
- Code-anchored follow-ups (the standalone verifier, R9 tenant-binding, R10 boundary-scanner) belong on
  the **plugin/INTKB repos** (the umbrella is docs-only), cross-referenced to epic `e06` ↔ GitHub
  `intent-solutions-io/bobs-big-brain-umbrella#27`. Mirror via `bd-sync` (never raw `bd close`).
- Sequencing check any future session can run: `bd ready` must show only `e06.3/.7/.8/.11/.12/.13`;
  `e06.1` is blocked until `e06.11` (anchor-backup) lands.

**References:** [`008-AT-CMPR`](008-AT-CMPR-wiki-memory-category-competitive-teardown.md) ·
[`009-AT-DECR`](009-AT-DECR-wiki-memory-positioning-and-adopt-decisions.md) ·
[`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md) · epic `compile-then-govern-e06`
(GH #27).
