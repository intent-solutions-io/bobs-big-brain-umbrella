<!-- fetched by CI — DO NOT HAND-EDIT. Source of truth: the repo's own CHANGELOG.md. -->
<!-- source: https://raw.githubusercontent.com/intent-solutions-io/governed-second-brain/main/CHANGELOG.md -->
<!-- fetched-at: 2026-07-18T13:42:03Z -->

# Changelog

All notable changes to the **Bob's Big Brain** umbrella are documented here.
This is the umbrella / landing repo (the thesis, the competitive teardown, and the
map to the plugin + engines) — application code and its own changelogs live in the
engine and plugin repos. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2026-07-16] — Bob's Big Brain rename, contributor surface & changelog automation

### Added

- `AGENTS.md` — a concise, repo-specific contributor guide (scope boundary,
  working-surface commands, trust-model language, Beads workflow), replacing the
  duplicated generic boilerplate; rode with CLAUDE.md currency fixes (product
  name, repo map, team-mode write tools, honesty-lint documentation). (#52)
- **Push-based changelog aggregation**: all four sub-repos now send a
  `changelog-updated` `repository_dispatch` to this repo when a merged PR touches
  their `CHANGELOG.md`, so `changelogs/` refreshes within minutes instead of
  waiting for the weekly cron. Sender workflows: ICO #155, INTKB #250, plugin
  #46, team marketplace #5; the receiver shipped earlier as #29.
- "Powered by [tobi/qmd](https://github.com/tobi/qmd)" credit and the `bbb-qmd`
  operator tip in the README. (#50)
- `.greptile` review config for the umbrella. (#38)

### Changed

- **Public product name renamed to "Bob's Big Brain"** across the README, banner,
  and social card. (#37)
- **Repos renamed to match the product**: `governed-second-brain` →
  `bobs-big-brain-umbrella` (#49) and the plugin repo →
  `bobs-big-brain-plugin` (references canonicalized in #46, local dir matched in
  #48). Old GitHub URLs auto-redirect; local dirs now equal remote names.

## [2026-07-13] — Capture pipeline & proof tracks

### Added

- **Agent-reviewed capture inbox**: decision record `014-AT-DECR`, the nightly
  review agent, and the digest. (#39)
- Team auto-capture buy-in + rollout runbook `015-AT-RNBK`. (#40)
- The backup now re-verifies the restored external anchor against the restored
  chain (not just presence). (#43)

### Changed

- Honesty lint: bare "append-only" / "ordered log" claims fail the gate unless qualified (by protocol / hash-chained / disclosed same-timestamp forks) or negated. (#44)
- The three drifted teamkb runtime scripts deduped to one source of truth. (#42)

### Fixed

- `teamkb-backup` records the `.ok` success marker again, restoring the
  two-marker liveness doctrine. (#45)

## [2026-06-30] — Working surface, honesty gates & nightly compile

### Added

- **The umbrella as the single working surface**: topology map `007-AT-SMAP`,
  the `bin/gsb` cross-repo helper over `repos.yml`, and self-updating live
  stats in `005-AT-ARCH` §0. (#14)
- Pull-based cross-repo CHANGELOG aggregation (`changelogs/` mirror +
  `scripts/aggregate-changelogs.sh` + the weekly workflow). (#29)
- Nightly `teamkb-compile` job that compiles the day's work into the governed
  brain (#25) and a govern-quality drift canary for the nightly loop (#34).
- **Forbidden-words honesty doc-lint + CI gate**
  (`scripts/lint-forbidden-words.sh`, per ISEDC decision D1). (#33)
- Wiki-Memory category competitive teardown + canon review + ISEDC decision
  record (#28); e06 adopt-list gap analysis + risk assessment `010-AT-RISK` (#30).
- Grounded system map `005-AT-ARCH` + full-brain backup/DR runbook
  `006-AT-RNBK` (#12); the external anchor log captured in backup Tier A with
  restore gated on it (#31).
- EPIC 1 decision record + govern-at-merge system map (#10);
  Dolt-as-substrate + distributed-remote exploration (#7).

### Changed

- Clarified in the docs: the local↔team bridge is the **single remote brain**
  (ratified D27); Cloudflare R2 is off-host **backup only**, not the bridge. (#13)

### Fixed

- All `~/.teamkb` writers serialized under one flock, closing the concurrent-
  writer corruption window. (#32)

## [2026-06-18] — Scaffolding & the retrieval decision

### Added

- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) and this `CHANGELOG.md`. (#4)
- Retrieval-backend decision recorded in repo guidance: ship BM25-on-qmd now →
  eval-gate a lean native sqlite-vec path on EmbeddingGemma-300M; skip qmd's heavy
  hybrid; pin the model weights. Canonical ADR in INTKB `038-AT-DECR`, tracked in
  epic `qmd-team-intent-kb-0t9`. (#2)

### Changed

- Status table: the installable plugin pinned to **v0.1.6** (#3); ICO **v1.14.0**;
  the plugin row added (npm + SLSA provenance); `qmd-team-intent-kb` pinned to
  **v0.7.0** (was v0.6.0). (#6)
- CLAUDE.md trust-model guidance: the external chain-head anchor described as
  **implemented** (verifiable via `ico audit verify`) rather than "on the
  roadmap". (#5, #6)

## [2026-06-16] — Productization

### Added

- Full product landing README — competitive teardown, dual-theme Mermaid diagrams
  (sequence + architecture), the receipts/audit thesis, and getting-started.
- Dark/light SVG banner (editable `<text>`), 2× PNG renders (2400×680), and a
  1280×640 social card.
- `CLAUDE.md` repo guidance — thesis framing, audit-honesty rules, editing
  conventions.

### Changed

- Repo renamed `intent-solutions-io/compile-then-govern` →
  `intent-solutions-io/governed-second-brain` (renamed again to
  `bobs-big-brain-umbrella` on 2026-07-14 — see above; all old URLs
  auto-redirect).
- Audit trail framed as **tamper-evident** (detection), never tamper-proof; the
  external chain-head anchor is implemented and verifiable via `ico audit verify`.

## [2026-06-01] — Genesis

### Added

- Initial *Compile-Then-Govern* ecosystem landing: the "compile, then govern"
  thesis, the dependency map (ICO · INTKB · qmd), and governance files
  (`CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`).
