#!/usr/bin/env python3
"""Scan Claude Code session transcripts for teamkb-compile material.

Reads JSONL session files from ~/.claude/projects/*/*.jsonl, filters by date
range, extracts user/assistant text exchanges, groups by project and day.

Output is a condensed summary suitable for feeding into the teamkb-compile
pipeline as additional source material alongside git logs, PRs, beads, and
decision records. It captures rationale, false starts, and user intent that
commit messages alone miss.

Vendored into the teamkb-compile skill so the skill is self-contained
(enforcement / tooling travels with the skill, not with the blog repo). Logic
is identical to blog-backfill's scanner.

WARNING: Session transcripts may contain sensitive data (.env contents, API
keys, credentials) that appeared during debugging. Output is for internal
use only and is fed only to the local distiller — the distiller is instructed
to never emit secrets, and the deterministic govern secret-scan is a backstop.

Usage:
    python3 scan-session-transcripts.py --start 2026-06-27 --end 2026-06-28
    python3 scan-session-transcripts.py --start 2026-06-27 -o /tmp/sessions.txt
    python3 scan-session-transcripts.py --start 2026-06-27  # single day (end defaults to start+1)
"""

import argparse
import json
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"

# Max chars of assistant text to include per message (avoid dumping 10MB agent results)
MAX_ASSISTANT_CHARS = 500

# Entry types to skip entirely
SKIP_TYPES = frozenset({
    "permission-mode",
    "file-history-snapshot",
    "custom-title",
    "progress",
    "agent-name",
    "attachment",
    "system",
})


def parse_date(s: str) -> datetime:
    """Parse YYYY-MM-DD date string."""
    return datetime.strptime(s, "%Y-%m-%d")


def project_name_from_dir(dirname: str) -> str:
    """Convert directory name to readable project name.

    e.g. '-home-jeremy-000-projects-governed-second-brain' -> 'governed-second-brain'
         '-home-jeremy' -> 'home'
    """
    name = dirname.lstrip("-")
    for prefix in ("home-jeremy-000-projects-", "home-jeremy-"):
        if name.startswith(prefix):
            name = name[len(prefix):]
            break
    if "--claude-worktrees" in name:
        name = name.split("--claude-worktrees")[0]
    return name or dirname


def extract_text_from_content(content, role: str) -> str | None:
    """Extract plain text from message content blocks.

    For user messages: skip tool_result blocks (too verbose).
    For assistant messages: skip thinking and tool_use blocks.
    """
    if isinstance(content, str):
        return content.strip() or None

    if not isinstance(content, list):
        return None

    texts = []
    for block in content:
        if not isinstance(block, dict):
            continue
        block_type = block.get("type", "")

        if role == "user":
            if block_type == "text":
                t = block.get("text", "").strip()
                if t:
                    texts.append(t)
        elif role == "assistant":
            if block_type == "text":
                t = block.get("text", "").strip()
                if t:
                    texts.append(t)

    return "\n".join(texts) if texts else None


def scan_jsonl_file(filepath: Path, start_ts: datetime, end_ts: datetime) -> list[dict]:
    """Stream-read a JSONL file, extract relevant entries in date range."""
    entries = []
    try:
        with open(filepath, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                entry_type = obj.get("type", "")
                if entry_type in SKIP_TYPES:
                    continue

                ts_str = obj.get("timestamp")
                if not ts_str:
                    continue

                try:
                    ts_clean = ts_str.replace("Z", "+00:00")
                    ts = datetime.fromisoformat(ts_clean).replace(tzinfo=None)
                except (ValueError, TypeError):
                    continue

                if ts < start_ts or ts >= end_ts:
                    continue

                if entry_type not in ("user", "assistant"):
                    continue

                msg = obj.get("message", {})
                if not isinstance(msg, dict):
                    continue

                role = msg.get("role", entry_type)
                content = msg.get("content", "")
                text = extract_text_from_content(content, role)
                if not text:
                    continue

                if role == "assistant" and len(text) > MAX_ASSISTANT_CHARS:
                    text = text[:MAX_ASSISTANT_CHARS] + "..."

                entries.append({
                    "timestamp": ts,
                    "role": role,
                    "text": text,
                    "is_sidechain": obj.get("isSidechain", False),
                })

    except (OSError, PermissionError) as e:
        print(f"  [WARN] Could not read {filepath}: {e}", file=sys.stderr)

    return entries


def scan_all_projects(start_ts: datetime, end_ts: datetime) -> dict:
    """Scan all project directories, return {project_name: {date_str: [entries]}}."""
    results = defaultdict(lambda: defaultdict(list))

    if not PROJECTS_DIR.exists():
        print(f"Projects directory not found: {PROJECTS_DIR}", file=sys.stderr)
        return results

    for project_dir in sorted(PROJECTS_DIR.iterdir()):
        if not project_dir.is_dir():
            continue

        project_name = project_name_from_dir(project_dir.name)
        jsonl_files = sorted(project_dir.glob("*.jsonl"))
        if not jsonl_files:
            continue

        for jf in jsonl_files:
            entries = scan_jsonl_file(jf, start_ts, end_ts)
            for entry in entries:
                date_str = entry["timestamp"].strftime("%Y-%m-%d")
                results[project_name][date_str].append(entry)

    return results


def format_output(results: dict) -> str:
    """Format results into readable output."""
    lines = []
    if not results:
        lines.append("No session activity found in the given date range.")
        return "\n".join(lines)

    for project_name in sorted(results.keys()):
        dates = results[project_name]
        for date_str in sorted(dates.keys()):
            entries = sorted(dates[date_str], key=lambda e: e["timestamp"])

            session_count = 1
            for i in range(1, len(entries)):
                gap = (entries[i]["timestamp"] - entries[i - 1]["timestamp"]).total_seconds()
                if gap > 1800:
                    session_count += 1

            lines.append(f"=== PROJECT: {project_name} ({date_str}) ===")
            lines.append(f"Sessions: ~{session_count} | Messages: {len(entries)}")
            lines.append("")

            for entry in entries:
                ts = entry["timestamp"].strftime("%H:%M")
                role = entry["role"].capitalize()
                sidechain = " [background]" if entry.get("is_sidechain") else ""
                text = entry["text"]

                text_lines = text.split("\n")
                if len(text_lines) > 1:
                    indented = text_lines[0] + "\n" + "\n".join(
                        "  " + tl for tl in text_lines[1:]
                    )
                    lines.append(f"[{ts}] {role}{sidechain}: {indented}")
                else:
                    lines.append(f"[{ts}] {role}{sidechain}: {text}")
                lines.append("")

            lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Scan Claude Code session transcripts for teamkb-compile material."
    )
    parser.add_argument("--start", required=True, help="Start date (YYYY-MM-DD, inclusive)")
    parser.add_argument("--end", default=None, help="End date (YYYY-MM-DD, exclusive). Defaults to start + 1 day.")
    parser.add_argument("--output", "-o", default=None, help="Output file path. Defaults to stdout.")
    parser.add_argument("--project", "-p", default=None, help="Filter to a single project name (substring match).")
    args = parser.parse_args()

    start_ts = parse_date(args.start)
    end_ts = parse_date(args.end) if args.end else start_ts + timedelta(days=1)

    print(
        f"Scanning sessions: {start_ts.date()} to {end_ts.date()} (~{(end_ts - start_ts).days} day(s))",
        file=sys.stderr,
    )

    results = scan_all_projects(start_ts, end_ts)

    if args.project:
        results = {
            name: dates for name, dates in results.items()
            if args.project.lower() in name.lower()
        }

    output = format_output(results)

    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"Output written to: {args.output}", file=sys.stderr)
    else:
        print(output)

    total_projects = len(results)
    total_messages = sum(len(e) for dates in results.values() for e in dates.values())
    print(f"Summary: {total_projects} project(s), {total_messages} message(s)", file=sys.stderr)


if __name__ == "__main__":
    main()
