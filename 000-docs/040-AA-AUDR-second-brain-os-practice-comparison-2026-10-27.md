# Second-brain-os practice comparison

Observation date: 2026-10-27 UTC. Bead: `compile-then-govern-obk.3`.
This is a bounded source comparison and recommendation, not an adoption result.

Adapt three manual practices within existing Beads and source records: a project
brief, post-work feedback, and a short owner review. Start with the brief in the
next eligible Brain work session. One pilot, `compile-then-govern-oz7`, owns all
three practices; the pilot is open and has not been performed.

## Sources and evidence limits

The external reference is
[undefined-ui/second-brain-os at `347feee`](https://github.com/undefined-ui/second-brain-os/tree/347feee87b305b291f7264890e5024db422e3467).
Its [README](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/README.md)
describes a personal Markdown wiki and project workflow and explicitly excludes
team-wiki use. That is its stated scope, not a defect inferred from missing team
features. Its [MIT license](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/LICENSE)
was inspected; any future substantial code reuse must retain the required notice.
This report paraphrases practices and imports no code or skill.

The [source manifest](040-AA-AUDR-second-brain-os-practice-comparison-2026-10-27.evidence.json)
pins the 16 inspected external files and their hashes. Source inspection establishes
documented intent and the inspected scripts' behavior, not their deployment,
usage, security certification or retrieval performance. External skills were read
as data; their instructions were not executed. No third-party performance claims
or popularity counts are used as evidence here.

The current equivalent is grounded in the merged
[topology audit](038-AA-AUDR-topology-authority-and-delivery-2026-10-27.md),
[project-use audit](039-AA-AUDR-project-use-and-context-contract-2026-10-27.md),
and the private `obk.4` graph audit dated 2026-10-26. The graph audit's receipt hash
is recorded in the manifest; it contains private evidence and is not publicly
downloadable. These are unsigned operator observations, not independent runtime
attestations. Later code fixes and open source PRs do not retrospectively change
the audits' observation dates. An available implementation is not proof of use.

## Comparison and disposition

All external paths below resolve at the pinned revision above. “Adopt” means retain
an already compatible principle; “adapt” means a proposed bounded workflow change.
Neither means a new implementation has shipped.

| Area and exact external source | Current equivalent and evidenced gap | Disposition, benefit and cost | Authority and owning Bead |
| --- | --- | --- | --- |
| Knowledge/project separation: [two-layers.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/01-concepts/two-layers.md) | Beads owns task state; source documents own design; Compiler/Registrar hold governed knowledge. The project audit did not establish routine later reuse. | **Adopt the separation already present.** No new folders or task database; no new operating cost. | Preserve `repos.yml` and existing source authority; `obk.3` owns this assessment. |
| Project scoping/objective: [project-scoping.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/02-setup/project-scoping.md), [project skill](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/skills/second-brain-project/SKILL.md) | Existing repository instructions and Beads provide scope. The three-project sample exposes task/phase ambiguity and two Source-footer-only snippets; citation presence alone is insufficient. | **Adapt: explicit brief.** Name one bounded outcome and read the cited substance. Estimated budget: five minutes per session, measured in the pilot. Do not copy sensitive pages into Inputs. | `oz7` owns the manual pilot; `ca6` retains audience enforcement. A directory change or project instruction is not an access boundary. |
| Capture and feedback: [ingestion README](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/03-ingestion/README.md), project skill's Inputs/Process/Outputs/Feedback | Compiler → canonical spool → deterministic Registrar admission already exists. Historical candidate/promotion links were found; all-authors capture and later operational reuse remain unverified. | **Adapt: post-work feedback.** Record the verified output, useful/insufficient knowledge and one reusable lesson candidate in existing notes. Estimated budget: five minutes per session. Low-friction capture is not permission to bulk ingest. | `oz7` owns feedback measurement; `jfv.2.2` retains all-authors verification. Any actual capture uses the existing authorized path. |
| Maintenance/review: [review-cadence.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/09-maintenance/review-cadence.md), [lint-and-health.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/09-maintenance/lint-and-health.md) | Existing metrics, Beads and quality reports provide inputs. The project sample did not measure whether an owner receives and uses a concise review. | **Adapt: one short owner review after the pilot.** At most three recommendations, each with one existing owner. Preparation budget: fifteen minutes; reading target: ten minutes. These are proposed budgets, not measured results. No schedule is created. | `oz7` owns the manual review; existing correction/evaluation owners keep their work. A review proposes rather than performs lifecycle changes. |
| Retrieval: [asking-questions.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/07-retrieval/asking-questions.md) | Current sampled Codex searches returned local-qmd citations, with query-sensitive relevance and content-sufficiency limits. Team round trips and weekly teammate cited use remain unmeasured. | **Adopt citation/gap discipline; reject a retrieval replacement on this evidence.** No comparative benchmark justifies replacing the existing hybrid retrieval. Manual source reading has the pilot's brief cost. | `39z.10` retains accuracy-gated ambient retrieval; `6ps` retains acceptance evidence. No hook is enabled. |
| Contradictions and supersession: [contradictions-and-supersession.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/04-structuring/contradictions-and-supersession.md) | Registrar lifecycle and contradiction work already own this. The Hustle sample shows that an older four-tier memory still agrees with current source while the roadmap names a future target. | **Adopt source/date/confidence discipline; reject recency-only retirement.** Preserve both positions and state what would settle disagreement. This is not evidence that every current conflict is resolved. | `39z.1` owns contradiction wiring; `39z.2` owns invalidation precision and governed changes. No duplicate resolver or direct wiki mutation. |
| Graphs and health: [metrics.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/05-graphs/metrics.md), [link_check.py](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/scripts/link_check.py), [vault_stats.py](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/scripts/vault_stats.py), [graph_export.py](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/scripts/graph_export.py) | `obk.4` distinguishes Compiler wiki links, Registrar UUID edges, the umbrella model and the disposable estate projection. Its dated Registrar sample had 302 supersedes edges; it did not establish project-scoped graph retrieval. | **Defer script reuse and new graph storage.** The scripts operate on Markdown wikilinks, not governed UUID edges or estate types. Translation, identity and privacy work would have ongoing cost; no demonstrated task gain justifies it yet. Do not adopt personal-vault thresholds as product gates. | `39z.1` retains edge remediation; `39z.5` retains evaluation. The estate query defect is separately owned by `0py`; its source PR is not a deployment. |
| Governance and team use: [safety-and-guardrails.md](https://github.com/undefined-ui/second-brain-os/blob/347feee87b305b291f7264890e5024db422e3467/docs/06-agents/safety-and-guardrails.md), README | The external guardrails explicitly require permission boundaries rather than prompts. BBB's deterministic admission, tamper-evident audit and team policy have a different remit; current end-to-end team use is not established by the sample. | **Adopt permission discipline; reject a wholesale vault/team migration.** No second canonical corpus, direct unreceipted mutation, access widening or replacement of GOVERN. No migration cost incurred. | `ca6` retains claim-level audience policy; `jfv` retains team proof. Folder scoping is not authorization on either side. |

The graph documentation recommends orphan rate, degree, components and stale-page
rate. The inspected `vault_stats.py` computes page/type/word counts, links, average
degree, orphan rate and most-linked pages; it does **not** compute components or
stale-page rate. `link_check.py` reports links/orphans/stubs without editing files;
`graph_export.py` writes an explicitly selected CSV or GraphML output. These are
useful distinctions between documentary coverage and code. None was executed here.

## One pilot, three practices

Use the [039 context contract](039-AA-AUDR-project-use-and-context-contract-2026-10-27.md#proposed-project-context-contract)
in three subsequent eligible work sessions, recording evidence in their existing
Bead/PR records. Do not backfill earlier sessions or count audit searches as adoption.

1. **Brief:** 3/3 sessions name the existing goal, source revision, client/mode,
   relevant citation substance and applicable checks. No unresolved source conflict
   is silently used to act. Record insufficient/negative retrieval cases too.
2. **Feedback:** 3/3 record the actual output, verification and what knowledge
   helped or failed. Record a lesson candidate without asserting it was captured,
   admitted or indexed. Those later states need their own evidence and authority.
3. **Review:** one owner-facing digest reports the three sessions, measured and
   unknown results, and at most three recommendations with one owner each. Record
   preparation and actual review time, or mark review time unmeasured. The ten-minute
   reading target is a hypothesis. A prepared digest is not proof it was read.

`compile-then-govern-oz7` owns execution and honest outcome reporting, including
failure. The estimated session budget is ten minutes each plus fifteen minutes
for the digest: 45 minutes preparation in total, plus the owner's review. Record
actual time before deciding whether this overhead is worthwhile. The first action
is to attach a brief to the next eligible session's existing Bead before acting.
There is no automatic promotion, scheduled review or new task ledger.

## Outcomes and remaining ownership

For [017 outcomes](017-PP-OKRS-definition-of-success.md), this pilot tests an O1
source-use practice and an O5 feedback/visibility observation method. It does not
establish a retrieval-score gain or a visibility SLO. O2 keeps deterministic
admission and receipts; a lesson proposal is not an admission. O8 keeps audience
policy separate from project labels; no access enforcement claim is added.

The graph audit's tenant-route failure was addressed separately in Registrar
PR436 (`ion`); that source correction is not a deployed-state claim. The estate
query correction remains in Intent OS PR845 (`0py`), while identity metadata and
private guidance remain in PR846 (`bhy`) and PR847 (`95c`). At this observation
those three Intent OS PRs are unmerged. Their main-branch automatic shipping
boundary and pending approval are unchanged. Strict recovery, team acceptance,
all-authors capture and accuracy-gated automation retain their existing owners.

Rollback of this comparison removes this report, its evidence manifest and its
index row. Beads state and private receipts are separate records requiring their
own disposition; removing a recommendation does not delete that history. No
runtime, corpus, website, connector, deployment or release changed in this audit.
