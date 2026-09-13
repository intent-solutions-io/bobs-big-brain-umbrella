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

```bash
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
| `TEAMKB_COMPILE_TIMEOUT` | `1800` | Compile-model phase timeout in seconds, followed by a 10-second termination grace. |
| `TEAMKB_COMPILE_RUN_TIMEOUT` | `3000` | Whole-date deadline including review, audit and notification work; 10-second termination grace and at most 1 second of child reap bookkeeping follow. |
| `TEAMKB_COMPILE_MAX_DATES` | `3` | Maximum dates per dispatcher invocation (1–7); pending dates persist across invocations. |
| `TEAMKB_COMPILE_MAX_TRANSCRIPT_LINES` | `5000` | Transcript cap in the gather doc (truncation is logged). |
| `TEAMKB_COMPILE_PROJECTS_ROOT` | `/home/jeremy/000-projects` | Repo root to scan. |

## Operations

- **Logs:** `~/.local/state/teamkb-compile-daily/run-<DATE>.log` (per run) + `cron.log` (crontab stdout).
- **Manual backfill of a missed night:** `TEAMKB_COMPILE_DATE=2026-06-27 ~/bin/teamkb-compile-daily.sh`.
- **Idempotent:** a second run skips only when the date/mode decision has a matching independent
  verification receipt. A valid historical decision without that receipt is verified read-only
  before adoption; a changed previously verified decision fails visibly without recertifying it.
- **Notifications:** email (full digest) + ntfy topic from `~/.ntfy-topic` (status only). 3+ consecutive
  failures escalate to max priority — catches a silent multi-day stall.

## September 2026 reliability correction

The umbrella entry verifies a commit-addressed compiler bundle under
`~/.local/lib/teamkb-compile/current`; it no longer embeds a second runner or executes a mutable
source checkout. The compiler defaults to the already configured MiniMax Anthropic-compatible
Claude path, with the key read from `~/.config/intentsolutions/api-providers.sops.json` in memory.
Missing authentication fails visibly without changing provider. The nightly C8 MCP boundary checks
actual capture proposals before the native spool; the native govern kernel remains authoritative.

A clean agent exit is insufficient: the date needs a complete governed outcome, a refreshed index,
and independent live audit verification. Invalid old records remain in the methodology history (append-only by protocol) and
do not suppress retries. No-activity dates still produce a zero-candidate audit record and digest.

The dispatcher initially examines seven days and persists pending dates before work begins.
Persisted misses survive longer outages. Each nightly invocation handles at most three dates
(`TEAMKB_COMPILE_MAX_DATES`, 1–7), current date first; an explicit `TEAMKB_COMPILE_DATE` runs only
that day. `pending-dates.json` and `verified-YYYY-MM-DD.json` expose backlog and successful proof.

Deploy after both owning PRs merge with
`TEAMKB_COMPILER_REVISION=<full-reviewed-commit-sha> bin/deploy-teamkb-compile.sh --compile-only`.
An omitted SHA or mutable ref is rejected before any installation. Fetch the compiler remote
before selecting the reviewed SHA; the installer also requires it to belong to `origin/main`. The option
preserves backup/quality script versions and the runtime methodology log. Previous bundles remain
under `~/.local/lib/teamkb-compile/releases/`; `previous` records the earlier active bundle.
Rollback repoints `current` atomically to that retained, verified bundle; do not restore or rewrite
brain data or methodology history. The first migration also backs up the previous entry script.

The compiler behavior and original lock-independence regression are owned by
[compiler PR 213](https://github.com/jeremylongshore/bobs-big-brain-compiler/pull/213).
Its `Test` CI job executes `scripts/distiller/test_nightly_compile.py`, including
`test_compile_lock_never_takes_brain_writer_lock`; the
[reviewed implementation and test](https://github.com/jeremylongshore/bobs-big-brain-compiler/tree/dbc2125b075bc82c4f8225b8df9142adca81da56/scripts/distiller)
passed [CI run 34779530820](https://github.com/jeremylongshore/bobs-big-brain-compiler/actions/runs/34779530820).
The umbrella retains installation tooling and its installed-entry/rollback tests; moving the
actual runner and lock test together removes the duplicate implementation that drifted.

## Verified deployment and recovery — 2026-09-13

The installed compiler is
[`1a6a5f474c64b3c6edc3790e9da261030bc0ad6a`](https://github.com/jeremylongshore/bobs-big-brain-compiler/commit/1a6a5f474c64b3c6edc3790e9da261030bc0ad6a)
([PR 214](https://github.com/jeremylongshore/bobs-big-brain-compiler/pull/214)); the installer is
[`1e8b512db5f2b03b4b835c791665df5a9a62b3c0`](https://github.com/intent-solutions-io/bobs-big-brain-umbrella/commit/1e8b512db5f2b03b4b835c791665df5a9a62b3c0)
([PR 95](https://github.com/intent-solutions-io/bobs-big-brain-umbrella/pull/95)). The final bundle
was deployed at **20:41:37.446374 UTC**, with all five payload hashes verified. The wrapper,
backup/quality scripts, review skill and methodology history were unchanged by that upgrade.
The initial migration separately preserved the old wrapper and runtime skill archive.

| Target date | Actual completion UTC | Proposals | Promoted | Independent audit |
|---|---|---:|---:|---|
| 2026-09-08 | 20:24:50.603629 | 7 | 7 | Passed |
| 2026-09-09 | 20:29:24.739614 | 2 | 1 | Passed |
| 2026-09-10 | 20:33:53.754716 | 2 | 2 | Passed |
| 2026-09-11 | 20:36:11.645625 | 2 | 2 | Passed |
| 2026-09-12 | 20:39:48.053109 | 2 | 2 | Passed |

All completions above occurred on September 13 under the first repaired bundle
`723d243cd1478b03876675dc3158f1ce5b0d570b`. Native govern also processed an older held inbox;
its rejection/flag counts were retained separately instead of attributed to the new proposals.
Each date refreshed the index. The independent audit ended at 25,132 events and 783 anchors,
with zero tamper signatures or anchor breaks; the 155 previously known chain forks were unchanged.
All 14 promoted memories were retrieved from the correct tenant index. The September 11
methodology row omitted its two citations, so those two were independently located in curated
storage and retrieved by their indexed export paths; the old row was preserved.

The existing mail sender recorded SMTP acceptance and a Sent-folder copy for all five summaries.
This proves transport acceptance, not that the recipient read the messages. No separate manual
recap was sent. Exact delivery IDs and private corpus remain in the private incident evidence.

The final installed bundle's default dispatcher passed at **20:42:04.218685 UTC** with zero
pending dates. It adopted already-valid September 6/7 decisions through independent read-only
verification without recapture. At **20:42:54.651914 UTC**, explicit duplicate runs for all five
recovered dates returned success without model calls, email sends or methodology changes.

The deployment host schedules `30 3 * * *` in fixed **CST / UTC−06:00**, hence **09:30 UTC daily**.
Its persisted mode is `auto` and provider is MiniMax-M3 via the configured Claude API path.
Three dates allow 9,030 seconds of run/termination budget plus up to three seconds of child reap
bookkeeping and local dispatch I/O; the operational monitor may allow 9,300 seconds. This does
not shorten the native writer lock or bypass governance. The next scheduled night has **not yet
been observed**; durable pending state, verified-date receipts, failure exits and `.beat`/`.ok`
markers remain the ongoing detection signals.

Validation includes 24 hermetic process tests in the
[compiler CI run](https://github.com/jeremylongshore/bobs-big-brain-compiler/actions/runs/34781388936),
with the existing 131 TypeScript test files and required CodeQL/lint/type/coverage gates passing;
9 installer tests passed in the
[umbrella CI run](https://github.com/intent-solutions-io/bobs-big-brain-umbrella/actions/runs/34780202733).
An isolated replay also exercised the **actually installed** deadline code against stubborn
nested-session and earlier-orphan fixtures, proving child termination and lock release.
Three original regressions failed against the old runner; the later orphan regression also failed
against its prior implementation before the correction. All fixture processes were reaped.

Private operator evidence is under
`~/.local/state/intent-os/alert-review/20260913T193100Z/teamkb/`: `deadline-actual-deploy.json`,
`recovery-YYYY-MM-DD.json`, `brain-audit-after.json`,
`recovery-governance-delivery-retrieval.json`, `actual-default-dispatch.json`,
`actual-duplicate-replay.json`, and `installed-deadline-replay.log`. These are local receipts,
not publicly accessible links. Mail bodies and memory content are intentionally not published.

### Rollback without rewriting brain data

Confirm no compile owns the lock, then atomically select the retained previous verified bundle:

```bash
python3 - <<'PY_ROLLBACK'
from pathlib import Path
import os, uuid
root = Path.home() / '.local/lib/teamkb-compile'
previous = (root / 'previous').resolve(strict=True)
link = root / ('.rollback-' + uuid.uuid4().hex)
link.symlink_to(previous)
os.replace(link, root / 'current')
PY_ROLLBACK
```

At this deployment, `previous` is `723d243cd1478b03876675dc3158f1ce5b0d570b`; the installed
entry verifies its manifest before execution. Preserve `pending-dates.json`, all verification
receipts, methodology history and the brain database. The first-migration artifacts are
`~/.local/state/teamkb-compile-daily/wrapper-before-20260913T201710Z.sh` and
`deploy-20260913T201709Z.rEFUeP3N/compile-skill-before.tar.gz`; restoring that older Claude-only
wrapper also restores its known authentication problem, so the retained repaired bundle is the
normal rollback target.
