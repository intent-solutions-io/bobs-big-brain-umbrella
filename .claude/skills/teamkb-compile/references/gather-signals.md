# Gather the day's work signals

The gather phase turns "what happened today" into **one structured signal doc** that the distiller
reads. It reuses `/blog-backfill`'s gather-material pattern, scoped to the governed brain instead of a
blog post.

Run the helper (it writes nothing durable — pure read):

```bash
mkdir -p /tmp/teamkb-compile
SIGNALS="/tmp/teamkb-compile/signals-$DATE.txt"
${CLAUDE_SKILL_DIR}/scripts/gather-signals.sh "$DATE" "$NEXT_DATE" > "$SIGNALS"
wc -l "$SIGNALS"
```

## What it collects (across `~/000-projects`, for the window)

| Source | How | Why it matters |
|---|---|---|
| **Git commits** | `git log --all --since-as-filter --until`, filtered to the exclusive end, per repo | The skeleton of the day. Commit **bodies** carry rationale, not just subjects. |
| **Merged PRs** | `gh pr list --repo <slug> --state merged --search "merged:DATE..NEXT"` | Richest signal — PR bodies hold before/after tables, decisions, and review outcomes. |
| **Closed beads** | `bd list -C <repo> --status closed --closed-after --closed-before` (per-repo + umbrella store) | The close **reason** is a one-line distilled lesson already. |
| **Decision records** | Changed decision paths at the selected commits, with the first 25 lines of each committed blob | Preserves branch-only records and revisions with commit provenance; verify approval before treating a branch proposal as ratified. |
| **Session transcripts** | `scan-session-transcripts.py --start --end` | Rationale, false starts, gotchas, and user intent that commits never record. |

The signal doc is sectioned (`===== GIT COMMITS =====`, `===== MERGED PULL REQUESTS =====`, …) so the
distiller can weight sources. Output is **capped** (commit/PR bodies truncated) so a busy day can't blow
up the doc. The commit pass reports unique commit counts across all local refs before the body cap,
both in the signal document and on stderr. A visible truncation marker identifies capped commit text.
The decision pass uses the same commit snapshot and reads each version from Git, never from the
current working tree. Unmerged work is evidence of work in progress, not evidence of deployment or
approval. This is a local-ref scan; it does not fetch remote branches.

The date window uses local time, includes the starting midnight, and excludes the next midnight.
GNU `date` and Git supporting `--since-as-filter` are required. An old-dated descendant does not
stop traversal to newer ancestors.

## The no-activity rule

If the doc shows no commits / PRs / beads / decisions / sessions for the window, **exit clean** — a quiet
day produces no memories. Never fabricate. This mirrors blog-backfill's "no git activity for a day → skip,
do not generate filler."

## Secrets warning (load-bearing)

Session transcripts can contain secrets that surfaced during debugging (`.env` dumps, API keys). The
signal doc is **internal-only** and is fed *only* to the local distiller, which is instructed to never
emit a secret into a candidate. The deterministic govern secret-scan is a **backstop**, not the primary
gate. Never publish or commit the raw signal doc.

## Tuning

- `TEAMKB_COMPILE_PROJECTS_ROOT` overrides the repo root (default `/home/jeremy/000-projects`).
- Pass both `DATE` and `NEXT_DATE`; for one day, calculate `NEXT_DATE` as `DATE` + 1.
- `TMPDIR` selects the scratch parent (default `/tmp`), allowing isolated fixture runs.
- The transcript scanner accepts `--project <substring>` to narrow to one project when debugging.
