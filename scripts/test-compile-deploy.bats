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
for name in ('nightly-entry.py', 'runtime-proof.py', 'c8-mcp.py', 'teamkb-compile-daily.sh', 'eval-distiller-output.mjs', 'notify-routing.sh'):
    (payload / name).write_text('#!/bin/sh\nexit 0\n' if name.endswith('.sh') else '# fixture\n' if name.endswith('.py') else '// fixture\n')
(payload / 'nightly-entry.py').write_text('import json,os,pathlib,sys\npathlib.Path(os.environ["FIXTURE_RESULT"]).write_text(json.dumps(sys.argv[1:]))\nraise SystemExit(int(os.environ.get("FIXTURE_EXIT", "0")))\n')
git('add', '.'); git('commit', '-qm', 'Compiler payload fixture')
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

deploy_with_tools() {
  env -i HOME="$TEST_HOME" PATH="$TEST_HOME/tools:/usr/bin:/bin" LANG=C GIT_CONFIG_NOSYSTEM=1 \
    TEAMKB_COMPILER_REPO="$COMPILER" TEAMKB_COMPILER_REVISION="$REVISION" \
    bash "$ROOT/bin/deploy-teamkb-compile.sh" "$@"
}

entry() {
  env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin LANG=C \
    FIXTURE_RESULT="$RESULT" FIXTURE_EXIT="${FIXTURE_EXIT:-0}" \
    bash "$TEST_HOME/bin/teamkb-compile-daily.sh" "$@"
}

selected_entry() {
  local selected="$1"
  shift
  env -i HOME="$TEST_HOME" PATH=/usr/bin:/bin LANG=C \
    TEAMKB_COMPILE_RELEASE="$selected" FIXTURE_RESULT="$RESULT" \
    bash "$TEST_HOME/bin/teamkb-compile-daily.sh" "$@"
}

seed_audit() {
  local audit="$TEST_HOME/.claude/skills/teamkb-compile/methodology/decisions.jsonl"
  mkdir -p "$(dirname "$audit")"
  printf 'audit sentinel\n\n' > "$audit"
  cp "$audit" "$BATS_TEST_TMPDIR/audit-before.jsonl"
}

assert_audit_preserved() {
  cmp "$TEST_HOME/.claude/skills/teamkb-compile/methodology/decisions.jsonl" "$BATS_TEST_TMPDIR/audit-before.jsonl"
}

seed_index() {
  local index="$TEST_HOME/.claude/skills/teamkb-compile/methodology/index.db"
  mkdir -p "$(dirname "$index")"
  python3 - "$index" <<'PY_INDEX'
import sqlite3,sys
with sqlite3.connect(sys.argv[1]) as db:
    db.execute('CREATE TABLE fixture (id INTEGER PRIMARY KEY, value TEXT)')
    db.execute('INSERT INTO fixture VALUES (1, ?)', ('preserved index fixture',))
PY_INDEX
  cp "$index" "$BATS_TEST_TMPDIR/index-before.db"
}

assert_index_preserved() {
  local index="$TEST_HOME/.claude/skills/teamkb-compile/methodology/index.db"
  cmp "$index" "$BATS_TEST_TMPDIR/index-before.db"
  python3 - "$index" <<'PY_INDEX'
import sqlite3,sys
with sqlite3.connect('file:' + sys.argv[1] + '?mode=ro', uri=True) as db:
    assert db.execute('PRAGMA integrity_check').fetchone() == ('ok',)
    assert db.execute('SELECT value FROM fixture WHERE id=1').fetchone() == ('preserved index fixture',)
PY_INDEX
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
  seed_audit
  seed_index
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
  assert_audit_preserved
  assert_index_preserved
}

@test "compile-only preserves review skill and unrelated executable bytes" {
  mkdir -p "$TEST_HOME/bin" "$TEST_HOME/.claude/skills/teamkb-review"
  printf 'review sentinel\n' > "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md"
  for name in teamkb-quality-digest.sh teamkb-backup.sh; do
    printf 'runtime sentinel\n' > "$TEST_HOME/bin/$name"
  done
  seed_index
  seed_audit
  run deploy --compile-only
  [ "$status" -eq 0 ]
  assert_index_preserved
  assert_audit_preserved
  [ "$(cat "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md")" = 'review sentinel' ]
  for name in teamkb-quality-digest.sh teamkb-backup.sh; do
    [ "$(cat "$TEST_HOME/bin/$name")" = 'runtime sentinel' ]
  done
  [ ! -e "$TEST_HOME/.claude/skills/teamkb-review/scripts" ]
}

@test "full deploy preserves a separately managed quality observer's bytes and mode" {
  local digest="$TEST_HOME/bin/teamkb-quality-digest.sh"
  mkdir -p "$TEST_HOME/bin"
  printf '#!/bin/sh\n# separately managed observer\nexit 23\n' > "$digest"
  chmod 0700 "$digest"
  cp "$digest" "$BATS_TEST_TMPDIR/digest-before.sh"
  run deploy
  [ "$status" -eq 0 ]
  cmp "$digest" "$BATS_TEST_TMPDIR/digest-before.sh"
  [ "$(stat -c %a "$digest")" = 700 ]
  [[ "$output" == *'quality digest preserved'* ]]
  cmp "$ROOT/bin/teamkb-backup.sh" "$TEST_HOME/bin/teamkb-backup.sh"
  [ -f "$TEST_HOME/.claude/skills/teamkb-review/SKILL.md" ]
}

@test "full deploy preserves an existing dangling quality observer symlink" {
  local digest="$TEST_HOME/bin/teamkb-quality-digest.sh"
  local target="$TEST_HOME/separately-managed-observer.sh"
  mkdir -p "$TEST_HOME/bin"
  ln -s "$target" "$digest"
  run deploy
  [ "$status" -eq 0 ]
  [ -L "$digest" ]
  [ "$(readlink "$digest")" = "$target" ]
  [ ! -e "$target" ]
  [[ "$output" == *'quality digest preserved'* ]]
}

@test "full deploy preserves an observer created at the publication boundary" {
  mkdir -p "$TEST_HOME/tools"
  cat > "$TEST_HOME/tools/ln" <<'TOOL'
#!/usr/bin/env bash
printf 'concurrent owner fixture\n' > "${@: -1}"
exit 1
TOOL
  chmod +x "$TEST_HOME/tools/ln"
  run deploy_with_tools
  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_HOME/bin/teamkb-quality-digest.sh")" = 'concurrent owner fixture' ]
  [[ "$output" == *'quality digest preserved'* ]]
  cmp "$ROOT/bin/teamkb-backup.sh" "$TEST_HOME/bin/teamkb-backup.sh"
  run compgen -G "$TEST_HOME/bin/.teamkb-quality-digest.*"
  [ "$status" -eq 1 ]
}

@test "failed quality seed publication stops before backup and removes its seed" {
  mkdir -p "$TEST_HOME/tools"
  printf '#!/bin/sh\nexit 1\n' > "$TEST_HOME/tools/ln"
  chmod +x "$TEST_HOME/tools/ln"
  run deploy_with_tools
  [ "$status" -eq 1 ]
  [[ "$output" == *'Unable to seed quality digest'* ]]
  [ ! -e "$TEST_HOME/bin/teamkb-quality-digest.sh" ]
  [ ! -e "$TEST_HOME/bin/teamkb-backup.sh" ]
  run compgen -G "$TEST_HOME/bin/.teamkb-quality-digest.*"
  [ "$status" -eq 1 ]
}

@test "failed quality seed preparation removes its unpublished temporary file" {
  mkdir -p "$TEST_HOME/tools"
  cat > "$TEST_HOME/tools/install" <<'TOOL'
#!/usr/bin/env bash
case "${@: -1}" in
  "$HOME/bin/.teamkb-quality-digest."*) exit 1 ;;
esac
exec /usr/bin/install "$@"
TOOL
  chmod +x "$TEST_HOME/tools/install"
  run deploy_with_tools
  [ "$status" -eq 1 ]
  [ ! -e "$TEST_HOME/bin/teamkb-quality-digest.sh" ]
  [ ! -e "$TEST_HOME/bin/teamkb-backup.sh" ]
  run compgen -G "$TEST_HOME/bin/.teamkb-quality-digest.*"
  [ "$status" -eq 1 ]
}

@test "first deploy seeds empty audit log and a repeat preserves its contents" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  local audit="$TEST_HOME/.claude/skills/teamkb-compile/methodology/decisions.jsonl"
  [ -f "$audit" ]
  [ ! -s "$audit" ]
  printf 'later audit\n\n' > "$audit"
  cp "$audit" "$BATS_TEST_TMPDIR/audit-before.jsonl"
  run deploy --compile-only
  [ "$status" -eq 0 ]
  assert_audit_preserved
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

@test "unavailable compiler revision fails before activation and leaves the old wrapper unchanged" {
  mkdir -p "$TEST_HOME/bin"
  printf 'old wrapper\n' > "$TEST_HOME/bin/teamkb-compile-daily.sh"
  REVISION=0000000000000000000000000000000000000000
  run deploy
  [ "$status" -ne 0 ]
  [ ! -e "$RELEASE" ]
  [ ! -L "$RELEASE" ]
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

@test "drift in any of the six pinned payloads prevents entry execution" {
  run deploy --compile-only
  [ "$status" -eq 0 ]
  for name in nightly-entry.py runtime-proof.py c8-mcp.py teamkb-compile-daily.sh eval-distiller-output.mjs notify-routing.sh; do
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
  run selected_entry "$selected" --selected
  [ "$status" -eq 0 ]
  python3 - "$RESULT" <<'PY_ASSERT'
import json,sys
assert json.load(open(sys.argv[1])) == ['--selected']
PY_ASSERT
  rm -- "$RESULT"
  cp "$selected/manifest.json" "$BATS_TEST_TMPDIR/selected-manifest.json"
  printf 'invalid selected manifest\n' > "$selected/manifest.json"
  run selected_entry "$selected"
  [ "$status" -eq 69 ]
  [ ! -e "$RESULT" ]
  cp "$BATS_TEST_TMPDIR/selected-manifest.json" "$selected/manifest.json"
  printf '\n# selected entry drift\n' >> "$selected/nightly-entry.py"
  run selected_entry "$selected"
  [ "$status" -eq 69 ]
  [ ! -e "$RESULT" ]
  cp "$RELEASE/nightly-entry.py" "$selected/nightly-entry.py"
  run selected_entry "$selected" --selected
  [ "$status" -eq 0 ]
  [ -f "$RESULT" ]
}
