# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The **umbrella / landing repo** for **Bob's Big Brain** (the public product name since 2026-07-10,
PR #37; formerly "Governed Second Brain") — the local-first knowledge stack
built on the *compile, then govern* architecture. (Renamed from `compile-then-govern` on
2026-06-16; the GitHub repo is now `intent-solutions-io/bobs-big-brain-umbrella` and the old URL
auto-redirects. The local working directory was renamed to match — it is
`~/000-projects/bobs-big-brain-umbrella/` (the bead prefix stays `compile-then-govern`).) It contains
**ecosystem-level documentation plus the cross-repo working-surface helpers** — the landing README,
governance files (`CONTRIBUTING.md`/`SECURITY.md`/`LICENSE`), `assets/` (banner + social-card), the
program-level beads tracker, the topology manifest [`repos.yml`](repos.yml), and `bin/`. **No
product code lives here** (the engines and plugin own that), but `bin/` + `.claude/skills/` are more
than mapping helpers: `bin/deploy-teamkb-compile.sh` (its header: "The repo copy under bin/ is
CANONICAL; ~/bin holds deploy artifacts", bead `compile-then-govern-6ps.1`) deploys the brain's
runtime ops scripts from here (see "Runtime ops scripts" below).

## Commands (validation = what CI runs)

There is no build or unit-test suite. CI is five workflows; run the matching command locally before
pushing:

```bash
bash scripts/lint-forbidden-words.sh README.md       # docs-honesty: forbidden claim-words (any brand-surface .md)
bash scripts/test-lint-forbidden-words.sh            # docs-honesty: the lint's own self-test
./scripts/audit-harness verify                       # docs-honesty: hash pins in .harness-hash
python3 scripts/render-system-graph.py --check       # system-graph-sync: system-graph.yml ↔ 020-AT-SMAP
python3 scripts/render-system-graph.py --check-local # box-only extra: systemd units/cron really exist (not in CI)
bash scripts/test-teamkb-compile-lock.sh             # shellcheck workflow: compile-deploy ownership/rollback
shellcheck bin/*.sh scripts/*.sh                     # shellcheck workflow lints every tracked shebang file
```

- **`.harness-hash` pins every workflow file and `scripts/lint-forbidden-words.sh`.** Editing any of
  them fails `audit-harness verify` until you re-pin with `./scripts/audit-harness init` after review.
- After editing `system-graph.yml`, regenerate the doc block with
  `python3 scripts/render-system-graph.py --write` (never hand-edit the rendered block).
- `bin/teamkb-systemmap.sh` rewrites the generated live-stats block in `000-docs/005-AT-ARCH`;
  preserve its markers.

## Runtime ops scripts (repo copy is canonical, `~/bin` is a deploy artifact)

`bin/deploy-teamkb-compile.sh` copies the reviewed scripts to where cron/systemd run them —
`teamkb-compile-daily.sh` (cron 03:30),
`teamkb-backup.sh` (`teamkb-backup.service` 04:30), plus `.claude/skills/teamkb-{compile,review}/` →
`~/.claude/skills/`. It seeds the public `teamkb-quality-digest.sh` bootstrap only
when no destination exists; it preserves an existing observer, including symlinks
and its mode. The company host's quality observer is owned by private Intent OS;
its implementation must be updated through that owner's reviewed deployment,
not overwritten with this public bootstrap. The helper reports seeded/preserved;
preservation does not certify the observer's health or provenance.

| Existing observer | Operating owner and update source | Reviewed update path |
|---|---|---|
| Company host observer | Private Intent OS operating source; the operator maintains the installed caller. | Use that source's reviewed deployment and rollback procedure; do not replace it with the public bootstrap. |
| Public bootstrap copy | The installing operator; source is this repository's `bin/teamkb-quality-digest.sh` at a deliberately selected reviewed revision. | Back up the installed file and its mode, then deliberately deploy the selected observer file through the operator's update procedure. The compiler helper only seeds absent paths and does not perform observer upgrades. |
| Unknown file, directory or symlink | Ownership and provenance are unverified. | Preserve it, identify its owner and update procedure before replacement; preservation is not a health check. |

Fresh seeding needs GNU-compatible `ln -T` and a destination filesystem supporting
hard links. Seed preparation/publication failure can stop a full deploy before
backup-script installation, after earlier compiler/skill steps; full deployment
is not one transaction. Existing observer modes are retained, not normalized to
0755. Only newly created seeds receive mode0755. No additional package is installed.

It requires `TEAMKB_COMPILER_REVISION=<full 40-char compiler SHA>` (the compiler
implementation is installed as a commit-addressed, hash-verified bundle under
`~/.local/lib/teamkb-compile`), is idempotent, and is run **after merge**. Never hand-edit deployed
copies: update each owning source and use its reviewed deployment path. Compiler entry and
backup changes start in `bin/` here; an existing quality observer has its own owner.
`teamkb-tailnet-canary.sh` (+ its deploy script) is the
daily Tier-A proof run from a separate tailnet node through the plugin installed from its public
GitHub marketplace (`jeremylongshore/bobs-big-brain-plugin`).

## Public product site

The public product site is **`https://intentsolutions.io/bbb/`** (landing repo
`intent-solutions-landing` PR #93 merged; source: `astro-site/src/pages/bbb/`, facts in
`src/data/bbb.mjs`). Its product
record, claims register, site map and acceptance criteria are `000-docs/029`–`035` here; change a
public claim there first, then the data module. The older `demos.intentsolutions.io/bbb/` page predates
it.

**The plugin moved out (2026-06-16).** The installable **Governed Second Brain plugin** now lives in
its own personal repo, **[`jeremylongshore/bobs-big-brain-plugin`](https://github.com/jeremylongshore/bobs-big-brain-plugin)**.
This company-org repo is the **umbrella / landing**: the thesis, the competitive teardown, and the map
that *points at* the plugin + the engines. The README is the repository entry point; the public site has its own claims register — alongside the working-surface tooling (`repos.yml` + `bin/gsb` + `bin/teamkb-systemmap.sh`)
that makes the umbrella the one place to operate the whole stack from.

**Repo map:**

| Layer | Repo | Owner |
|---|---|---|
| Umbrella / landing (this repo) | `bobs-big-brain-umbrella` | `intent-solutions-io` (company) |
| Public plugin (installable code) | `bobs-big-brain-plugin` | `jeremylongshore` (personal) |
| Engines | `bobs-big-brain-compiler` (compile; npm: `intentional-cognition-os`) · `bobs-big-brain-registrar` (govern) — renamed 2026-07-19 from `intentional-cognition-os` / `qmd-team-intent-kb` | `jeremylongshore` (personal) |

Program-level beads + the GitHub tracking issue (#1, epic `compile-then-govern-qy7`) live **here** — the
umbrella is the program tracker. Plugin build + architecture details live in the plugin repo's CLAUDE.md.

## The working surface — start here (`gsb` + the topology map)

This umbrella is the **single working surface** for the whole stack — the one place that answers
"which repo / where's the brain / where's the key" without re-deriving. Two artifacts make that real:

- **[`000-docs/007-AT-SMAP`](000-docs/007-AT-SMAP-repo-topology-and-working-surface.md)** — the
  canonical repo-topology map (Mermaid diagram + the exact local↔remote table + the doctrine).
- **[`system-graph.yml`](system-graph.yml)** — the machine-readable **dependency MODEL** (nodes +
  evidenced edges: depends-on / reads / writes / invokes / gates). `repos.yml` is the inventory;
  this is the graph. **Load it before wiring anything** — it names the owning locus for shared
  config (e.g. serving-dense lives in `qmd-adapter/src/config.ts`, nowhere else) and marks every
  manual lock-step mirror as a dotted drift-risk edge. Rendered view + editing rules:
  [`000-docs/020-AT-SMAP`](000-docs/020-AT-SMAP-system-dependency-graph.md); the
  `system-graph-sync` CI job fails any PR where doc and model drift. Before ENGINE-repo feature
  work, also check `bd list --label cross-session` in `~/000-projects` — one feature, one bead,
  one owning store (the #327/#328 duplicate was cross-store routing, not a missing map).
- **[`bin/gsb`](bin/gsb)** — cross-repo helper over [`repos.yml`](repos.yml): `gsb map` (topology +
  per-repo branch/dirty), `gsb status` (branch + dirty + ahead/behind across all), `gsb sync` (clone
  any missing sub-repo to its canonical path, `pull --rebase` the rest). Manifest + helper, **not**
  git submodules — the 4 repos stay independent (own CI / releases / visibility).
- **[`changelogs/`](changelogs/)** — an **auto-generated, pull-based mirror** of every sub-repo's
  `CHANGELOG.md` plus a rollup index (`changelogs/README.md`: table + latest-version-per-repo).
  Generated by [`scripts/aggregate-changelogs.sh`](scripts/aggregate-changelogs.sh); refreshed by the
  `.github/workflows/aggregate-changelogs.yml` workflow (weekly Mon 06:00 UTC, `workflow_dispatch`, or
  a `changelog-updated` `repository_dispatch` from any sub-repo). **Do not hand-edit** — the source of
  truth is each repo's own `CHANGELOG.md`. (The private `team-intent-claude-plugins` was an optional
  token-gated source here; it was **retired + archived 2026-07-17**, but the aggregator still attempts its token-gated historical changelog. It warn-skips only when the token or file is unavailable; retirement does not itself disable that fetch.)

**The exact local↔remote map** (4 repos + 1 live-data dir across 2 orgs; local dir name == remote
repo name for all of them — the plugin's local dir was renamed
`governed-second-brain-plugin/` → `bobs-big-brain-plugin/` on 2026-07-14 to match its remote, and
the compile/review crons + backup anchor-verify + `~/.claude.json` MCP path were repointed):

| Local dir (`~/000-projects/`) | GitHub remote | Org | Vis | Role |
|---|---|---|---|---|
| `bobs-big-brain-umbrella/` | `intent-solutions-io/bobs-big-brain-umbrella` | company | public | **umbrella (here)** |
| `bobs-big-brain-compiler/` | `jeremylongshore/bobs-big-brain-compiler` | personal | public | Compiler · compile engine (renamed 2026-07-19 from `intentional-cognition-os`; npm name + `@ico/*` scope unchanged; bead prefix stays `intentional-cognition-os`) |
| `bobs-big-brain-registrar/` | `jeremylongshore/bobs-big-brain-registrar` | personal | public | Registrar · govern engine (renamed 2026-07-19 from `qmd-team-intent-kb`; `@qmd-team-intent-kb/*` scope + GHCR image unchanged; bead prefix stays `qmd-team-intent-kb`) |
| `bobs-big-brain-plugin/` | `jeremylongshore/bobs-big-brain-plugin` | personal | public | public unified plugin (local + team modes) |
| ~~`team-intent-claude-plugins/`~~ | `intent-solutions-io/team-intent-claude-plugins` | company | private | **RETIRED + archived 2026-07-17** — was the private team marketplace (renamed from `claude-plugins` on 2026-06-24); a redirect-only catalog pointing at the public plugin, no private content. "Team" is a runtime mode of the public plugin, not a repo. |
| `~/.teamkb/` | *(not a repo)* | — | — | the live brain data (one dir; backed up by `~/bin/teamkb-backup.sh`) |

**`~/000-projects/second-brain/` is NOT part of this** — it was a dead local-only scaffold (no
remote, empty `.gitkeep` dirs) that also held a stale snapshot of the `~/000-projects/.beads/`
store. Deleted 2026-06-24 (its 7 stray `bd_000-projects-704w` beads were rescued into the canonical
store first). The brain is `~/.teamkb/`, never `second-brain/`. The adjacent
`claude-code-slack-channel` / `agent-governance-plane` / `claude-code-plugins-plus-skills` repos are a
**separate** ecosystem — not under this umbrella, not in `repos.yml`.

## Where the Code Actually Lives

This repo is just the map. Code, issues, PRs, test gates, and security reports belong in the
flagship repos:

| Repo | Layer | Role |
|------|-------|------|
| [`bobs-big-brain-compiler`](https://github.com/jeremylongshore/bobs-big-brain-compiler) | **Compile** | Local-first knowledge OS (npm: `intentional-cognition-os`). Deterministic kernel (SQLite + JSONL) + probabilistic compiler (LLM). 6 compiler passes → emits a governance spool. |
| [`bobs-big-brain-registrar`](https://github.com/jeremylongshore/bobs-big-brain-registrar) | **Govern** | Deterministic control plane. Consumes the Compiler's spool, runs dedupe → policy → promotion, hash-chained by-protocol append-only audit log. |
| [`qmd`](https://github.com/tobi/qmd) (by @tobi) | **Retrieve** | The pinned lexical BM25 arm. Govern fuses it with native FTS5 and dense sqlite-vec/EmbeddingGemma through RRF, then freshness/category reranks; every result is a `qmd://` citation. |
| [`bobs-big-brain-plugin`](https://github.com/jeremylongshore/bobs-big-brain-plugin) | **Package** | The installable Claude Code + Cowork plugin (local stdio MCP, read + write). Bundles Registrar libraries; the Compiler CLI is optional and separate. |

Per `CONTRIBUTING.md`: code/feature PRs go to the flagship repos (or the plugin repo). Only
**ecosystem-level doc fixes** (this README, the dependency map, the status table, the diagrams) belong here.

## Grounded system map, distribution & backup scope (read before guessing about data/state)

Where the brain's state actually lives, what's source-of-truth vs derived, the distribution model,
and the correct backup/DR scope are **code-verified** in
[`000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md`](000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md)
(start there — don't re-derive from scratch; also the auto-memory `governed-brain-architecture-and-backup-scope`). Key facts:

- **The whole live brain is ONE directory on the dev box (itself a VPS): `~/.teamkb/`** (~3.4 GB as
  of 2026-07-29 — don't trust a number written here; the live size + row counts auto-update in
  [`005-AT-ARCH` §0](000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md) on each backup).
  The production VPS `intentsolutions` holds **no brain** (verified). Two SQLite DBs: ICO
  `brain/.ico/state.db` (compile) + INTKB `teamkb.db` (govern). Plus `brain/raw/` (corpus = source of
  truth), `brain/wiki/` (compiled Markdown, expensive-derived), `brain/audit/` + `audit_events`
  (hash-chained receipts), `kb-export/` + `qmd-index/` (cheaply derived), `tokens.json` (a **SECRET** → SOPS).
- **Distribution — one channel now (the two-channel split is retired):** the single **public plugin**
  `jeremylongshore/bobs-big-brain-plugin` (the unified installable artifact) is the whole distribution
  surface, in two runtime modes — *local mode* (default, in-process `~/.teamkb`; the outsider showcase)
  and *team mode* (how Jeremy's team, e.g. Ope, reaches the one remote brain over the tailnet). The old
  **private team marketplace** `intent-solutions-io/team-intent-claude-plugins` (renamed from
  `claude-plugins` on 2026-06-24) was **retired + archived 2026-07-17** — it was a redirect-only catalog
  whose only entry pointed at this same public plugin, so it added indirection with no private content;
  "team" is a runtime mode, not a separate build. The old standalone `intent-brain` plugin was likewise
  folded into that team mode and retired (`650.4`).
- **Local↔team bridge — ALREADY BUILT. It is the single remote brain (ratified decision D27,
  "build-not-decide" — NOT an open architecture choice, and NOT Cloudflare R2).** There is exactly ONE
  governed brain; teammates reach it over the tailnet, they do not each run their own. Two shipped pieces:
  (1) the Registrar's **Fastify HTTP API** (`bobs-big-brain-registrar/apps/api`, scrypt-hashed per-user bearer tokens,
  tailnet-bound) — **deployed live** on the team-server (`650.5` closed); (2) the **one unified plugin**
  (`bobs-big-brain-plugin`, `650.1` closed; latest tag v1.2.0, with unreleased changes on `main`; see the dated source-versus-release register) with two runtime modes dispatched by
  `TEAMKB_API_URL`: **local** (default, in-process `~/.teamkb`) and **team** (remote proxy to the live
  brain over the tailnet with a per-user token). **Local mode exposes the six core `brain_*` tools
  in-process** (read: `brain_search` / `brain_status` / `brain_audit_verify`; write: `brain_capture` /
  `brain_govern` / `brain_transition`); **team mode registers nine tools** in
  `src/remote-server.ts`: `brain_search` / `brain_status` / `brain_capture` (member) plus admin-only
  `brain_transition` / `brain_inbox` / `brain_approve` / `brain_reject` / `brain_holds` /
  `brain_hold_recommend` (the two holds tools are unreleased past tag v1.2.0); `brain_govern` and
  `brain_audit_verify` are local-only — the team write loop shipped via plugin PR #8 (`650.2` closed 2026-06-25).
  Only the DATA + `TEAMKB_API_URL` + token are private. What's left is **publish + hardening, not
  architecture**: `650.3` (publish to the marketplaces; deferred → 2026-09-01), `650.6` (API hardening:
  token expiry/rotation, anon health probe, dedicated tailnet VM; deferred → 2026-08-15).
- **Cloudflare R2 is NOT the bridge — it is off-host BACKUP only (`c5k.6`).** The bridge is an
  authenticated, governed HTTP API (above); R2 is dumb blob storage with no auth, no governed write-path,
  no live query proxy — wrong tool for the bridge. The genuinely-deferred **distributed** model (each
  teammate runs a *local* brain that clones/pulls/**merges** into the team brain) is demand-gated EPIC 1
  (`8da`), and its substrate is **Dolt** (git-for-data: clone/pull/merge with govern-at-merge + an
  audit-readable commit graph) — also not R2. R2 touches neither the live bridge nor the future merge layer.
- **Backup/DR (`c5k.4`) — DONE: current trust-bearing scope restore-gated, restore-tested,
  off-host live.**
  `~/bin/teamkb-backup.sh` captures the full brain in one age-encrypted archive
  (`~/.teamkb/backups/teamkb-full-<UTC>.tar.zst.age`): Tier A (`teamkb.db` + `brain/.ico/state.db`,
  both quiesced via `VACUUM INTO`; `brain/raw/` + `brain/audit/` + `spool/` + `audit/` +
  `tokens.json`) + Tier B (`brain/wiki/`, `feedback/`); derived dirs skipped. Encrypted to **two**
  recipients (dev SOPS key + VPS host key); gated on a per-run restore round-trip (both DBs
  `integrity_check` + table-count + exact corpus/receipt/spool/anchor counts + restored-anchor
  verification on tmpfs). **Off-host is live:** every
  run `rsync`s the `.age` to the VPS `intentsolutions:teamkb-backups` over the tailnet with a
  `sha256` byte-match + remote retention — and the VPS can decrypt its own copy with the host key
  (`/etc/intentsolutions/age.key`), DR-loop verified end-to-end (VPS is cold storage: `age`+`zstd`
  but no `sqlite3`). Daily systemd user timer `teamkb-backup.timer` (04:30, after borg). Runbook +
  restore steps: [`000-docs/006-AT-RNBK`](000-docs/006-AT-RNBK-brain-backup-and-restore-runbook.md).
  Second off-host target — Cloudflare R2 (`c5k.6`) — **LIVE (2026-06-25)**: each run also pushes the
  `.age` to `r2-teamkb:teamkb-backups`; S3 keys in runbook `secrets.prod.sops.yaml` (`r2_teamkb_*`) +
  `rclone.conf`. R2 is **backup only** (encrypted blobs), **not** the team bridge — see the local↔team bridge bullet above.

### The agent↔brain seam (AGP) — composed at a contract, not absorbed

Intent OS is the private company control plane and source corpus; Bob's Big Brain is the compiled,
governed knowledge plane; `agent-governance-plane` (AGP) governs actions in a separate ecosystem.
AGP's signed `CrossChainPointer` (`correlation_id` + `gsb_receipt_tip_hash`, ADR 058) can bind an
action to the Bob's Brain governance-chain position returned by authenticated
`GET /api/audit/receipt-tip` (bead `qmd-team-intent-kb-1fx`). The `gsb_` prefix is the pre-rename
name frozen into the wire contract.

This is operational **chain-position proof**, not exact knowledge proof: the pointer can be resolved
against `audit_events`, but it does not identify which `qmd://` results the agent read or show that
they caused the action. Exact per-query read-set receipts remain bead `qmd-team-intent-kb-sdg`.
Never paraphrase the current seam as "what the agent knew."
Full seam doc: [`000-docs/007-AT-SMAP` §5](000-docs/007-AT-SMAP-repo-topology-and-working-surface.md).

## The Architecture Thesis (why the README says what it says)

Understanding the wording matters more than any file structure here. The whole pitch rests on
one constraint:

> **The model proposes; the deterministic system owns durable state and control.**

- **Compile, don't index** — ICO *derives* knowledge (summaries, concepts, contradictions, gaps),
  keeping raw and derived strictly separate with provenance from the first byte.
- **Govern by code, not by model** — dedupe, policy, secret-detection, trust levels, tenant
  isolation, and promotion are deterministic in INTKB's kernel. The model never writes durable
  state directly.
- **Receipts are the wedge** — the differentiator vs. the "AI memory" category is not better
  recall, it's **tamper-evident, SHA-256 hash-chained receipts** plus inline `qmd://` citations.
  The Compiler records JSONL compile traces; the Registrar records governance decisions in
  SQLite `audit_events`. These are distinct audit surfaces with distinct verifiers.

When editing the README, preserve this framing: the competitive axis is **govern + receipts**,
not recall. Don't soften "deterministic," "append-only," or "hash-chained" into vague
memory-marketing language — the precision is the point.

Keep verification scoped to the owning source contract:
[`ico audit verify`](https://github.com/jeremylongshore/bobs-big-brain-compiler/blob/main/packages/kernel/src/audit-verify.ts)
walks the Compiler's JSONL trace chain, including cross-day links and disclosed legacy boundaries.
[`brain_audit_verify`](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/main/src/local-server.ts)
checks the Registrar's SQLite governance chain and its chain-head snapshots in
[`audit/anchors.jsonl`](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/main/packages/store/src/audit-anchor.ts).
Passing one does not establish that the other passed; neither proves the content is true.
See [005-AT-ARCH, recovery playbook](000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md)
for the two-surface recovery check. These links describe source behavior, not a successful live verification.

Equally, don't *over*claim. Local chains provide integrity checks and ordering evidence, not tamper-proof
storage. A writer can edit events and re-hash the chain; retained chain-head snapshots
allow detection of a rewrite before an anchored position. The plugin's
[anchor writer](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/main/src/anchor.ts)
also commits snapshots to a local git witness, but local commit success does not prove a remote
push or an independent witness. Someone able to rewrite the store, snapshots and witness can evade
those local checks. A generic external anchor does not establish per-actor identity or non-repudiation.
Keep the README's "What the receipt does *not* do" box honest.
**Forbidden words** (never claim these): tamper-proof, immutable, non-repudiation (for local mode), blockchain.
This honesty discipline is **CI-enforced on the README** (`.github/workflows/docs-honesty.yml`);
check any brand-surface edit locally with `bash scripts/lint-forbidden-words.sh <file>`.
Bare "append-only" / "ordered log" claims are linted too — qualify them (by protocol / hash-chained / disclosed same-timestamp forks) or negate them.

## Editing Conventions

- **Mermaid + dual-theme SVG banners**: the README embeds three Mermaid diagrams with inline
  `%%{init...}%%` theme blocks, and a
  `<picture>`-switched dark/light banner. After editing a diagram, render every fenced Mermaid
  block locally with the installed `mmdc` plus the newest Playwright Chromium, then inspect GitHub's web
  rendering too (GitHub may pin a different Mermaid version):

  ```bash
  scripts/render-mermaid-blocks.py \
    README.md 000-docs/007-AT-SMAP-repo-topology-and-working-surface.md
  ```

  If Chromium is absent—or an older browser cannot render a current Mermaid diagram—install the
  current browser with `npx playwright install chromium`. The helper discovers the newest build and
  the committed Puppeteer config supplies the required no-sandbox flags. Local success proves
  parse/render viability, not visual quality or exact GitHub parity.
- **Assets are committed binaries/SVG** in `assets/`. The banner exists as both `.svg` (source of
  truth, referenced by the README) and `.png` (2x raster fallback, 2400×680); `social-card.*` is the
  1280×640 GitHub social preview. The SVGs carry live `<text>` — the product title is editable text,
  not outlined paths. Regenerate the PNGs if the SVG changes with **`rsvg-convert`** (NOT ImageMagick
  `convert`, whose internal renderer mangles the SVG fonts/gradients):
  `rsvg-convert -w 2400 -h 680 banner-dark.svg -o banner-dark.png` (social-card uses `-w 1280 -h 640`).
- **The thesis doc is meant to match across repos but currently does not**: *"Compile, Then Govern"*
  lives at `000-docs/034-AT-NTRP-ecosystem-thesis.md` in **both** flagships (not in this repo). As of
  2026-10-25 the two copies differ in 7 hunks and the registrar copy still uses a word the trust model forbids
  (consistency audit; bead compile-then-govern-eqw.6). Use current owning code for capability claims; treat both thesis copies as historical analysis, not interchangeable current specifications.
- **Status table** (versions / licenses near the bottom of the README) drifts as the flagships
  release. Verify against the actual repo tags before changing version numbers.
- **[`AGENTS.md`](AGENTS.md)** is the concise contributor guide (scope boundary, validation,
  review flow) for non-Claude agents and outside contributors — keep it consistent with this file
  when either changes.


## Retrieval backend decision (2026-06-18; shipped status updated 2026-08-04)

The phased decision completed: qmd BM25 shipped first, measurement crossed the semantic-recall
gate, and Govern now fuses qmd BM25 + native FTS5 + a lean sqlite-vec/EmbeddingGemma-300M dense arm
through RRF (k=60), followed by freshness/category reranking. Dense is production-default across
the API, edge daemon, MCP server, CLI, and plugin local mode (registrar PRs #328/#334, merged as
`46f6bf5`/`861ecc7` and confirmed on `origin/main` `628c225`; plugin PR #60, merged as `f684448`
and confirmed on `origin/main` `dae88b5`, all verified 2026-08-17); it fails open to lexical
retrieval if the embedder is unavailable. The heavier qmd hybrid and stale NEXUS RAG stack remain
rejected. Serving uses no query-time generative LLM.

**Delivered foundation** (epic `qmd-team-intent-kb-0t9`, all in the INTKB `qmd-adapter` package):

- `0t9.5` — owned qmd runtime artifacts and semantic weights have **SHA-256 verification contracts**; legacy executable discovery is only version-checked
  (`packages/qmd-adapter/src/weights`). Non-negotiable before any semantic path: a
  govern-by-receipts brand can't ship an unverified retrieval brain.
- `0t9.6` — a Recall@10 / nDCG@10 **eval harness** (`packages/qmd-adapter/src/eval`),
  backend-agnostic, carrying the ADR's `0.85` BM25-sufficiency gate.
- `0t9.2` — a **native FTS5 (BM25) backend** (`packages/qmd-adapter/src/native`), model-free,
  in-process, dropping the external Bun binary for keyword search.
- `0t9.3` — the lean **sqlite-vec + EmbeddingGemma-300M dense path**, now shipped after the eval
  and observed-recall gates were met; `TEAMKB_DENSE_ENABLED=false` is the emergency kill switch.

Canonical record: `bobs-big-brain-registrar/000-docs/038-AT-DECR`. Tracked in epic
`qmd-team-intent-kb-0t9` (the bead prefix keeps the pre-rename name;
GH `jeremylongshore/bobs-big-brain-registrar#170` / Plane INTKB-7);
`compile-then-govern-qy7.13` folds in.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
