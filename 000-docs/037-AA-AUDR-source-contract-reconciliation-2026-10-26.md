# Document consistency audit report

Project: Bob's Big Brain umbrella, remediation of the 2026-10-25 consistency audit.
Date: 2026-10-26. Baseline: umbrella `b993ede`; source checks: Compiler `9dc7488`,
Registrar `3dede3c`, plugin `09b6644`. Bead: `compile-then-govern-eqw.6.1`.
Registry: `intent-os/sot-map.yaml` absent; bootstrap mode, fact classes unowned.
The diagnostic skill does not name an authority winner or write registry rows.
The separate source-backed edits implement the owner's existing reconciliation request.

## Executive summary

This is the umbrella slice, not closure of all findings in the four-repository
report. Its nine grouped deterministic findings and five advisory findings are
listed below. Original historical audits, release evidence and clean-room
observations retain their dates. Validation receipts and configured-review
outcomes belong in the PR and Bead; this record does not assert a fresh installer,
live-brain, website-deployment or team-acceptance pass.

| Severity | Grouped baseline findings |
|---|---:|
| Critical, deterministic | 0 |
| Warning, deterministic | 9 |
| Info, deterministic | 0 |
| Advisory, judged | 5 |
| Total | 14 |

## Part A — deterministic findings

### Category 1: status drift

- Warning D1, unowned `version-string`: baseline README status table listed
  Compiler v1.22.0; the checked GitHub release is v1.23.1. Locations: umbrella
  README status table; Compiler package.json and releases/tag/v1.23.1. Auto-fixable:
  yes. The corrected table names release tags and date, not installed payload identity.

### Category 4: CI and validation drift

- Warning D2, unowned `ci-commands`: README source demo omitted `--intkb-repo`;
  Compiler scripts/demo-e2e.sh defaults to the old clone path and supports the
  explicit flag. Auto-fixable: yes. The source quickstart now builds both checkouts
  and passes the renamed sibling path. Shell syntax/path inspection is not a new
  execution of the full example.
- Warning D3, unowned `code-fence-content`: README's source-command fence included
  partner-badge Markdown. Auto-fixable: yes. The badge is outside the bash fence.

### Category 6: cross-document contradiction

- Warning D4, unowned `trace-event-schema`: README showed ask.complete and citation
  arrays; Compiler packages/cli/src/commands/ask.ts writes ask with integer
  verifiedCitations/unverifiedCitations. Auto-fixable: yes. The trace example is a
  fragment; full citation details belong to the separate JSON answer.
- Warning D5, unowned `component-inventory`: README listed six apps/nine packages;
  Registrar apps/ and packages/ contain six and ten manifests. Auto-fixable: yes.
- Warning D6, unowned `thesis-doc-identity`: README claimed byte-identical thesis
  copies; the two engines' 034-AT-NTRP files differ. Auto-fixable: yes. Current
  guidance describes separately maintained historical copies.
- Warning D7, unowned `aggregation-scope`: CLAUDE.md said the retired marketplace
  no longer contributes; scripts/aggregate-changelogs.sh still attempts its
  token-gated historical changelog and skips only on unavailable input.
  Auto-fixable: yes. This correction changes the description, not fetch behavior.

### Category 7: index and reference drift

- Warning D8, referential integrity: system-graph.yml cited a missing
  dense-policy-import-discipline.test.ts. Registrar dependency-cruiser rules and
  source configuration do not supply that guard. Auto-fixable: yes. The model now
  labels serving/eval separation a configuration convention, with real source
  loci, and its rendered document is regenerated. Index coverage also includes
  the actual historical PDF and cut-over proposal; previously repaired index
  entries are not counted as new fixes.

- Warning D9, referential integrity: a full scan of 68 tracked Markdown files
  found two upstream-relative links inside generated changelog mirrors. The
  umbrella source changelog link is made absolute here; the Compiler source
  link belongs to eqw.6.2. Generated mirrors are not edited by hand. Parent
  eqw.6 remains open until normal aggregation reflects both source corrections.
  Auto-fixable: no, requires owning-source correction and generated refresh.

## Part B — advisory findings, never blocking

### Category 1: status drift

- Advisory A1, unowned `phase-status`: README's "latest" demo metrics came from an
  older run. The replacement links the dated 2026-06-14 seven-stage summary;
  it is not current product performance. Auto-fixable: yes.

### Category 3: capability and behavior drift

- Advisory A2, unowned `receipt-scope`: README conflated cited retrieval, Compiler
  JSONL traces and Registrar SQLite governance receipts. Source references:
  Compiler traces.ts/ask.ts; Registrar API search.ts; plugin govern.ts/anchor.ts.
  The edited guide distinguishes them and makes anchoring best-effort, including
  the ordinary background push. Auto-fixable: yes.
- Advisory A3, unowned `packaging-mode`: README/007 implied both engines were
  bundled; plugin build.mjs and installer show Registrar libraries plus an
  optional separate Compiler CLI. Native setup and optional semantic service
  have their own requirements. Auto-fixable: yes.

### Category 5: planning versus implementation

- Advisory A4, unowned `evidence-state`: product029/claims031 treated original
  installation limits as unqualified current behavior. They now preserve the
  a1b74ca clean-room observations alongside plugin #88/#89/#90/#95 source fixes.
  Existing policies, seed failures, flags, raw refusals, retention and release
  alignment remain qualified. No blueprint owner-review status is promoted.
  Auto-fixable: yes.

### Category 6: description comparison

- Advisory A5, unowned `repository-scope`: contributor/security text omitted
  plugin ownership and umbrella operational helpers. Current scope and private
  security-report routing are clarified. Unsupported current competitor metrics
  are removed rather than represented as a new competitive evaluation.
  Auto-fixable: yes.

## Check coverage

| Skill check | Scope |
|---|---|
| 3.1 index/filesystem | All immediate 000-docs Markdown, JSON and PDF artifacts versus index links. |
| 3.2 versions | README release labels versus checked release metadata; dated source pins retained separately. No umbrella package manifest exists. |
| 3.3 commands/CI | README shell fences and actual demo flags; CLAUDE validation commands versus workflow YAML. Installer/demo commands are not CI test claims. |
| 3.4 CLAUDE references | Current named repository files and workflow references; abbreviated doc numbers denote an index lookup. |
| 3.5 stale status | Reviewed current entry points; dated historical reports retain original observations. |
| 3.6 capabilities | Receipt, retrieval, packaging and anchor boundaries checked against named owning source. |
| 3.7 cross-doc facts | Topology, repository/license scope, release/runtime and inventory statements reviewed. Model weights are not covered by the code license. |
| 3.8 links | All tracked Markdown scanned; changed source targets and index entries checked. Two generated-mirror links remain pending source correction/normal refresh, not hidden by a clean changed-file result. External HTTP correctness is separate. |
| 3.9 planning | Product evidence-state labels reviewed; no planning/ directory exists. This is not a re-audit of every epic's implementation. |

## Unowned fact classes — human adjudication needed

No registry authority is invented. Version, command, trace-schema, inventory,
thesis-identity, aggregation, phase, receipt, packaging and evidence-state classes
remain unowned in the validator's registry. The paired observations and locations
above are candidate diagnostic evidence; referential existence needs no registry.

## Proposed registry rows

Bootstrap draft for human review only; this audit does not write sot-map.yaml:

```yaml
version: 1
fact_classes:
  version-string: {owner: package-manifest, mirrors: [readme], determinism: deterministic, depth_tier: T1, staleness_bound: 0, criticality: high, volatile: false}
  trace-event-schema: {owner: code, mirrors: [readme, canonical-docs], determinism: deterministic, depth_tier: T1, staleness_bound: 0, criticality: high, volatile: false}
  component-inventory: {owner: code, mirrors: [readme, canonical-docs], determinism: deterministic, depth_tier: T1, staleness_bound: 0, criticality: medium, volatile: false}
  capability-claims: {owner: code, mirrors: [readme, canonical-docs], determinism: llm-judged, depth_tier: T2, staleness_bound: 0, criticality: medium, volatile: false}
```

## Priority actions

Direct mismatches are reconciled in the umbrella patch and require its validation
and review evidence before closure. Compiler, Registrar, plugin and site-data
slices remain owned by eqw.6.2–eqw.6.5. Release/distribution and live recovery
retain their separate acceptance and approval requirements. Advisory wording
changes are not a new product benchmark, compliance conclusion or deployment.

## Source locations

Baseline locations use umbrella b993ede. Counterpart paths use the pinned revisions above; directory inventory and whole-file identity are file-level observations.

| Finding | Baseline artifact | Counterpart observation |
|---|---|---|
| D1 | README.md:280 | Compiler package.json:3; GitHub release v1.23.1 |
| D2 | README.md:270 | Compiler scripts/demo-e2e.sh:54 |
| D3 | README.md:256 | Current README shell-fence structural check |
| D4 | README.md:210 | Compiler packages/cli/src/commands/ask.ts:314 |
| D5 | README.md:78 | Registrar pnpm-workspace.yaml:1 and all app/package manifests |
| D6 | README.md:286 | Both engine 034-AT-NTRP files:1 (whole-file comparison) |
| D7 | CLAUDE.md:109 | scripts/aggregate-changelogs.sh:41 |
| D8 | system-graph.yml:211 | Registrar packages/qmd-adapter/src/eval/ci-retrieval-ratchet.ts:134,144 |
| D9 | CHANGELOG.md:20 | Generated mirrors: umbrella:24, Compiler:520; Compiler CHANGELOG.md:516 |
| A1 | README.md:241 | Compiler dogfood/runs/demo-2026-06-14T031420Z/summary.json:1 |
| A2 | README.md:207 | Compiler packages/kernel/src/traces.ts:1; plugin src/anchor.ts:1 |
| A3 | README.md:80 | Plugin build.mjs:1 and bin/init.mjs:1 |
| A4 | 000-docs/029-PP-PROD-bbb-product-record.md:108 | Plugin src/seed-policy.ts:1, govern.ts:1, local-server.ts:1; PRs88/89/90/95 |
| A5 | CONTRIBUTING.md:4 | repos.yml:1; bin/deploy-teamkb-compile.sh:1 |
