<!-- fetched by CI — DO NOT HAND-EDIT. Source of truth: the repo's own CHANGELOG.md. -->
<!-- source: https://raw.githubusercontent.com/intent-solutions-io/team-intent-claude-plugins/main/CHANGELOG.md -->
<!-- fetched-at: 2026-07-18T13:46:24Z -->

# Changelog

All notable changes to this **private Intent Solutions plugin catalog** are documented here.
This is the internal team marketplace (`intent-solutions-io/team-intent-claude-plugins`); the
plugins it lists carry their own changelogs in their own repos. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this catalog adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- This `CHANGELOG.md` — the catalog was previously untracked in a changelog; seeded from history.

### Changed

- **Unified `governed-second-brain` plugin published to the catalog** (marketplace `v0.2.0`); it
  supersedes the standalone `intent-brain` entry — one plugin, two runtime modes (local by default;
  team when `TEAMKB_API_URL` is set). `/brain` reads, `/brain-save` proposes, with per-user audit
  over the tailnet.
- README: setup instructions for **team mode** — point the plugin at the one brain over Tailscale
  (`TEAMKB_API_URL` + a personal `TEAMKB_API_TOKEN`), read-and-propose for everyone, admin-only
  lifecycle changes.

### Removed

- The standalone `intent-brain` catalog entry — retired and folded into the unified
  `governed-second-brain` plugin's **team mode**.

## [2026-06-21] — Source-shape fix

### Fixed

- Converted the `intent-brain` plugin `source` to object form so the catalog resolves the plugin
  from its own repo.

## [2026-06-14] — Genesis

### Added

- Initial private Intent Solutions plugin catalog (`marketplace.json` + README) — add once with
  `/plugin marketplace add intent-solutions-io/team-intent-claude-plugins`; new internal tools land
  here as catalog entries. First entry: `intent-brain`.
