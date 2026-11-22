#!/usr/bin/env bash
# Gather the day's work signals for /teamkb-compile.
#
# Emits ONE structured signal doc to stdout: git commits, merged PRs, closed
# beads, changed decision records, and Claude session transcripts, for the
# date window, across all repos under ~/000-projects. The skill redirects this
# to /tmp/teamkb-compile/signals-<DATE>.txt and hands it to the distiller.
#
# Self-contained: the transcript scanner is vendored alongside this script.
# Run via shebang (non-interactive bash) so ~/.zshrc aliases never apply.
#
# Usage: gather-signals.sh <DATE> <NEXT_DATE>     (YYYY-MM-DD ; NEXT_DATE exclusive-end-of-day)

set -uo pipefail
# Transcript + signal material can contain secrets that surfaced during debugging
# (the scanner warns about this). Restrict everything we write under /tmp to the
# owner so it can't land world-readable on a multi-user box.
umask 077

DATE="${1:?usage: gather-signals.sh <DATE> <NEXT_DATE>}"
NEXT_DATE="${2:?usage: gather-signals.sh <DATE> <NEXT_DATE>}"

PROJECTS_ROOT="${TEAMKB_COMPILE_PROJECTS_ROOT:-$HOME/000-projects}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="${TMPDIR:-/tmp}/teamkb-compile"
mkdir -p "$SCRATCH"
chmod 700 "$SCRATCH" 2>/dev/null || true   # tighten even if it pre-existed loose

SINCE="$DATE 00:00:00"
UNTIL="$NEXT_DATE 00:00:00"
# Git's --until includes its boundary. Filter epochs for an exclusive next day;
# --since-as-filter traverses old-dated children to reach in-window ancestors.
SINCE_EPOCH=$(date -d "$SINCE" +%s) || exit 64
UNTIL_EPOCH=$(date -d "$UNTIL" +%s) || exit 64
[ "$UNTIL_EPOCH" -gt "$SINCE_EPOCH" ] || exit 64

# Caps so a busy day can't produce a megabyte signal doc.
PR_BODY_MAX_LINES=80
COMMIT_BODY_MAX_LINES=400

echo "##### TEAMKB-COMPILE SIGNAL DOC #####"
echo "Window: ${DATE} 00:00 .. ${NEXT_DATE} 00:00 (local)"
echo "Projects root: ${PROJECTS_ROOT}"
echo

# Repos with activity in the window (drives the PR + bead + decision passes).
ACTIVE_REPOS=()
declare -A REPO_COMMITS=()
TOTAL_COMMITS=0

echo "===== GIT COMMITS (subject + body, by repo) ====="
for dir in "$PROJECTS_ROOT"/*/; do
  [ -d "$dir" ] || continue          # glob didn't expand (no subdirs) → skip the literal
  [ -d "$dir/.git" ] || continue
  repo=$(basename "$dir")
  if ! ids=$(git -C "$dir" log --all --since-as-filter="$SINCE" --until="$UNTIL" \
          --format='%H %ct' 2>/dev/null \
          | awk -v start="$SINCE_EPOCH" -v end="$UNTIL_EPOCH" '$2 >= start && $2 < end {print $1}'); then
    printf '[gather-signals] failed all-ref scan: %s\n' "$repo" >&2
    exit 1
  fi
  if [ -n "$ids" ]; then
    count=$(printf '%s\n' "$ids" | wc -l)
    TOTAL_COMMITS=$((TOTAL_COMMITS + count))
    ACTIVE_REPOS+=("$repo")
    REPO_COMMITS["$repo"]="$ids"
    echo "=== $repo ==="
    echo "Commits across all refs: $count (before body cap)"
    printf '[gather-signals] %s: %s commits across all refs\n' "$repo" "$count" >&2
    commits=$(printf '%s\n' "$ids" | git -C "$dir" log --no-walk=unsorted --stdin \
                --format='%h %an  %s%n%b' 2>/dev/null)
    printf '%s\n' "$commits" | head -n "$COMMIT_BODY_MAX_LINES"
    lines=$(printf '%s\n' "$commits" | wc -l)
    if [ "$lines" -gt "$COMMIT_BODY_MAX_LINES" ]; then
      echo "[TRUNCATED: showing first $COMMIT_BODY_MAX_LINES of $lines commit lines]"
    fi
    echo
  fi
done
echo "Total commits across all refs: $TOTAL_COMMITS"
printf '[gather-signals] total: %s commits across all refs\n' "$TOTAL_COMMITS" >&2
[ ${#ACTIVE_REPOS[@]} -eq 0 ] && echo "(no git commits in window)"
echo

echo "===== MERGED PULL REQUESTS ====="
pr_found=0
for repo in "${ACTIVE_REPOS[@]}"; do
  dir="$PROJECTS_ROOT/$repo"
  slug=$(git -C "$dir" remote get-url origin 2>/dev/null \
           | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##; s#^https://github.com/##')
  [ -n "$slug" ] || continue
  prs=$(gh pr list --repo "$slug" --state merged \
          --search "merged:${DATE}..${NEXT_DATE}" \
          --json number,title,body,mergedAt \
          --jq '.[] | "=== '"$slug"' #\(.number): \(.title) (merged \(.mergedAt)) ===\n\(.body)\n"' \
          2>/dev/null)
  if [ -n "$prs" ]; then
    pr_found=1
    # cap each PR body
    echo "$prs" | awk -v max="$PR_BODY_MAX_LINES" '
      /^=== / { n=0 }
      { if (n++ < max) print }'
    echo
  fi
done
[ "$pr_found" -eq 0 ] && echo "(no merged PRs in window, or gh unauthenticated)"
echo

echo "===== CLOSED BEADS (with close reasons) ====="
bead_found=0
# Per-repo beads + the umbrella/home store.
for dir in "$PROJECTS_ROOT"/*/ "$PROJECTS_ROOT"; do
  [ -d "$dir" ] || continue          # glob didn't expand → skip the literal
  [ -d "$dir/.beads" ] || continue
  # Drop bd's transient upgrade/doctor nag lines that print to stdout.
  closed=$(bd list -C "$dir" --status closed --closed-after "$DATE" --closed-before "$NEXT_DATE" \
             --all --flat 2>/dev/null \
             | grep -vE 'bd upgraded|Run .bd (upgrade|doctor)|^(🔄|💡|💊)')
  if [ -n "$closed" ]; then
    bead_found=1
    echo "=== $(basename "$dir") ==="
    echo "$closed"
    echo
  fi
done
[ "$bead_found" -eq 0 ] && echo "(no beads closed in window)"
echo

echo "===== DECISION RECORDS (added/modified in window) ====="
decr_found=0
for repo in "${ACTIVE_REPOS[@]}"; do
  dir="$PROJECTS_ROOT/$repo"
  # Use the same all-ref commit snapshot as the first pass. Reading blobs at
  # each commit preserves branch-only and subsequently deleted/revised records.
  while IFS= read -r commit; do
    while IFS= read -r -d '' f; do
      decr_found=1
      echo "=== $repo ==="
      printf '%s\n' "--- $f (commit $commit) ---"
      # Only regular file blobs; never follow a decision-record symlink.
      mode=$(git --literal-pathspecs -C "$dir" ls-tree "$commit" -- "$f" | cut -d ' ' -f 1)
      if [[ "$mode" == 100644 || "$mode" == 100755 ]]; then
        git -C "$dir" cat-file blob "$commit:$f" 2>/dev/null | head -n 25
      else
        echo "[SKIPPED: decision record is not a regular file]"
      fi
      echo
    done < <(git -C "$dir" diff-tree --root -r --no-commit-id --name-only -z \
               --diff-filter=AM "$commit" -- \
               '000-docs/*-AT-DECR-*' '000-docs/**/*-AT-DECR-*' 2>/dev/null)
  done <<< "${REPO_COMMITS[$repo]}"
done
[ "$decr_found" -eq 0 ] && echo "(no decision records added/modified in window)"
echo

echo "===== CLAUDE SESSION TRANSCRIPTS (rationale, false starts, intent) ====="
# Bound a pathological day: cap transcript lines, but LOG the truncation
# (no silent caps — a dropped tail must be visible to the distiller + the log).
MAX_TX="${TEAMKB_COMPILE_MAX_TRANSCRIPT_LINES:-5000}"
TXFILE="$SCRATCH/transcripts-$DATE.txt"
python3 "$SCRIPT_DIR/scan-session-transcripts.py" --start "$DATE" --end "$NEXT_DATE" \
  > "$TXFILE" 2>/dev/null || echo "(transcript scan failed)" > "$TXFILE"
TX_TOTAL=$(wc -l < "$TXFILE" 2>/dev/null || echo 0)
head -n "$MAX_TX" "$TXFILE"
if [ "$TX_TOTAL" -gt "$MAX_TX" ]; then
  echo
  echo "[TRUNCATED: showing first ${MAX_TX} of ${TX_TOTAL} transcript lines — raise TEAMKB_COMPILE_MAX_TRANSCRIPT_LINES to include more]"
fi
echo

echo "##### END SIGNAL DOC #####"
