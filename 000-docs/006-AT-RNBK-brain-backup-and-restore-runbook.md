# 006-AT-RNBK — Governed-brain backup & restore runbook

Operational companion to [`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md)
(which defines *what* the brain stores and *why* the backup scope is what it is). This doc is
*how* the backup runs and *how to restore it*. Bead `compile-then-govern-c5k.4`.

The whole live brain is one directory on the dev box: `~/.teamkb/` (~48–56 MB). The backup
captures the **source-of-truth + receipts**, not the cheaply-derived views.

The canonical source is [`bin/teamkb-backup.sh`](../bin/teamkb-backup.sh); `~/bin/teamkb-backup.sh`
is a deployed copy and must be changed only by the reviewed deploy helper. The failure path uses
Intent OS `af_dispatch` on `sys-backups` with MiniMax-M3 normalization requested, and requires a
`delivered` or `dedup_suppressed` receipt when an alert is attempted. It owns
`~/.local/state/intent-os/liveness/teamkb-backup.{beat,ok,skipped}`: `.beat` records every attempt,
`.ok` advances only after the local restore gate passes, and a writer-lock skip records `.skipped`
without falsely advancing `.ok`.

## What runs

| | |
|---|---|
| Script | `bin/teamkb-backup.sh` (canonical; deployed to `~/bin/teamkb-backup.sh`) |
| Schedule | systemd **user** timer `teamkb-backup.timer` — daily `04:30` (after `borg-backup.timer` at `00:00`), `Persistent=true` |
| Output | `~/.teamkb/backups/teamkb-full-<UTC>.tar.zst.age` (one self-contained encrypted archive) |
| Retain | newest 14 locally (`TEAMKB_BACKUP_RETAIN`) |
| Log | `~/.local/state/teamkb-backup/backup.log` |

borg still runs separately and gives a live whole-`$HOME` hot copy; it is **not** a substitute
for this — borg hot-copies a WAL-mode SQLite file (possibly mid-write) and is not restore-tested
per-brain. This script is the quiesced, restore-tested, brain-scoped path.

## What's in the archive

Captured (per `005-AT-ARCH` scope):

- **Tier A (must-have):** `dbs/teamkb.db` (govern DB, `VACUUM INTO` snapshot) · `dbs/ico-state.db`
  (compile DB, `VACUUM INTO` snapshot) · `brain/raw/` (corpus = source of truth) · `brain/audit/`
  (hash-chained receipts) · `spool/` (shared ICO/plugin→INTKB handoff) · `tokens.json` (secret —
  protected by the archive's age encryption)
- **Tier B (expensive-derived):** `brain/wiki/` (compiled markdown) · `feedback/`
- **`MANIFEST.txt`** — timestamp, table counts, corpus/receipt file counts, component list

Deliberately **skipped** (cheaply re-derived from Tier A): `kb-export/`, `qmd-index/`,
`brain/recall/`, `brain/outputs/`, `brain/tasks/`.

## Encryption & key custody

The archive is `age`-encrypted to **two recipients**, so it restores even if the dev box is lost:

- dev-box SOPS key — `~/.config/sops/age/keys.txt` → recipient `age1me3v…`
- VPS host key — `/etc/intentsolutions/age.key` (root) → recipient `age1csyjr…`

Either private key decrypts any archive. Plaintext is never written to durable disk — the
in-script restore test decrypts only onto `/dev/shm` (tmpfs).

## Acceptance gate (runs every backup)

A backup is **kept only if it provably restores**. After encrypting, the script decrypts +
extracts onto tmpfs and asserts: both DBs `PRAGMA integrity_check = ok` **and** their
`sqlite_master` table counts match the pre-encryption snapshot; `brain/raw/` and `brain/audit/`
restore with the recorded file counts; `tokens.json` is present. Any failure → the archive is
deleted (an unrestorable backup is worse than a missing one) and the run exits non-zero.
The local archive remains available when an off-host push is degraded; that degradation is logged
and sent through `sys-backups`, while `.ok` continues to mean only that the local restore gate
passed.

## Restore procedure (disaster recovery)

From the encrypted artifact alone (works with either private key):

```bash
ENC=$(/usr/bin/ls -1t ~/.teamkb/backups/teamkb-full-*.tar.zst.age | head -1)   # or the off-host copy
KEY=~/.config/sops/age/keys.txt            # on the VPS: /etc/intentsolutions/age.key

# 1. decrypt + extract to a staging dir
mkdir -p /tmp/teamkb-restore
~/bin/age -d -i "$KEY" -o /tmp/teamkb-restore/b.tar.zst "$ENC"
tar --zstd -xf /tmp/teamkb-restore/b.tar.zst -C /tmp/teamkb-restore
cat /tmp/teamkb-restore/MANIFEST.txt        # sanity: table/file counts

# 2. verify before trusting
sqlite3 /tmp/teamkb-restore/dbs/teamkb.db   'PRAGMA integrity_check;'   # expect: ok
sqlite3 /tmp/teamkb-restore/dbs/ico-state.db 'PRAGMA integrity_check;'  # expect: ok

# 3. stop the live writer, swap the brain into place, restart
systemctl --user stop teamkb-brain-api
mv ~/.teamkb ~/.teamkb.bak-$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p ~/.teamkb/brain/.ico
cp /tmp/teamkb-restore/dbs/teamkb.db        ~/.teamkb/teamkb.db
cp /tmp/teamkb-restore/dbs/ico-state.db     ~/.teamkb/brain/.ico/state.db
cp -a /tmp/teamkb-restore/brain/raw         ~/.teamkb/brain/raw
cp -a /tmp/teamkb-restore/brain/audit       ~/.teamkb/brain/audit
cp -a /tmp/teamkb-restore/spool             ~/.teamkb/spool         2>/dev/null || true
cp -a /tmp/teamkb-restore/brain/wiki        ~/.teamkb/brain/wiki    2>/dev/null || true
cp /tmp/teamkb-restore/tokens.json          ~/.teamkb/tokens.json && chmod 600 ~/.teamkb/tokens.json
systemctl --user start teamkb-brain-api

# 4. prove the receipts chain survived (the whole point of the brand)
#    in qmd-team-intent-kb: curator-cli verify-audit-chain --db ~/.teamkb/teamkb.db
```

The derived dirs (`kb-export/`, `qmd-index/`) are intentionally absent after a restore — rebuild
them from the restored corpus + DBs (re-index / re-export); they were never the source of truth.

## Off-host (LIVE — VPS over the tailnet)

Every run pushes the encrypted archive off the dev box to the VPS `intentsolutions` over the
tailnet (`TEAMKB_VPS_REMOTE=intentsolutions:teamkb-backups`, on by default): `rsync` the `.age`,
verify the remote copy **byte-for-byte by `sha256`**, then prune the VPS to the newest
`TEAMKB_BACKUP_RETAIN`. Non-fatal if the tailnet/VPS is unreachable — the local copy is retained
and the next run re-pushes. The failure is not silent: the source emits a governed `sys-backups`
receipt and accepts only `delivered` or `dedup_suppressed`; an unaccepted receipt is recorded as a
delivery failure without deleting the verified local artifact. Set `TEAMKB_VPS_REMOTE=` explicitly
to disable the target in a hermetic or intentionally local-only run.

This is a real DR site, not just a file drop: the archive is encrypted to the VPS host key
(`age1csyjr…`) and the VPS holds the matching private key (`/etc/intentsolutions/age.key`,
readable by the `intentsolutions` user via the `adm` group). **Verified end-to-end** — the VPS
decrypts its own copy with the host key and the corpus (726 files) extracts cleanly. Note: the VPS
has `age` + `zstd` but **not** `sqlite3`, so treat it as **cold storage** — decrypt there, then
restore the DBs onto a brain host (which has `sqlite3`) per the restore procedure above.

**R2 (second off-host target — `c5k.6`, LIVE 2026-06-25):** each backup run also pushes the `.age`
to `r2-teamkb:teamkb-backups` (Cloudflare R2, rclone S3; default `TEAMKB_R2_REMOTE`). The S3 access
key id + secret live in the runbook `secrets.prod.sops.yaml` (keys `r2_teamkb_*`, age-encrypted) and
in `~/.config/rclone/rclone.conf` for runtime; bucket created and first push verified. This is a
belt-and-suspenders **backup** (encrypted blobs) on top of the VPS off-host — **not** the team brain
bridge (that is the INTKB tailnet API + the unified plugin's team mode). Restore from R2: `rclone
copy r2-teamkb:teamkb-backups/<archive>.age .` then follow the decrypt+restore procedure above.
Set `TEAMKB_R2_REMOTE=` explicitly to skip R2; an empty override is distinct from the default
`r2-teamkb:teamkb-backups` target.
