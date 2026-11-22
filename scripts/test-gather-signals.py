#!/usr/bin/env python3
"""Exercise the real gatherer using disposable Git history and no external tools."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / '.claude/skills/teamkb-compile/scripts/gather-signals.sh'


class GatherSignalsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.projects = self.root / 'projects'
        self.repo = self.projects / 'fixture'
        self.repo.mkdir(parents=True)
        self.env = {'HOME': str(self.root), 'PATH': '/usr/bin:/bin', 'TZ': 'UTC',
                    'LANG': 'C', 'GIT_CONFIG_NOSYSTEM': '1', 'TMPDIR': str(self.root),
                    'TEAMKB_COMPILE_PROJECTS_ROOT': str(self.projects)}
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.commit('base', '2026-11-03T12:00:00Z')
        self.script = self.root / 'gather-signals.sh'
        shutil.copyfile(SOURCE, self.script)
        (self.root / 'scan-session-transcripts.py').write_text('print("(fixture: no transcripts)")\n')
        # No origin or .beads directories: gh and bd must never be called.
        tools = self.root / 'tools'
        tools.mkdir()
        for name in ('gh', 'bd'):
            tool = tools / name
            tool.write_text('#!/bin/sh\necho forbidden >> "$HOME/external-called"\nexit 99\n')
            tool.chmod(0o755)
        self.env['PATH'] = str(tools) + ':/usr/bin:/bin'

    def git(self, *args, env=None):
        return subprocess.check_output(['git', '-C', str(self.repo), *args],
                                       env=env or self.env, stderr=subprocess.PIPE).decode().strip()

    def commit(self, subject, date, path=None, content=None):
        if path:
            target = self.repo / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
            self.git('add', '--', path)
        env = dict(self.env, GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
        self.git('commit', '--allow-empty', '-qm', subject, env=env)
        return self.git('rev-parse', 'HEAD')

    def gather(self):
        result = subprocess.run(['bash', str(self.script), '2026-11-04', '2026-11-05'],
                                env=self.env, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / 'external-called').exists())
        return result.stdout, result.stderr

    def test_branch_decision_blobs_and_duplicate_refs(self):
        self.git('switch', '-qc', 'unmerged')
        path = '000-docs/001-AT-DECR-branch decision.md'
        first = self.commit('branch-only work', '2026-11-04T12:00:00Z', path, 'BRANCH ORIGINAL\n')
        second = self.commit('decision amendment', '2026-11-04T13:00:00Z', path, 'BRANCH AMENDED\n')
        self.git('tag', 'duplicate-ref')
        self.git('update-ref', 'refs/remotes/origin/duplicate', second)
        self.git('switch', '-q', 'main')
        # An unrelated dirty checkout must not supply historical decision text.
        (self.repo / path).parent.mkdir(parents=True, exist_ok=True)
        (self.repo / path).write_text('UNCOMMITTED WRONG CONTENT\n')
        out, err = self.gather()
        self.assertIn('Total commits across all refs: 2', out)
        self.assertIn('total: 2 commits across all refs', err)
        self.assertEqual(out.count('branch-only work'), 1)
        for sha, text in ((first, 'BRANCH ORIGINAL'), (second, 'BRANCH AMENDED')):
            self.assertIn(f'(commit {sha})', out)
            self.assertIn(text, out)
        self.assertNotIn('UNCOMMITTED WRONG CONTENT', out)
        self.assertEqual((self.repo / path).read_text(), 'UNCOMMITTED WRONG CONTENT\n')

    def test_exclusive_end_and_clock_skew(self):
        self.commit('inclusive-start', '2026-11-04T00:00:00Z')
        self.commit('last-second', '2026-11-04T23:59:59Z')
        self.commit('exclusive-end', '2026-11-05T00:00:00Z')
        # Old-dated descendant must not prune its newer ancestors.
        self.commit('old-descendant', '2026-11-03T23:59:59Z')
        out, _ = self.gather()
        self.assertIn('inclusive-start', out)
        self.assertIn('last-second', out)
        self.assertNotIn('exclusive-end', out)
        self.assertNotIn('old-descendant', out)
        self.assertIn('Total commits across all refs: 2', out)

    def test_count_precedes_visible_truncation(self):
        self.commit('busy-day\n\n' + '\n'.join(f'line {i}' for i in range(450)),
                    '2026-11-04T12:00:00Z')
        out, err = self.gather()
        self.assertIn('Total commits across all refs: 1', out)
        self.assertIn('[TRUNCATED: showing first 400', out)
        self.assertIn('total: 1 commits across all refs', err)

    def test_quiet_day_reports_zero(self):
        out, err = self.gather()
        self.assertIn('Total commits across all refs: 0', out)
        self.assertIn('(no decision records added/modified in window)', out)
        self.assertIn('total: 0 commits across all refs', err)


if __name__ == '__main__':
    unittest.main()
