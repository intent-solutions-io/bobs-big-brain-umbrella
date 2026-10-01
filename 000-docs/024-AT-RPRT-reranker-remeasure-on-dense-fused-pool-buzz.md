# 024-AT-RPRT — Qwen3 reranker re-measured over the dense-fused candidate pool (run on Buzz)

Bead: `compile-then-govern-39z.7` (parent epic `39z`). Measurement date: 2026-10-01.
Mode: external measurement host, no live service touched. Draft; not committed.

## Verdict

**YES on quality, with a serving-latency caveat. The decision rule in the bead is met: the semantic delta is NOT ~zero over a dense-fused pool.**

The original MISS (050-AT-RNBK section 9) is not generation-independent. Over a dense-fused pool the reranker lifts the semantic stratum's ranking quality materially (nDCG@10 +0.1023, MRR +0.1466), against an original semantic delta of structurally 0.0000. The bead's rule says that if it now helps, it earned its footprint; it did.

Caveats that belong next to the YES:

- **Recall@10 did not improve; it dipped by 1 query-gold.** Semantic Recall@10 0.9643 -> 0.9464 (-0.0179). One query (q16, two gold docs) lost one gold out of the top 10 when the 50-doc window was truncated to topN 10. This is a ranking win, not a recall win. Dense already owns recall.
- **Lexical regressed slightly:** nDCG@10 -0.0113, MRR -0.0238 (Recall@10 unchanged at 1.0000). Smaller than the original run (-0.0259 / -0.0357), but the 050 gate asked for ~0.
- **Latency is the real cost.** 42 queries x 50 docs = 2100 docs in 3636.8 s of model time = **1.73 s/doc, 86.6 s/query** on 3 CPU threads. Not an interactive serving path. "Earns its footprint" holds for an offline / async rerank or a much smaller window; a top-k window sweep (e.g. 10 / 20) was NOT measured here and is the obvious follow-up before any default wiring.
- The 1.4 GiB resident is real: the reranker sat at 1.36 GiB RSS with `--parallel 1 --ctx-size 2048 --ubatch-size 512`, and ballooned to ~3.0 GiB RSS under the unit's own flags (see Deviations).

## What the stock harness does NOT measure (important)

The bead says to run `GOVERNED_EVAL_RERANK=1` "against the DENSE-fused baseline". **It cannot, as shipped.** In `governed-eval-anchor.ts`, `maybeRunRerankArm` builds its adapter with `rerank` only (no `dense`), so `GOVERNED_EVAL_RERANK=1` reranks the lexical-only fusion, which is the exact experiment that already missed. To measure the intended thing, this run added a scratch arm (`GOVERNED_EVAL_RERANK_ON_DENSE=1`, patch in Appendix B) that builds ONE adapter with both `dense` and `rerank`; `adapter.ts` runs `maybeRerank` over `fuseReciprocalRank(lexical, native, dense)`. Pool evidence: every one of the 42 queries had a full 50-doc rerank window (42/42 calls, 50 docs each) versus <=3 candidates for most semantic queries in the lexical-only pool.

Follow-up for the repo (not done here): upstream the compose option into `governed-eval-anchor.ts` so this is a first-class arm.

## Numbers (frozen snapshot sha256 0a0bf769...c7366b, verified against the lock; k=10; n=42: 14 lexical, 28 semantic)

| stratum | lexical-fused (R@10 / nDCG / MRR) | dense-fused baseline | dense-fused + rerank | rerank minus dense |
| --- | --- | --- | --- | --- |
| lexical (n=14) | 1.0000 / 0.9411 / 0.9286 | 1.0000 / 0.9265 / 0.9167 | 1.0000 / 0.9152 / 0.8929 | 0.0000 / -0.0113 / -0.0238 |
| semantic (n=28) | 0.3393 / 0.3433 / 0.3571 | 0.9643 / 0.7704 / 0.7076 | 0.9464 / 0.8727 / 0.8542 | -0.0179 / **+0.1023** / **+0.1466** |
| overall (n=42) | 0.5595 / 0.5426 / 0.5476 | 0.9762 / 0.8224 / 0.7773 | 0.9643 / 0.8869 / 0.8671 | -0.0119 / +0.0645 / +0.0898 |

Reproduction checks: the lexical-fused and dense-fused baselines reproduced the committed floors and the 051-AT-RNBK section 9 table to four decimals (`ANCHOR PASS`, fused and dense). Validity gates inside the new arm: rerank client calls = 42, **nulls (silent fail-open) = 0**, dense degraded queries = 0. The rerank score cache and reused dense index were derived data in a throwaway temp base.

Dense index: the preserved `dense-prebuilt/dense-vec.sqlite` (sha256 cfc07051...3ce9, 12,645 / 17,295 docs, covers the curated scope) was reused, per 051 section 9.

## Timing and Buzz impact (load evidence)

- Host: `intent-ops-buzz`, 6 cores / 11 GB. Pre-run: load 2.15 / 1.88 / 1.68 (residual from two aborted attempts earlier the same hour; idle load before any work was 0.25), MemAvailable 5.9 GB.
- Guard: one `systemd-run --user --scope -p MemoryMax=3G -p CPUQuota=300% nice -n 19` scope holding both llama-servers and the eval. Sampler (20 s) logged 186 samples, 02:36 to 03:38 UTC (wall 61 min for the rerank-on-dense arm; whole run ~62 min).
- Scope peak 1.64 GiB (memory.peak 1,725,394,944 B), peak anon 1.0 GiB, **minimum system MemAvailable 4.8 GB** (abort threshold was 2.0 GB, never approached).
- Load1 while running: ~3.0-3.4 for the first 52 minutes (that is my 3 threads on top of ~0.3-0.5 baseline). **From 03:24 to the end load1 climbed to 9.6 (max) and stayed ~9.** My scope's memory and the per-call rerank latency (80-95 s/call, flat all run) did not change at that point, so the spike was NOT produced by this job; it is unattributed foreign load on Buzz (the Win11 qemu guest or a container are the candidates; not investigated). It does not affect the scores (deterministic) or the timing figure (flat), but it exceeds the "load > 3" line, so I am reporting it rather than hiding it. The run is nice 19 and capped at 300%, and finished 14 minutes into the spike.
- The relay, postgres, redis, minio, the Win11 VM and omarchy-rig were not touched; 8 containers up before and after.

## Deviations from the runbooks (all flag-level; binary and weights are exact pins)

1. **Weights/binary:** llama.cpp b10068 installed via the repo's `install-llama-server.sh` (SHA-256 `6bf3d20d...4be4eb2` verified). Weights SHA-256 verified before every start (`sha256sum -c`, fail-closed): reranker `22c9979c...429a48`, embedder `b5ce9d77...490d63`. Reranker repo name in the manifest (`ggml-org/qwen3-reranker-0.6B-GGUF`) 401s on HuggingFace; the live repo is `ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF` (same filename, matching hash). Both GGUFs had been removed from `~/.cache/qmd/models` on the dev box, so they were downloaded on Buzz, not copied.
2. **Reranker flags:** the unit's `--ctx-size 4096 --ubatch-size 1024` (4 auto slots) hit ~3.0 GiB RSS and tripped the 3 GiB scope cap (attempt 1 OOM-killed the reranker mid-run; attempt 2 was stopped before it died). Final run used `--ctx-size 2048 --parallel 1 --batch-size 512 --ubatch-size 512 --threads 3` with `MALLOC_ARENA_MAX=2`. 600-char docs plus template are well under 512 tokens and a failure would have shown as a null (0 observed). Scoring is per-document math, so this changes memory, not scores. The unit's 1.47 GiB figure in the bead is therefore not what the unit's own flags use under a 50-doc batch on this build.
3. **Embedder flags:** `--ubatch-size 512` instead of 2048. Only 42 short queries are embedded (the dense index is prebuilt, no doc embedding), so the 2048 correctness requirement in 051 section 5 does not apply to this run. Do NOT use 512 to build an index.
4. **libgomp1** is absent on Buzz and apt installs are forbidden. Fetched the package without installing (`apt-get download libgomp1`, `dpkg-deb -x` into scratch) and pointed `LD_LIBRARY_PATH` at it.
5. **No compiler on Buzz:** `better-sqlite3@13` has its install script `node-gyp rebuild` but also ships `prebuilds/linux-x64.node`. `pnpm install --ignore-scripts` uses the prebuild and works.
6. Source: `git archive origin/main` at `100792efe277755a6919857d2d6567bfe1c84ff6` of the registrar, scp'd over the tailnet (nothing cloned from GitHub). The frozen snapshot and prebuilt dense index were scp'd over the tailnet only, sha256 verified on arrival.
7. Threads are 3 for the reranker and 2 for the embedder, within the 300% quota. CPU-only; no GPU.

## Cleanup (done)

Snapshot and dense index `shred -u`'d; `~/bbb-eval-scratch`, `~/.local/lib/bbb` (llama.cpp), `~/.local/opt` (node, pnpm), `~/.local/share/pnpm`, `~/.local/state/pnpm`, `~/.cache/{pnpm,node-gyp}`, `~/.npm` all removed. No process or systemd unit left running; no service enabled; Buzz's own files were untouched. Result artifacts are kept only here and in the dev-box session scratchpad.

## Runbook: re-run this eval on Buzz

Prereqs on the dev box (read-only sources): `git -C ~/000-projects/bobs-big-brain-registrar fetch origin main && git archive --format=tar.gz -o registrar-src.tgz origin/main`; the frozen snapshot `~/.teamkb/eval-anchor/kb-export-frozen-20260719T230939Z.tar.zst` (sha256 `0a0bf76963fd114c1c5b92f3ec6cdd8a6a91708df669cd5e35ea1c6047c7366b`) and `~/.teamkb/eval-anchor/dense-prebuilt/dense-vec.sqlite`. Check Buzz first: `uptime` (idle load must be < 3) and `free -m` (available > 2 GB); stop if not.

```bash
# 1. scratch dir + transfer (tailnet only; verify the hash)
ssh intent-ops-buzz 'umask 077; mkdir -p ~/bbb-eval-scratch && chmod 700 ~/bbb-eval-scratch'
scp kb-export-frozen-20260719T230939Z.tar.zst dense-vec.sqlite registrar-src.tgz intent-ops-buzz:bbb-eval-scratch/
ssh intent-ops-buzz 'cd ~/bbb-eval-scratch && sha256sum -c <<< "0a0bf76963fd114c1c5b92f3ec6cdd8a6a91708df669cd5e35ea1c6047c7366b  kb-export-frozen-20260719T230939Z.tar.zst"'

# 2. user-local toolchain (no apt)
V=v22.21.0; cd ~/bbb-eval-scratch
curl -fsSLO https://nodejs.org/dist/$V/node-$V-linux-x64.tar.xz
curl -fsSL https://nodejs.org/dist/$V/SHASUMS256.txt | grep node-$V-linux-x64.tar.xz | sha256sum -c
mkdir -p ~/.local/opt && tar -xJf node-$V-linux-x64.tar.xz -C ~/.local/opt
export PATH=$HOME/.local/opt/node-$V-linux-x64/bin:$HOME/.local/opt/pnpm9/bin:$PATH XDG_CONFIG_HOME=$HOME/bbb-eval-scratch/xdg
npm install -g --prefix ~/.local/opt/pnpm9 pnpm@9.15.4
mkdir -p src && tar -xzf registrar-src.tgz -C src
# libgomp without installing it
mkdir -p debs gomp && (cd debs && apt-get download libgomp1) && dpkg-deb -x debs/libgomp1*.deb gomp
export LD_LIBRARY_PATH=$HOME/bbb-eval-scratch/gomp/usr/lib/x86_64-linux-gnu
bash src/scripts/install-llama-server.sh      # SHA-pinned, fail-closed (b10068)

# 3. weights (HF repo for the reranker differs from the manifest name), then verify the pins
mkdir -p models && cd models
curl -fsSL -o emb.gguf https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/main/embeddinggemma-300M-Q8_0.gguf
curl -fsSL -o rr.gguf  https://huggingface.co/ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF/resolve/main/qwen3-reranker-0.6b-q8_0.gguf
printf '%s  emb.gguf\n%s  rr.gguf\n' b5ce9d77a3fc4b3b39ccb5643c36777911cc4eb46a66962eadfa3f5f60490d63 22c9979ce4fbcdc5acdc310c6641c32797eff1aa980b8f7a2db8a8ea23429a48 | sha256sum -c   # MUST say OK x2

# 4. build (ignore-scripts: better-sqlite3 uses its shipped prebuild; there is no make/gcc)
cd ~/bbb-eval-scratch/src
pnpm install --frozen-lockfile --ignore-scripts --filter "@qmd-team-intent-kb/qmd-adapter..." --filter @qmd-team-intent-kb/root
python3 ../patch.py        # Appendix B: adds GOVERNED_EVAL_RERANK_ON_DENSE
pnpm --filter @qmd-team-intent-kb/qmd-adapter build
```

The guarded run. Hold ONE persistent ssh session for the duration (linger is off on Buzz; the user manager, and so the scope, dies when the last session ends), and keep `run.sh` in one scope so MemoryMax covers everything:

```bash
ssh -o ServerAliveInterval=30 intent-ops-buzz \
  'systemd-run --user --scope -p MemoryMax=3G -p CPUQuota=300% nice -n 19 ~/bbb-eval-scratch/run.sh 2>&1 | tee ~/bbb-eval-scratch/logs/run.log'
```

`run.sh` does, in order: weight gate (`sha256sum -c`, exit 9 on failure), start the embedder (`--embedding --pooling mean --embd-normalize 2 --ctx-size 2048 --parallel 1 --threads 2 --threads-batch 2 --ubatch-size 512`, port 8098) and the reranker (`MALLOC_ARENA_MAX=2 ... --rerank --ctx-size 2048 --parallel 1 --threads 3 --threads-batch 3 --batch-size 512 --ubatch-size 512`, port 8097), start a 20 s sampler (load, scope memory, MemAvailable, abort if MemAvailable < 2 GB), then:

```bash
export GOVERNED_EVAL_SNAPSHOT=$SC/kb-export-frozen-20260719T230939Z.tar.zst
export GOVERNED_EVAL_DENSE=1 GOVERNED_EVAL_DENSE_PREBUILT=$SC/dense-vec.sqlite
export GOVERNED_EVAL_RERANK_ON_DENSE=1          # do NOT also set GOVERNED_EVAL_RERANK=1: the stock arm reranks the lexical pool and re-runs the old MISS
pnpm --filter @qmd-team-intent-kb/qmd-adapter eval:governed:local
```

Expect ~62 min (lexical index build ~1 min, dense baseline ~1 min, rerank ~61 min). Cleanup: `shred -u` the snapshot and dense index, then remove `~/bbb-eval-scratch`, `~/.local/{opt,lib/bbb,share/pnpm,state/pnpm}`, `~/.cache/{pnpm,node-gyp}`, `~/.npm`; confirm `ps` shows no llama-server and `docker ps` is unchanged. Copy the log and `governed-brain-v1-rerank-on-dense.json` off Buzz before deleting.

## Appendix A — per-query note

Exactly one query changed Recall@10 versus the dense baseline: q16 (semantic, "the model can propose actions but the deterministic system o...") 1.0 -> 0.5. Every other query had identical Recall@10; the ranking gain is all within-top-10 reordering.

## Appendix B — the scratch arm (diff against `governed-eval-anchor.ts` at origin/main 100792e)

Adds `import { RerankClient }`, a call `await maybeRunRerankOnDenseArm(exportDir, frozen.sr, denseSr, resultsDir, verified.sha256)` after the dense arm, and the function itself: it returns unless `GOVERNED_EVAL_RERANK_ON_DENSE=1` and the dense arm produced a result; reuses the dense arm's temp copy of the prebuilt index; builds `evalCorpus(..., { skipIndexBuild: true, logProgress: true, dense: { enabled, url: :8098, searchK: 50, maxDocChars: 2000, timeoutMs: 300000, onQueryDegraded, indexPath }, rerank: { enabled, url: :8097, candidateWindow: 50, topN: 10, maxDocChars: 600, timeoutMs: 300000 } })`; wraps `RerankClient.prototype.rerank` to count calls and `null` results (silent fail-open) and prints `INVALID MEASUREMENT` if any null or dense degradation occurred; prints deltas versus dense-fused and lexical-fused; writes `governed-brain-v1-rerank-on-dense.json`. The script that applies it (`patch.py`, run from the registrar checkout root; it asserts its anchors so it fails loudly if upstream moved) and `run.sh` are reproduced in full below; save them as `~/bbb-eval-scratch/patch.py` and `~/bbb-eval-scratch/run.sh` (the latter also needs `env.sh`).

### patch.py

```python
import re,sys
p='packages/qmd-adapter/src/eval/governed-eval-anchor.ts'
s=open(p).read()
s=s.replace("import { qmdRetrievalFn } from './qmd-retrieval.js';",
"import { qmdRetrievalFn } from './qmd-retrieval.js';\nimport { RerankClient } from '../rerank/rerank-client.js';",1)
call="    const denseSr = await maybeRunDenseArm(exportDir, frozen.sr, resultsDir, verified.sha256);\n"
assert call in s
s=s.replace(call, call+"    await maybeRunRerankOnDenseArm(exportDir, frozen.sr, denseSr, resultsDir, verified.sha256);\n",1)
fn='''
/**
 * SCRATCH PATCH (bead 39z.7, Buzz run): rerank over the DENSE-fused pool.
 * Upstream's GOVERNED_EVAL_RERANK arm builds its adapter WITHOUT `dense`, so it
 * reranks the lexical-only fusion. This arm composes dense + rerank in ONE
 * adapter (adapter.maybeRerank runs over fuseReciprocalRank(lexical, native, dense)).
 * Counts rerank-client failures so a silent fail-open cannot pass as a measurement.
 */
async function maybeRunRerankOnDenseArm(
  exportDir: string,
  fusedSr: StratifiedReport,
  denseSr: StratifiedReport | null,
  resultsDir: string,
  snapshotSha256: string,
): Promise<void> {
  if (process.env['GOVERNED_EVAL_RERANK_ON_DENSE'] !== '1') return;
  if (denseSr === null) {
    console.error('\\nrerank-on-dense arm SKIPPED: dense baseline arm did not produce a result');
    return;
  }
  const rerankUrl = process.env['GOVERNED_EVAL_RERANK_URL'] ?? 'http://127.0.0.1:8097';
  const denseUrl = process.env['GOVERNED_EVAL_DENSE_URL'] ?? 'http://127.0.0.1:8098';
  const indexPath = join(process.env['TEAMKB_BASE_PATH'] ?? tmpdir(), 'dense-prebuilt-reuse.sqlite');
  if (!existsSync(indexPath)) {
    console.error('\\nrerank-on-dense arm SKIPPED: reused dense index missing at ' + indexPath);
    return;
  }
  let rerankCalls = 0;
  let rerankNulls = 0;
  const proto = RerankClient.prototype as unknown as {
    rerank: (...a: unknown[]) => Promise<unknown>;
  };
  const orig = proto.rerank;
  proto.rerank = async function (this: unknown, ...a: unknown[]): Promise<unknown> {
    rerankCalls++;
    const t0 = Date.now();
    const r = await orig.apply(this, a);
    if (r === null) rerankNulls++;
    console.log(
      `    [rerank-call ${rerankCalls}] ${Array.isArray(a[1]) ? (a[1] as unknown[]).length : '?'} docs ` +
        `${((Date.now() - t0) / 1000).toFixed(1)} s ${r === null ? 'NULL(fail-open!)' : 'ok'}`,
    );
    return r;
  };
  const degradedDense: string[] = [];
  const t0 = Date.now();
  const res = await evalCorpus(exportDir, 'dense-fused + qwen3-rerank (frozen snapshot)', {
    skipIndexBuild: true,
    logProgress: true,
    dense: {
      enabled: true,
      url: denseUrl,
      searchK: 50,
      maxDocChars: 2000,
      timeoutMs: 300_000,
      onQueryDegraded: (r: unknown) => {
        degradedDense.push(r instanceof Error ? r.message : String(r));
      },
      indexPath,
    },
    rerank: {
      enabled: true,
      url: rerankUrl,
      candidateWindow: 50,
      topN: 10,
      maxDocChars: 600,
      timeoutMs: 300_000,
    },
  });
  proto.rerank = orig;
  const wallMin = (Date.now() - t0) / 60_000;
  if (!res.ok) {
    console.error('\\nrerank-on-dense arm FAILED: ' + res.reason);
    return;
  }
  console.log('\\n=== rerank-on-DENSE arm (informational; bead 39z.7) ===');
  console.log(formatStratifiedReport(res.sr));
  console.log(
    `wall ${wallMin.toFixed(1)} min · rerank client calls=${rerankCalls} nulls(fail-open)=${rerankNulls} · dense degraded queries=${degradedDense.length}`,
  );
  if (rerankNulls > 0 || degradedDense.length > 0) {
    console.error('INVALID MEASUREMENT: rerank fail-open or dense degradation occurred');
  }
  const fmt = (n: number): string => (n >= 0 ? '+' : '') + n.toFixed(4);
  for (const [name, base] of [['dense-fused', denseSr], ['lexical-fused', fusedSr]] as const) {
    console.log('\\n=== per-stratum delta (reranked-on-dense minus ' + name + ') ===');
    const by = new Map(base.byKind.map((x) => [x.stratum, x]));
    const rows = [...res.sr.byKind.map((x) => ({ x, b: by.get(x.stratum) })), { x: res.sr.overall, b: base.overall }];
    for (const { x, b } of rows) {
      if (!b) continue;
      console.log(
        `  ${x.stratum.padEnd(9)} dRecall@10=${fmt(x.meanRecallAtK - b.meanRecallAtK)}  ` +
          `dnDCG@10=${fmt(x.meanNdcgAtK - b.meanNdcgAtK)}  dMRR=${fmt(x.mrr - b.mrr)}`,
      );
    }
  }
  try {
    writeFileSync(
      join(resultsDir, 'governed-brain-v1-rerank-on-dense.json'),
      JSON.stringify(
        { snapshotSha256, wallMin, rerankCalls, rerankNulls, degradedDense: degradedDense.length,
          dense: { overall: denseSr.overall, byKind: denseSr.byKind },
          reranked: { overall: res.sr.overall, byKind: res.sr.byKind }, perQuery: res.perQuery },
        null, 2,
      ) + '\\n',
    );
  } catch (err: unknown) {
    console.error('WARN could not write artifact', err);
  }
}
'''
marker="/**\n * GOVERNED_EVAL_DENSE=1: the A/B arm for the dense-retrieval verdict (B4)."
assert marker in s
s=s.replace(marker, fn+"\n"+marker,1)
open(p,'w').write(s)
```

## Appendix C — env.sh and run.sh (as used)

```bash
# env.sh
export PATH=$HOME/.local/opt/node-v22.21.0-linux-x64/bin:$HOME/.local/opt/pnpm9/bin:$PATH
export XDG_CONFIG_HOME=$HOME/bbb-eval-scratch/xdg
export LD_LIBRARY_PATH=$HOME/bbb-eval-scratch/gomp/usr/lib/x86_64-linux-gnu
export TMPDIR=$HOME/bbb-eval-scratch/tmp
mkdir -p $TMPDIR $XDG_CONFIG_HOME
GUARD="systemd-run --user --scope --quiet -p MemoryMax=3G -p CPUQuota=300% nice -n 19"
```

```bash
# run.sh
#!/usr/bin/env bash
# Runs INSIDE the guard scope (MemoryMax=3G, CPUQuota=300%, nice 19).
set -uo pipefail
SC=$HOME/bbb-eval-scratch
source $SC/env.sh
LS=$HOME/.local/lib/bbb/llama-server/current/llama-server
LOG=$SC/logs; mkdir -p $LOG
# weight gate (fail-closed)
printf '%s  %s\n' b5ce9d77a3fc4b3b39ccb5643c36777911cc4eb46a66962eadfa3f5f60490d63 $SC/models/emb.gguf  > $SC/models/pins.sha256
printf '%s  %s\n' 22c9979ce4fbcdc5acdc310c6641c32797eff1aa980b8f7a2db8a8ea23429a48 $SC/models/rr.gguf  >> $SC/models/pins.sha256
sha256sum -c $SC/models/pins.sha256 || { echo "WEIGHT GATE FAILED"; exit 9; }
echo "$(cat /sys/fs/cgroup/$(cut -d: -f3 /proc/self/cgroup)/memory.max 2>/dev/null) <- scope memory.max"
CG=/sys/fs/cgroup$(cut -d: -f3 /proc/self/cgroup)

# sampler: load, scope mem, system available; aborts the run on unsafe host state
( while true; do
    la=$(cut -d' ' -f1-3 /proc/loadavg); av=$(awk '/MemAvailable/{print int($2/1024)}' /proc/meminfo)
    sm=$(( $(cat $CG/memory.current 2>/dev/null || echo 0) / 1048576 ))
    an=$(awk '/^anon /{print int($2/1048576)}' $CG/memory.stat 2>/dev/null); fl=$(awk '/^file /{print int($2/1048576)}' $CG/memory.stat 2>/dev/null)
    pr=$(ps -eo rss,args --sort=-rss 2>/dev/null | awk -v sc="$SC" '/bbb-eval-scratch|governed/{printf "%d:%s ", $1/1024, substr($2,length($2)-18)}' | cut -c1-200)
    echo "$(date -u +%FT%TZ) load=$la scopeMiB=$sm anon=$an file=$fl availMiB=$av | $pr" >> $LOG/sampler.log
    if [ "$av" -lt 2048 ]; then echo "ABORT: available RAM $av MiB < 2048" | tee -a $LOG/sampler.log; pkill -P $$ -f governed-eval; kill -TERM -$$ 2>/dev/null; kill -9 $PPID 2>/dev/null; break; fi
    sleep 20; done ) &
SAMPLER=$!

$LS -m $SC/models/emb.gguf --host 127.0.0.1 --port 8098 --embedding --pooling mean --embd-normalize 2 --ctx-size 2048 --parallel 1 --threads 2 --threads-batch 2 --ubatch-size 512 > $LOG/embedder.log 2>&1 &
EMB=$!
MALLOC_ARENA_MAX=2 $LS -m $SC/models/rr.gguf --host 127.0.0.1 --port 8097 --rerank --ctx-size 2048 --parallel 1 --threads 3 --threads-batch 3 --batch-size 512 --ubatch-size 512 > $LOG/reranker.log 2>&1 &
RR=$!
cleanup(){ kill $EMB $RR $SAMPLER 2>/dev/null; sleep 1; kill -9 $EMB $RR 2>/dev/null; }
trap cleanup EXIT
for i in $(seq 1 60); do
  curl -sf http://127.0.0.1:8098/health >/dev/null && curl -sf http://127.0.0.1:8097/health >/dev/null && break; sleep 2; done
curl -s http://127.0.0.1:8098/health; curl -s http://127.0.0.1:8097/health; echo
echo "servers up: rss(MiB) emb=$(( $(awk '/VmRSS/{print $2}' /proc/$EMB/status) / 1024 )) rr=$(( $(awk '/VmRSS/{print $2}' /proc/$RR/status) / 1024 ))"
cd $SC/src
export GOVERNED_EVAL_SNAPSHOT=$SC/kb-export-frozen-20260719T230939Z.tar.zst
export GOVERNED_EVAL_DENSE=1 GOVERNED_EVAL_DENSE_PREBUILT=$SC/dense-vec.sqlite
export GOVERNED_EVAL_RERANK_ON_DENSE=1
export GOVERNED_EVAL_JSON_PATH=$SC/logs/governed-brain-v1.json
echo "=== eval start $(date -u +%FT%TZ) ==="
pnpm install --frozen-lockfile --ignore-scripts --offline --filter "@qmd-team-intent-kb/qmd-adapter..." --filter @qmd-team-intent-kb/root >/dev/null 2>&1
pnpm --filter @qmd-team-intent-kb/qmd-adapter eval:governed:local
rc=$?
echo "=== eval end rc=$rc $(date -u +%FT%TZ) ==="
echo "peak scope mem: $(cat $CG/memory.peak 2>/dev/null)"
exit $rc
```
