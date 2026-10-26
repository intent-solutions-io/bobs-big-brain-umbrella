---
blueprint:
  documentId: DOC-BBB-WEBSITE.ACCEPTANCE-CRITERIA
  documentType: acceptance-criteria
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-26'
  sourceRefs: [031-PP-PROD-bbb-website-prd.md, 034-AT-DSGN-bbb-website-frontend-spec.md]
  relatedArtifacts: [031, 034]
  humanReview: {required: true, status: not-started}
---

# Acceptance criteria: the Bob's Big Brain website

Each criterion names its requirement and how it is checked. Results are recorded in the landing PR.

| ID | Criterion | Requirement | Verification |
|---|---|---|---|
| AC-01 | `npm run build` succeeds and emits the five `/bbb/` routes. | REQ-01 | build output |
| AC-02 | `npm run audit:site-map` and `npm run audit:indexability` pass with the five routes registered and indexable. | REQ-10 | landing scripts |
| AC-03 | Every route shows the product bar with a "Beta" tag that links to `/bbb/status/`. | REQ-02 | rendered HTML check |
| AC-04 | The local install prompt names `jeremylongshore/bobs-big-brain-plugin` and `governed-second-brain@governed-second-brain`, matching `marketplace.json` at the recorded commit. | REQ-03 | diff against the plugin manifest |
| AC-05 | No rendered page contains a `100.` tailnet address, a port `3847`, the tenant id `intent-solutions`, or an operator first name as token issuer. | REQ-04 | grep over `dist/bbb/` |
| AC-06 | Every claim sentence maps to a CLM or LIM row in 031; none maps to an FBD row. | REQ-05 | reviewer read-through |
| AC-07 | The status page lists the clean-room date, the proven steps, LIM-01..LIM-07 with their observation dates, later source corrections and links, and separately identified source/release/install revisions with a verified-at date drawn from `src/data/bbb.mjs`. | REQ-06, REQ-07 | rendered HTML check |
| AC-08 | The receipts page carries the tiered "does not prove" statement. | REQ-08 | read-through + lint |
| AC-09 | In a real browser the demo: verify passes on load; editing record 3 makes verify fail naming link 3; re-hash forward makes verify pass; the anchor check then reports a mismatch; reset restores intact. Without JavaScript the explanation is visible. | REQ-09 | Playwright run |
| AC-10 | Hallmark `sloplint --render` reports 0 FAIL for each route; every REFLEX fixed or waived on the record. | REQ-11 | sloplint output |
| AC-11 | Impeccable `detect` findings on changed files are fixed or answered; the finish review verdict is recorded. | REQ-11 | detector JSON + review |
| AC-12 | Keyboard: every control reachable, focus visible, demo results announced; no horizontal scroll from 320 to 1920 px. | REQ-11 | Playwright + `test-brand-polish.py` |
| AC-13 | `scripts/lint-forbidden-words.sh` passes on the built HTML of every route. | REQ-12 | umbrella lint |
| AC-14 | Largest Contentful Paint is under 2.5 s on every route, served from the VPS. | PRD non-functional (LCP) | Playwright Chromium at 1440 × 900, fresh context per run, `PerformanceObserver` `largest-contentful-paint` (buffered), median of 3 runs per route against `https://intentsolutions.io/bbb/…` after deploy. Pre-deploy reference (local `astro preview`, loopback, 2026-10-25): medians 272–436 ms; this does not satisfy AC-14, which needs the VPS run. |
