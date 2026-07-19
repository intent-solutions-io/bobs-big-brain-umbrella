# Repository Guidelines

## Scope and Structure

This repository is the documentation-first umbrella for Bob's Big Brain. It
contains the public product narrative and cross-repository working surface; it
does not contain application code. Keep implementation, runtime configuration,
and code-level security work in the owning repository:

- `bobs-big-brain-compiler` (npm: `intentional-cognition-os`) compiles source material into a spool.
- `bobs-big-brain-registrar` deterministically governs that spool.
- `bobs-big-brain-plugin` packages the local and team experiences.

At the root, `README.md` is the landing page, `000-docs/` holds architecture,
decision, risk, and runbook documents, and `assets/` holds committed banners
and social cards. `repos.yml` is the topology source of truth; `bin/gsb` reads
it to operate across the independent repositories. `changelogs/` is generated
from each repository's `CHANGELOG.md` and must not be edited by hand.

## Working Locally

Run `./bin/gsb map` to orient yourself, `./bin/gsb status` for cross-repo
state, and `./bin/gsb sync` only when you intend to clone or pull every mapped
repository. This repo has no application build or unit-test suite. Validate
brand-surface changes with:

```bash
bash scripts/lint-forbidden-words.sh <changed-file.md>   # e.g. README.md
```

CI enforces this lint on `README.md`; run it locally on any brand-surface
markdown you touch.

Run `bash scripts/aggregate-changelogs.sh` only when refreshing derived
changelogs; it needs network access and an optional private-repository token.
For code changes, run the tests and quality gates in the owning engine or
plugin repository instead.

## Documentation and Style

Use concise Markdown, sentence-case headings, descriptive links, and existing
`NNN-XX-CODE-topic.md` names under `000-docs/`. Preserve generated markers in
`000-docs/005-AT-ARCH-...` and never hand-edit `changelogs/`. Verify Mermaid
or banner changes on GitHub's rendered view.

Keep the trust model precise: the audit trail is **tamper-evident**—local mode
provides integrity, ordering, and rewrite detection. Never describe local mode as tamper-proof, immutable, a blockchain, or non-repudiable.

## Issues, Commits, and Pull Requests

Use Beads for every task: run `bd prime`, create or claim work with `bd`, and
close it when complete. The Dolt database is authoritative; do not treat
`.beads/issues.jsonl` as a sync mechanism. Use conventional commits such as
`docs(topology): clarify plugin ownership`. Keep pull requests focused; for a
docs-only change, state **What**, **Why**, and the linked Bead or issue. Include
rendering evidence for visual changes and follow the session-close protocol
from `bd prime` for changed work.
