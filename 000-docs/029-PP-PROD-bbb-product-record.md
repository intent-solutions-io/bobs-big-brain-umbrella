---
blueprint:
  documentId: DOC-BBB-WEBSITE.PRODUCT-RECORD
  documentType: product-record
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  generatedAt: '2026-10-25'
  updatedAt: '2026-10-26'
  sourceRefs:
    - plugin@a1b74ca (jeremylongshore/bobs-big-brain-plugin origin/main)
    - registrar@2599598 (jeremylongshore/bobs-big-brain-registrar origin/main)
    - compiler@b7ad84b (jeremylongshore/bobs-big-brain-compiler origin/main)
    - umbrella@ffd2711 (intent-solutions-io/bobs-big-brain-umbrella origin/main)
    - intent-os 000-docs/244-AA-AUDR-consistency-2026-10-25T191052Z-c0f76ce56e6750b1.md
    - clean-room local install, 2026-10-25 (bead compile-then-govern-eqw)
  relatedArtifacts: [030, 031, 032, 033, 034, 035]
  humanReview: {required: true, status: not-started}
---

# Product

<!-- impeccable:product-schema 1 -->

This file is the proposed canonical product record for Bob's Big Brain (draft; owner review pending).
Design tooling (Impeccable) reads a `PRODUCT.md` copied by hand from it into the landing worktree,
untracked, so the only committed copy is this one. Every capability below was checked against code on 2026-10-25; the
evidence state follows each claim in brackets (`verified` = read in code or proven in the
clean-room run; `provided` = owner statement; `unknown` = not yet established). Edit this
file, never the copy.

## Source update, 2026-10-26

The clean-room results below remain a dated observation of plugin `a1b74ca`;
they are not a test of every later release or deployed installation. Current
source was checked separately at plugin `09b6644`, Registrar `3dede3c` and
Compiler `9dc7488`. Matching `1.2.0` manifest labels do not prove identical bundles.

| Original finding | Later merged source evidence | Remaining boundary |
|---|---|---|
| LIM-01: only two local policy rules enabled | Plugin #90 seeds the canonical ten enabled rules for a fresh tenant. | Existing policies are not rewritten; enabled does not mean every rule decides every capture; best-effort seed failure is not fail-closed bootstrap. |
| LIM-02: rejected inbox rows lack a receipt | Plugin #88 settles rejected candidates with canonical per-candidate rejection evidence; the real mixed-sweep tests retain content and verify receipts. | Review-only flags can remain in the inbox without a new receipt; a skipped or failed settlement is not a completed rejection. |
| LIM-03: capture silently lost at intake | Plugin #89 returns disclosure feedback before writing an MCP capture. Plugin #95 reports safe refusal counts for raw spool intake. | Pre-intake refusals do not create candidate/memory/audit rows. Raw source/archive bytes can retain refused content. Regex filtering is not exhaustive disclosure prevention. |

These source fixes do not establish that an older installed package contains them.
Keep LIM-01–03 as dated installation findings with this source update beside them;
do not present them as unqualified current-source behavior. Release/channel
alignment remains open under `compile-then-govern-eqw.5`. Recheck a chosen artifact
before claiming its behavior. Searches remain unreceipted, team audit verification
is not exposed through the plugin, and current-answer ranking remains measured
separately. Review-only decisions and pre-intake refusals must not inherit a
per-decision receipt guarantee.

## Platform

web

(The platform of the surface this record designs, the website. The product itself is a Claude Code and
Cowork MCP plugin.)

## Users

- **Primary: Claude Code builders** [provided, owner 2026-10-25]. Individual developers and
  operators who already work in Claude Code or Cowork and want their agent to answer from what
  they decided, with a citation they can open, instead of re-deriving or guessing. They install
  tools themselves and read the code before they trust it.
- **Secondary: team leads** [provided]. People who want one governed brain their whole team
  reaches, set up with help from Intent Solutions.

## Product Purpose

A governed knowledge brain for Claude. You capture facts, decisions and lessons; deterministic code
decides what becomes durable memory; Claude answers from that memory with a `qmd://` citation to
the exact entry; and durable governance settlements leave SHA-256 hash-chained receipts you can
verify. Success for a builder [goal, not a measured result]: they install it, save something, get it back cited,
and can check the receipt trail against retained anchors. A writer able to rewrite all local witnesses can evade those checks; a local git commit does not prove an independent remote witness.

## Positioning

Most AI memory competes on recall. Bob's Big Brain competes on **govern and receipts**: the model
proposes, deterministic code owns what is saved, and the trail is tamper-evident. It is honest
about the limit: tamper-evident, not tamper-proof [verified: `plugin/README.md:63-69`].

## Operating Context

- Runs inside Claude Code and Cowork as an MCP plugin; Claude Desktop through a manual MCP entry
  [verified in source]. The original clean-room proof covers its tested Linux environment; local native dependencies and owned-runtime platform/ABI requirements need separate checks on other hosts.
- Two commands front it: `/brain` (cited answers, read-only) and `/brain-save` (governed capture,
  runs only when the user types it) [verified: `plugin/skills/brain/SKILL.md`,
  `plugin/skills/brain-save/SKILL.md:8`].
- Install from the plugin's own GitHub marketplace: `jeremylongshore/bobs-big-brain-plugin`,
  plugin `governed-second-brain@governed-second-brain` [verified: `plugin/.claude-plugin/marketplace.json:2,13`].

## Capabilities and Constraints

**Local mode (default)** [verified, clean-room 2026-10-25 at plugin a1b74ca]
- In-process stdio MCP server; data under `~/.teamkb`; no daemon. The plugin's govern never invokes the
  compiler; compiling files is a separate, optional step (CLM-11).
- First start provisions three lockfile-pinned native modules once with npm (24 s in the clean
  room); basic local governance needs no remote service; configured semantic retrieval can call a separately provisioned embedder [verified:
  `plugin/plugin-runtime/bootstrap.cjs:87-108`].
- Six tools: `brain_search`, `brain_status`, `brain_audit_verify`, `brain_capture`,
  `brain_govern`, `brain_transition` [verified: clean-room `tools/list`].
- Governed write path: capture to a spool, then govern runs dedupe → policy → promotion; each
  promotion and supersession writes a hash-chained audit event; the ordinary path attempts a local anchor commit and, with origin configured, a bounded background push; neither proves an independent witness [verified: clean-room `brain_audit_verify` ok, 6 events, 2 anchors].
- Subject-keyed supersession: a decision on the same subject retires a stale reference, and search
  returns only the current entry [verified: clean-room run].
- Retrieval: keyword arms (qmd BM25 when installed, native SQLite FTS5 always) fused by
  reciprocal-rank fusion (k=60), then a bounded freshness and category rerank; an optional local
  semantic arm (EmbeddingGemma-300M via sqlite-vec) runs only when a loopback embedder is present,
  otherwise search stays keyword-based. No generative model runs at query time [verified:
  `registrar/packages/qmd-adapter/src/search/rrf-fusion.ts:11`, `config.ts:115-121`; plugin ships
  no embedder]. Search works without qmd installed; the index refresh warns [verified: clean room].
- Requirements are artifact- and mode-specific. The older legacy setup documented Node 20+
  and npm; the dated run is not proof for every such host. Current owned-runtime execution
  and reviewed local recovery require Linux Node22 with matching ABI. qmd enables its BM25
  arm; git enables local anchor commits. Provisioning and other-platform acceptance remain
  separate evidence.

**Team mode** [verified in code; not exercised in the clean room]
- One governed brain on a server; teammates reach it over a private network with a per-user
  bearer token (stored server-side as salted scrypt hashes) [verified:
  `registrar/apps/api/src/auth/token-registry.ts:96-115`].
- The plugin becomes a thin proxy and does not expose `brain_govern`; governance runs on the server,
  members read and propose, admins approve [verified: `plugin/src/remote-server.ts`].
- `brain_audit_verify` is local-only; team users cannot verify from the plugin [verified].

**Dated installation limits** [observed 2026-10-25 at a1b74ca; read the later-source update above]
- Fresh local installs seed a policy that leaves 8 of 10 governance rules dormant; only the
  secret and length checks gated that tested brain (eqw.1; source correction above).
- Rejected candidates stay in the inbox and lack a per-candidate receipt (eqw.2).
- A capture containing a secret is acknowledged, then dropped at ingest without a receipt or
  feedback in that tested build (eqw.3). Detected refused content did not become memory in that run.
- Receipts cover governance decisions; searches are not hash-chained.
- On a large brain, current truth does not always outrank older reference material (umbrella epic
  compile-then-govern-39z).
- Distribution channels carry different builds labelled 1.2.0; the original audit counted 33 commits past tag v1.2.0 at its recorded revision (eqw.5).

**Terminology**: "Bob's Big Brain" is the product; `governed-second-brain` is the plugin and
marketplace id; `governed-brain` is the MCP server; "receipt" means a hash-chained governance
audit event; "anchor" means a committed chain-head snapshot.

## Brand Commitments

- Presented on intentsolutions.io under the master brand contract (`intent-solutions-landing`
  `000-docs/084-AT-DSGN-brand-family-contract.md`): Syne display, Inter body, charcoal surfaces,
  orange signal, owned arrow mark [provided].
- Voice: polished casual, direct, mechanism-first; company "we" [provided, owner 2026-10-25].
- Tagged **beta, under development** everywhere it is presented [provided, owner 2026-10-25].
- Honesty words: say tamper-evident; never claim tamper-proof, immutable, blockchain or local non-repudiation.
  Qualify "append-only" (by protocol, hash-chained) [verified: umbrella `scripts/lint-forbidden-words.sh`].

## Evidence on Hand

- A real cited answer from the owner's live brain (query "compile then govern receipts", top hit
  `qmd://kb-curated/e1d5424d-…`, captured 2026-10-25) [verified].
- Clean-room transcript: first start, capture, govern, supersession, search, audit verify
  (bead compile-then-govern-eqw) [verified].
- Live brain health 2026-10-25: 18,206 memories, `brain_audit_verify` over 33,887 events with 0
  tamper signatures, consistent with 847 anchors [verified, owner's brain; internal evidence only,
  never shown on the site as a product or usage metric].
- Public source: four Apache-2.0 repositories; qmd (MIT) upstream by @tobi [verified].
- **Absent, never to be fabricated**: customers, testimonials, logos, usage counts, benchmark
  wins, performance figures, pricing.

## Product Principles

1. The model proposes; deterministic code owns durable state.
2. Show the receipt, and say exactly what it does not prove.
3. Claim only what the code and a clean-room run prove; name every known limit.
4. Local first: a builder gets the whole loop on their own machine before any team setup.
5. Current truth over volume: retiring stale knowledge is a feature, with its own receipt.

## Accessibility & Inclusion

WCAG 2.2 AA for every public surface [provided by the Intent Blueprint quality contract].
