# 016 · OD · STND — Testing and proof standard

| Field | Value |
|---|---|
| **Date** | 2026-08-17 |
| **Applies to** | Bob's Big Brain umbrella, Compiler, Registrar, and plugin |
| **Status** | Canonical v1; records shipped gates and names unshipped proof work explicitly |
| **Companions** | [005 architecture](005-AT-ARCH-grounded-system-map-and-backup-scope.md), [006 backup runbook](006-AT-RNBK-brain-backup-and-restore-runbook.md), [016 development plan](016-AT-PLAN-cited-development-plan-retrieval-govern-receipts-federation.md), [017 definition of success](017-PP-OKRS-definition-of-success.md) |

## Purpose

This standard defines what evidence is required before a Bob's Big Brain change may be called
working. Green unit tests are necessary, but they are not enough for a system whose useful claim is
the composed path:

```text
source -> Compiler -> content-addressed spool -> Registrar -> qmd:// retrieval -> plugin
                                                       |
                                                       `-> audit receipt + anchor
```

Evidence stays attached to the layer that owns the behavior. Cross-repository claims require a
composed-path proof as well as each repository's local gates. A test result proves only the behavior
and boundary it exercised.

## Layer applicability

| Repository | Owned layer | Minimum change-time evidence | Additional evidence when applicable |
|---|---|---|---|
| Umbrella | Narrative, topology, runbooks, deployment helpers | forbidden-word lint for changed brand Markdown; ShellCheck for shell; system-graph sync for topology; rendered Mermaid for diagrams | live command receipt for an operational claim; restore receipt for backup changes |
| Compiler | source ingestion, deterministic kernel, model-backed compilation, spool production | lint, typecheck, tests, coverage, architecture check, CLI smoke, audit-chain positive and tamper controls | fixed-cost receipt for model work; same-input spool hash for determinism; Compiler-to-Registrar handoff for spool changes |
| Registrar | deterministic govern, durable store, retrieval, API, audit chain and anchors | validate, govern/provenance evals, retrieval ratchet, integration tests, security checks | live migration/deploy/rollback receipt; tenant negative control; anchor and truncation controls for audit changes |
| Plugin | local and team dispatch, teammate tools, independent anchor verifier | lint, scoped typecheck, unit coverage, full-chain zero-egress smoke, store-to-standalone anchor conformance | clean-install proof for packaging; tailnet probe for team mode; both local and team modes for dispatch changes |
| Composed system | Compiler -> spool -> Registrar -> plugin | one fresh happy path with a content hash, governed memory id, `qmd://` citation, and audit verification | failure-path and rollback proof at every newly crossed trust boundary |

Tests that cannot exercise their advertised dependency must fail or report an explicit skip. A green
job with the load-bearing cases silently skipped is not evidence.

## Enforcement and branch protection

The table below is a dated operational snapshot, not a promise that workflow files and GitHub rules
cannot drift. Re-check the repository workflow and branch-protection API before changing this
standard.

| Repository | Checks run on pull requests | Required on `main` as of 2026-08-17 |
|---|---|---|
| Umbrella | docs honesty, system-graph sync when relevant, ShellCheck, advisory Review and Adversarial review | Branch protection is not enabled. Passing workflows and addressed review findings remain the merge policy. |
| Compiler | CI matrix, CodeQL, docs quality when relevant, mutation test for its configured paths, cross-repo nightly smoke on its own trigger | `CodeQL Analyze (javascript-typescript)`, `Test`, `Coverage`, `Lint`, `Typecheck` |
| Registrar | validate, moat evals, retrieval eval, integration, security, seam independence, docs/review workflows when relevant | `validate`, `gitleaks`, `semgrep`, `moat-evals`, `retrieval-eval`, `integration` |
| Plugin | quality, full-chain smoke, anchor conformance, advisory review | `Lint · typecheck · unit tests`, `Full-chain smoke (zero egress)`, `Anchor conformance (store ↔ standalone)` |

A check being present in a workflow does not make it required. A required check does not prove
deployment. Branch protection is a backstop; the PR evidence described in
[013-OD-STND](013-OD-STND-commit-branch-pr-conventions.md) remains mandatory.

## Harness and fixture version policy

1. Every labeled dataset, fixture, baseline, policy bundle, and machine-readable result has an
   explicit schema or dataset version. Results name that version.
2. A semantic label change creates a new dataset version. Correcting prose or adding an equivalent
   serialization does not.
3. A baseline may move only in the same PR as the behavior or fixture that justifies it. The PR
   records old value, new value, segmented results, and the decision rationale. Never lower a floor
   merely to make CI green.
4. Policy-artifact hash pins guard bytes, not meaning. Updating a pin requires reviewer-visible
   disclosure of the policy change and a fresh eval receipt.
5. Cross-repository fixtures name one owner and pin the consuming revision or released artifact.
   Consumers must not silently follow an unversioned `latest`.
6. A result from a changed harness is not directly comparable with the old result unless a bridge run
   scores the same frozen fixture through both versions.
7. Harness alignment is not yet uniform across all repositories. Until
   `compile-then-govern-6ps.17` closes, each result must report its repository, commit, command,
   dataset version, and relevant tool version rather than claiming one stack-wide harness version.

## Evaluation gates: ratchets and decisions

These are different controls and must not be described interchangeably.

**A ratchet protects shipped behavior.** It fails when a measured stratum falls below its committed
baseline minus its documented tolerance. The Registrar's synthetic retrieval check is a PR-time
ratchet over exact-term and semantic Recall@10. It guards the retrieval already shipped; it does not
prove that a new retrieval architecture should ship. A legitimate improvement raises its baseline in
the same reviewed PR.

**A decision threshold authorizes a change in behavior.** It is set before the experiment and is
evaluated on the applicable frozen set, including the existing production control arm. The live
governed-brain retrieval set is a decision surface because a cold GitHub runner cannot reproduce the
private corpus or local model. Dense, rerank, or fusion changes must beat the named control on the
predeclared strata without hiding an exact-term regression inside an aggregate.
The engineer who owns the Registrar change also owns this decision-time run and attaches its result
to that change's PR and Bead; a decision surface without a named change owner is not a release gate.

**Fail-closed safety metrics are neither averages nor tradeable.** An undocumented secret or PII
false negative fails the govern eval. Provenance-integrity cases must accept disclosed benign forks
and reject genuine edits or anchored truncation. A higher retrieval score cannot compensate for a
failed safety or provenance check.

Synthetic fixtures provide a deterministic CI floor. Live, hand-labeled queries provide the release
decision. Publish both with their scope; do not present synthetic results as team-production quality.
The review-agent three-class classifier and live golden-set gate remain unshipped work under
`compile-then-govern-6ps.13`.

## Two-tier tailnet proof

### Tier A: daily liveness, shipped

An independently scheduled VPS probe uses the published plugin in team mode against the tailnet-only
API. It requires:

- deployment evidence that identifies both the probe host and API host as Tailscale peers, and that
  the configured API address belongs to the expected peer; an address inside `100.64.0.0/10` is a
  supporting check, not identity evidence by itself;
- a pinned published-plugin release path, healthy team mode, and the reported API service version;
- a successful member-token `brain_search` in the isolated `synthetic-probe` tenant;
- no access to the team corpus and no durable write;
- a content-safe receipt and governed Buzz incident alert on failure.

The Tier-A proof bundle combines the daily receipt with peer-identity and route or ACL evidence
captured at deployment and whenever the tailnet configuration changes. Together they prove network
reachability through the intended peers, published-package startup, and member authentication from
a machine other than the brain host. The daily address check alone does not prove tailnet
confinement. The public health endpoint alone is not an authentication proof, which is why the
isolated search is mandatory. Tier A does not prove capture, promotion, citation correctness, or
audit writing.

### Tier B: state-changing acceptance, not yet shipped

The nightly and on-deploy Tier B canary will use a dedicated synthetic tenant to perform capture ->
govern -> search -> cite -> audit-verify, followed by cleanup or deterministic retirement. It must
also run negative controls for an invalid token, wrong tenant, rejected candidate, missing citation,
and a modified receipt. Any residue is namespaced and discoverable.

Until `compile-then-govern-6ps.4` closes with live receipts, no document may say the scheduled
tailnet canary proves the full write path. Production rollout requires both Tier A and a fresh manual
composed-path proof in the meantime.

## Tamper-evidence boundary

The local audit trail is tamper-evident. Verification establishes integrity, ordering, and rewrite
detection relative to the inputs and witnessed anchor available to the verifier. The external anchor
extends detection across a boundary the database writer does not solely control. The standalone
plugin verifier provides an implementation-independent cross-check of the anchor format.

Required positive and negative evidence for an audit change includes:

- an intact chain and anchor pass;
- an edited or reordered row fails;
- an anchored tail truncation or history deletion fails;
- a legitimate same-position fork is disclosed without being mislabeled as tamper;
- a restored backup reproduces the recorded chain and anchor checks.

The proof does **not** establish that a memory is true, that a cited memory caused an answer, that the
global receipt tip is the exact read set for a query, or that a local producer could not rewrite
history before a checkpoint was witnessed. It is not non-repudiation. Per-query read-set receipts
remain tracked in `qmd-team-intent-kb-sdg`.

## Evidence bundle and closure rule

A Bead that changes behavior closes only when its note identifies:

1. owning repository and pinned commit or release;
2. exact commands or CI run and the observed result;
3. happy path, applicable failure path, and rollback;
4. live deploy or operator receipt when the claim concerns production;
5. documented residuals as linked Beads, not prose-only promises.

If one item is unavailable because it needs another teammate, an owner decision, a daily cost reset,
or a scheduled window, keep the Bead open and name that dependency. "Implemented" and "proven in
team production" are deliberately different states.
