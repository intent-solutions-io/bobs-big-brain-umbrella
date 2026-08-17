#!/usr/bin/env bash
#
# teamkb-systemmap.sh — regenerate the live-stats block in 005-AT-ARCH so the
# system map can never drift from the real brain again.
#
# Every volatile number (DB sizes, table row counts, file counts, backup status)
# lives ONLY inside the
#     <!-- AUTOGEN:live-stats ... -->  ...  <!-- /AUTOGEN:live-stats -->
# fences of 000-docs/005-AT-ARCH. This script reads the live brain (both SQLite
# DBs via sqlite3 — already a teamkb-backup.sh dependency — plus du/find against
# ~/.teamkb) and rewrites exactly that block, touching nothing else.
#
# It is invoked by ~/bin/teamkb-backup.sh after a backup's restore round-trip
# passes, so the map refreshes every day the brain is provably backed up. It is
# also safe to run by hand. sqlite3 is used directly (not `ico status` / a built
# CLI) because a daily hook must not depend on a Node build being present.

set -euo pipefail

TEAMKB_HOME="${TEAMKB_HOME:-$HOME/.teamkb}"
DB="${TEAMKB_DB:-$TEAMKB_HOME/teamkb.db}"
ICO_DB="${TEAMKB_ICO_DB:-$TEAMKB_HOME/brain/.ico/state.db}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC="${TEAMKB_SYSTEMMAP_DOC:-$SCRIPT_DIR/../000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md}"

DU=/usr/bin/du
FIND=/usr/bin/find

command -v sqlite3 >/dev/null || { echo "teamkb-systemmap: sqlite3 not on PATH" >&2; exit 1; }
[ -f "$DOC" ] || { echo "teamkb-systemmap: target doc not found: $DOC" >&2; exit 1; }
# Fail loud if the live brain isn't present — a "grounded" snapshot must never
# succeed with ?/‑ placeholders for missing DBs (that would silently ship a lie).
[ -f "$DB" ]     || { echo "teamkb-systemmap: INTKB DB not found: $DB" >&2; exit 1; }
[ -f "$ICO_DB" ] || { echo "teamkb-systemmap: ICO DB not found: $ICO_DB" >&2; exit 1; }

# sqlite helper — empty string on any error (table absent, locked, etc.)
q() { sqlite3 "$DB" "$1" 2>/dev/null || true; }
# human size of a path ("-" if absent); strips the trailing path column from du
sz() { [ -e "$1" ] && "$DU" -sh "$1" 2>/dev/null | cut -f1 || echo "-"; }
# file count of a dir ("-" if absent)
nf() { [ -d "$1" ] && "$FIND" "$1" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "-"; }
# "k1 v1 / k2 v2" from a "key|count" grouped query
group_str() {
  local sql="$1" sep="${2:- / }" out=""
  while IFS='|' read -r k v; do
    [ -n "$k" ] || continue
    out="${out:+$out$sep}$k $v"
  done < <(q "$sql")
  echo "${out:--}"
}

ts="$(date -u +%FT%TZ)"

cand="$(q 'SELECT count(*) FROM candidates;')";            cand="${cand:-?}"
cur="$(q 'SELECT count(*) FROM curated_memories;')";       cur="${cur:-?}"
cur_life="$(group_str 'SELECT lifecycle, count(*) FROM curated_memories GROUP BY lifecycle ORDER BY 2 DESC;')"
cur_cat="$(group_str 'SELECT category, count(*) FROM curated_memories GROUP BY category ORDER BY 2 DESC;' ' · ')"
ae="$(q 'SELECT count(*) FROM audit_events;')";            ae="${ae:-?}"
ae_ver="$(group_str "SELECT 'v'||hash_version, count(*) FROM audit_events GROUP BY hash_version ORDER BY 1;")"
links="$(q 'SELECT count(*) FROM memory_links;')";         links="${links:-?}"

sz_db="$(sz "$DB")"
sz_ico="$(sz "$ICO_DB")"
sz_raw="$(sz "$TEAMKB_HOME/brain/raw")";   nf_raw="$(nf "$TEAMKB_HOME/brain/raw")"
sz_wiki="$(sz "$TEAMKB_HOME/brain/wiki")"; nf_wiki="$(nf "$TEAMKB_HOME/brain/wiki")"
sz_audit="$(sz "$TEAMKB_HOME/brain/audit")"
sz_spool="$(sz "$TEAMKB_HOME/spool")"
sz_kbx="$(sz "$TEAMKB_HOME/kb-export")"
sz_qmd="$(sz "$TEAMKB_HOME/qmd-index")"
sz_total="$(sz "$TEAMKB_HOME")"

# latest off-host-capable archive + its mtime. Filenames are teamkb-full-<ISO8601>Z.…,
# so lexical max == newest — pick it with a glob (no `ls` parsing).
latest_arc=""
shopt -s nullglob
for f in "$TEAMKB_HOME"/backups/teamkb-full-*.tar.zst.age; do
  [[ "$f" > "$latest_arc" ]] && latest_arc="$f"
done
shopt -u nullglob
if [ -n "$latest_arc" ]; then
  bk="\`$(basename "$latest_arc")\` ($(date -u -r "$latest_arc" +%FT%TZ 2>/dev/null || echo '?'))"
else
  bk="_no full-brain archive yet_"
fi

# Build the new inner block in a temp file, then splice it between the fences.
block="$(mktemp)"
trap 'rm -f "$block"' EXIT
{
  echo "_Snapshot ${ts} · auto-updated by [\`bin/teamkb-systemmap.sh\`](../bin/teamkb-systemmap.sh) (reads both SQLite DBs + du/find)._"
  echo
  echo "| Store (\`~/.teamkb/…\`) | Size | Rows / files |"
  echo "|---|---|---|"
  echo "| \`teamkb.db\` — INTKB govern | ${sz_db} | candidates ${cand} · curated_memories ${cur} (${cur_life}) · audit_events ${ae} (${ae_ver}) · memory_links ${links} |"
  echo "| \`brain/.ico/state.db\` — ICO compile | ${sz_ico} | — |"
  echo "| \`brain/raw/\` — corpus (source of truth) | ${sz_raw} | ${nf_raw} files |"
  echo "| \`brain/wiki/\` — compiled markdown | ${sz_wiki} | ${nf_wiki} files |"
  echo "| \`brain/audit/\` — ICO receipts | ${sz_audit} | — |"
  echo "| \`spool/\` — shared ICO→INTKB intake | ${sz_spool} | — |"
  echo "| \`kb-export/\` — derived | ${sz_kbx} | — |"
  echo "| \`qmd-index/\` — derived | ${sz_qmd} | — |"
  echo "| **\`~/.teamkb\` total** | **${sz_total}** | — |"
  echo
  echo "**curated_memories by category:** ${cur_cat}."
  echo
  echo "**Backup:** latest ${bk} · daily timer \`teamkb-backup.timer\` (04:30)."
} > "$block"

BLOCK="$block" DOC="$DOC" /usr/bin/env python3 - <<'PY'
import os, re, pathlib
doc = pathlib.Path(os.environ["DOC"])
inner = pathlib.Path(os.environ["BLOCK"]).read_text(encoding="utf-8").rstrip("\n")
text = doc.read_text(encoding="utf-8")
pat = re.compile(r"(<!-- AUTOGEN:live-stats[^\n]*-->\n).*?(\n<!-- /AUTOGEN:live-stats -->)", re.DOTALL)
if not pat.search(text):
    raise SystemExit(f"teamkb-systemmap: AUTOGEN:live-stats fences not found in {doc}")
new = pat.sub(lambda m: m.group(1) + inner + m.group(2), text)
if new != text:
    doc.write_text(new, encoding="utf-8")
    print(f"teamkb-systemmap: updated live-stats block in {doc.name}")
else:
    print(f"teamkb-systemmap: live-stats block already current in {doc.name}")
PY
