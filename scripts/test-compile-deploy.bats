#!/usr/bin/env bats
# Installed compiler payloads are fixture Git objects; every deployment target is below Bats' temp HOME.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TEST_HOME="$BATS_TEST_TMPDIR/home"
  COMPILER="$BATS_TEST_TMPDIR/compiler"
  RESULT="$TEST_HOME/entry-result.json"
  mkdir -p "$TEST_HOME"
  env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin GIT_CONFIG_NOSYSTEM=1 \
    python3 - "$COMPILER" <<'PY'
import pathlib, subprocess, sys
root = pathlib.Path(sys.argv[1]); root.mkdir()
def git(*args):
    return subprocess.check_output(['git', '-C', str(root), *args])
git('init', '-q'); git('config', 'user.name', 'Fixture')
git('config', 'user.email', 'fixture@example.invalid')
payload = root / 'scripts/distiller'; payload.mkdir(parents=True)
for name in ('nightly-entry.py', 'runtime-proof.py', 'c8-mcp.py', 'teamkb-compile-daily.sh', 'eval-distiller-output.mjs'):
    (payload / name).write_text('#!/bin/sh\nexit 0\n' if name.endswith('.sh') else '# fixture\n' if name.endswith('.py') else '// fixture\n')
(payload / 'nightly-entry.py').write_text('import json,os,pathlib,sys\npathlib.Path(os.environ["FIXTURE_RESULT"]).write_text(json.dumps(sys.argv[1:]))\nraise SystemExit(int(os.environ.get("FIXTURE_EXIT", "0")))\n')
git('add', '.'); git('commit', '-qm', 'Reviewed fixture')
git('update-ref', 'refs/remotes/origin/main', git('rev-parse', 'HEAD').decode().strip())
PY
  REVISION="$(git -C "$COMPILER" rev-parse HEAD)"
  RELEASE="$TEST_HOME/.local/lib/teamkb-compile/current"
}

deploy() {
  env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin LANG=C GIT_CONFIG_NOSYSTEM=1 \
    TEAMKB_COMPILER_REPO="$COMPILER" TEAMKB_COMPILER_REVISION="$REVISION" \
    bash "$ROOT/bin/deploy-teamkb-compile.sh" "$@"
}

entry() {
  env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin LANG=C \
    FIXTURE_RESULT="$RESULT" FIXTURE_EXIT="${FIXTURE_EXIT:-0}" \
    bash "$TEST_HOME/bin/teamkb-compile-daily.sh" "$@"
}

@test "deploy rejects an unknown option before writing runtime paths" {
  run deploy --unknown
  [ "$status" -eq 64 ]
  [[ "$output" == *'Usage:'* ]]
  [ ! -e "$TEST_HOME/.local" ]
}

@test "deploy rejects absent reviewed revision before writing runtime paths" {
  REVISION=''
  run deploy
  [ "$status" -eq 64 ]
  [ ! -e "$TEST_HOME/.local" ]
}

@test "full deploy installs all canonical scripts and both skills without overwriting audit state" {
  local skill="$TEST_HOME/.claude/skills/teamkb-compile"
  mkdir -p "$skill/methodology"
  printf 'audit sentinel\n' > "$skill/methodology/decisions.jsonl"
  printf 'index sentinel\n' > "$skill/methodology/index.db"
  printf 'stale\n' > "$skill/obsolete-fixture.txt"
  run deploy
  [ "$status" -eq 0 ]
  [ -L "$RELEASE" ]
  for name in teamkb-compile-daily.sh teamkb-quality-digest.sh teamkb-backup.sh; do
    cmp "$ROOT/bin/$name" "$TEST_HOME/bin/$name"
    [ -x "$TEST_HOME/bin/$name" ]
  done
  [ -f "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md" ]
  [ -f "$skill/SKILL.md" ]
  [ ! -e "$skill/obsolete-fixture.txt" ]
  [ "$(cat "$skill/methodology/decisions.jsonl")" = 'audit sentinel' ]
  [ "$(cat "$skill/methodology/index.db")" = 'index sentinel' ]
}

@test "compile-only preserves review skill and unrelated executable bytes" {
  mkdir -p "$TEST_HOME/bin" "$TEST_HOME/.claude/skills/teamkb-review"
  printf 'review sentinel\n' > "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md"
  for name in teamkb-quality-digest.sh teamkb-backup.sh; do
    printf 'runtime sentinel\n' > "$TEST_HOME/bin/$name"
  done
  run deploy --compile-only
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md")" = 'review sentinel' ]
  for name in teamkb-quality-digest.sh teamkb-backup.sh; do
    [ "$(cat "$TEST_HOME/bin/$name")" = 'runtime sentinel' ]
  done
  [ ! -e "$TEST_HOME/.claude/skills/teamkb-review/scripts" ]
}

@test "first deploy seeds empty audit log and a repeat preserves its contents" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  local audit="$TEST_HOME/.claude/skills/teamkb-compile/methodology/decisions.jsonl"
  [ -f "$audit" ]
  [ ! -s "$audit" ]
  printf 'later audit\n' > "$audit"
  run deploy --compile-only
  [ "$status" -eq 0 ]
  [ "$(cat "$audit")" = 'later audit' ]
}

@test "changed installed wrapper is backed up before replacement" {
  mkdir -p "$TEST_HOME/bin"
  printf 'old wrapper\n' > "$TEST_HOME/bin/teamkb-compile-daily.sh"
  run deploy --compile-only
  [ "$status" -eq 0 ]
  local backups=("$TEST_HOME"/.local/state/teamkb-compile-daily/wrapper-before-*.sh)
  [ "${#backups[@]}" -eq 1 ]
  [ "$(cat "${backups[0]}")" = 'old wrapper' ]
  [ "$(stat -c %a "${backups[0]}")" = 700 ]
  cmp "$ROOT/bin/teamkb-compile-daily.sh" "$TEST_HOME/bin/teamkb-compile-daily.sh"
}

@test "failed compiler installation cannot activate or overwrite an old wrapper" {
  mkdir -p "$TEST_HOME/bin"
  printf 'old wrapper\n' > "$TEST_HOME/bin/teamkb-compile-daily.sh"
  REVISION=0000000000000000000000000000000000000000
  run deploy
  [ "$status" -ne 0 ]
  [ ! -e "$RELEASE" ]
  [ "$(cat "$TEST_HOME/bin/teamkb-compile-daily.sh")" = 'old wrapper' ]
  [ ! -e "$TEST_HOME/bin/teamkb-backup.sh" ]
  [ ! -e "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md" ]
}

@test "missing reviewed bundle refuses execution with unavailable status" {
  mkdir -p "$TEST_HOME/bin"
  cp "$ROOT/bin/teamkb-compile-daily.sh" "$TEST_HOME/bin/"
  run entry
  [ "$status" -eq 69 ]
  [ ! -e "$RESULT" ]
}

@test "malformed manifest shapes refuse execution without a traceback" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  for manifest in '{' '[]' '{"revision":"main","sha256":{}}' '{"revision":"0000000000000000000000000000000000000000","sha256":{}}'; do
    printf '%s\n' "$manifest" > "$RELEASE/manifest.json"
    run entry
    [ "$status" -eq 69 ]
    [[ "$output" == *'verification failed'* ]]
    [[ "$output" != *'Traceback'* ]]
    [ ! -e "$RESULT" ]
  done
}

@test "drift in any of the five pinned payloads prevents entry execution" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  for name in nightly-entry.py runtime-proof.py c8-mcp.py teamkb-compile-daily.sh eval-distiller-output.mjs; do
    cp "$RELEASE/$name" "$BATS_TEST_TMPDIR/original"
    printf '\n# fixture drift\n' >> "$RELEASE/$name"
    run entry
    [ "$status" -eq 69 ]
    [ ! -e "$RESULT" ]
    cp "$BATS_TEST_TMPDIR/original" "$RELEASE/$name"
  done
}

@test "installed wrapper forwards exact arguments and preserves the compiler exit status" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  FIXTURE_EXIT=42
  run entry --literal 'two words' '' $'line\nbreak' '*'
  [ "$status" -eq 42 ]
  python3 - "$RESULT" <<'PY'
import json,sys
assert json.load(open(sys.argv[1])) == ['--literal', 'two words', '', 'line\nbreak', '*']
PY
}

@test "manifest without its entry payload refuses before delegation" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  rm -- "$RELEASE/nightly-entry.py"
  run entry
  [ "$status" -eq 69 ]
  [ ! -e "$RESULT" ]
}

@test "explicit release path with spaces is verified instead of a broken default" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  local selected="$TEST_HOME/selected release"
  cp -aL "$RELEASE" "$selected"
  printf 'invalid default manifest\n' > "$RELEASE/manifest.json"
  run entry
  [ "$status" -eq 69 ]
  run env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin LANG=C \
    TEAMKB_COMPILE_RELEASE="$selected" FIXTURE_RESULT="$RESULT" \
    bash "$TEST_HOME/bin/teamkb-compile-daily.sh" --selected
  [ "$status" -eq 0 ]
  python3 - "$RESULT" <<'PY_ASSERT'
import json,sys
assert json.load(open(sys.argv[1])) == ['--selected']
PY_ASSERT
}
