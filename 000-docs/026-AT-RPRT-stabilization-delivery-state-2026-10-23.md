# Stabilization delivery evidence — 2026-10-23

Snapshot: 2026-10-23, after Registrar PR387 and plugin PR80 merged.

This dated record separates source, artifacts and deployed behavior. The program
is in progress under `compile-then-govern-1io`; it is not an all-repository or
production-readiness sign-off. Beads remains the task/status authority.

## Repository and delivery states

| Surface | Observed source state | Release or distributed artifact | Acceptance boundary |
| --- | --- | --- | --- |
| Compiler | Main `5d45bac1fe93a9a9f3bad375f189da6067e1be12`; original checkout clean | Published [v1.23.1](https://github.com/jeremylongshore/bobs-big-brain-compiler/releases/tag/v1.23.1); existing [release PR240](https://github.com/jeremylongshore/bobs-big-brain-compiler/pull/240) proposes 1.24.0 | No fresh complete Compiler test/release ceremony performed in this stabilization slice. |
| Registrar | Main `78ded1048a9f8b9889717bb18a35b5dbf497292a`; original checkout clean; correction [PR387](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/387) merged | Published [v0.8.0](https://github.com/jeremylongshore/bobs-big-brain-registrar/releases/tag/v0.8.0) | Required correction PR checks passed; the preceding code main 904a077 also passed CI. The running API still resolves to recorded release `f5e696b-f5e696b42a7b`; active/running state is not authenticated team acceptance or proof these new fixes are deployed. |
| Plugin | Main `d7d16e9305b6e28b62b64bc6c6697facf828d537`; original checkout clean | Published [v1.2.0](https://github.com/jeremylongshore/bobs-big-brain-plugin/releases/tag/v1.2.0). Main lock pins Registrar `904a077dc460ef8dfc9bf43ca725047ea0c5eae4`; [runtime PR80](https://github.com/jeremylongshore/bobs-big-brain-plugin/pull/80) merged | Merged artifact tested locally and all three required hosted checks passed; publication/install/deployment are separate. |
| Umbrella | Original main checkout retains pre-existing changes in the interactions log and grounded-system-map document | Documentation and generated changelogs; no application runtime | New work uses a separate clean worktree. Existing local changes are preserved; generated changelogs are not hand-edited. |
| Marketplace | Existing [draft PR1743](https://github.com/jeremylongshore/tons-of-skills-marketplace/pull/1743) retains its reviewed-source target `ca942d4d6f63bb79e6a8aef63306aa8c5ee83255` | No new approval, relock or payload synchronization claimed | The exact upstream-diff human review required by its sync workflow remains pending. Plugin source advances do not silently expand that target. |

## Evidence completed in this slice

Review timing exception: Registrar PR387 and plugin PR80 were merged before
their final advisory lanes completed, contrary to the wait rule in 013. Required
checks were green. Plugin 80's final adversarial review subsequently returned
LGTM; Registrar 387's final lane reached its ten-minute limit without a new
result. The deviation is recorded in Beads; this is not a claim that every
review approved or that the merge process fully complied with 013.

Registrar [PR384](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/384)
closed the pre-spawn signal-ownership race; a real detached-child reproduction
went from three live survivors in twenty attempts to zero in twenty. Focused
executor tests and the full local suite passed. This does not guarantee cleanup
of descendants that leave the process group or settle the separate once-handler
limitation in `compile-then-govern-1io.5`.

Registrar [PR385](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/385)
changed the default dense maintenance request to one document, keeping measured
explicit overrides. A one-document-capacity HTTP fixture failed with the old
batch and indexed all three documents with the new default; unchanged rescan
sent no further embedding requests. Local full suite: 3,369 passed/two skipped;
final focused 32 passed; required hosted checks passed. Real-service deadline
performance is not guaranteed by that fixture.

Registrar [PR386](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/386)
made lifecycle/category service mutations atomic with their audit receipts on
the shared SQLite connection. Four real-repository regression cases check
insert-then-throw rollback, valid retry, receipt fields/predecessor and nested
outer rollback. Local full suite: 3,372 passed/two skipped; focused 45 passed;
required hosted checks passed. After both merges, the combined source passed 56
focused tests and main CI. Separate full-suite counts must not be presented as
one combined local rerun. No power-loss or cross-connection atomicity claim is made.

[Umbrella PR118](https://github.com/intent-solutions-io/bobs-big-brain-umbrella/pull/118)
separated the Compiler JSONL verifier from the Registrar SQLite/anchor verifier
and corrected local audit-trust wording. Local honesty lint on the changed file
passed; the README-only hosted honesty filter did not run on that file.

## Selective current-answer repair

The operator reports seventeen scoped originals deprecated with canonical
per-record audit receipts after fifteen replacements were accepted through
normal, owned-spool governance. Useful shared material is reused rather than
recaptured. Private fourteen-record and three-record rehearsals restored the old
records and removed stale archive copies while retaining accepted corrections;
these rehearse retirement rollback, not candidate-admission rollback.

Local export and metadata checks found all seventeen originals preserved in
archive and absent from nonarchive paths across qmd, native FTS5 and dense
indexes. All fifteen correction citations were readable and found by diagnostic
queries. Configured audience-narrowing and contradiction-check rules were
reported dormant, not proven enforced. Local anchor commits do not establish
publication to an independent remote witness.

The final label set was reported fixed before the new isolated retrieval run:
113 relevant citations and64 obsolete labels across25 questions. Sixteen questions
replace relevant citations; e03 only gains an obsolete label. Fourteen accepted
corrections become gold; the emergency-access correction is not added as gold
for e03. The scored 45 ids, kinds and question texts stay unchanged.

| Captured lists scored with the same corrected labels | Recall@10 | nDCG@10 | FAMA@10 | Questions exposing labeled obsolete answers |
| --- | ---: | ---: | ---: | ---: |
| Original 450 citation slots | 0.375926 | 0.286305 | 0.356667 | 12/45 |
| Later 425 citation slots | 0.438889 | 0.339036 | 0.421481 | 5/45 |

These are observations at different corpus/index states and times. The later run
reported five generic dense-query failures and failed open to lexical results;
the current counter also covers unscored gap probes. It is explicitly degraded,
not a controlled pure-hybrid comparison. The captured lists are preserved rather
than rerun until clean. `compile-then-govern-1io.8` owns sanitized per-query
failure diagnosis. e21/e22/e28/e38/e42 still expose other labeled obsolete
answers; e45's worktree-policy coverage remains partial under 39z.33.4. Unlabeled
stale answers and other unreviewed gold may remain.

The correction receipt/replay is in [Registrar PR387](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/387).
Its command checks canonical old projection hash, actual 450/425 slot counts,
source-versus-frozen label/question identity and finite metrics. Seven corrupted
receipt controls reject. It uses no live corpus or embedder. Individual SQLite
backups are consistent, but independent snapshots plus the original export tree
are not an atomic ensemble; readonly SQLite connections can update WAL/SHM
coordination sidecars.

## Plugin artifact and remaining proof

The merged runtime artifact in [PR80](https://github.com/jeremylongshore/bobs-big-brain-plugin/pull/80)
records Registrar 904a077 and bundle SHA256
`bf68afc529c9c9e1422285f26288cee5ce53c1a7d71d72f3b19974aac11e3ca1`.
Local typecheck/lint, 147 unit tests with coverage floors and 37 conformance tests
(zero skipped) passed. The final artifact passed clean-install bootstrap, local
capture/govern/audit/cited-search, team stub, export reconcile, golden-set,
inbox-sweep/admin wire and 19 contract tests. These are isolated fixtures; the
team stub is not an authenticated remote-tailnet round trip. A local pack dry-run
includes host-provisioned runtime natives and is not a portable-release sign-off.

The program still needs release/distribution reconciliation (`1io.1`/`39z.22`),
contradiction linkage and precise receipted invalidation (`39z.1`/`39z.2`), actual
team acceptance (`6ps.4`), cross-project later-reuse evidence (`obk.2`), and only
then bounded fixture interoperability (`1io.2`). Google OKF and ArcKit conformance
is not established by the current fixes or test suites.
