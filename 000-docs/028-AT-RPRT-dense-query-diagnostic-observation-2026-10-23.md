# Dense-query diagnostic observation — 2026-10-23

This local readiness observation failed. After registrar PR388 added per-invocation
diagnostics, one separately recorded run observed **49 timeouts and one transport
failure across all 45 scored queries and five unscored gaps**. No events were
dropped. The transport failure occurred during scored invocation e07. The
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
an acceptance success. These are degraded results; dense was unavailable for
every invocation. Qmd, native and dense snapshots were present, but that does not
prove every lexical query arm executed successfully. No controlled before/after
or pure-hybrid comparison is established.

After the observation, the configured embedder service reported active/running
and zero restarts; its health endpoint returned 200 in 0.11 s. One separately named
synthetic embedding request returned 200 and one 768-dimensional vector in 12.883 s,
using a 30 s observation deadline. The production request budget remained 5 s.
The sanitized journal summary counted 49 cancellation markers during the run.
A CPU-pressure sample after the run was high; compiler CLI tests were also running.
These observations support a current responsiveness/cancellation problem without
proving a sole cause or characterizing production load.

## Remaining work

`compile-then-govern-1io.8` remains in progress. Inspect pinned-service queue and
request timing, distinguish host scheduling from service work, and preserve the
existing fail-open and timeout policies. Do not rerun until clean or overwrite
either captured run. Source instrumentation is merged; release publication,
bundle refresh, service deployment and team acceptance remain separate work.

The receipt is an operator-authored projection of private local run artifacts.
It contains no memory bodies, query text, raw responses, credentials or private
filesystem paths. Individual SQLite snapshots are consistent; the export tree
and independent snapshots do not form an atomic ensemble.
