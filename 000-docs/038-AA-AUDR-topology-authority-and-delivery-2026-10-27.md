# Brain topology, authority and delivery audit

Observation date: 2026-10-27 UTC. Bead: `compile-then-govern-obk.1`.
This is a read-only audit, not a deployment decision or readiness sign-off.

The four repositories form one product working surface, with independent code,
releases and task ownership. Intent OS owns the private company operating record;
the Brain derives and governs reusable knowledge from approved inputs. A source
merge, published release, installed artifact and successful user workflow are
separate observations. The website is a separate delivery surface.

## Evidence and limits

Public authority files were inspected at umbrella
`2bb1457650bf7093be600dea208e27ebf66e6059`. Their seven recorded digests match
the earlier clean `a6f0648` checkout; intervening changes are generated changelogs.
Remote main and latest-release API observations were recorded for all components.

The operator also recorded private, unsigned host metadata: systemd state,
selected listeners and schedules, installed script digests, and the installed
compiler bundle's self-manifest. These observations do not independently attest
provenance or prove endpoint authentication, recent successful work, content
accuracy, backup restorability or the deployment of newly merged fixes.

Three private receipts are retained with their full paths in the Bead, outside
the public repository. Their SHA-256 values are:

- Topology observations: `1ff039887e51411d8a570d01ac82397977334b62ebe86d6569ce569ddd1a2958`.
- Operations observations: `c1e29fcfb1a56e7a6f3faa2a12d4e5e3734dfb7578c40c091d307451802fd14f`.
- Compiler self-manifest observation: `b196d9d0e8ba76f65cca9d84e085015cd2b2abeece2f137fa232891d5a87ce28`.

These are local evidence identifiers, not publicly downloadable or signed receipts.
No corpus, tokens, environment secrets, private bind addresses or DNS names are
published here. No DNS name is inferred from a repository or service name.

## Ownership and system map

The content path is approved inputs → Compiler → canonical spool → Registrar
governance → exports and retrieval indexes → local plugin or authenticated team
API client. Compiler traces and Registrar governance receipts record different
layers; passing one verifier does not establish that the other passed.

| Surface | Working and tracking owner | Authority and boundary |
| --- | --- | --- |
| Umbrella | This repository; program Beads with `compile-then-govern` prefix | [repos.yml](../repos.yml), [007 topology](007-AT-SMAP-repo-topology-and-working-surface.md), [system model](../system-graph.yml). Product narrative, cross-repo contracts and canonical ops helpers; no engine implementation. |
| Compiler | `bobs-big-brain-compiler`; owning engine Beads/PRs | [Compiler source](https://github.com/jeremylongshore/bobs-big-brain-compiler/tree/9fe7f6d04ad51e9b55447b98ef240ccb41641642). Model-driven derivation above the spool, deterministic kernel and separate compile trace. |
| Registrar | `bobs-big-brain-registrar`; owning engine Beads/PRs | [Registrar source](https://github.com/jeremylongshore/bobs-big-brain-registrar/tree/83d7d9075c9fd0cbf801427f14143b55e7b283f9). Admission, store, governance receipts, retrieval adapter and HTTP API. |
| Plugin | `bobs-big-brain-plugin`; owning plugin Beads/PRs | [Plugin source](https://github.com/jeremylongshore/bobs-big-brain-plugin/tree/cad3815c61c4e63306f599e49d2f10d716e1d3c9). Packages Registrar libraries and local/team clients; optional Compiler CLI is separate. |
| Company operating record | Private `intent-os`; its authoritative company and operations records | Approved corpus input, inventory, decisions and notification contracts. Neither this umbrella nor compiled memories replace that record. |
| Runtime data and spool | Operator-managed data, not a source repository | [005 data scope](005-AT-ARCH-grounded-system-map-and-backup-scope.md). `~/.teamkb/spool` is canonical intake; raw sources, compile state, governed state, receipts and tokens have different roles. |
| Retrieval dependency and caches | Registrar adapter owns integration; upstream qmd owns its implementation | [Pinned lockfile](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/83d7d9075c9fd0cbf801427f14143b55e7b283f9/pnpm-lock.yaml) selects `@tobilu/qmd` 2.5.3. qmd lexical retrieval, native FTS5 and dense sidecars are distinct; exported/indexed views are derived. A lockfile does not identify every installed executable. |
| Runtime ops and schedules | Umbrella `bin/` helpers, Compiler runtime bundle, operator installation; private Intent OS notification contracts | [Deployment helper](../bin/deploy-teamkb-compile.sh), [system model](../system-graph.yml), [backup runbook](006-AT-RNBK-brain-backup-and-restore-runbook.md). Cron/systemd configuration is not proof of useful work. |
| Team access | Registrar API and plugin remote client; operator owns access configuration | [Mode dispatch](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/cad3815c61c4e63306f599e49d2f10d716e1d3c9/src/index.ts), [remote client](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/cad3815c61c4e63306f599e49d2f10d716e1d3c9/src/remote-server.ts). Team mode reaches a shared brain; it is not a second team repository or evidence of distributed replication. |
| Backup | Umbrella canonical backup script and operator-managed encrypted destinations | [006 runbook](006-AT-RNBK-brain-backup-and-restore-runbook.md). Tier A includes both stores, raw corpus, spool, receipts, anchors and protected tokens; expensive reproducibility roots are also retained. R2 is blob backup, not a query bridge. |
| Action integration | AGP owns actions; Brain owns knowledge/governance | [007 §5](007-AT-SMAP-repo-topology-and-working-surface.md#5-intent-os--brain--agp--composed-not-absorbed). A signed pointer to a governance-chain position is not the exact search read set or proof of what caused an action. |
| Website and external comparisons | Landing repository and product claims register; separate programs retain their own contracts | [Product record](029-PP-PROD-bbb-product-record.md), [claims register](031-PP-PROD-bbb-website-prd.md). This audit neither edits the website nor establishes Google OKF, ArcKit or second-brain-os conformance. |

## Delivery and operating state

“Current” below names the stated source or observation, not blanket production
acceptance. “Unverified” means the available evidence cannot establish that claim.

| Surface | State at the observation | Remaining boundary and owner |
| --- | --- | --- |
| Compiler | Current source main `9fe7f6d`; latest published [v1.23.1](https://github.com/jeremylongshore/bobs-big-brain-compiler/releases/tag/v1.23.1). Installed ops bundle declares revision `1a6a5f474c64b3c6edc3790e9da261030bc0ad6a`; its five declared file hashes match. | Self-consistency is not independently attested source identity or a successful nightly run. Current source expects an additional bundle member. Reconcile provenance under `compile-then-govern-jgh`; release PR240 remains separate. |
| Registrar | Current source main `83d7d90`; latest published [v0.8.0](https://github.com/jeremylongshore/bobs-big-brain-registrar/releases/tag/v0.8.0). API service observed active/running from a versioned release directory. | The configured target was already recorded in the dated026 snapshot; its name alone does not establish the serving payload's exact identity or deployment of recent fixes. Release/deployment acceptance stays with `1io.1` and `6ps.4`. |
| Plugin | Current main `cad3815`; latest published [v1.2.0](https://github.com/jeremylongshore/bobs-big-brain-plugin/releases/tag/v1.2.0). Local/team implementations exist in source. | No fresh installed-payload or authenticated teammate round trip was performed. Distribution candidate PR85 is separately frozen; `1io.1`/`6ps.4` retain acceptance. |
| Dense retrieval | Current Registrar [configuration](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/83d7d9075c9fd0cbf801427f14143b55e7b283f9/packages/qmd-adapter/src/config.ts) enables dense by default at production entrypoints, with lexical fallback on failure; direct callers omitting dense remain lexical. Embedder service observed running. | Running service and default configuration do not prove a query used dense or returned useful/current context. `1io.8` owns observed degradation diagnosis; `obk.2` owns project-use measurement. |
| Reranker | Host service observed inactive. The dated [dense-pool experiment](024-AT-RPRT-reranker-remeasure-on-dense-fused-pool-buzz.md) records a quality gain with latency limits. | The historical experiment does not establish present serving enablement. Do not turn a measured experiment into a current production claim; `obk.2` records actual client/query behavior. |
| Compile and quality automation | Two selected cron entries observed. Installed compile wrapper and quality digest differ from current umbrella copies; the installed digest uses an alert-floor path absent from the older umbrella copy. | Byte differences are proven, ownership and safe reconciliation are not. `jgh` owns provenance; never overwrite the installed digest with old source or publish private code automatically. |
| Backup and eval automation | Backup, retrieval-eval and faithfulness timers observed active/waiting; backup unit's recorded result is success. Installed backup script matches the umbrella source bytes. | No new backup, restore, off-host transfer or eval was run. Timer/result metadata does not prove current restorability or quality. Restore/live acceptance remains `6ps`; no new runtime authority is granted. |
| Tailnet canary | Separate-node deployment is specified by [its helper](../bin/deploy-teamkb-tailnet-canary.sh). No local installed script was found in the selected comparison. | Local absence does not prove absence on the separate node. Actual remote execution remains unverified under `6ps.4`. |
| Governance integrity | Current source exposes distinct compile/govern verification surfaces; earlier recovery evidence is preserved. | The separate private 2026-10-26 rehearsal retained 155 classified chain forks and failed strict recovery. No new live-chain verification, repair or cut-over is claimed; `eqw.8.1.2.9` remains authoritative. |
| Estate relationship projection | Separate private Intent OS derived graph; not the governed knowledge corpus or a project authorization boundary. | `obk.4` is the completed graph audit; `0py` owns the misleading repo/service query. Its source fix is not an operator graph rebuild. |
| Distributed brains/federation | Distributed rollout is demand-gated; [merge-govern primitives](002-AT-DECR-epic1-deterministic-merge-gate.md) exist separately from the shared team API. | `8da` and O7 retain their own prerequisites; a working shared client does not prove replica merge or federation acceptance. |
| Former private marketplace and standalone intent-brain entry | Retired in the [topology authority](007-AT-SMAP-repo-topology-and-working-surface.md). | Team is a runtime mode of the public plugin. Retired topology must not be revived by an inventory description. |

Private configured listener addresses and ports were captured separately from repo
layers. No fresh DNS lookup or authenticated HTTP probe was performed. Service
metadata alone cannot establish who can reach the API or which client payload ran.

## Conflicts and proposed corrections

| Discovery claim or discrepancy | Dated reconciliation | Owning action |
| --- | --- | --- |
| Team bridge described as unbuilt versus already built | Current umbrella source and plugin dispatch implement local/team modes. Current private Intent OS CLAUDE describes company-record/corpus ownership rather than the earlier unbuilt-bridge claim. A current teammate workflow remains unverified. | Retain the source/operating distinction in `obk.1`; acceptance remains `6ps.4`, not another bridge implementation. |
| Semantic retrieval described as deferred versus production default | Current umbrella CLAUDE and pinned Registrar config describe dense defaults and fallback. The historical phased decision is not evidence that source dense support remains unbuilt. Actual dense query success remains a separate measurement. | No duplicate source correction; `1io.8` and `obk.2` own operational evidence. |
| Source and installed ops ownership disagree | The five-member installed wrapper differs from the six-member source contract; quality-digest implementations also differ. The installed bundle passes its own five-file digest check. | `jgh`: reconcile exact revisions and canonical ownership across umbrella `bin/`, Compiler runtime and Intent OS alert floor before proposing any paired deployment. |
| Private inventory retains legacy engine descriptions and an unqualified audit-storage description | Selected Intent OS inventory fields do not match the current four-repo roles. Inventory is not a live endpoint authority. | `bhy`: identify the owning inventory source/generator, correct descriptions, preserve stable identities and validate supported projections. Do not hand-edit unrelated generated records. |
| Current source/release treated as current installed behavior | Main, latest release and installed metadata disagree in revision and scope. The [026 snapshot](026-AT-RPRT-stabilization-delivery-state-2026-10-23.md) already establishes this distinction. | Keep dated observations; `1io.1`, release240, frozen PR85 and `6ps.4` retain their own gates. This report grants no release/deploy approval. |

No application code, existing topology model, deployment configuration or website
is corrected by this audit. The two new follow-ups are linked as discovered work;
their implementation is not a prerequisite for reporting an honestly bounded audit.

## Relationship to the product outcomes

[017](017-PP-OKRS-definition-of-success.md) defines desired outcomes;
[019](019-PP-PLAN-master-blueprint-epics-and-beads.md) sequences work. Neither is
a substitute for current acceptance evidence or the Beads task database.

| Outcome | What this audit establishes | What it does not establish |
| --- | --- | --- |
| O1 retrieval | Owning adapter, dependencies, defaults, experiment and host-service distinction. | Current project relevance, per-stratum quality or reranker deployment. |
| O2 admission | Compiler/spool/Registrar ownership and separate source-versus-installed state. | Universal sole-writer enforcement or complete gate precision/recall. |
| O3 receipts | Distinct compile/govern surfaces, backup scope and retained strict-recovery limit. | Every fact receipted, independent witness publication or successful strict restore. |
| O4 seam | Layer and derived-cache boundaries have named owners. | A fresh complete seam-independence test run across all artifacts. |
| O5 freshness | Schedules and their source/runtime ownership are identified. | Recent successful compilation, visibility latency or later reuse. |
| O6 poisoning scope | Authenticated team access is distinct from content truth and provenance. | Prevention of authenticated-insider, compositional or dormant poisoning. |
| O7 federation | Shared team mode is separated from deferred distributed-brain work. | Federation rollout, merge acceptance or cross-organization trust. |
| O8 audience | API/plugin/store ownership is explicit; graph structure and project labels are not authorization. | Deployment and completeness of every audience control; `ca6` remains authoritative. |

The first bounded improvement is `jgh`: establish exact ops provenance before any
redeployment is proposed. In parallel, `obk.2` must measure project usefulness;
this topology audit cannot answer adoption from the presence of a timer or tool.
`obk.3` consumes those results before recommending external practices. Closing
this bounded report must not close the parent audit or the implementation epics.
