# 012 · AA · AACR — Team Production Rollout Pass 1 + 6-Engineer Adversarial Review (After-Action Report)

| Field | Value |
|---|---|
| **Date** | 2026-07-09 |
| **Author** | Claude (Opus 4.8) for Jeremy Longshore |
| **Program** | Governed Second Brain — team production rollout |
| **Epic** | `compile-then-govern-jfv` ↔ GH `intent-solutions-io/bobs-big-brain-umbrella#35` ↔ Plane BRAIN-9 |
| **Scope** | (1) what shipped in Pass 1, (2) post-mortem of three flawed calls, (3) verbatim findings of a 6-engineer Fable adversarial review, (4) consolidated risk register, (5) gated action plan |
| **Verdict** | **Do NOT go all-at-once, and do NOT email tokens, until Gate 0 clears.** The all-at-once shape is right for six people — but only after one person proves the path end-to-end and the Gate-0 blockers are fixed. |

---

## 0. Executive summary

Pass 1 shipped the entire "safety before people" core plus the Access foundation of the rollout: tokens hashed at rest (E1), six per-user tokens minted (A2), the founder plugin enabled (A1), a teammate onboarding runbook (A3), three hardening items verified already-live (E2/E4/E5), one deferred with a recorded decision (E3), and the full bead/GitHub/Plane tracking scaffold. Everything shipped was verified against live state, not merely committed.

A subsequent **six-engineer adversarial review (Fable model), each verifying against real code and the live `~/.teamkb` state**, then stress-tested the design. It *validated* two judgment calls (holding B1 as spec-not-build; careful sequencing) and *broke* three (E1 hashing did not actually protect the live secrets; A1's user-scope enablement introduced unlocked concurrent writers and bypassed the control plane; the B1 delete-based design was wrong on the merits). It also surfaced gaps the plan missed entirely — GitHub org access, a silent smoke test, no immutable deploy artifact, and no working offboarding path.

The review produced **18 consolidated risks** across three gates. The critical path to a real kickoff is: **R3 (GitHub access) → R4 (fix the smoke test) → R7+R8 (B1 done right) → R5 (Ope pilot) → R1/R2 (rotate + don't-email-admin) → R6 (deploy artifact).**

No emails were sent. No teammate has been onboarded. This is the correct state.

---

## 1. What we set out to do

The Governed Second Brain is built and live but unused — not by the team, not even by the founder. The rollout activates all six leaders (Jeremy, Pablo — admin; Ope, Max, Ezekiel, Tim — member) on the ONE governed brain (`~/.teamkb`, tailnet-bound Fastify API at `100.109.119.103:3847`), reading it, feeding it (governed), and receiving a pushed digest — **all-at-once** (Jeremy's call: no staged beachhead).

Five epics: **A** Access (brain + Plane + Twenty + Drive), **B** Capture (auto-govern the remote inbox + transcripts), **C** Comms (Slack + email + WhatsApp digest), **D** Judge (NVIDIA-Llama→DeepSeek eval), **E** Hardening.

---

## 2. Pass 1 — what shipped (timeline + evidence)

| Item | Bead | What | Evidence |
|---|---|---|---|
| **E1** tokens hashed at rest | jfv.5.1 | `InMemoryTokenRegistry` accepts a pre-hashed `scrypt$salt$hash` verbatim | qmd-team-intent-kb **PR #227 merged `a2143be`**; +4 tests; 32/32 registry, 288/288 api green; typecheck clean |
| **E1/A2** live reseed | jfv.1.2 | `~/.teamkb/tokens.json` re-seeded to **6 hashed records**; API rebuilt to origin/main+E1 and restarted | Verified: existing token → 200, bogus → 401, anon health → 200; 6 records all `scrypt$` (jeremy/pablo admin, ope/max/ezekiel/tim member) |
| **A1** founder plugin on | jfv.1.1 | `governed-brain` MCP added at **user scope** (local mode) | `claude mcp list` → Connected; smoke: server governed-brain 1.0.0, 6 `brain_*` tools, `brain_search` → 3 results w/ 3 `qmd://` citations |
| **A3** onboarding runbook | jfv.1.3 | `000-docs/011-AT-RNBK-teammate-brain-onboarding.md` | Committed `4bf2608`, pushed to umbrella main |
| **E2** anon health | jfv.5.2 | `/api/health` exempt from auth | Verified live: anon GET → 200 `{status:healthy}`; protected → 401 |
| **E4** anchor in DR | jfv.5.4 | external anchor `audit/` dir is in backup Tier-A | `teamkb-backup.sh` TIER_A_PATHS + restore anchor_missing guard |
| **E5** R2 off-host | jfv.5.5 | age archive pushed to `r2-teamkb:teamkb-backups` | rclone remote present; backup script pushes |
| **E3** VM decision | jfv.5.3 | keep dev-box soak, VM as fast-follow | Decision recorded; deferred 2026-08-15 |
| **Tracking** | jfv | program epic + 5 child epics + ~28 beads; three-layer linked; Plane BRAIN-2 reconciled → Done | GH #35, Plane BRAIN-9 |

**B1 (auto-govern the remote inbox)** was **designed, not built** — deliberately held as the "one real engineering fork" and highest-risk change.

---

## 3. Post-mortem

### 3.1 What went well
- **Everything shipped was verified live**, not just committed (health probe, existing+new token resolution, an actual `brain_search` returning cited hits, the migration-version check before restart).
- **B1 was held as spec-not-build** precisely because it was flagged as the highest-risk change with a live-path + delete behavior. The review confirmed the design was wrong — so the instinct not to rush it was correct.
- **Migration safety was checked before the restart** — the live DB was confirmed at the latest migration version (7 of 7), so the restart was a pure code deploy with no schema change against the live brain.
- **Three-layer tracking discipline** (bead ↔ GitHub ↔ Plane) held throughout; the stale Plane BRAIN-2 card was reconciled to reality.
- **Emails were held** until the build is complete — later reinforced by Jeremy.
- **A stale memory was corrected** (the audit anchor is now in backup Tier-A, resolving the old "trust root outside DR" warning).

### 3.2 What went wrong — three flawed calls (root causes)

**(a) E1 hashed the four existing tokens *in place* — reusing the same secret values — instead of rotating them.**
- *Root cause:* optimized for "existing holders keep their tokens" (zero re-issue friction) and did not reason about the **retained backups** (local 14d + VPS 14d + **unbounded R2**) that already encrypt the pre-E1 *plaintext* `tokens.json`. Those backups reference the *same* secrets that are still live.
- *Consequence:* hashing protected the file *going forward at rest* but did **not** protect the currently-live jeremy/pablo/ope/max secrets — they remain recoverable from any pre-2026-07-09 `.age` archive + an age key.
- *Lesson:* **hashing an existing secret in place ≠ protecting it** when the plaintext exists elsewhere. Retiring a plaintext-exposed secret requires **rotation** (new value) + purging the exposure, not a re-hash.

**(b) A1 enabled the brain in every interactive session via *user-scope local mode*.**
- *Root cause:* optimized for "the founder can query the brain from any session" (dogfood reach) and did not reason about two properties of local mode: (i) local mode runs as **owner/admin in-process**, bypassing the entire HTTP control plane (write-gate, tenancy-guard, audit-actor); (ii) up to **11 concurrent sessions** become **unlocked writers** that never take the `~/.teamkb/.write.lock`, racing the 03:30 compile and 04:30 backup.
- *Consequence:* the e06.12 single-writer flock was hollowed out — it is now honored only by the two cron wrappers. A backup taken while an interactive `brain_govern`/`brain_transition` lands can restore a brain whose own trust machinery reports **"TAMPER DETECTED"** with no tampering. Combined with a non-transactional `promote()`, an ill-timed kill can leave a promoted memory with **no receipt** — a direct violation of the product's core promise.
- *Lesson:* **local mode is a single-writer, single-user design.** Making it multi-session promoted it to a concurrency + authorization surface it was never built for. The reach goal should have been met via *team mode* (through the API's single writer + audit-actor) or with the flock added to the plugin's writers.

**(c) The B1 candidate-retirement design used DELETE.**
- *Root cause:* reasoned from the code path actually read (the `z.literal('inbox')` schema, the curator, `runGovern`) and the live "0 currently rotting" state — but did **not** read (i) `005-AT-ARCH:65`, which classifies `candidates` as **insert-only / immutable / Tier-A non-reproducible source of truth**; (ii) `promotion-service.ts:28-30`, whose admin-review model depends on flagged/rejected candidates **staying in the inbox**; (iii) the spool re-ingest idempotency that dedupes by `findById` against the candidates table.
- *Consequence:* the delete design would have destroyed the only copy of a teammate's remote proposal (remote captures write nowhere else), broken the human-review queue, created a permanent nightly re-ingest/re-reject loop, institutionalized a cross-tenant dedup leak, and hard-deleted 2,186 rows with zero receipts. The proposed "second run = no-op" test would have *passed while missing the loop* (it seeds the table, not the spool files).
- *Lesson:* **a design that deletes durable rows must be checked against the data-classification doc AND every consumer of that data** (review queue, re-ingest, provenance back-links), not just the immediate write path.

**(d) Secondary: E1 was deployed from a feature branch and the deploy artifact is mutable.**
- *Root cause:* no immutable/versioned release artifact; the service runs from Jeremy's working checkout (`apps/api/dist`). Deploying from the branch then merging closed the *forward* lockout window, but the *backward* window is permanent: any rollback past `a2143be` rebuilds the pre-E1 registry, which double-hashes the now-hashed `tokens.json` and **locks out all six**. Only 1 of 6 tokens was smoke-tested, and no pre-restart backup was taken.
- *Lesson:* a **stateful auth migration** must deploy from a **tag** into an **immutable release dir**, gated by a **lockout preflight** and a per-token smoke — never build-from-working-tree.

### 3.3 Lessons (carry forward)
1. Hash-in-place is not rotation; retire exposed secrets by rotating + purging.
2. Local mode ≠ multi-session; concurrency and authz change when you widen the audience.
3. Deleting durable rows requires a data-classification + all-consumers review.
4. Stateful migrations deploy from tags with a lockout preflight.
5. A smoke test that can return the same result on success and three distinct failures is not a smoke test.
6. "All-at-once" only works after **one** person has walked the path end-to-end.

---

## 4. The adversarial review — methodology

Six general-purpose engineer agents on the **Fable** model, run in parallel, each given the same design brief and a distinct lens, each instructed to **verify against real code and live state** (they read the repos, queried the live DBs, recomputed all 2,186 candidate content hashes, checked GitHub org membership, inspected the systemd unit). Each returned a numbered finding list (title · class · severity · concrete failure with file:line · risk moderation) and a single highest-priority concern.

| # | Engineer lens |
|---|---|
| 1 | Data integrity & correctness |
| 2 | Security & secrets |
| 3 | Deployment & operations |
| 4 | Reliability & concurrency |
| 5 | Rollout completeness & teammate UX |
| 6 | Adversarial / threat model |

---

## 5. Verbatim findings (per engineer)

> Preserved faithfully with severities and file:line citations. Class ∈ {GAP, WEAKNESS, RISK}. Severity P0 (highest) → P3.

### 5.1 Engineer 1 — Data integrity & correctness
*(verified read-only against real code + a full recompute of all 2,186 candidate content hashes)*

1. **`candidates` is documented insert-only / immutable / source-of-truth** — GAP · P1. B1's "transient staging" premise contradicts `005-AT-ARCH:65` ("insert-only; the immutable record of what was proposed") and `:125/:130-131` (Tier-A non-reproducible SoT). Remote captures (`remote-server.ts:178-197` → `POST /api/candidates` → `candidate-repository.ts:175`) write nowhere else — for the 122 `source='mcp'` rows and every future teammate proposal, the candidate row is the only copy. *Moderation:* ratify an AT-DECR reclassifying `candidates`, or retire by archival (copy row to `candidates_archive` / a sweep receipt), not bare DELETE.
2. **Delete-on-flagged/rejected destroys the human-review queue and the only copy** — RISK · **P0**. `promotion-service.ts:28-30` + `candidates.ts:52`: a flagged/rejected candidate is "left untouched in the inbox … so the admin can fix the policy and retry." The reject audit event (`rejector.ts:29-45`) stores `reason` only — **never content**. So the 03:30 sweep writes a content-free event and deletes; the admin's `POST /:id/promote` 404s; content permanently gone. (Copying content into the audit event is NOT the fix — a secret-rejection would launder the secret into the append-only chain forever.) *Moderation:* delete only `{promoted, duplicate}`; keep `{flagged, rejected}`. Widen `CandidateStatus` (the `z.literal('inbox')` at `enums.ts:23` is self-imposed, not load-bearing) + migration, or add a nullable `governed_at`/`last_outcome` column.
3. **Delete breaks spool re-ingest idempotency → permanent nightly re-ingest/re-reject loop** — RISK · P1. `ingestFromSpool` dedupes by candidate ID against the candidates table (`spool-intake.ts:140-141`); spool files are never cleaned (live: `~/.teamkb/spool/` holds 11 files, 2,177 lines, since 06-22). After delete, the next nightly re-inserts every spool candidate, re-rejects (new `randomUUID` audit event each night → unbounded chain bloat). The bead's "second run = no-op" test seeds the table, not spool files, so it would pass while missing this. *Moderation:* archive spool files after ingest (`spool/ingested/`), or dedupe re-ingest by `content_hash`; rewrite the test to run twice through real spool files.
4. **`promote()` non-atomic; crash + B1 delete permanently orphans a memory with no receipt** — WEAKNESS · P1. `promoter.ts:141-242` = up to 5 autocommits (supersede-update :155 → `superseded` event :158 → memory insert :179 → links → `promoted` event :229); no `db.transaction`. Crash between :179 and :229 → memory with no `promoted` event; today the candidate row survives as forensic evidence; under B1 the duplicate path (no audit) deletes it → memory with no receipt, invisible to `brain_audit_verify`. *Moderation:* wrap the promote write block in `db.transaction()`; gate the duplicate-delete on `SELECT 1 FROM audit_events WHERE memory_id=? AND action='promoted'`.
5. **Curator batch dedupe is cross-tenant; the API path calls this a leak; B1 institutionalizes it with deletion** — WEAKNESS · P2 now, P1 at 2nd tenant. `dedup-checker.ts:28`→`findByContentHash` (no tenant filter) and `getAllContentHashes()` (global) vs `promotion-service.ts:60-67` which tenant-scopes deliberately ("a global hash lookup would let tenant A's candidate be blocked as a duplicate of tenant B's memory, leaking cross-tenant state"). *Moderation:* tenant-scope `checkDuplicate`/`getAllContentHashes` before the sweep ships, or assert single-tenant in the sweep and fail loudly.
6. **One poison row aborts the entire sweep forever; no per-candidate containment** — RISK · P2. `rowToCandidate` throws on the first invalid row (`candidate-repository.ts:36-87`, no skip); `processBatch` wraps nothing. A future schema tighten, a hand-edited row, or a mid-batch PK conflict (an admin `POST /:id/promote` racing the sweep — API takes no flock) → `runGovern` throws → delete loop never runs → same row aborts govern every night. *Moderation:* per-candidate try/catch (skip, count, surface, never delete an errored row) + a skip-and-report row mapper.
7. **2,186 deletes with zero receipts; dangling `candidateId` back-links** — WEAKNESS · P2. The duplicate path returns before any audit write (`curator.ts:57-63`). Post-sweep, every `curated_memories.candidate_id` and `promoted` event's `details.candidateId` points at a nonexistent row → "what was proposed vs promoted" becomes unanswerable, in a receipts-branded product. *Moderation:* one batch-level `action:'deleted'` audit event per sweep (counts + `{candidateId, outcome, matchedMemoryId}` tuples, ids only).
8. **E1 token-loader silent-drop semantics** — RISK · P2. Live tokens.json verified good (6 records, valid hex). But `parseRecords` silently `continue`s malformed entries (`token-registry.ts:264-283`) → a typo drops a user, boots green, teammate gets bare 401s; `parseStoredHash` uses `Buffer.from(hex)` (never throws) → a corrupted hash falls through to `hashToken(rec.token)` (:144) → loads "successfully" but never matches (silent lockout); whole-file JSON corruption → 0 records → prod boot throws → `Restart=on-failure` loop. *Moderation:* log `loaded N records (actors: …)` at boot, WARN per skip (fail boot if parsed < entries); treat a `scrypt$` that fails parse as a load error, never plaintext fallthrough; `jq length==6` deploy smoke.
9. **"Promoted → dedupe forever" holds only byte-identically** — WEAKNESS · P3. `computeContentHash` is raw sha256, no normalization (`hash.ts:5-7`); a one-whitespace re-proposal promotes anew, and title-similarity supersession (0.6) may mis-supersede. Pre-B1 these sat visibly in the inbox. *Moderation:* accept for rollout, document, route to the eval track (0t9).
10. **Multi-writer audit-chain forks become routine, diluting the benign-fork signal** — WEAKNESS · P2. The always-on API, nightly `runGovern`, and any interactive `brain_govern` each do a non-atomic read-head→insert → CHAIN_FORKs (already 155, all benign). *Moderation:* `BEGIN IMMEDIATE` (or honor the write-lock) on audit head-read+insert; alert on week-over-week benign-fork growth.

**Highest concern (E1):** Finding 2 — the uniform delete silently, permanently destroys precisely the material the policy engine said needs a human decision, firing automatically at 03:30 the first night a teammate's proposal trips a flag.

### 5.2 Engineer 2 — Security & secrets
*(verified against live tokens.json, the systemd unit, `~/.claude.json`, `teamkb-backup.sh`, and source)*

1. **Retained backups hold PLAINTEXT of currently-live token secrets — E1 undermined** — RISK · **P0**. `tokens.json` is Tier-A (`teamkb-backup.sh:81`) and was plaintext before today's re-seed; local `RETAIN=14`, VPS `RETAIN=14`, **R2 has NO prune** (`:247` bare `rclone copy`) → R2 accumulates every pre-E1 plaintext-token archive forever. The re-seed reused the same secrets → anyone reading one pre-E1 `.age` + an age key recovers the live jeremy/pablo/ope/max plaintext. *Moderation:* rotate the token secrets at cutover; purge all pre-2026-07-09 `.age` from local+VPS+R2; add R2 lifecycle retention.
2. **Emailing a plaintext ADMIN token, no expiry, non-durable revoke = permanent full-brain compromise on any mailbox breach** — RISK · **P0**. Pablo = admin (promote/policy/import/transition + **revoke**, `write-gate.ts:16`). All records `expiresAt:None`. Live revoke is in-memory (`token-registry.ts:185-196`), lost on `Restart=on-failure RestartSec=3` → a revoked token silently returns after any restart. *Moderation:* don't email admin tokens; set `expiresAt` on every token; make revocation durable (rewrite tokens.json / persisted revocation list at boot).
3. **User-scope local-mode MCP makes EVERY session an unaudited admin on the shared prod brain** — RISK · P0/P1. `~/.claude.json` `governed-brain` (no `TEAMKB_API_URL`) → local mode, same DB the API writes; `config.ts:9-15` "local mode is always the owner (admin) … no server to re-enforce a role boundary." So `brain_capture`/`brain_govern`/`brain_transition` run in-process as admin, bypassing write-gate/tenancy/raw-inbox lock, in up to 11 sessions + headless cron, stamped `actor:'owner'` (no attribution). A prompt-injected session can `brain_transition` to retire governed memories. *Moderation:* point the box's user-scope MCP at team mode (`TEAMKB_API_URL` = local tailnet API) so even Jeremy's writes traverse token+write-gate+audit; or gate local write tools behind explicit opt-in; at minimum stamp a real per-session actor.
4. **Backup single-writer lock does not cover the dominant writers → silently skewed DR archives** — WEAKNESS · P1. `teamkb-backup.sh:111-128` + `teamkb-compile-daily.sh:69-74` honor `.write.lock`, but the plugin write path and the live API have **zero** lock primitives (grep = none). The 04:30 `VACUUM INTO` (`:148`) racing an interactive/API write → snapshot DB state mismatches exported wiki/qmd/anchor; the restore round-trip (`:207-230`) checks integrity + counts, not cross-artifact consistency → an internally skewed brain that passes restore. *Moderation:* make `.write.lock` mandatory for all writers (wrap `runGovern`/`brain_transition` + API promotion/transition/import).
5. **Write-boundary secret scanner is narrower than the policy scanner** — GAP · P1. `assertDisclosureClean` → `disclosure-filter.ts:88-111` = **11 provider-prefixed patterns**; `scanForSecrets` → `patterns.ts` = **15** including `connection-string`, `env-secret` (`PASSWORD=…`), `high-entropy-hex`, Azure/GCP. The extras are absent at the boundary → `postgres://svc:pw@db/prod`, `DATABASE_PASSWORD=…`, an Azure `AccountKey`, a GCP service-account blob pass `assertDisclosureClean`, are INSERTed durably, and even if later rejected the row stays at rest (swept to backup + R2). *Moderation:* converge boundary SECRET_PATTERNS up to the policy superset + a drift regression test.
6. **All 6 tokens unscoped (`tenants:None`) — latent cross-tenant read the moment a 2nd tenant exists** — WEAKNESS · P2. `tenancy-guard.ts:128` early-returns on empty allowlist → the whole c5k.2 isolation machinery is dormant; add a 2nd tenant and all 6 read it. *Moderation:* bind every token to `tenants:['intent-solutions']` now.
7. **`scryptSync` in the request path — event-loop-blocking, O(records)/request, tailnet amplifier** — WEAKNESS · P2. `resolve()` runs scrypt over every record for every request, no early return (`token-registry.ts:169-183`); blocks the single Node thread; rate limit per-IP 100/60s. Bursts from tailnet nodes serialize all handling. *Moderation:* async scrypt and/or key records by a fast prefix; keep constant-time compare on the matched record.
8. **Tailnet is the only network control** — RISK · P2. `bindHost`/`isLoopbackHost` fail-closed logic is correct (`api-key-auth.ts:44-113`), but past that the only control is tailnet reachability; any member token reads scope `all`/`inbox`/`archived` across the tenant. *Moderation:* Tailscale ACLs restricting `:3847` to the 6 devices; treat verbose `brain_audit_verify` + `inbox` scope as admin-gated on read too.

**Highest concern (E2):** #1 + #2 — the plaintext-token blast radius is both retroactive (pre-E1 backups on unbounded R2 hold live secrets) and forward (about to email pablo's admin token, no expiry, revoke that doesn't survive a 3s restart) → a single mailbox or backup-object compromise = permanent, unrevocable admin over the one brain. Fix before the email goes out.

### 5.3 Engineer 3 — Deployment & operations
*(verified: service restarted 16:06:28; E1 merge `a2143be` landed 16:08:34, ~2 min AFTER the restart; live `schema_migrations` MAX=7 = MIGRATIONS count; 6 scrypt records; 2186 candidates all inbox, unpromoted=0)*

1. **The deployed artifact is a mutable, mixed-vintage dist with no rollback target** — GAP · **P0**. `dist/main.js`/`app.js`/`api-key-auth.js` mtime **Jun 23**; `dist/auth/token-registry.js` **Jul 9 16:05**; `packages/store/dist` a Jun 23/Jun 30 mix. Today's `pnpm -r build` was incremental `tsc -b`, layered on artifacts of unknown provenance, and overwrote the build that served Jun 25–Jul 9 in place — it no longer exists anywhere, and its source ref is unknown. *Moderation:* deploy from immutable versioned release dirs (`git tag` → clean build → `releases/<tag>/` → flip a `current` symlink → point the unit at it → restart → smoke → keep last N). Rollback = symlink flip + restart.
2. **Residual lockout path: any rollback past E1 double-hashes tokens.json → all 6 locked out** — RISK · P1. The forward window is closed (main has `a2143be`), but every ref before it — including every tag (`v0.7.0`≤) — has the pre-E1 registry that re-hashes the token field; dist is gitignored so any rollback is a rebuild-from-source; every rollback target that exists today is pre-E1. *Moderation:* tag E1 now (e.g. `v0.8.0`) as the rollback floor ("never deploy a ref without `a2143be`"); add a lockout preflight (`grep -q parseStoredHash dist/... || abort`) + a startup self-test resolving a known token before declaring the restart good. Safer sequence for next time: merge → tag → clean-build-from-tag → re-seed → restart → smoke all 6.
3. **Working-tree == live-service, on a box with concurrent Claude sessions and `Restart=on-failure`** — RISK · P1. Unit runs `apps/api/dist/main.js` from Jeremy's checkout. (i) crash-time nondeterminism: a crash relaunches from whatever dist is on disk — a torn mid-build dist or one built from the parked `feat/e06.15` (3 unmerged commits, verified present) → an unreviewed deploy by systemd at a random time; (ii) cross-session clobber (a documented 2026-07-01 hazard, now a prod deploy surface); (iii) dist survives branch switches (gitignored) → feature-branch poison persists. *Moderation:* release-dir pattern eliminates all three; interim, build the parked branch only in a `git worktree`.
4. **The (a) justification was necessary but not sufficient — four unchecked things** — WEAKNESS · P1. Migration argument verified sound (`database.ts:83-105` filters `version>7`, no-ops, transactional). But: (i) **no pre-restart backup** — last was 04:30, ~11.5 h of writes exposed; transactionality protects a failed migration, not a successful behavior change; running `teamkb-backup.sh` (2 min, restore-verified) first was free; (ii) the API opens the DB read-write and mutates at startup (`main.ts:33`) — "no migration ran" was luck-of-state confirmed after the fact, not a preflight gate; (iii) 288 tests ran against src; the service runs the mixed-vintage dist — nothing validated the deployed artifact; (iv) **only 1 of 6 tokens smoke-tested** (journal shows one `query-access actor:jeremy` at 16:06:51 + a **401 at 16:06:32**, source unidentified). *Moderation:* a deploy preflight: on-demand backup → migration-delta check with ack → clean build → restart → smoke `/health` + one authed search per token → watch 401 rate 10 min.
5. **B1's first sweep is safe by verified accident; steady-state deletes proposals never backed up, with no receipt** — RISK · P1 (first-run P2). First run: all 2186 dedupe (recoverable 14d), fine. Structural: (i) the duplicate path writes no audit → 2186 deletes with no receipt; (ii) **timing inverts backup coverage** — compile+sweep 03:30, backup 04:30 → a 10:00 remote proposal is deleted at 03:30 before the 04:30 backup ever sees it → **no remote candidate row ever appears in any backup**; a hash-logic/normalization bug that mis-classifies one as duplicate = gone (no memory, no receipt, no backup row); (iii) the delete loop has no count-match guard. *Moderation, priority order:* (1) **graveyard before DELETE** — append each swept candidate to `~/.teamkb/brain/spool/swept-candidates.jsonl` (already Tier-A) before `deleteById`; (2) assert `r.results.length === inbox.length` before any delete; (3) an audit event for the duplicate-delete path; (4) run the first live sweep **manually in daylight** with a fresh backup, not the 03:30 cron whose wrapper SIGKILLs at 1800 s.
6. **No monitoring, no alerting, no watchdog on the team-critical service** — GAP · P2. `Restart=on-failure` but no `WatchdogSec`, no memory limit; nothing polls `/api/health`; the box dead-man's-switch covers cron beats, not this daemon. *Moderation:* a 5-min cron `curl /api/health` → `notify-lib cron_fail` (the anon health probe's consumer); add `MemoryMax` + `StartLimitIntervalSec/Burst`.
7. **Team prod runs in a user slice on a dev box with a documented systemd-kills-user-scopes hazard** — RISK · P2. `systemctl --user`, `Linger=yes`; the DO-NOT list documents that a systemd minor upgrade → `daemon-reexec` → user-scope deaths; the mitigation is a convention, not a control; `jfv.5.3` (VM) frozen at P3. *Moderation:* near-term convert to a system unit (`User=jeremy`, `multi-user.target`); re-score the VM once >2 external users active.
8. **Manual deploy is a safety feature only by accident — the gap is no deploy procedure** — GAP · P2. With working-tree==live, auto-deploy-on-merge would be dangerous, so keep it manual — but "manual" = "whatever Jeremy typed": no script, no recorded ref, no health gate, no rollback step, no operator doc (`011-AT-RNBK` is onboarding; `006-AT-RNBK` is backup/restore). *Moderation:* one `deploy-brain-api.sh` (tag → clean build to release dir → preflight → symlink flip → restart → per-token smoke → append `DEPLOYS.log`) + an operator runbook section.
9. **Two weeks of behavior drift shipped to 4 users with no announcement or changelog gate** — WEAKNESS · P3. Verified drift since Jun 25: `#214` (audit-break classifier), `#221` (govern-rule precision), `#227` (E1). *Moderation:* the deploy script posts a one-line "brain API deployed `<tag>`: `<highlights>`" to Slack.
10. **Runtime unpinned: `/usr/bin/node` + PATH `~/.bun/bin` on an unattended-upgrades box** — WEAKNESS · P3. `better-sqlite3` is ABI-coupled; an apt node bump makes the next restart fail with an ABI error — and the next restart may be an unattended crash-restart. *Moderation:* pin node in the release dir (or record `node --version` in the deploy stamp + preflight check).

**Highest concern (E3):** There is no immutable versioned deploy artifact — findings 1+2 compound so every rollback target that exists today rebuilds a registry that locks out all six, while the only artifact known to work is destroyed by the next incremental build. Fix once with release-dir + symlink + tag-floor + lockout-preflight (~1 hour) and 1, 2, 3, 8, half of 4 collapse — **before B1 ships.**

### 5.4 Engineer 4 — Reliability & concurrency
*(verified: `grep flock` over the plugin + bundle = 0; user-scope MCP live at `~/.claude.json:7954`)*

1. **Interactive write tools bypass the e06.12 single-writer lock entirely — A1 hollowed it out** — GAP · **P0**. `brain_capture`/`brain_govern`/`brain_transition` (`local-server.ts:308-444`) write spool/DB/anchor-git with no lock; only the two shell wrappers take `.write.lock`. Race vs backup: 04:30 `VACUUM INTO` (snapshot T1) then tars `audit/` (T2); an interactive `brain_govern`/`brain_transition` between T1 and T2 appends anchor rows → archived anchor log `chainedRows` > archived DB rows → restore `verifyAnchors` (`audit-anchor.ts:186-192`) reports `HISTORY_TRUNCATED` → `brain_audit_verify` treats it as **always tamper-grade** (`local-server.ts:269-274`) → a restore-tested backup that screams **"TAMPER DETECTED"** in DR. *Moderation:* take `$TEAMKB_HOME/.write.lock` inside `runGovern()` + `brain_transition` (flock via `fs-ext`/`proper-lockfile`, or `O_EXCL` lockfile w/ stale-PID); on contention return "brain busy — retry."
2. **`appendAnchor` is a read-then-append with no lock — concurrent writers fork the anchor log → FALSE TAMPER** — RISK · P1. The DB chain fork was fixed with `BEGIN IMMEDIATE` (yxp), but `appendAnchor` (`audit-anchor.ts:98-120`) reads the tail for `prevAnchorHash` (:106-107) then `appendFileSync` (:118); two `brain_transition`s (or one racing the nightly `anchorChainHead`, `govern.ts:122`) → two records with the same `prevAnchorHash` → `ANCHOR_LINK_MISMATCH` (:176-183) → `ok:false` "TAMPER DETECTED" with zero tampering. *Moderation:* serialize under `.write.lock` (free with #1); defensively classify a same-`prevAnchorHash` pair with intact hashes as benign `ANCHOR_FORK` (mirror the yxp classifier).
3. **`promote()` writes memory, links, receipt as separate autocommits — a kill mid-promote leaves a promoted memory with NO receipt** — WEAKNESS · P1. `promoter.ts` supersede-update + `superseded` event (:155-176) commit before `memoryRepo.insert` (:179); `promoted` event last (:229); no `db.transaction` in the curator (grep = 0). The cron kills with `timeout 1800`; the server SIGTERM does `process.exit(0)` (`local-server.ts:455-461`). Contrast `brain_transition` which correctly uses `db.transaction` (:408-420). *Moderation:* wrap each candidate's promote in one `db.transaction` (repos share the handle `runGovern` creates).
4. **`runGovern`'s DB→export→index→anchor is non-atomic under crash** — RISK · P2. Mostly self-healing (export incremental, index re-runs), but the anchor is best-effort (`govern.ts:123-125` swallows) → new rows unanchored until the next pass, uncounted. *Moderation:* `timeout -k 30 1800` for a SIGTERM grace window; await in-flight govern in the shutdown handler; count consecutive anchor failures and alert at ≥2.
5. **Readonly connections get no `busy_timeout` → `brain_status`/`brain_audit_verify` throw raw SQLITE_BUSY under load** — WEAKNESS · P2. All pragmas are inside `if (!readonly)` (`database.ts:56-71`); readonly opens (`local-server.ts:205,243`) get `busy_timeout=0` → immediate `SQLITE_BUSY` during a WAL checkpoint. *Moderation:* `db.pragma('busy_timeout = 5000')` unconditionally (legal on readonly).
6. **Two concurrent govern passes double-drain the spool → a PK collision aborts the whole batch** — RISK · P2. Dedupe is `findById`-then-`insert` (`spool-intake.ts:139-149`), not atomic across processes; the loser throws a UNIQUE error which is not `DisclosureRejectedError` → `:157 throw e` aborts the whole ingest mid-file. *Moderation:* catch the constraint per-candidate and `continue` (`INSERT OR IGNORE`); primary fix is #1's lock.
7. **Lock-skip paths exit 0 AND drop the liveness heartbeat → a recurring collision = NO backup, forever, silently** — WEAKNESS · P2. `teamkb-backup.sh:122-124` flock timeout → `exit 0`; the EXIT trap touches `.beat` on every exit → the dead-man's-switch is satisfied by a run that backed up nothing; a manual compile straddling 04:30 nightly (compile can hold 30 min; backup waits 300 s) = unbounded unalerted gap. *Moderation:* write a distinct `skipped` marker; alert on 2 consecutive skips; don't drop the success beat on a skip.
8. **All 11 sessions append to ONE shared dated spool file, ignoring the per-agent API built for this** — WEAKNESS · P3. `local-server.ts:332` calls `writeToSpool` with no `agentId` despite `spool-writer.ts:19-23` providing per-agent files; a large candidate's append spans multiple `write()` syscalls → interleave corrupts a JSONL line (reader skips it → silent loss). *Moderation:* pass `agentId: String(process.pid)`.
9. **Concurrent anchor-git commits contend on `index.lock`; failures swallowed to `committed:false`** — RISK · P3. `anchor.ts:47-64` git add/commit in the shared `audit/` repo; concurrent committer → `index.lock` failure → caught → `false`; fire-and-forget push swallows errors. *Moderation:* one retry on `index.lock`; a failure counter in the result; covered by #1.
10. **Crash-ordering skew between `synchronous=NORMAL` WAL commits and the un-fsynced anchor append** — RISK · P3. `database.ts:62` NORMAL → an OS crash can lose the last DB commits while the anchor `appendFileSync` (no fsync) survives → anchor ahead of chain → `HISTORY_TRUNCATED` false tamper on reboot. *Moderation:* document in tamper-triage; special-case "single trailing anchor ahead of an otherwise-clean chain" as a crash artifact.

**Highest concern (E4):** Finding 1 — A1 silently converted the e06.12 flock from "the `~/.teamkb` single-writer lock" into "a lock only the two cron jobs respect"; the worst outcome is a poisoned DR path (a backup that restores a brain reporting "TAMPER DETECTED"), and findings 2 & 3 mean ordinary concurrency and ordinary kills produce forked anchors and receiptless promotions even without the backup. **Do not onboard the other 5 leaders' write traffic until the flock lands** (~30 lines: take the flock inside `runGovern` + `brain_transition`).

### 5.5 Engineer 5 — Rollout completeness & teammate UX
*(verified: GitHub org membership via `gh api`; the runbook; live API probe; the plugin bundle; marketplace.json)*

1. **Three of five teammates cannot reach the private marketplace — GitHub access never provisioned** — GAP · **P0**. `intent-solutions-io` members = `jeremylongshore`, `opeyemiariyo-netizen`, `pabs-ai`; the marketplace repo collaborators are the same three. **Max, Ezekiel, Tim have no access.** Ezekiel's runbook Step 2 `/plugin marketplace add intent-solutions-io/team-intent-claude-plugins` → "repository not found." 60% of the member cohort is dead at step 2. No bead covers GitHub invites (A6=Plane, A7=Twenty/Drive). *Moderation:* new bead "Invite max/ezekiel/tim to the org," a dep of A5; add "Prerequisite 0: GitHub account with org access + working `gh auth`/git creds" to the runbook.
2. **`brain_search` swallows every failure into an empty result — the smoke test can't detect a bad token, a dead API, or off-tailnet** — WEAKNESS · **P0**. `remote-server.ts:111` `if (!res.ok) return empty;` + `:131-133` `catch { return empty; }`. The runbook's "team token rejected" / "Connection refused" strings only exist on capture/transition, never search. Tim's token with a trailing newline → every search returns 0 → the troubleshooting table tells him "the brain may not have that topic yet." He believes he's in; he isn't; ×5 installers = Jeremy triaging five identical "search returns nothing" reports with three root causes. *Moderation:* small plugin PR — `search()` returns `errorResult(res)` on `!res.ok` + a "could not reach the brain API" on throw (as `brain_capture` already does), re-bundle. Interim: change the smoke test to `curl /api/health` + a `brain_capture` ping (which 401s loudly).
3. **Env-var mode dispatch fails silently into the WRONG mode; the "unconfigured" error is unreachable** — RISK · **P0**. `index.ts:24-28`: unset/empty/unexpanded `TEAMKB_API_URL` → silently LOCAL mode → `require("better-sqlite3")` (bundle 36048/38864) which a marketplace clone doesn't ship → native-module crash; or, with dev deps, silently searches/captures into a fresh EMPTY local `~/.teamkb` on the laptop. The runbook blesses "the desktop/IDE app" (:31) but Step 1 only sets vars in `~/.zshrc`/`~/.bashrc` — a Dock-launched app never reads those. *Moderation:* runbook "launch `claude` from a terminal where `echo $TEAMKB_API_URL` prints the URL" as a hard preflight + desktop-app caveat; add a team-mode `brain_status` tool (proxy `/api/health` + echo mode/url/actor) — today team mode has no way to ask "which mode am I in and am I authed?"
4. **A4 has never been executed — the install path is Jeremy-box-only folklore, and #1 makes it currently impossible to execute honestly** — GAP · **P0**. `jfv.1.4` OPEN, zero evidence; nobody has proven private-marketplace clone auth on a foreign machine, Claude Code compat, `${TEAMKB_API_URL}` expansion on macOS, or the member-token experience. *Moderation:* run A4 as a **pilot-of-one with Ope this week** (his machine, his member token, runbook verbatim), capture every deviation back into the runbook, close A4 with that transcript. Do not schedule A5 until then.
5. **B1 unbuilt = capture is a broken promise; the dep IS wired (good) but the runbook already published the promise** — RISK · P1. `jfv.1.5 depends-on jfv.2.1` (verified) — the plan doesn't sequence kickoff before B1. But `011-AT-RNBK` (public) already says captures are "governed automatically overnight" — false today; if anyone with a token captures before B1, it rots. *Moderation:* keep the A5→B1 dep hard; add "Capture goes live at kickoff — don't propose before then"; ship B1's throwaway-brain verify + first live sweep before the Ope pilot.
6. **Teammate proposals carry NO per-user identity; dedupe disposal leaves no receipt** — WEAKNESS · P1. `remote-server.ts:186` hardcodes `author:{type:'ai', id:'governed-brain'}`; `candidates.ts:31` calls `service.intake(request.body)` without `request.actor` (resolved at `api-key-auth.ts:84` but never stamped) → all six leaders' proposals are byte-identical in authorship; a duplicate-judged proposal vanishes with zero trace; the "admin review surface" is just the audit log + `GET /api/candidates` (no digest, no notification). *Moderation:* stamp `request.actor` into the candidate at intake; write a receipt/log line for the duplicate/disposal path; fold a govern-summary (counts + titles + proposers) into the nightly digest email.
7. **Offboard/revocation exists but is unusable, and is documented nowhere** — GAP · P1. `POST /api/auth/revoke` is live + tested but revokes **by plaintext value** — E1 hashed tokens so Jeremy holds no plaintext → for "Tim's laptop stolen" / "offboard Max" an admin **cannot call revoke**; the real path is edit tokens.json + restart. No bead covers revoke-by-actor/rotation/expiry (jfv.5 dropped the old 650.6 scope); the runbook has no lost-token section; `pending-tokens-…txt` (plaintext, verified on disk) needs a "shred after handoff" step. *Moderation:* a `POST /api/auth/revoke-actor {actor}` bead (registry already keys by actor) + a 5-line ops runbook section.
8. **SPOF on the dev box with no liveness alerting — and #2 makes an outage look like an empty brain** — RISK · P1. User-scope unit, `Restart=on-failure`, serving from the live checkout; E3 deferred (accepted) but no uptime probe → Slack. *Moderation:* 5-min `curl /api/health || notify`; deploy-freeze on kickoff day; later a versioned release dir.
9. **The public umbrella repo discloses the brain's tailnet host, IP, port, auth scheme** — WEAKNESS · P2. `011-AT-RNBK` (public) publishes `dev.tail70fc2c.ts.net`, `100.109.119.103:3847`, the health route, role assignments by name. *Moderation:* move the teammate runbook into the private marketplace repo (they need access anyway per #1), leave a public stub.
10. **Kickoff (A5) doesn't gate on the rest of "the full stack"; A6 is chained behind a Plane-reconcile chore** — GAP · P2. A5 deps are only 1.1–1.4 + 2.1; A6 additionally `depends-on jfv.1.8` (reconcile the board) — an internal hygiene task on the human-invite critical path; nothing schedules the actual humans. *Moderation:* scope A5's announcement to brain-only with "Plane/Twenty/Drive land this week"; break the A6→A8 dep; add a kickoff checklist to A5's notes.
11. **Runbook prerequisite gaps beyond GitHub** — WEAKNESS · P2. No Tailscale install/invite step ("run `tailscale status`" is command-not-found on a fresh machine); no Claude Code version floor / licensing note; no supported-OS statement; the desktop-env contradiction (#3). *Moderation:* add a "Prerequisites 0–3" block (GitHub, Tailscale, Claude Code ≥ X + login, terminal launch).
12. **Simultaneity itself is the smallest risk; rate limiting is per-IP, untested at N>1** — RISK · P3. 100 req/min per `request.ip` + 1 MB body (`app.ts:88`, `rate-limiter.ts:33`); six distinct tailnet IPs won't trip it; the genuine risk is five people hitting #1/#2/#3 in the same hour with one support person. *Moderation:* note agentic sessions can burst past human rates (the plugin swallows a 429 into empty — same fix as #2).

**Highest concern (E5):** This rollout is not ready all-at-once, and the blocker is not B1 — it's that **the install path has never been walked by anyone but Jeremy, and 3 of 5 can't reach step 2.** Must ship before scheduling A5, in order: (1) GitHub access for max+ezekiel+tim; (2) the `brain_search` error-surfacing fix + a team-mode `brain_status`; (3) B1 with proposer attribution + a receipt on every disposal; (4) A4 executed as a pilot-of-one by Ope. All-at-once is right for six people — but only after one has proven the path.

### 5.6 Engineer 6 — Adversarial / threat model
*(verified gates against real code; note: all 6 tokens are unscoped → the tenant guard is inert)*

1. **Leaked member token = full read of the entire company brain** — RISK · P1. No read-side authz: `search-service.ts` never inspects role/actor, filters only by tenant (`:115`, `:81`); the guard short-circuits for unscoped tokens (`tenancy-guard.ts:128`). HOLDS: member can't promote/transition/import (`write-gate.ts:40`) or read the raw inbox (`:112`). *Moderation:* short `expiresAt` on member tokens; hand over out-of-band; a member-role read filter dropping `restricted`/`confidential` memories at search.
2. **Proposer self-asserts trustLevel/author/tenant — poisons provenance, defeats the trust rule** — RISK · P1 now, **P0** the moment B1 ships. Team mode builds the entire `MemoryCandidate` client-side (`remote-server.ts:178-191`); `source-trust-rule.ts:31` reads `candidate.trustLevel` verbatim → `trustLevel:'high'` clears any minimum-trust gate; author hardcoded → forgeable/attribution-less; intake records no audit + no `request.actor` (`candidates.ts:31`). *Moderation:* server-side override — stamp `author=request.actor`, force member `trustLevel` to untrusted/low, bind tenant to token, ignore client `prePolicyFlags`; write a candidate-intake audit line.
3. **B1 auto-govern deletes the only human gate — member poison becomes durable, cited, "governed" memory** — **P0** (design-forward). Today `write-gate.ts:40` (admin-only promote) is the only thing between a member proposal and durable searchable memory; B1 routes proposals into auto-govern where the only judge is 8 regex rules (deterministic ≠ correct). A false "decision" auto-promotes, surfaces as a `qmd://`-cited hit, steers the team and Claude — laundered through the exact govern+receipts wedge. *Moderation:* don't ship B1 fully-auto for member content; gate on server-forced low trust + quarantine + admin digest-approve (the `teamkb-compile` "digest-first, flip one word to auto" pattern); restrict full auto to admin/self-authored captures.
4. **Secret smuggled past the regex scan into the durable hash-chained log** — RISK · P1. `secret-detection-rule.ts` → `scanForSecrets` is a fixed pattern set; a novel key shape, a prose-described secret ("the prod password is hunter2spring"), a punctuation-split key, or double-encoded content evades; once promoted it's durable and in the chain (can't excise without re-hashing, forbidden by D5). The e06.3 newline-split (`:124`) + bounded decode (`:163`) evasions HOLD; a prose secret matches nothing. *Moderation:* an LLM secret/PII review in the compile pass before the deterministic gate for member content; keep the regex as the auditable backstop.
5. **Compromised dev-box session = total read/write + undetectable history rewrite** — **P0** blast radius, partially accepted-by-design. A1 put the brain in every session at user scope; the brain is on the shared dev box; the chain is tamper-evident not tamper-proof (a local writer edits an event and re-hashes forward; `ico audit verify` passes) within the unanchored govern-cycle window. *Moderation:* execute the dedicated tailnet VM (`650.6`) to get the brain off the shared box; shrink the window by anchoring every cycle to OTS; move the anchor signing key off the host; make `tokens.json` unreadable by ordinary sessions (a dedicated service user).
6. **Single tenant = zero isolation — the primitive is built but switched off** — P2 now, P1 on first contractor. All 6 share `intent-solutions` unscoped; the isolation code is fully built + tested and completely unused. *Moderation:* give anyone outside the core trust circle a scoped tenant/token so `tenancy-guard.ts:135` fires; the wiring just needs a non-empty allowlist.
7. **Availability — unauthenticated CPU exhaustion via synchronous scrypt on the event loop** — P2. `resolve()` runs `scryptSync` per record on every request incl. garbage bearers (`token-registry.ts:176`, no early return), blocking the single Node thread; limiter per-IP 100/min. Note `buildApp` sets no `trustProxy` — fine while binding the tailnet IP directly, but **if Caddy is ever fronted, `request.ip` collapses to the proxy → one global bucket → a single member DoSes everyone.** *Moderation:* cheap-reject malformed bearers before hashing; move scrypt to a worker/async KDF; document "never front without `trustProxy`."
8. **`scope` is not a security boundary** — P3. `brain_search` advertises `scope: inbox|archived|all` (`remote-server.ts:144`); the SQLite fallback ignores scope (`search-service.ts:114`) → `archived` still returns curated hits. *Moderation:* document scope as a ranking hint; enforce lifecycle filtering server-side if required.

**Highest threat (E6):** #3 folded with #2 — B1 auto-govern + client-asserted candidate fields = an unauthenticated-quality write path to durable, `qmd://`-cited "governed" memory. Today the admin-promote gate HOLDS and is the only thing preventing it; the rollout is about to remove it while the server still trusts client `trustLevel`/`author` and judges with defeatable regex. Fix #2's server-side overrides **before** B1 lands.

**Gate scorecard (verified):** HOLD — admin-only promote/transition/import/policy/revoke, admin-only raw-inbox reads, fail-closed no-auth-off-loopback + no-auth-in-prod, tokens hashed at rest, scrypt evasion-hardening. GAP — no read-side authz (#1), client-controlled candidate trust/author/tenant (#2), no human gate post-B1 (#3), regex-only secret ceiling (#4), tamper-evident-only on a shared box (#5), tenant isolation built-but-unused (#6), sync-scrypt DoS (#7), no candidate-intake receipt (#2/#8).

---

## 6. Consolidated risk register (deduplicated, gated)

Multiple flags = higher confidence. Severity is the max across engineers.

### 🔴 Gate 0 — before any teammate onboards / before any token email
| # | Risk (engineers) | Severity | Moderation |
|---|---|---|---|
| **R1** | E1 hashed in place, never rotated → pre-E1 backups (local/VPS/unbounded R2) hold the plaintext of the currently-live secrets (E2) | P0 | Rotate the 4 existing secrets to new values; purge pre-2026-07-09 archives from all 3 targets; add R2 retention |
| **R2** | Emailing an admin token; no expiry; revoke is in-memory (lost on 3s restart) AND revoke-by-plaintext is impossible post-E1 (E2, E5) | P0 | Don't email admin tokens; `expiresAt` on all; `revoke-by-actor` + durable revocation; shred the handoff file after handoff |
| **R3** | max/ezekiel/tim have no GitHub access to the private marketplace → dead at runbook step 2; epic A has no GitHub bead (E5) | P0 | Invite the 3 to `intent-solutions-io`; A5 dependency; add "Prerequisite 0" to the runbook |
| **R4** | `brain_search` swallows all errors into empty; silent local-mode fallback; runbook strings can't fire (E5) | P0 | Plugin PR: surface errors in `search()` + add team-mode `brain_status`; fix the runbook smoke + prereqs |
| **R5** | A4 never executed — install path is Jeremy-box folklore (E5) | P0 | Pilot-of-one with Ope before scheduling A5; fold deviations into the runbook |
| **R6** | No immutable deploy artifact + permanent rollback-lockout landmine; only 1/6 tokens smoked; no pre-restart backup (E3) | P0 | Tag E1 (rollback floor); release-dir + symlink + lockout-preflight + per-token smoke; `deploy-brain-api.sh` + runbook |

### 🟠 Gate 1 — before B1 (auto-govern) ships
| # | Risk (engineers) | Severity | Moderation |
|---|---|---|---|
| **R7** | B1 delete-design is wrong — `candidates` is source-of-truth; delete destroys the review queue + only copy, breaks re-ingest, leaks cross-tenant, no receipts (E1, +4) | P0 | No DELETE — marker-based retirement (widen enum/add column); keep flagged/rejected; archive spool; tenant-scope dedup; per-candidate containment; batch receipt *(B1 bead already rewritten)* |
| **R8** | B1 removes the only human gate + server trusts client-asserted trustLevel/author/tenant; no proposer attribution (E6, E5) | P0 | Server-side override author/trust/tenant + capture-intake receipt; member auto-promote → quarantine + admin digest-approve; LLM secret/PII review in compile |
| **R9** | A1 user-scope local mode = ~11 unlocked writers bypass flock + control plane → poisoned DR, forked anchor, receiptless promote (E4, E2) | P0 | Take `.write.lock` in `runGovern`+`brain_transition`+`appendAnchor`; wrap `promote()` in a transaction; decide interactive team-vs-local MCP mode |

### 🟡 Gate 2 — hardening (soon, not blocking)
| # | Risk (engineers) | Severity | Moderation |
|---|---|---|---|
| **R10** | Secret-scanner drift (boundary 11 vs policy 15) + regex ceiling (E2, E6) | P1 | Converge pattern sets + drift regression test; LLM review for member content |
| **R11** | `promote()` not transactional (E4, E1) | P1 | `db.transaction` (folds into R9) |
| **R12** | All tokens unscoped → tenancy guard inert; cross-tenant dedup latent (E6, E2, E1) | P1 | Scope every token to `intent-solutions` now |
| **R13** | No liveness alerting on a SPOF; rebuild mutates dist (E3, E5) | P2 | 5-min `/api/health` cron → Slack; deploy-freeze on kickoff day; convert to a system unit |
| **R14** | Sync `scryptSync` per-record on the event loop = cheap tailnet DoS; trustProxy caveat (E6, E2) | P2 | Async scrypt + cheap prefilter; document the proxy caveat |
| **R15** | Token-loader silently drops malformed entries (unlogged lockout) (E1) | P2 | Log loaded actors; WARN on skip; treat a malformed `scrypt$` as a load error; `jq length` deploy smoke |
| **R16** | Readonly connections `busy_timeout=0` → raw SQLITE_BUSY (E4) | P2 | Set `busy_timeout` unconditionally |
| **R17** | All sessions append to one spool file → JSONL corruption (E4) | P2 | Pass `agentId` |
| **R18** | Public repo discloses tailnet host/IP/port (E5) | P2 | Move the teammate runbook to the private repo or accept with a note |

### Risk moderation — accepted / deferred
- **Dedicated VM (E3 / 650.6)** — dev-box soak accepted; re-score once >2 external users active; structural fix for the compromised-session + systemd-kill risks.
- **Tamper-evident-not-proof on a shared box** — documented/accepted; OTS anchor + off-box signing key are the named upgrades.
- **Simultaneity / rate limits** — accepted; per-IP is fine for 6 humans.
- **Byte-exact (not semantic) dedup** — accepted; route to the eval track (0t9).

---

## 7. Action plan (gated → beads)

**Critical path to a real kickoff:** R3 → R4 → R7 + R8 → R5 → R1/R2 → R6.

**Owners:** 🤖 = Claude can execute solo · 👤 = needs Jeremy's hands/decision.

### Gate 0 (clear before scheduling A5 / before any email)
- **R1** 👤+🤖 rotate secrets (re-issues tokens — Jeremy's go) + 🤖 purge pre-E1 archives + R2 retention
- **R2** 🤖 add `expiresAt` + durable `revoke-by-actor`; 👤 don't email the admin token (hand-deliver); 🤖 add shred-after-handoff to the runbook
- **R3** 👤 invite max/ezekiel/tim to `intent-solutions-io`; 🤖 add Prerequisite 0 to the runbook
- **R4** 🤖 plugin PR (error-surfacing + `brain_status`) + runbook fixes
- **R5** 👤 the Ope pilot-of-one (🤖 prep the checklist + capture deviations)
- **R6** 🤖 tag E1, `deploy-brain-api.sh` (release-dir + preflight + per-token smoke) + deploy runbook

### Gate 1 (before B1 ships)
- **R7** 🤖 rewrite + build B1 per the corrected design (marker not delete; verify on a throwaway brain) — *B1 bead jfv.2.1 already corrected*
- **R8** 🤖 server-side candidate override (author/trust/tenant) + intake receipt; quarantine + admin digest-approve for member auto-promote
- **R9** 🤖 flock in the plugin writers + `promote()` transaction; 👤 decide interactive team-vs-local MCP mode

### Gate 2 (hardening)
- **R10** 🤖 · **R12** 🤖 · **R13** 🤖 · **R14** 🤖 · **R15** 🤖 · **R16** 🤖 · **R17** 🤖 · **R18** 🤖/👤

---

## 8. Appendix

**Engineer roster:** 6 × general-purpose agents on the Fable model, parallel, each verifying against real code + live state.
**Bead cluster:** filed as epic `compile-then-govern-jfv.6` (remediation), children R1–R18 mapped to Gate 0/1/2, mirrored to GitHub + Plane BRAIN for the deliverable-code items.
**Related:** `005-AT-ARCH` (data map — the candidates-is-source-of-truth classification B1 must respect), `010-AT-RISK` (the e06 risk register this extends), `011-AT-RNBK` (the runbook R4/R11 fix), `governed-brain-team-rollout` (auto-memory).

> **Standing invariant from this review:** all-at-once is right for six people — but only after one person has proven the path end-to-end and Gate 0 is clear.
