#!/usr/bin/env bash
#
# aggregate-changelogs.sh — pull each GSB ecosystem repo's CHANGELOG.md into
# changelogs/<repo>.md and regenerate the changelogs/README.md rollup index.
#
# This is a PULL-based aggregator: the source of truth is each repo's own
# CHANGELOG.md. This directory is a derived, auto-generated mirror — do NOT
# hand-edit the files in changelogs/. Re-run this script (or the CI workflow)
# to refresh.
#
# Public repos are fetched over raw.githubusercontent.com (no auth). The one
# PRIVATE repo (team-intent-claude-plugins) is fetched via the GitHub contents
# API using $CHANGELOG_AGGREGATION_TOKEN; if that token (or the file) is absent,
# the private repo WARN-SKIPS so the job never hard-fails on it.
#
# Usage:  bash scripts/aggregate-changelogs.sh
# Env:    CHANGELOG_AGGREGATION_TOKEN  (optional) token with read access to the
#                                      private team-intent-claude-plugins repo.
#         FETCHED_AT                   (optional) ISO-8601 UTC stamp injected by
#                                      CI; defaults to `date -u` at runtime.
#
set -euo pipefail

# --- config -----------------------------------------------------------------
# Roots resolved relative to this script so it runs from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${REPO_ROOT}/changelogs"

# Stamp injected by CI, or computed here. NOT hardcoded into the mirrored files
# beyond this single provenance value per run.
FETCHED_AT="${FETCHED_AT:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

# Repo list — data-driven. Fields: name|owner|branch|visibility|role
# Roles mirror repos.yml. Order = umbrella first, then engines, plugin, marketplace.
REPOS=(
  "bobs-big-brain-umbrella|intent-solutions-io|main|public|Umbrella / landing — the single working surface"
  "bobs-big-brain-compiler|jeremylongshore|main|public|Compiler — the COMPILE engine (deterministic kernel + LLM compiler)"
  "bobs-big-brain-registrar|jeremylongshore|main|public|Registrar — the GOVERN engine (control plane, audit chain) + brain HTTP API"
  "bobs-big-brain-plugin|jeremylongshore|main|public|The public unified plugin — local + team runtime modes"
  "team-intent-claude-plugins|intent-solutions-io|main|private|Private team marketplace (RETIRED 2026-07-17) — warn-skips"
)

mkdir -p "${OUT_DIR}"

# --- helpers ----------------------------------------------------------------

# extract_latest <changelog-file>
# Print the first *released* version heading and its entry block. A released
# heading is "## [x.y.z] ..." or "## [YYYY-MM-DD] ..." — we skip "[Unreleased]".
# If none found, print a friendly placeholder.
extract_latest() {
  awk '
    # A version heading: "## [" but NOT "## [Unreleased]"
    /^## \[/ {
      if ($0 ~ /^## \[Unreleased\]/) { next }
      if (found) { exit }        # second version heading -> stop
      found = 1
      print
      next
    }
    found { print }
  ' "$1" | sed -e 's/[[:space:]]*$//'
}

# latest_version_label <changelog-file>
# Just the "[x.y.z]" or "[YYYY-MM-DD]" token from the first released heading.
# Filter out the Unreleased heading FIRST, then take the first remaining one
# (a bare `grep -m1 ... | grep -v Unreleased` would stop on Unreleased and drop it).
latest_version_label() {
  grep -E '^## \[[^]]+\]' "$1" \
    | grep -vi 'Unreleased' \
    | head -n1 \
    | sed -E 's/^## (\[[^]]+\]).*/\1/' || true
}

# fetch_public <owner> <repo> <branch> -> stdout (changelog body) or non-zero
fetch_public() {
  local owner="$1" repo="$2" branch="$3"
  curl -fsSL "https://raw.githubusercontent.com/${owner}/${repo}/${branch}/CHANGELOG.md"
}

# fetch_private <owner> <repo> -> stdout (changelog body) or non-zero
# Uses the contents API + base64 decode. Requires CHANGELOG_AGGREGATION_TOKEN.
fetch_private() {
  local owner="$1" repo="$2"
  if [ -z "${CHANGELOG_AGGREGATION_TOKEN:-}" ]; then
    return 10   # signal: no token
  fi
  # gh reads GH_TOKEN from env; scope the token to this call only.
  GH_TOKEN="${CHANGELOG_AGGREGATION_TOKEN}" \
    gh api "repos/${owner}/${repo}/contents/CHANGELOG.md" --jq '.content' 2>/dev/null \
    | base64 -d 2>/dev/null
}

# --- main loop --------------------------------------------------------------
# Accumulate rows for the README table + per-repo latest blocks.
declare -a TABLE_ROWS=()
declare -a LATEST_BLOCKS=()
SKIPPED=0

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name owner branch vis role <<< "${entry}"
  dest="${OUT_DIR}/${name}.md"
  live_url="https://github.com/${owner}/${name}"

  body=""
  status="ok"
  if [ "${vis}" = "private" ]; then
    if body="$(fetch_private "${owner}" "${name}")" && [ -n "${body}" ]; then
      status="ok"
    else
      status="skip"
    fi
  else
    if body="$(fetch_public "${owner}" "${name}" "${branch}")" && [ -n "${body}" ]; then
      status="ok"
    else
      status="skip"
    fi
  fi

  if [ "${status}" = "skip" ]; then
    SKIPPED=$((SKIPPED + 1))
    if [ "${vis}" = "private" ] && [ -z "${CHANGELOG_AGGREGATION_TOKEN:-}" ]; then
      echo "WARN: skipping ${owner}/${name} (private, no CHANGELOG_AGGREGATION_TOKEN)" >&2
    else
      echo "WARN: skipping ${owner}/${name} (could not fetch CHANGELOG.md)" >&2
    fi
    TABLE_ROWS+=("| [\`${name}\`](${name}.md) | ${role} | \`${vis}\` | [repo](${live_url}) | _not fetched this run_ |")
    LATEST_BLOCKS+=("### \`${name}\`

_Changelog not fetched this run (private without token, or file missing)._
")
    continue
  fi

  # Write the mirrored file with a provenance header.
  raw_url="https://raw.githubusercontent.com/${owner}/${name}/${branch}/CHANGELOG.md"
  {
    echo "<!-- fetched by CI — DO NOT HAND-EDIT. Source of truth: the repo's own CHANGELOG.md. -->"
    echo "<!-- source: ${raw_url} -->"
    echo "<!-- fetched-at: ${FETCHED_AT} -->"
    echo ""
    printf '%s\n' "${body}"
  } > "${dest}"

  # Extract the latest released version + block for the README rollup.
  ver_label="$(latest_version_label "${dest}")"
  [ -z "${ver_label}" ] && ver_label="_Unreleased only_"
  latest_block="$(extract_latest "${dest}")"
  [ -z "${latest_block}" ] && latest_block="_(no released version yet — see the mirrored file for the Unreleased section)_"

  TABLE_ROWS+=("| [\`${name}\`](${name}.md) | ${role} | \`${vis}\` | [repo](${live_url}) | ${ver_label} |")
  LATEST_BLOCKS+=("### \`${name}\` — latest: ${ver_label}

Source: [\`${owner}/${name}\`](${live_url}) · mirror: [\`${name}.md\`](${name}.md)

${latest_block}
")

  echo "ok: ${owner}/${name} -> changelogs/${name}.md (latest ${ver_label})" >&2
done

# --- regenerate changelogs/README.md ---------------------------------------
{
  cat <<HEADER
<!-- AUTO-GENERATED by scripts/aggregate-changelogs.sh — DO NOT HAND-EDIT. -->
<!-- generated-at: ${FETCHED_AT} -->

# Ecosystem changelogs (aggregated)

This directory is an **auto-generated, pull-based mirror** of every repo's
\`CHANGELOG.md\` in the Bob's Big Brain ecosystem. It is regenerated by
[\`scripts/aggregate-changelogs.sh\`](../scripts/aggregate-changelogs.sh) (run on
a weekly schedule, on \`workflow_dispatch\`, and on a \`changelog-updated\`
\`repository_dispatch\` from any sub-repo).

**Do not hand-edit anything in this directory.** The source of truth is each
repo's own \`CHANGELOG.md\`; edits here are overwritten on the next run. The one
private repo (\`team-intent-claude-plugins\`) is included when a read token is
configured, and warn-skipped otherwise.

## Repos

| Changelog | Role | Vis | Live repo | Latest |
|---|---|---|---|---|
HEADER

  for row in "${TABLE_ROWS[@]}"; do
    printf '%s\n' "${row}"
  done

  cat <<'MID'

## Latest entry per repo

MID

  for block in "${LATEST_BLOCKS[@]}"; do
    printf '%s\n' "${block}"
    echo "---"
    echo ""
  done
} > "${OUT_DIR}/README.md"

echo "done: regenerated changelogs/README.md (${#TABLE_ROWS[@]} repos, ${SKIPPED} skipped)" >&2
