---
blueprint:
  documentId: DOC-BBB-WEBSITE.PRD
  documentType: product-requirements
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-25'
  sourceRefs: [029-PP-PROD-bbb-product-record.md, 030-PP-PROD-bbb-website-project-brief.md, intent-os 000-docs/244-AA-AUDR-consistency-2026-10-25T191052Z-c0f76ce56e6750b1.md]
  relatedArtifacts: [029, 030, 032, 033, 034, 035]
  humanReview: {required: true, status: not-started}
---

# PRD: the Bob's Big Brain website

## Problem

The only public page for Bob's Big Brain (`demos.intentsolutions.io/bbb/`) overclaims (every
answer ships a receipt; zero ML; tenantId required), understates local requirements, exposes team
onboarding internals, and carries a stale services footer. Nothing on the company site presents the
product. [verified: consistency audit, web slice]

## Requirements

Each requirement traces to an objective in 030 and is verified by an acceptance criterion in 035.

| ID | Requirement | Objective | Priority |
|---|---|---|---|
| REQ-01 | Five routes exist under `/bbb/`: overview, how it works, receipts, install, status. | OBJ-1 | must |
| REQ-02 | Every page shows the product name beside the master mark and a visible "Beta" tag explained on the status page. | OBJ-1 | must |
| REQ-03 | The install route gives a copy-ready local-mode install prompt that matches the current marketplace manifest. | OBJ-1 | must |
| REQ-04 | A secondary path requests a team brain through `/contact/?door=outcome`; no team API address, tenant or token issuer appears anywhere. | OBJ-1 | must |
| REQ-05 | Every material claim matches the claims register below; no claim outside it ships. | OBJ-2 | must |
| REQ-06 | The status page lists what the clean-room run proved, each known limit with its tracking link, and the source commit each fact was checked at. | OBJ-2 | must |
| REQ-07 | Volatile facts (versions, commits, dates) come from one data module with a verified-at date. | OBJ-2 | must |
| REQ-08 | The receipts route states what a receipt does not prove, in the umbrella's honest tiered wording. | OBJ-2 | must |
| REQ-09 | A working in-browser receipt-chain demonstration lets the visitor edit a record, see verification fail, re-hash forward, and see an anchor catch the rewrite; it is labelled illustrative. | OBJ-1 | should |
| REQ-10 | All five routes are registered in the route contract, indexable, in the sitemap, and the catalog link points at `/bbb/`. | OBJ-1 | must |
| REQ-11 | WCAG 2.2 AA; Hallmark floor 0 FAIL; Impeccable detector findings fixed or answered. | OBJ-1 | must |
| REQ-12 | Every page passes the umbrella forbidden-word lint. | OBJ-2 | must |

## Claims register (what the site may say)

State: `verified` (code at named commit or clean-room 2026-10-25), `limit` (must be stated as a
limit), `forbidden` (never said). Sources are in 029 unless noted.

| ID | Claim | State |
|---|---|---|
| CLM-01 | Claude answers from your governed memory with a `qmd://` citation to the exact entry. | verified |
| CLM-02 | Saves run only when you type `/brain-save`; the model proposes, code decides what is kept. | verified |
| CLM-03 | Governance runs dedupe, policy and promotion; each promotion and retirement writes a SHA-256 hash-chained receipt; the chain head is committed to an anchor log. | verified |
| CLM-04 | `brain_audit_verify` checks the chain and the anchors and reports tamper signatures honestly. | verified (local mode only) |
| CLM-05 | A decision on the same subject retires an older reference, with its own receipt; search then returns the current entry. | verified (clean room) |
| CLM-06 | Local mode runs in-process on your machine; after a one-time native setup, search, capture and govern make no network calls. | verified |
| CLM-07 | Search fuses keyword arms (native SQLite FTS5, qmd BM25 when installed) by reciprocal-rank fusion, then reranks for freshness and category; an optional local semantic arm runs only with a local embedder; no generative model at query time. | verified |
| CLM-08 | Team mode: one governed brain on a server, reached over a private network with per-user tokens; members propose, admins approve. | verified (code; not clean-room) |
| CLM-09 | Four public Apache-2.0 repositories; qmd (MIT) by @tobi upstream. | verified |
| CLM-10 | Requirements: Claude Code or Cowork; Node 20+ and npm; optional qmd 2.x; git for anchors. | verified |
| CLM-11 | The optional compiler sends file text only to the model provider you configure; a local provider keeps it on the machine. | verified (compiler `packages/types/src/providers.ts:72-237`, `api/claude-client.ts:384`) |
| CLM-12 | The anchor log is committed locally and pushed only if you add a git remote. | verified (plugin `src/anchor.ts:24-34`) |
| CLM-13 | The team server stores each token only as a salted scrypt hash. | verified (registrar `apps/api/src/auth/token-registry.ts:96-115`) |
| CLM-14 | In team mode members search and propose; approve, reject and retire are admin-only. | verified (plugin `src/remote-server.ts`; code only, not clean-room) |
| CLM-15 | New local brains reject notes under 25 characters; `/brain` works best with one to four keywords. | verified (plugin `src/seed-policy.ts:49-58`, `skills/brain/SKILL.md:64`) |
| LIM-01 | Fresh local installs leave 8 of 10 governance rules dormant (eqw.1). | limit |
| LIM-02 | Rejected candidates stay in the inbox without a per-candidate receipt (eqw.2). | limit |
| LIM-03 | A capture containing a secret is dropped without a receipt or feedback (eqw.3). | limit |
| LIM-04 | Searches are not receipted; receipts cover governance decisions. | limit |
| LIM-05 | On a large brain, current truth does not always outrank older reference material (epic 39z). | limit |
| LIM-06 | Team users cannot run `brain_audit_verify` from the plugin. | limit |
| LIM-07 | Distribution channels carry different builds labelled 1.2.0 (eqw.5). | limit |
| FBD-01 | tamper-proof, immutable, blockchain, non-repudiation (local), unqualified append-only. | forbidden |
| FBD-02 | Customer counts, testimonials, logos, benchmark wins, performance numbers, pricing. | forbidden |
| FBD-03 | "Every answer ships a receipt"; "zero ML"; "tenantId required"; "bundles both engines"; "all Apache-2.0" for the semantic weights. | forbidden |

## Non-functional requirements

- Static Astro routes, no client framework for the demo; Web Crypto SHA-256 in the browser.
- Content visible without JavaScript; the demo degrades to a static explanation.
- LCP under 2.5 s on the VPS; no third-party scripts beyond the site's existing Umami.

## Risks

| ID | Risk | Response |
|---|---|---|
| RISK-1 | The site drifts from code as the plugin ships. | REQ-07 data module + verified-at dates; status page owns volatile facts. |
| RISK-2 | Limits read as weakness. | Present them as the receipts thesis applied to ourselves; one section, plain words. |
| RISK-3 | The demonstration is mistaken for the product. | Label it illustrative; link the real verifier commands. |
