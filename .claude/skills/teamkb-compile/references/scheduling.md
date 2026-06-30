# Scheduling — local cron, not a cloud routine

## Why local

Claude **Routines** (`/schedule`) run in **Anthropic's cloud**, which **cannot reach** this brain:

- The team brain API binds the **tailnet-only** IP (`TEAMKB_API_HOST=100.109.119.103`).
- The brain *data* is local: `~/.teamkb` on the box that owns it.

A cloud routine is therefore blocked. (`/blog-backfill` *can* be cloud-scheduled because its output is a
`git push` — cloud-reachable; the brain's output is a local SQLite write — not.) So `/teamkb-compile`
runs **locally**, via a cron wrapper that fires `claude -p "/teamkb-compile"` on the box with the brain +
repos + tailnet — the exact headless-`claude -p` pattern `/blog-backfill` uses in production.

## The wrapper

`~/bin/teamkb-compile-daily.sh` — self-contained: pty-wrapped headless `claude -p`, hard timeout,
fail-loud `EXIT` trap, idempotency (skips if an audit record for the date already exists), ntfy + email
delivery of the digest, and consecutive-failure escalation. It passes the brain MCP explicitly:

```
claude -p '/teamkb-compile <DATE> <NEXT> --<mode>' \
  --mcp-config ~/.claude/skills/teamkb-compile/scripts/brain-mcp-config.json \
  --strict-mcp-config --dangerously-skip-permissions
```

`--strict-mcp-config` loads **only** the `governed-brain` server in **local mode** (in-process
`~/.teamkb`) — required because the plugin is **not** in `enabledPlugins`, so a bare `claude -p` would
have no `brain_*` tools.

## The crontab entry

Nightly **03:30 local**, before the **04:30** `teamkb-backup.timer`, so the night's new memories land in
that night's backup. **No mode env var** — the wrapper self-manages its mode (see below):

```cron
30 3 * * * /home/jeremy/bin/teamkb-compile-daily.sh >> /home/jeremy/.local/state/teamkb-compile-daily/cron.log 2>&1
```

## Self-managing rollout — digest-first, AUTO-GRADUATES (no manual flip)

The wrapper owns its own rollout — *"I don't want to manage anything, the computer and AI should."*
Nobody flips a switch:

1. It starts in **`digest`** mode (no durable writes — emails "here's what I'd capture").
2. It counts **clean digest nights** (each clean digest run banks one, recorded in `decisions.jsonl`).
3. After **`SOAK_NIGHTS`** (default **3**) clean digest nights, it **graduates itself to `auto`**,
   persists that decision to a state file, and emails/ntfys a 🎓 graduation notice. From then on it
   auto-promotes nightly.

**Mode resolution order** (the wrapper, each run):

| Precedence | Source | Use |
|---|---|---|
| 1 | `TEAMKB_COMPILE_MODE` env | Explicit override — escape hatch to force a mode or revert (`=digest`). |
| 2 | State file `~/.local/state/teamkb-compile-daily/mode` | The persisted, self-managed mode (`digest` → `auto`, one-way). |
| 3 | default | `digest` (seeds the state file). |

Graduation is **one-way** and **skipped under an explicit env override** (so a manual `=digest` always
wins). To **revert** after graduation: `echo digest > ~/.local/state/teamkb-compile-daily/mode` (it will
re-graduate after the soak again) — or set `TEAMKB_COMPILE_MODE=digest` in the crontab to pin it.
**Test the rollout logic without a full run:** `TEAMKB_COMPILE_DRYRUN=1 ~/bin/teamkb-compile-daily.sh`.

## Knobs (env, overridable in the crontab line)

| Var | Default | Effect |
|---|---|---|
| `TEAMKB_COMPILE_MODE` | *(unset)* | Explicit override: `digest` (no writes) or `auto` (capture→govern). Unset = self-managed via the state file. |
| `TEAMKB_COMPILE_SOAK_NIGHTS` | `3` | Clean digest nights before the wrapper auto-graduates itself to `auto`. |
| `TEAMKB_COMPILE_DRYRUN` | *(unset)* | Resolve mode + graduation, log the decision, then exit (no claude, no writes) — for testing. |
| `TEAMKB_COMPILE_DATE` | yesterday | Target day (`YYYY-MM-DD`) — for manual backfill of a missed night. |
| `TEAMKB_COMPILE_TIMEOUT` | `1800` | Hard wall-clock ceiling (seconds). |
| `TEAMKB_COMPILE_MAX_TRANSCRIPT_LINES` | `5000` | Transcript cap in the gather doc (truncation is logged). |
| `TEAMKB_COMPILE_PROJECTS_ROOT` | `/home/jeremy/000-projects` | Repo root to scan. |

## Operations

- **Logs:** `~/.local/state/teamkb-compile-daily/run-<DATE>.log` (per run) + `cron.log` (crontab stdout).
- **Manual backfill of a missed night:** `TEAMKB_COMPILE_DATE=2026-06-27 ~/bin/teamkb-compile-daily.sh`.
- **Idempotent:** a second run for a date that already has an audit record is a clean no-op.
- **Notifications:** email (full digest) + ntfy topic from `~/.ntfy-topic` (status only). 3+ consecutive
  failures escalate to max priority — catches a silent multi-day stall.
