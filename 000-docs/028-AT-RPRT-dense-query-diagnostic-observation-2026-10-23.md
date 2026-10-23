# Dense-query diagnostic observation — 2026-10-23

This diagnostic did not demonstrate successful dense-query acceptance. After registrar PR388 added per-invocation
diagnostics, one separately recorded run observed **49 timeouts and one transport
failure across all 45 scored queries and five unscored gaps**. The receipt contains one categorized event for each expected query ID; the
source report states its bounded event buffer dropped zero events. The transport failure occurred during scored invocation e07. The
[evidence receipt](028-AT-RPRT-dense-query-diagnostic-observation-2026-10-23.evidence.json)
contains sanitized events, exact source/hash references, scopes and limitations.

The run used registrar `15f19d4` from 22:54:38 to 23:03:58 UTC. It retained the original
45 questions and frozen labels; it ran before the later worktree-policy admission
or index refresh. It does not replace the earlier five-event degraded capture
recorded in the [delivery snapshot](026-AT-RPRT-stabilization-delivery-state-2026-10-23.md).
Those five historical causes remain unknown.

## Results and limits

The application returned 127 scored citation slots; 20 of 45 scored queries returned
none. Corrected-label Recall@10 was 0.0593, nDCG@10 was 0.0594, FAMA@10 was 0.0593,
and obsolete exposure was 0/45. Low obsolete exposure alongside low recall is not
an acceptance success. These are degraded results; none of the 50 evaluation invocations obtained a usable dense result within
its request contract. Qmd, native and dense snapshots were present, but that does not
prove every lexical query arm executed successfully. No controlled before/after
or pure-hybrid comparison is established.

After the observation, the configured embedder service reported active/running
and zero restarts; its health endpoint returned 200 in 0.11 s. One separately named
synthetic embedding request returned 200 and one 768-dimensional vector in 12.883 s,
using a 30 s observation deadline. The local evaluator used the source-default 5 s embedding budget
([pinned client source](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/15f19d44b8e8f84801c52ce61cfcba2fb9d7b53c/packages/qmd-adapter/src/dense/embed-client.ts));
no serving-artifact verification is claimed.
The sanitized journal summary counted 49 cancellation markers during the run.
A CPU-pressure sample after the run was high; compiler CLI tests were also running.
These observations are consistent with a responsiveness/cancellation issue in
this window; they establish neither a sole cause, persistence afterward nor
production impact.

## Remaining work

`compile-then-govern-1io.8` remains in progress. Inspect pinned-service queue and
request timing, distinguish host scheduling from service work, and preserve the
existing fail-open and timeout policies. Do not rerun until clean or overwrite
either captured run. Source instrumentation is merged in [registrar PR388](https://github.com/jeremylongshore/bobs-big-brain-registrar/pull/388); release publication,
bundle refresh, service deployment and team acceptance remain separate work.

The receipt is an operator-authored projection of private local run artifacts.
It contains no memory bodies, query text, raw responses, credentials or private
filesystem paths. The launcher uses the SQLite backup API; this receipt includes no separate
per-snapshot integrity-check output. The export tree and independent backups
do not form an atomic ensemble.

The receipt records K=10, frozen dataset file hash, pinned scorer/aggregation
source, and the45 per-query citation lists and metrics for offline replay.
No private memory text is required for that replay. Bead status is
operator-reported on2026-10-23; it is not a public tracker attestation.

## Offline replay

In a registrar checkout at the receipt source revision, supply the evidence JSON
path below. This scores the captured lists without retrieval or corpus writes.

```bash
node --import tsx --input-type=module - /path/to/evidence.json <<'NODE'
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { runEval } from './packages/qmd-adapter/src/eval/run-eval.ts';
import { ESTATE_ONBOARDING_V1_DATASET as dataset,
  ESTATE_ONBOARDING_V1_GAPS as gaps } from './packages/qmd-adapter/src/eval/datasets/estate-onboarding-v1.ts';
const p = JSON.parse(readFileSync(process.argv[2], 'utf8'));
assert.equal(execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(), p.sourceRevision);
const sha = createHash('sha256').update(readFileSync('packages/qmd-adapter/src/eval/datasets/estate-onboarding-v1.ts')).digest('hex');
assert.equal(sha, p.datasetSourceSha256);
assert.equal(p.k, 10);
assert.deepEqual(p.perQuery.map(q => q.id), dataset.queries.map(q => q.id));
const expected = new Set([...dataset.queries.map(q => `scored:${q.id}`), ...gaps.map(q => `gap:${q.id}`)]);
assert.equal(p.denseFailureEvents.length, expected.size);
assert.deepEqual(new Set(p.denseFailureEvents.map(e => `${e.phase}:${e.queryId}`)), expected);
const lists = new Map(p.perQuery.map(q => [q.id, q.retrieved]));
const replay = await runEval(dataset, async (_q, k, context) => lists.get(context.queryId).slice(0, k), { k: p.k });
for (const [key, value] of Object.entries(p.observedMetrics)) {
  assert.equal(typeof value, 'number');
  assert.ok(Number.isFinite(value) && Math.abs(replay[key] - value) < 1e-12, key);
}
for (let i = 0; i < p.perQuery.length; i++) {
  for (const key of ['recallAtK', 'ndcgAtK', 'famaAtK']) {
    const value = p.perQuery[i][key];
    assert.equal(typeof value, 'number');
    assert.ok(Number.isFinite(value) && Math.abs(replay.perQuery[i][key] - value) < 1e-12, key);
  }
}
console.log('PASS: frozen source,45 citation lists,50 identities and metrics replay');
NODE
```
