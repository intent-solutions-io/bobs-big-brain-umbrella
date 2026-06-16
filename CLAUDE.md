# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

The **umbrella / landing repo** for **Governed Second Brain** — the local-first knowledge stack
built on the *compile, then govern* architecture. (Renamed from `compile-then-govern` on
2026-06-16; the GitHub repo is now `intent-solutions-io/governed-second-brain` and the old URL
auto-redirects. The local working directory is still `compile-then-govern/`.) It contains
ecosystem-level documentation only — **no application code, no build, no tests, no lint.** The
entire repo is `README.md` plus a handful of governance files (`CONTRIBUTING.md`, `SECURITY.md`,
`LICENSE`) and `assets/` (banner + social-card SVG/PNG). `.github/` is intentionally empty (CI
badges in the README point at the flagship repos' workflows, not this one).

The single deliverable here is the README: it explains what the components are, how they stack,
and why the architecture beats vector stores / agent-memory layers. Treat the README as the
product.

## Where the Code Actually Lives

This repo is just the map. Code, issues, PRs, test gates, and security reports belong in the
flagship repos:

| Repo | Layer | Role |
|------|-------|------|
| [`intentional-cognition-os`](https://github.com/jeremylongshore/intentional-cognition-os) (ICO) | **Compile** | Local-first knowledge OS. Deterministic kernel (SQLite + JSONL) + probabilistic compiler (Claude). 6 compiler passes → emits a governance spool. |
| [`qmd-team-intent-kb`](https://github.com/jeremylongshore/qmd-team-intent-kb) (INTKB) | **Govern** | Deterministic control plane. Consumes ICO's spool, runs dedupe → policy → promotion, append-only audit log. |
| [`qmd`](https://github.com/tobi/qmd) (by @tobi) | **Retrieve** | On-device hybrid search (BM25 + vector + LLM rerank). Pinned upstream dependency; every result is a `qmd://` citation. |

Per `CONTRIBUTING.md`: code/feature PRs go to the flagship repos. Only **ecosystem-level doc
fixes** (this README, the dependency map, the status table, the diagrams) belong here.

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
  recall, it's a **tamper-evident, SHA-256 hash-chained audit trail** (`prev_hash` per JSONL
  event) plus inline `qmd://` citations, verifiable after the fact via `ico audit verify`.

When editing the README, preserve this framing: the competitive axis is **govern + receipts**,
not recall. Don't soften "deterministic," "append-only," or "hash-chained" into vague
memory-marketing language — the precision is the point.

Equally, don't *over*claim. The chain is tamper-**evident** (detection of edits/reordering),
**not** tamper-proof: a local writer with write access can edit an event *and* re-hash the chain
forward, and `ico audit verify` passes again. So the README carries a "What the receipt does
*not* do" trust-model box — local = integrity + ordering; cross-actor non-repudiation needs the
external chain-head anchor (sign via `git-exporter` / OpenTimestamps), which is on the roadmap and
gated before any cross-actor "tamper-evident" claim. Keep that box honest. **Forbidden words:**
tamper-proof, immutable, non-repudiation (for local mode), blockchain.

## Editing Conventions

- **Mermaid + dual-theme SVG banners**: the README embeds two Mermaid diagrams (a sequence flow
  and an architecture flowchart) with inline `%%{init...}%%` theme blocks, and a
  `<picture>`-switched dark/light banner. After editing either, verify rendering on the GitHub
  web view — there is no local preview build.
- **Assets are committed binaries/SVG** in `assets/`. The banner exists as both `.svg` (source of
  truth, referenced by the README) and `.png` (2x raster fallback, 2400×680); `social-card.*` is the
  1280×640 GitHub social preview. The SVGs carry live `<text>` — the product title is editable text,
  not outlined paths. Regenerate the PNGs if the SVG changes with **`rsvg-convert`** (NOT ImageMagick
  `convert`, whose internal renderer mangles the SVG fonts/gradients):
  `rsvg-convert -w 2400 -h 680 banner-dark.svg -o banner-dark.png` (social-card uses `-w 1280 -h 640`).
- **The thesis doc is byte-identical across repos**: *"Compile, Then Govern"* lives at
  `000-docs/034-AT-NTRP-ecosystem-thesis.md` in **both** flagships (not in this repo). If a claim
  in this README is sourced from it, keep them consistent.
- **Status table** (versions / licenses near the bottom of the README) drifts as the flagships
  release. Verify against the actual repo tags before changing version numbers.


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
