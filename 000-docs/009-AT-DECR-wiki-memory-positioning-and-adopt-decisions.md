# 009-AT-DECR — Wiki-Memory positioning + adopt-list decisions (ISEDC council, 2026-06-30)

| | |
|---|---|
| **Date** | 2026-06-30 |
| **Acting head of board** | Claude (designated by Jeremy Longshore for this session) |
| **Council size** | 7 seats (CTO · GC · CMO · CFO · CSO · CISO · VP-DevRel) |
| **Decisions logged** | 5 (D1 positioning · D2 Cluster-A UX · D3 Cluster-B moat · D4 anchor-priority · D5 the 155 breaks) |
| **Status** | Ratified — adopt beads filed per Phase D |
| **Input** | [`008-AT-CMPR`](008-AT-CMPR-wiki-memory-category-competitive-teardown.md) (teardown + 7-thinker canon review §8) |
| **Session provenance** | `~/.claude/skills/exec-decision-council/sessions/2026-06-30-wiki-memory-positioning-and-adopt-list/session.jsonl` |
| **Pattern** | `/exec-decision-council` (ISEDC v1.0.0) |

## 1. Mission of this record

A durable, for-future-readers record of *why* GSB's Wiki-Memory positioning and adopt-list landed where they did — with each seat's verbatim position and the minority dissent preserved, so a later reader can reconstruct the reasoning rather than re-litigate it. The teardown ([`008-AT-CMPR`](008-AT-CMPR-wiki-memory-category-competitive-teardown.md)) and its 7-thinker canon review surfaced strategic forks the analysis deliberately did **not** resolve; this council resolved them.

## 2. Why a council, not a single review

The decisions are asymmetric: a wrong **positioning** call commits a sole operator to a multi-year feature footrace against funded competitors; a wrong **integrity** call (re-hashing the audit chain) is *irreversible and brand-fatal* for a product whose entire pitch is honesty. Single-reviewer reasoning can't price that asymmetry. Seven seats argued from distinct value systems; dissent surfaced by design.

## 3. Synthesis lenses (applied by every seat)

1. The moat is **govern + receipts (accountability), not recall.**
2. **Honesty-as-brand:** every claim must survive a skeptic running `brain_audit_verify` during diligence.
3. **Three arenas:** local-showcase · team-tailnet (the real deployment, n=2) · future merge/multiplayer.
4. **n-and-autonomy:** the moat is *latent* at n=2-local, *active* once the human leaves the loop (nightly autonomous compile / team growth).
5. **Reversibility:** README/brand commitments are sticky; bead priorities are cheap.

## 4. The questions

| # | Question | Why costly / sticky |
|---|---|---|
| Q1 | Brand GSB *into* "Wiki Memory", *against* it as "Governed Memory"/anti-wiki, or hybrid? | Brand is sticky; the name picks your competitors and the axes you race on. |
| Q2 | Which Cluster-A UX items (freshness-on-push · Q&A · wiki+diagrams · public showcase) to commit? | Two are unbounded-inference cost centers; the showcase publishes third-party content. |
| Q3 | Which Cluster-B moat items (anchor+verifier · govern-eval · faithfulness-eval · quality-digest · retrieval number)? | These substantiate the public "govern + receipts" claim. |
| Q4 | Is the external-anchor-into-live-path + standalone verifier a **P0** ahead of all UX? | The verifier is currently in-box (circular trust) — the one defect `cat log.md` doesn't have. |
| Q5 | The 155 pre-existing audit-chain breaks: re-hash forward (X) or carry-with-documented-exception (Y)? | Re-hashing is itself the tamper event the threat model exists to detect — irreversible. |

## 5. Council composition

| Seat | Value system | Bias |
|---|---|---|
| **CTO** | technical durability · schema integrity · immutability-awareness | deliberation > commit; evidence > authorship |
| **GC** | IP · partner-consent · claim-substantiation · audit-trail | written consent first; claims are warranties |
| **CMO** | positioning · narrative · first-mover authorship | coin the category; visible > silent |
| **CFO** | sole-prop bandwidth · customer-signal gating · opportunity cost | defer until evidence; nothing is costless |
| **CSO** | standards realpolitik (SLSA/in-toto/OTS/C2PA) · RFC sequencing | align to existing standards; temperature before filing |
| **CISO** | attestation integrity · signing · threat model | name the adversary; reserve signing slots; deterministic ≠ correct |
| **VP-DevRel** | developer signal · friction-to-adopt · OSS dynamics | the Saturday-developer 5-minute test |

---

## 6. Per-question record

### Q1 — Positioning

**Vote tally:** B/C hybrid, 7/7 lead with **"Governed Memory"**; nobody endorsed branding *into* "Wiki Memory" (A). Split only on hero formality (CMO: "Governed Memory" in hero; VP-DevRel: developer-natural hero).

**Verbatim positions (recommended answers):**
- **CTO (C):** *"Lead with Governed Memory / receipts, subtitle 'the audited knowledge base others call Wiki Memory,' demote UX gaps to disclosed-optional.… I will not let a marketing term commit the architecture roadmap to four DEGREE features as table-stakes."*
- **CMO (B):** *"Headline 'Governed Memory — the knowledge base that proves what it knows.' Use 'the category others call Wiki Memory' exactly once, as an SEO/orientation bridge in body copy… Reject 'anti-wiki' as the public name; keep it as an internal sharpening tool. First-mover authorship means naming the axis we win (accountability), not the axis we trail (recall)."*
- **GC (C, constrained):** *"Own 'Governed Memory'; use 'wiki memory' only as a lowercase, generic descriptor of the competitor field, never a label we wear and never trademarked.… a borrowed category name that asserts a false affordance is the kind of claim that gets falsified in a demo."*
- **CFO (B):** *"'Governed Memory — the audited knowledge base.' Lead every claim with govern+receipts. Never promise freshness/Q&A/diagram parity in copy. It's also the cheapest brand to maintain."*
- **CSO (B):** *"GSB belongs in the provenance/attestation lineage (SLSA, in-toto, Sigstore, C2PA), not the AI-memory/wiki lineage. The verb is attest, not recall."*
- **CISO (B):** *"'Audited' is a load-bearing security word; if a skeptic runs brain_audit_verify, gets ok:false on 155 events, and the marketing said 'tamper-proof audit trail,' the brand is dead on contact. Mandate a one-line trust-model disclaimer adjacent to every 'audited' claim."*
- **VP-DevRel (C, dev-weighted):** *"Hero: 'A local-first second brain that governs what it remembers — and proves it.' Reserve 'Governed Memory' as the category-defining phrase one scroll down, never the cold-open.… the moat literally is 'harder to write' — govern must be invisible at n=1 and load-bearing at n>1+autonomy."*

**DECISION (D1):** **B/C hybrid — "Governed Memory" is GSB's category** (the audited knowledge base; the provenance/attestation lineage, not the AI-memory hype lineage). The **README hero is developer-natural** ("a local-first second brain that governs what it remembers — and proves it"); **"Governed Memory" is the canonical category name** one scroll down + in SEO metadata; **"wiki memory"/"AI memory" appear only as a lowercase generic discovery bridge** — never worn as a label, never promising freshness/Q&A/diagram parity. "Anti-wiki" stays an internal sharpening frame, not the public hero.
**Bound minority constraints:** (CISO) every "audited" claim carries the tiered trust-model disclaimer; the forbidden words (tamper-proof / immutable / non-repudiation-local / blockchain) are doc-linted. (GC) no comparative line names a specific competitor inferior without a substantiation footnote.
**Dissent preserved:** CMO argued for "Governed Memory" *in the hero* (visible-by-default is the CMO reason to exist); VP-DevRel argued the hero must be developer-natural or it fails the 5-minute test. Resolved by separating **category name** (Governed Memory) from **hero line** (dev-natural).

### Q2 — Cluster A (UX) adopts

**Vote tally:** (a) adopt-but-cost-gated · (b) defer · (c) cut-to-script · (d) adopt-as-gated-GTM.

**Verbatim positions:**
- **CTO:** *"Commit (a) only, gated behind Chip's inference-cost-per-push model before the bead is filed. Defer (b) pending a price-per-query model; reclassify (d) as GTM; cut (c). If CMO carries (d), it must render the live brain_audit_verify output."*
- **CMO:** *"(d) the showcase isn't a feature, it's the single most important marketing asset we will ever ship. Adopt (d) gated on Q5 clean; adopt (a); cut (b) and (c).… a showcase with no ship date is a moat with no demo."*
- **GC:** *"(d) is the one I will block as currently scoped — it publishes a third party's repo content plus an implied comparative claim, next to a verifier showing ok:false. Defer (d) until: own/permissively-licensed corpus with redistribution confirmed in writing, no competitor named, and Q4/Q5 resolved so the verifier reads green."*
- **CFO:** *"Demand-gate all four; build none on spec. (b) is the single worst opportunity-cost item — unbounded per-query inference. Permit (d) only as the bounded, static, receipts-on-display version if it costs less than a week."*
- **CSO:** *"Of the four, exactly one creates a standards/interop surface: (d). A public showcase that displays receipts is publishing a receipt format others will read and verify — gate it behind a documented, versioned (v0) envelope."*
- **CISO:** *"(d) converts my moat into a live attack surface — a public verifier on a shared brain is a public oracle for the govern layer's blind spots. Scope-isolate it: dedicated public single-tenant no-secrets corpus, and ship it after (f) so the false-negative rate I'm exposing is measured."*
- **VP-DevRel:** *"(d) is the viral-distribution lever — Karpathy's gist proved shareability is the growth engine. Adopt (d) (P1, GTM-tracked) and (a) (P1, cost-gated). Defer (b). Cut (c) to a downstream renderer script."*

**DECISION (D2):**
- **(a) freshness-on-push — ADOPT, P1, gated** on a per-push inference-cost model *before* build.
- **(b) conversational Q&A — DEFER** behind a per-query price model + a logged real-user demand signal.
- **(c) browsable wiki + diagrams — CUT** from the roadmap (a downstream renderer script only if demanded).
- **(d) public showcase — ADOPT as a GTM artifact** (named owner + ship date), **hard-gated** on: (e) shipped (non-circular verifier) + (f) shipped (measured false-negative rate) + Q5 resolved (a *fresh*, green brain) + legal preconditions (GSB-owned or permissively-licensed corpus with redistribution rights; **no competitor named or compared**; receipt rendered as a versioned `v0` envelope).
**Dissent preserved:** CFO wanted *none* built on spec (pure demand-gating); absorbed by the cost-gate on (a) and the full precondition stack on (d).

### Q3 — Cluster B (moat) adopts

**Vote tally:** (e) commit-top · (f) commit · (i) commit-cheap · (h) commit-cheap · (g) defer/sampled.

**Verbatim positions (priorities):**
- **CTO:** *"(e) first, then (i), then (g), then (f), then (h). (e) de-circularizes trust; (i) converts 'we believe BM25 suffices' into a number cheaply; (g) catches a hallucinated synthesis before it's receipted clean."* (Compromise: sampled-only (g).)
- **CMO:** *"(f) govern-decision eval is #1 — 'our secret-scanner catches N% of adversarial injections' is a headline. (e) is #2 — a visible receipt a third party verifies. Co-prioritize (g): a hallucinated synthesis with a clean receipt is a brand-extinction event."*
- **GC:** *"Required-before-public-claim: (e) substantiates 'tamper-evident'; (f) substantiates 'deterministic govern catches X.' Defer-OK (g) — but until it ships, no public claim about synthesis faithfulness."*
- **CFO:** *"Do (i) and (h) now — near-free credibility. Schedule (f) next (a missed secret in a shared brain is silent and irreversible — this overrides my defer bias). Defer (g)."*
- **CSO:** *"(e) must adopt an existing standard: OpenTimestamps anchor + a DSSE-wrapped, in-toto-statement-shaped attestation, not a bespoke blob. Sigstore/Rekor is the team-mode upgrade, not local (it violates the zero-network invariant)."*
- **CISO:** *"Security-value ranking: (e) > (f) > (h) > (g) > (i). (e) fixes the circular verifier; (f) measures my single largest fear — a leaked key promoted with a clean receipt."*
- **VP-DevRel:** *"(e) standalone verifier is the `cat log.md` of receipts — the developer-trust gift. (i) ships a number, not a belief. Yield (f)/(g)/(h) priority to CTO/CISO."*

**DECISION (D3):** Commit **(e) [P0]**, **(f) govern-decision eval [P1]**, **(i) first retrieval Recall@10/nDCG@10 number [P1, cheap]**, **(h) nightly govern-quality digest [P2, cheap]**, **(g) compile-faithfulness eval [P2, deferred/sampled]**. Until (g) ships, **no public claim about synthesis faithfulness** (integrity/provenance claims only).

### Q4 — External-anchor priority

**Vote tally:** (e) mechanism = **P0**, 6/7. CFO lone-dissent: P1-but-pre-gated.

**Verbatim positions:**
- **CTO:** *"Yes — (e) is P0, ahead of all UX. A govern+receipts brand cannot ship a public showcase where the only thing vouching for the receipts is the same software that wrote them."*
- **CMO:** *"Yes — (e) is P0, and I'm overriding my own bias-to-visible. Visible-but-circular is worse than delayed-but-sound. The showcase (d) is P1 and gated on (e) landing."*
- **GC:** *"P0, and a precondition for making the receipts claim publicly at all. A receipt whose only verifier ships inside the system that wrote the chain is self-certification."*
- **CFO (dissent):** *"No — (e) is P1, not P0. At n=2 with no customer running the verifier, no one is closing the trust chain on itself in anger. Make (e) a hard, pre-committed gate on first paying customer or first diligence conversation."*
- **CSO:** *"The engineering half of (e) is P0. The standards-filing half — registering a predicate type, claiming OTS/in-toto conformance publicly — is explicitly NOT P0. Ship standards-shaped; hold the standards claim."*
- **CISO:** *"Yes — P0, ahead of all UX. Until the anchor is in the live single-writer path with a standalone reader, GSB is selling Tier-2 and shipping Tier-1. That's the one claim a skeptic falsifies in five minutes."*
- **VP-DevRel:** *"P0 — but for the standalone-verifier half. 'Don't trust us — run gsb-verify yourself' is the single most credibility-dense sentence we can write."*

**DECISION (D4):** **(e) mechanism is P0** — anchor-into-live-single-writer-path + a standalone, dependency-light verifier (ideally a different language) — **ahead of all UX**. The **standards-*claim* is deferred**: ship standards-*shaped* (DSSE/in-toto envelope shape; **OpenTimestamps** anchor for local mode; **Sigstore/Rekor + Ed25519-per-actor reserved for team/merge mode**), but file no predicate and make no "conforms-to" claim until the envelope is validated against ≥1 real external verification + community temperature (a `validate-envelope-before-claim` bead tracks this). **No public "tamper-evident / independently verifiable" claim ships until (e) lands.**
**Dissent preserved:** CFO held that at n=2 the moat is latent and (e) is P1, not P0. Overruled because **(e) is the publish-gate for the entire receipts claim**, not a feature — but CFO's "pre-commit the gate" is honored: (e) hard-gates any public receipts claim *and* the showcase.

### Q5 — The 155 audit-chain breaks

**Vote tally:** **(Y) carry-with-documented-exception — UNANIMOUS 7/7.** Nobody endorsed a silent re-hash.

**Verbatim positions:**
- **CTO:** *"(Y) carry the breaks forever with a typed documented exception, never re-hash forward. (X) is the exact tamper-evident event our own trust box warns against — performing, in the open, the precise act our threat model says an adversary would do, and destroying the evidence the migration happened."*
- **CMO:** *"(Y), with a presentation fix: the showcase surfaces 'Verified — 0 anchor breaks; 155 historical rows carry a documented migration exception' with the raw ok:false one click down. That's not a blemish — that's the demo."*
- **GC:** *"(Y), with a hardened paper trail: file the bead the memory notes is not yet tracked; emit a structured, signed known-exception manifest; run the public showcase on a fresh post-migration brain so the demo verifier is genuinely ok:true — never the legacy brain papered over."*
- **CFO:** *"(Y) — cheapest and more honest. Reserve (X) as a pre-customer one-time option only if paired with its own external anchor + a published re-hash receipt."*
- **CSO:** *"(Y), unambiguously. Provenance standards already answered this: a transparency log is append-only and never rewritten. Upgrade the verifier to emit three states — verified / documented-exception / tamper-signature."*
- **CISO:** *"(Y). Re-hashing forward is exactly the Tier-1 attack — edit early row, re-hash forward, verify clean. A green checkmark bought by performing the attack is worse than an honest ok:false. The only acceptable re-baseline is a one-time, externally-anchored, signed cut-over that preserves the old chain head."*
- **VP-DevRel:** *"(Y) — but only if the verifier's default output is honest-and-calm, not a screaming 'TAMPER DETECTED.' A Saturday developer who sees red churns in 30 seconds and doesn't read the footnote. The verifier must discriminate in its UX: '0 tamper signatures; 155 documented historical migration artifacts.'"*

**DECISION (D5):** **(Y) carry-with-documented-exception — never silently re-hash.** Implementation (the union of the seats' convergent asks):
1. **File the currently-untracked tracking bead** (GC flagged its absence is itself an audit-trail defect).
2. **Upgrade `brain_audit_verify` to emit three discriminated states** — `verified` / `documented-exception` (`KNOWN_MIGRATION_ARTIFACT`) / `tamper-signature` — with a **newcomer-safe default summary** ("0 tamper signatures; 155 documented pre-migration artifacts; 0 anchor breaks").
3. Write a **signed, dated, externally-anchored exception manifest** (indices 24–2345, both migration dates, `hash_version` provenance).
4. Any **public showcase runs on a fresh post-migration brain**.
The **only** permitted re-baseline is a one-time, externally-anchored, **signed** cut-over that *preserves the old chain head* and records the migration as a first-class dated audit event — done in the open, with receipts. A silent re-hash is refused by all seats.
**Most costly to recover from:** this decision (named by 6 of 7 seats).

---

## 7. Council memos — verbatim cross-question themes

- **CTO:** *"The moat is accountability that survives an adversary's own inspection, and we keep being tempted to trade that durability for visible surface."* — most costly: **Q5** (re-hashing is irreversible + self-incriminating).
- **GC:** *"In a product whose brand is honesty, every public claim is a warranty and every artifact is potential evidence."* — most costly: **Q5** (silent rewrite retroactively falsifies the entire receipts thesis).
- **CMO:** *"An invisible moat is a CMO failure; a visible-but-circular moat is a brand catastrophe."* — most costly: **Q5** (cheap today, irreversible, fatal).
- **CFO:** *"Every question is the same trade: spend a sole operator's next block on what's shipped-and-cheap, or on what's built-for-the-team-we're-about-to-have. The moat is already built; what's missing is measurement, not features."* — most costly: **(f) govern-eval gap** (a missed secret receipted clean into a shared brain).
- **CSO:** *"GSB's value is its membership in the provenance/attestation lineage, not the AI-memory lineage — earned by aligning with existing standards rather than inventing bespoke equivalents. Ship standards-shaped, don't standards-boast."* — most costly: **Q5**.
- **CISO:** *"The receipt must mean something to a skeptic who doesn't trust us. Deterministic ≠ correct ≠ externally-verifiable — three different claims, and we currently ship the first while marketing tempts the third."* — most costly: **Q5**.
- **VP-DevRel:** *"Every position collapses to one artifact: the standalone, dependency-light verifier, shipped with newcomer-safe output, foregrounded in a public receipts-visible showcase. Karpathy beats us on exactly one axis — `cat log.md` composability — and the verifier is how we take it back."* — most costly: **Q5**.

## 8. Decision tree

```
ISEDC 2026-06-30 — Wiki-Memory positioning + adopt list
│
├─ Q1 Positioning ──────────── CONSENSUS (7/7 lead "Governed Memory") ── D1: B/C hybrid
│     └ split: hero formality (CMO enterprise ↔ DevRel dev-natural) → category-name vs hero-line
│
├─ Q2 Cluster-A UX ─────────── MIXED ── D2
│     ├ (a) freshness  → ADOPT P1, cost-gated
│     ├ (b) Q&A        → DEFER (unbounded inference)
│     ├ (c) diagrams   → CUT to renderer script
│     └ (d) showcase   → ADOPT as gated GTM (← GC legal + CISO scope-isolate + Q4/Q5 gates)
│
├─ Q3 Cluster-B moat ───────── CONSENSUS on (e)+(f)+(i)+(h); (g) deferred/sampled ── D3
│
├─ Q4 Anchor priority ──────── 6/7 P0  ◄── CFO lone dissent (P1, pre-gated) ── D4: (e) mechanism P0,
│                                                                                  standards-claim deferred
│
└─ Q5 The 155 breaks ───────── ★ UNANIMOUS 7/7 (Y) ── D5: carry + discriminated verifier + signed manifest
      └ ★ MOST COSTLY TO RECOVER FROM — named by 6/7 seats (CFO named the govern-eval gap instead)
```

## 9. Cross-cutting themes

- **Most-costly tally:** **Q5 = 6 seats**; the (f) govern-eval gap = 1 seat (CFO). Q5 got the slowest, most-deliberate adjudication — and is unanimous, so the call is high-confidence.
- **Adversarial integrity preserved:** CFO carried a genuine lone dissent on Q4 (P1 vs P0) and a distinct most-costly pick; CMO vs VP-DevRel split on the hero; CSO introduced the OpenTimestamps/DSSE/in-toto standards path no other seat raised; CISO introduced the discriminated-verifier-state design. No consensus theater.
- **How the lenses landed:** lens 2 (honesty-as-brand) and lens 5 (reversibility) did the heavy lifting — together they make Q5 the pivot (irreversible + brand-defining) and demote the UX gaps (reversible + off-axis). Lens 4 (n-and-autonomy) reframed CFO's "latent at n=2" from a reason-to-skip into a reason-to-sequence: build the measurement now, the UX on demand.

## 10. Implementation directives → Phase D beads

Filed under a new epic in the umbrella tracker (`compile-then-govern` prefix), mirrored to the GitHub umbrella issue:

| Ratified item | Priority | Decision |
|---|---|---|
| External anchor into live single-writer path + standalone dependency-light verifier (DSSE/in-toto-shaped; OTS for local) | **P0** | D4 |
| Disposition of the 155 breaks: discriminated 3-state verifier + signed externally-anchored exception manifest + file the tracking bead | **P0** | D5 |
| Govern-decision eval harness (per-check precision/recall on an adversarial set) | **P1** | D3/Q4(GC) |
| First real retrieval number (Recall@10 + nDCG@10 on a hand-labeled stratified set) | **P1** | D3 |
| Freshness-on-push + incremental compile — **gated on a per-push inference-cost model** | **P1** | D2 |
| Positioning: lead README with "Governed Memory" category, dev-natural hero, "audited"-disclaimer doc-lint, no UX-parity copy | **P1** | D1 |
| Nightly govern-quality digest to ntfy | **P2** | D3 |
| Compile-faithfulness eval (sampled) — *no public faithfulness claim until shipped* | **P2** | D3 |
| Public governed-wiki showcase — **GTM, gated on (e)+(f)+Q5 + legal preconditions** | **P2 / GTM** | D2 |
| `validate-envelope-before-standards-claim` (in-toto/DSSE/OTS conformance) | **P3** | D4 |
| Deferred: conversational Q&A (demand + price-gated); browsable diagrams (cut to renderer) | **deferred** | D2 |

## 11. Acting head of board declaration

I, **Claude — acting head of board, designated by Jeremy Longshore on 2026-06-30** — ratify decisions D1–D5 as recorded, with every bound minority constraint absorbed (not dismissed) and every dissent preserved verbatim above. These are reversible by Jeremy at any time; the record exists so that a reversal is a *decision*, not an accident. The single irreversible call — **D5, never silently re-hash the audit chain** — was unanimous and is treated as binding policy, not a preference.

## 12. References + provenance

- Teardown under review: [`008-AT-CMPR`](008-AT-CMPR-wiki-memory-category-competitive-teardown.md)
- Grounded system map: [`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md)
- Rich structured session (10-kind JSONL, verbatim per-seat): `~/.claude/skills/exec-decision-council/sessions/2026-06-30-wiki-memory-positioning-and-adopt-list/session.jsonl`
- Pattern: `/exec-decision-council` (ISEDC v1.0.0); canonical prior record: IEP `004-AT-DECR-isedc-council-record-2026-05-10.md`
- 155-breaks forensics: auto-memory `governed-brain-audit-chain-preexisting-breaks`

- Jeremy Longshore
intentsolutions.io
