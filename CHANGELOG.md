# Changelog

All notable changes to the **Governed Second Brain** umbrella are documented here.
This is the umbrella / landing repo (the thesis, the competitive teardown, and the
map to the plugin + engines) — application code and its own changelogs live in the
engine and plugin repos. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1) and this `CHANGELOG.md`.
- Retrieval-backend decision recorded in repo guidance: ship BM25-on-qmd now →
  eval-gate a lean native sqlite-vec path on EmbeddingGemma-300M; skip qmd's heavy
  hybrid; pin the model weights. Canonical ADR in INTKB `038-AT-DECR`, tracked in
  epic `qmd-team-intent-kb-0t9`. (#2)

### Changed

- Status table: the installable plugin is pinned to **v0.1.6** (#3); ICO **v1.14.0**;
  the plugin row added (npm + SLSA provenance).
- Status table: `qmd-team-intent-kb` pinned to **v0.7.0** (was v0.6.0).
- CLAUDE.md trust-model guidance: the external chain-head anchor is now described as
  **implemented** (verifiable via `ico audit verify`) rather than "on the roadmap".

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
  `intent-solutions-io/bobs-big-brain-umbrella` (the old URL auto-redirects).
- Audit trail framed as **tamper-evident** (detection), never tamper-proof; the
  external chain-head anchor is implemented and verifiable via `ico audit verify`.

## [2026-06-01] — Genesis

### Added

- Initial *Compile-Then-Govern* ecosystem landing: the "compile, then govern"
  thesis, the dependency map (ICO · INTKB · qmd), and governance files
  (`CONTRIBUTING.md`, `SECURITY.md`, `LICENSE`).
