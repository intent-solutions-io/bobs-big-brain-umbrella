# 013 · OD · STND — Commit, branch & PR conventions (context-rich, outsider-legible)

| Field | Value |
|---|---|
| **Date** | 2026-07-09 |
| **Applies to** | the Governed Second Brain stack — `intentional-cognition-os` (ICO), `qmd-team-intent-kb` (INTKB), `bobs-big-brain-plugin`, and this umbrella |
| **Status** | canonical standard, **v1.1 — strengthened 2026-07-09 per external review**: decision rationale, evidence requirements, risk assessment, operational impact, deferred-work tracking, architectural-layer declaration, and the 7-question outsider test are now first-class. Referenced from each repo's `CONTRIBUTING.md` |
| **Companion** | global workflow rules in `~/.claude/CLAUDE.md` § "Workflow Orchestration" (this doc is the *how-to-write-it* layer + worked examples) |

## The one rule

> **A commit or PR note must let someone who has never seen this repo understand WHAT changed, WHY — and why this way over the alternatives — where it sits in the architecture, how we know it works, what it could break, how to undo it, and what remains unfinished.**

The audit trail is load-bearing. We ship a product whose entire wedge is *receipts* — our own change history has to hold to the same bar. A note that says only "fix bug" or "update code" fails the standard, no matter how green the CI.

---

## 1. The workflow (never merge blind)

1. **Branch from `origin/main`.** Never commit to `main`/`develop` directly. Fetch first — local `main` is often behind (squash + dependabot merges).
2. **Commit only after tests pass** locally (the repo's `test` + `typecheck` + `lint`).
3. **First push opens the PR** — that's what lets CI and the review bot see the diff. This push needs no other justification.
4. **Wait for the gate:** the required CI checks **and** the AI reviewer (see §6). Do not merge on green-CI alone if a review is pending.
5. **Address findings with a *targeted* fix-up push** — each push must answer a specific CI failure or reviewer comment. Never a speculative "made more changes" push.
6. **Merge only when checks are green, review is addressed, and the PR passes the Outsider Test (§8).** Squash-merge; the squash subject/body is the durable record — write it to this standard.
7. **After merge**, realign your working tree to `main` (`git checkout main && git pull --rebase`) so your checkout matches what's deployed.

Corollary for stateful/live services (e.g. the brain API): a PR that changes runtime behavior of a live service names the deploy step and the rollback in its body (see the AAR's R6 — deploy from a tag, not the working tree).

---

## 2. Branch names

`<type>/<short-kebab-topic>` — optionally `-<bead-or-issue-handle>`.

- `feat/` new capability · `fix/` bug · `refactor/` no-behavior-change · `docs/` · `test/` · `chore/` tooling/deps.
- Good: `feat/e1-hash-on-disk-tokens`, `fix/anchor-fork-false-tamper`, `docs/commit-conventions`.
- Bad: `patch-1`, `jeremy-branch`, `wip`.

---

## 3. Commit messages

```
type(scope): imperative subject, ≤ ~72 chars, no trailing period

WHAT changed — the mechanism, in plain terms.

WHY — the problem it solves and the architectural constraint it serves.
When a real alternative existed, one line of decision rationale:
"chose X over Y because Z." This is the part an outsider can't
reconstruct from the diff. Name the framework rule at stake ("the
model proposes; deterministic code owns durable state") when the
change touches it.

HOW verified — the tests/evidence (counts, commands, what you observed).

Refs/closes the bead + issue.
```

- **Types:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `build`, `ci`.
- **Scope:** the package/area (`api`, `curator`, `plugin`, `store`, `govern`).
- **Subject** is the headline someone scanning `git log` reads — make it specific ("accept pre-hashed scrypt tokens at rest", not "update auth").
- **Body** wraps at ~72 cols and carries the *why + rationale + architecture + verification*. Bullet lists are fine.
- **Decision rationale in commits:** non-trivial commits carry a one-line *"chose X over Y because Z"* whenever a real alternative existed. The PR body carries the full alternatives-considered paragraph (§4); the commit carries the one-liner so `git log` alone preserves the fork in the road.
- The commit **footer signature is automatic** (`attribution.commit` in settings) — don't hand-add it; never use "Co-Authored-By" or model strings.

### Worked example (real — E1, PR #227)

```
feat(api): accept pre-hashed scrypt tokens at rest (E1 / jfv.5.1)

The InMemoryTokenRegistry unconditionally re-hashed whatever string sat in
a token record's `token` field, so the on-disk ~/.teamkb/tokens.json had to
carry PLAINTEXT bearer secrets — any backup of ~/.teamkb leaked live tokens.

Teach the constructor to detect an already-salted `scrypt$salt$hash` value
(via parseStoredHash) and use it verbatim, so the at-rest form can be the
hash and no plaintext bearer secret ever lands on disk. Plaintext records
still work; a plaintext that merely looks like `scrypt$...` with non-hex
segments fails parseStoredHash and is safely hashed as plaintext.

32/32 registry tests, 288/288 api tests, typecheck clean. Unblocks A2.
Folds 650.6 item 1.
```

Why it passes: the subject is specific; the body explains the *pre-existing risk* (why), the *mechanism* (what), the *fail-safe* (architecture), and the *evidence* (how). A stranger understands the whole change without reading the diff. Under v1.1 it would also carry the one-line rationale — *"chose hash-at-rest over SOPS-encrypting tokens.json because a hash is non-recoverable even if the file leaks"* — the PR example in §4.5 shows the full version.

---

## 4. PR descriptions — the canonical structure

The PR body onboards a reviewer who knows nothing about the task, and it is what a maintainer two years from now reads *instead of* re-deriving your reasoning. It must not just claim the change works — it must point at the artifacts that prove it.

### 4.1 Two lanes — proportional, not bureaucratic

| Lane | Eligibility | Required headings |
|---|---|---|
| **Full** | anything touching code, config, CI, schemas, dependencies, or runtime behavior | all REQUIRED headings in §4.2 |
| **Lightweight** | docs/comments/changelog/typo/pure-formatting only — **no** code, config, CI, schema, or dependency change; no runtime surface | **What · Why (one line) · Refs** |

A one-line docs fix does not need a benchmark or a risk matrix. But a "docs" PR that also edits CI YAML is not docs-only. **If in doubt, use the full lane.**

### 4.2 The headings

| # | Heading | Answers | Full lane | Lightweight |
|---|---|---|---|---|
| 1 | **What** | the change, in plain terms | REQUIRED | REQUIRED |
| 2 | **Why & decision rationale** | the problem + alternatives considered & why this one | REQUIRED | REQUIRED (one line) |
| 3 | **Layer(s) touched** | compile / spool / govern / receipts / cross-cutting + invariants changed | REQUIRED | skip |
| 4 | **How it works** | mechanism + load-bearing files/lines | REQUIRED (may fold into What for tiny diffs) | skip |
| 5 | **Verification & evidence** | what ran + a link/paste to the proving artifact | REQUIRED | only if a render/build step exists |
| 6 | **Risk assessment** | what could break / compat / audience / contract | REQUIRED | skip |
| 7 | **Operational impact** | env vars / migrations / deps / cost / secrets / deploy order | REQUIRED ("None" allowed *after* walking the list) | skip |
| 8 | **Follow-up & deferred** | deferred work, limitations, debt, future PRs — with beads | REQUIRED ("None" allowed) | skip |
| 9 | **Governance links** | design docs, AT-DECR/ADRs, issues, prior PRs, specs, beads | REQUIRED when any exist | optional |
| 10 | **Refs / Closes / Beads** | issue linkage + beads covered | REQUIRED | REQUIRED |

### 4.3 What each heading must contain

**Why & decision rationale.** The biggest gap in most PR notes is decision rationale: what/why/verification/rollback without *alternatives considered*. Two to four lines: the chosen approach, the one or two *real* alternatives, and why they lost. This is what makes future maintenance cheap — the next engineer learns the road not taken without re-walking it. If no credible alternative existed, say so explicitly ("no real alternative — X is forced by Y").

**Layer(s) touched.** Since the architecture is **compile → spool → govern → receipts**, declare which layer(s) the PR modifies: compile (above the spool) / spool boundary / govern / store / receipts-audit / API-auth / plugin surface / cross-cutting / docs-only. Then state whether any **cross-layer invariant** changed — by name:

| Invariant | Meaning |
|---|---|
| **Content-stable UUID-v5 at the spool** | same content → same id; re-runs are idempotent |
| **No model below the spool** | INTKB's govern pipeline is deterministic — no LLM call in dedupe/policy/promotion/audit |
| **Append-only hash-chained receipts** | audit events are never edited or deleted; each carries `prev_hash` |
| **Tenant isolation** | no cross-tenant read/write through any govern or API path |
| **Insert-only `candidates`** | source-of-truth table; rows are never updated or deleted (005-AT-ARCH) |

The default, common answer is **"no cross-layer invariant changed"** — but you must say it. If one *did* change, the PR needs a linked decision record (AT-DECR) authorizing it; an invariant change without one is an automatic review block.

**Verification & evidence.** "Verified" is a claim, not evidence. Accepted evidence types — check what applies and **link or paste the artifact that proves it**:

- [ ] **Unit/integration test run** — counts + suite ("32/32 registry, 288/288 api")
- [ ] **CI run** — the URL of the green run
- [ ] **Manual validation** — what you drove and what you observed (exact steps, not "it works")
- [ ] **Reproduction steps** (bug fixes) — broken-before steps → fixed-after observation
- [ ] **Performance / benchmark results** — before/after numbers
- [ ] **Evaluation report** — for retrieval/quality changes (Recall@10, nDCG@10, or a link)
- [ ] **Screenshot(s)** — when the change is visible
- [ ] **Signed receipt / `audit verify` output** — for audit-chain or governance changes

Every claim in the PR points at one of these. A PR that says "faster" without a benchmark, or "fixed" without a repro, isn't done.

**Risk assessment.** Every full-lane PR answers four questions:

| Question | Typical answers |
|---|---|
| What could this break? | name the blast radius, or "nothing beyond the touched module — because X" |
| Is it backward compatible? | yes/no + what old inputs/state still work |
| User-facing or internal? | which users/surfaces see it, or "internal only" |
| Does it change a public API or contract? | endpoint/schema/tool-surface changes, or "no" |

**Operational impact** (the classically overlooked one). Walk the list; "None" is a valid answer only after checking each item:

- New environment variables?
- Schema migrations?
- New dependencies?
- Cost implications?
- New permissions or secrets?
- Deployment order — code-first vs data-first, paired live steps, restart required?

**Follow-up & deferred.** What is *intentionally* not in this PR: deferred work, known limitations, tech debt introduced, planned future PRs. **Each item gets a bead, filed before merge** — a deferred item without a bead is lost work, not deferred work.

**Governance links.** Link whatever governs or contextualizes the change: design docs, AT-DECR/ADRs, GitHub issues, prior PRs, specs, beads. This is how an outsider reconstructs the decision chain.

**Refs / Closes / Beads.** `Refs OWNER/REPO#N` while sibling work remains, `Closes …#N` only on the PR that retires the last piece; list the **Beads:** covered.

### 4.4 Copy-paste PR body template

Drop this into each repo as **`.github/pull_request_template.md`** so GitHub pre-fills every PR. For a lightweight-lane PR (§4.1), delete everything except **What / Why / Refs**.

```markdown
## What
<!-- One paragraph: the change in plain terms. -->

## Why & decision rationale
<!-- The problem. Then alternatives considered and why this approach won:
     "chose X over Y because Z." If no credible alternative existed, say so. -->

## Layer(s) touched
<!-- compile (above the spool) / spool boundary / govern / store /
     receipts-audit / API-auth / plugin surface / cross-cutting / docs-only.
     Cross-layer invariants changed? Default: "none changed" — say it.
     If one changed, name it (content-stable UUID-v5 at the spool ·
     no model below the spool · append-only hash-chained receipts ·
     tenant isolation · insert-only candidates) and link the AT-DECR. -->

## How it works
<!-- Mechanism + the load-bearing files/lines. -->

## Verification & evidence
<!-- Check what applies; LINK or PASTE the proving artifact for each. -->
- [ ] Unit/integration tests: <counts + suite>
- [ ] CI run: <URL>
- [ ] Manual validation: <steps driven + what you observed>
- [ ] Bug repro: <broken-before → fixed-after>
- [ ] Benchmark: <before/after numbers>
- [ ] Eval report: <numbers or link>
- [ ] Screenshot(s): <attach>
- [ ] Signed receipt / audit-verify output: <paste>

## Risk assessment
<!-- What could this break? Backward compatible? User-facing or internal?
     Public API / contract change? -->

## Operational impact
<!-- Walk the list; "None" only after checking each: env vars ·
     schema migrations · new dependencies · cost · permissions/secrets ·
     deployment order / paired live steps. -->

## Follow-up & deferred
<!-- Intentionally deferred, known limitations, tech debt introduced,
     planned future PRs — each with its bead. "None" if truly none. -->

## Governance links
<!-- Design docs, AT-DECR/ADRs, GitHub issues, prior PRs, specs, beads. -->

## Refs
<!-- Refs OWNER/REPO#N while siblings remain; Closes …#N on the last piece.
     Beads: <bead(s) covered>. -->
```

### 4.5 Worked example (real — E1, PR #227, written to the v1.1 structure)

> **What** — `InMemoryTokenRegistry` now accepts an already-salted `scrypt$salt$hash` and uses it verbatim, so `~/.teamkb/tokens.json` stores hashes, not plaintext bearer secrets.
>
> **Why & decision rationale** — the registry hashed *in memory* but unconditionally re-hashed whatever sat on disk, forcing plaintext at rest — every backup of `~/.teamkb` (borg / daily archive / R2) carried live tokens. **Alternative considered: SOPS-encrypt `tokens.json`** with the host age key. Rejected: encryption keeps the plaintext *recoverable* (any holder of the host key — and every backup — can decrypt it), and the API would need the private key at runtime, which moves the secret rather than removing it. Hashing makes the at-rest form non-recoverable and reuses the registry's existing scrypt verify path — smaller diff, stronger property.
>
> **Layer(s) touched** — below the spool: govern-adjacent API auth (`qmd-team-intent-kb/apps/api`, token registry). **No cross-layer invariant changed** — no touch to spool UUIDs, receipts, `candidates`, or promotion; tenant + expiry fields preserved (covered by a test).
>
> **How it works** — the constructor runs `parseStoredHash` on each record's `token`; a well-formed `scrypt$salt$hash` is used verbatim; anything else — including a plaintext that merely *looks* like `scrypt$...` with non-hex segments — fails the parse and is safely hashed as plaintext, as before.
>
> **Verification & evidence** — +4 registry tests (pre-hashed resolves its plaintext + rejects both a wrong token and the-hash-itself-as-token; mixed pre-hashed+plaintext; tenant/expiry preserved; scrypt-lookalike fail-safe). 32/32 registry, 288/288 api, typecheck clean — green CI on the PR; merged to main as `a2143be`. Post-deploy manual validation: existing token → 200, bogus token → 401, anonymous health probe → 200.
>
> **Risk assessment** — backward compatible: plaintext records still load and are hashed in memory exactly as before. Internal-only: tailnet-bound API auth, no user-facing behavior, no public API/contract change. Rollback caveat: **after the live reseed, a plain code revert locks everyone out** — the old code re-hashes the stored hashes, so every token fails verification. Rollback = revert the code **and** re-seed `tokens.json` in the same step.
>
> **Operational impact** — no new env vars, no schema migration, no new dependencies, no cost change, no new permissions. One paired live step, code-first order: deploy, then re-seed `tokens.json` to 6 hashed records and restart the service.
>
> **Follow-up & deferred** — rotate the in-place-hashed token secrets and purge the pre-E1 plaintext-bearing backups (`jfv.6.1`); token expiry + durable revoke-by-actor (`jfv.6.2`). Both filed before merge.
>
> **Governance links** — pre-kickoff review AAR `012-AA-AACR` (finding E1); grounded system map `005-AT-ARCH` (the backup scope that made at-rest plaintext a live leak).
>
> **Refs #226** · Beads: hash the on-disk brain API tokens (`jfv.5.1`).

Why it passes: an engineer who has never seen this repo can answer all seven Outsider Test questions (§8) from the body alone — including the two that most PRs skip: *why this approach and not SOPS* (rationale), and *the reseed-lockout trap* (risk/rollback).

---

## 5. The framework context to carry (GSB-specific)

Outsiders (and future us) need the same one-paragraph map to read any change here. Keep a version of this in the PR when the change touches the pipeline:

> **Architecture in one line:** ICO **compiles** (probabilistic, model-driven) → emits a **spool** (the trust boundary; content-stable UUID-v5 + manifest SHA-256) → INTKB **governs** it with a deterministic 8-rule policy pipeline (dedupe / policy / secret-scan / promotion — *no model call below the spool*) → every promotion writes a SHA-256 **hash-chained receipt**. **The model proposes; deterministic code owns durable state, policy, promotion, and all audit writes.**

Practical consequences for notes:
- A change **above the spool** (compile) is probabilistic — say what the model now proposes and how the deterministic layer still gates it.
- A change **below the spool** (govern/store/audit) is durable-state — say which invariant it preserves (the named table in §4.3) and how you verified it.
- **Forbidden overclaims** in notes and code: *tamper-proof, immutable, non-repudiation (for local mode), blockchain.* Local mode is integrity + ordering + rewrite-**detection** only. Say "tamper-evident," never "tamper-proof."
- If you touch `candidates`, remember it's **insert-only, source-of-truth** (005-AT-ARCH) — a note that proposes deleting from it must justify against that classification.

---

## 6. The gate: CI checks + the review bot (current reality)

**Deterministic gate = the required CI checks.** Per repo today:
- **ICO / INTKB**: full CI — `lint`, `typecheck`, `test` + coverage (INTKB), `mutation` + CodeQL (ICO), plus `security`/`docs-quality`/`gitleaks`/`semgrep`. Strong.
- **plugin**: `build` + `typecheck` + `smoke` only — **no unit-test / lint job yet** (a gap; see §7).
- **umbrella**: docs-honesty + changelog aggregation (docs repo).

**AI reviewer = Gemini Code Assist and/or Greptile — either is acceptable** (Gemini is actively used; Greptile is the org standard where its quota is available). Read whichever bot reviews the PR and address or resolve its comments. The review is advisory; the *deterministic* gate is the required CI checks. Keep the in-repo `.gemini` config — Gemini stays.

**⚠️ Honest gap:** **branch protection is currently OFF on all four repos** — so "wait for the gate before merging" is a *discipline this standard enforces*, not something GitHub blocks. Until protection is enabled, the human/agent merging is the gate. Tracked in §7.

---

## 7. Known gaps in the gate (tracked)

1. **No branch protection** on any GSB repo → required checks aren't enforced at merge. Enable required-status-checks (+ up-to-date branch) on `main` for ICO/INTKB/plugin.
2. **Plugin CI is thin** — add a `test` + `lint` job so the repo that receives the review's riskiest changes (R4/R8/R9/B1) is actually gated.
3. **Confirm a reviewer is active** — an AI reviewer (Gemini Code Assist and/or Greptile) actually reviews PRs on all three code repos (confirm by the bot login on the first PR). Gemini stays — no config removal needed.

All three are tracked as *"Firm up the CI review-gate"* (`jfv.6.17`) under the remediation epic `compile-then-govern-jfv.6` (see AAR `012-AA-AACR`).

---

## 8. The Outsider Test (the pre-merge gate)

Before merging, answer these seven questions **using only the PR description** (not the diff, not your memory of the work):

1. **What changed?**
2. **Why was it necessary?**
3. **Which architectural component changed?**
4. **How was it verified?**
5. **How do I roll it back?**
6. **What are the risks?**
7. **What remains unfinished?**

**The rule: if an engineer unfamiliar with the project can't answer all seven after reading the PR, the PR isn't ready** — the code might be, but the record isn't, and here the record is part of the product.

Supplementary style gate: no forbidden overclaims (§5), no bare `fix`/`update` subjects.
