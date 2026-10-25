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
  updatedAt: '2026-10-25'
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
the exact entry; and every governance decision leaves a SHA-256 hash-chained receipt you can
verify. Success for a builder [goal, not a measured result]: they install it, save something, get it back cited,
and can detect any edit to the receipt trail (tamper-evident; an edit is caught by an anchor mismatch, and
an outside witness needs the anchor log pushed to a remote).

## Positioning

Most AI memory competes on recall. Bob's Big Brain competes on **govern and receipts**: the model
proposes, deterministic code owns what is saved, and the trail is tamper-evident. It is honest
about the limit: tamper-evident, not tamper-proof [verified: `plugin/README.md:63-69`].

## Operating Context

- Runs inside Claude Code and Cowork as an MCP plugin; Claude Desktop through a manual MCP entry
  [verified: `plugin/README.md:219-221`]. macOS, Windows, Linux.
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
  room); after that, search, capture and govern make no network calls [verified:
  `plugin/plugin-runtime/bootstrap.cjs:87-108`].
- Six tools: `brain_search`, `brain_status`, `brain_audit_verify`, `brain_capture`,
  `brain_govern`, `brain_transition` [verified: clean-room `tools/list`].
- Governed write path: capture to a spool, then govern runs dedupe → policy → promotion; each
  promotion and supersession writes a hash-chained audit event; the chain head is committed to a
  git-backed anchor log [verified: clean-room `brain_audit_verify` ok, 6 events, 2 anchors].
- Subject-keyed supersession: a decision on the same subject retires a stale reference, and search
  returns only the current entry [verified: clean-room run].
- Retrieval: keyword arms (qmd BM25 when installed, native SQLite FTS5 always) fused by
  reciprocal-rank fusion (k=60), then a bounded freshness and category rerank; an optional local
  semantic arm (EmbeddingGemma-300M via sqlite-vec) runs only when a loopback embedder is present,
  otherwise search stays keyword-based. No generative model runs at query time [verified:
  `registrar/packages/qmd-adapter/src/search/rrf-fusion.ts:11`, `config.ts:115-121`; plugin ships
  no embedder]. Search works without qmd installed; the index refresh warns [verified: clean room].
- Requirements: Node 20+ and npm on PATH; qmd 2.x for the BM25 arm (optional); git for anchor
  commits [verified: `plugin/gsb.lock.json:40`, `plugin/README.md:161`].

**Team mode** [verified in code; not exercised in the clean room]
- One governed brain on a server; teammates reach it over a private network with a per-user
  bearer token (stored server-side as salted scrypt hashes) [verified:
  `registrar/apps/api/src/auth/token-registry.ts:96-115`].
- The plugin becomes a thin proxy and does not expose `brain_govern`; governance runs on the server,
  members read and propose, admins approve [verified: `plugin/src/remote-server.ts`].
- `brain_audit_verify` is local-only; team users cannot verify from the plugin [verified].

**Known limits (must be stated, not hidden)** [verified 2026-10-25; tracked in compile-then-govern-eqw]
- Fresh local installs seed a policy that leaves 8 of 10 governance rules dormant; only the
  secret and length checks gate a new brain (eqw.1).
- Rejected candidates stay in the inbox and lack a per-candidate receipt (eqw.2).
- A capture containing a secret is acknowledged, then dropped at ingest without a receipt or
  feedback (eqw.3). The secret never becomes memory.
- Receipts cover governance decisions; searches are not hash-chained.
- On a large brain, current truth does not always outrank older reference material (umbrella epic
  compile-then-govern-39z).
- Distribution channels carry different builds labelled 1.2.0; 33 commits sit past tag v1.2.0 (eqw.5).

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
