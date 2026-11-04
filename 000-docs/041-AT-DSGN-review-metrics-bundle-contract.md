# Review metrics Compiler bundle contract

Bead: `compile-then-govern-6ps.14.1`, under review-agent measurement task
`compile-then-govern-6ps.14`. This is an installer/launcher source change tested
in disposable release directories. It does not select a production revision,
install a live bundle, activate a cron, provision a token or permit scaling.

The Compiler owns `scripts/distiller/review-metrics.py` and its review-phase
invocation. This repository owns commit-addressed distribution and verification.
The previous exact six-file contract omitted the new helper, leaving source
instrumentation unavailable after an otherwise successful installation.

## Selected Git objects determine the payload

`bin/install-teamkb-compiler.py` retains the existing six base files. If the
explicitly selected full Compiler commit contains `review-metrics.py` in its
distiller tree, the installer copies that seventh file from the same Git object,
compiles it for syntax validation, and includes its SHA-256 in the manifest.
It never copies the mutable working tree. The selected commit must remain an
ancestor of the source repository's `origin/main` tracking ref; this is the
existing selection rule, not an independent approval attestation.

A wrapper containing the known literal `review-metrics.py` dependency without
that file in its selected tree is rejected before replacing `current`. This is
a bounded compatibility check for the current Compiler's dependency spelling,
not a general shell dependency analyzer. The base file set remains mandatory;
missing or invalid dependencies retain the existing fail-closed install behavior.

The installed launcher accepts exactly the six base manifest entries or those
six plus the metrics helper. It hashes every listed file before delegation. A
hash-verified wrapper that declares the known metrics helper must also have that
helper in its verified manifest. This rejects a newer wrapper packaged by the
older six-file installer, including a manifest with the helper entry removed.
It does not execute an unverified helper.

## Legacy compatibility and rollback

Older Compiler commits without the helper and without the dependency spelling
retain the exact existing six-file manifest. Their installs remain idempotent,
and verified old bundles can still be selected through the existing `previous`
symlink rollback process. Five-file manifests remain unsupported. New seven-file
bundles receive the same full-commit/hash checks and managed `current`/`previous`
behavior; existing release contents under a commit are never overwritten to hide
drift.

These local manifest checks detect divergence from the manifest. They do not
establish externally anchored signatures, approval of a revision, or protection
against a local writer replacing both files and manifest. The source merge is
separate from choosing or installing any runtime revision.

## Evidence and tests

`scripts/test-compile-install.py` uses temporary Git repositories, synthetic
payloads, temporary HOME and temporary managed release directories. New controls
prove the helper comes from the selected commit despite mutable checkout changes;
missing or modified installed helpers fail before execution; a stripped helper
manifest entry fails; incomplete source retains `current`; and upgrade followed
by verified legacy rollback succeeds. Existing revision-selection, notification
dependency, audit preservation and deployment-branch tests remain required.

```bash
python3 scripts/test-compile-install.py -v
bash scripts/test-teamkb-compile-lock.sh
bats scripts/test-compile-deploy.bats
shellcheck --severity=warning bin/teamkb-compile-daily.sh
```

After the Compiler source PR is merged, an additional disposable install of its
exact merged revision must confirm seven pinned files and matching hashes. That
installation must not execute the real nightly entry or change an operator's
runtime. Synthetic launcher tests supply the successful-execution evidence;
the real-source disposable install supplies the artifact-completeness evidence.
Neither proves a live provider call, real usage availability, billing accuracy,
nightly operation or production acceptance. Parent task closure must retain those
limits and must not claim installed operation.
