# teamkb-compile — nightly "compile the day's work into the governed brain"

This directory is the **reviewed source of truth** for the `/teamkb-compile` skill. It is **deployed**
to its runtime locations (it does not run from here):

| Source (this repo) | Runtime (deployed) | Why |
|---|---|---|
| `.claude/skills/teamkb-compile/` | `~/.claude/skills/teamkb-compile/` | Global skill so the nightly cron (`claude -p "/teamkb-compile"`) resolves it from any cwd. |
| `bin/teamkb-compile-daily.sh` | `~/bin/teamkb-compile-daily.sh` | Cron wrapper (crontab `30 3 * * *`). |

Deploy after review/merge: `bin/deploy-teamkb-compile.sh` (rsyncs source → runtime, preserving the
runtime-local `methodology/decisions.jsonl` audit log).

## What it does

Gathers the day's work signals (git commits, merged PRs, closed beads, `AT-DECR` decision records,
Claude session transcripts across `~/000-projects`) → Claude **compiles** them into durable
governed-memory candidates → the deterministic **govern** path (`brain_capture` → `brain_govern`:
dedupe / policy / secret-scan / promotion) writes each with a SHA-256 hash-chained receipt. *The model
proposes; deterministic code disposes.* Ships **digest-first** and **auto-graduates itself** to
auto-promote after a clean-night soak — no manual flip. Full design: [`SKILL.md`](SKILL.md) +
[`references/`](references/).

## Why it runs locally (not a cloud Routine)

Claude Routines run in Anthropic's cloud, which cannot reach the tailnet-bound brain API / local
`~/.teamkb`. So it runs locally via the cron wrapper — the `/blog-backfill` headless-`claude -p` pattern.

## Runtime-only (NOT committed)

`methodology/decisions.jsonl` is committed **empty** — the real audit log accumulates at the runtime copy
(`~/.claude/skills/teamkb-compile/methodology/decisions.jsonl`) and holds internal distilled candidates,
so it stays out of this public repo.
