# 023-AT-RPRT — Triage of the 2026-07-16 "bulk import" and the over-capture premise

Bead: `compile-then-govern-39z.3` (parent epic `39z`). Date of measurement: 2026-10-01.
Mode: READ-ONLY. Source: a `.backup` copy of `~/.teamkb/teamkb.db` (the live DB, `integrity_check` = ok). Nothing in `~/.teamkb` or any repo was modified. Draft for CTO review; not committed.

## 1. Verdict

The bead's headline is right and its details are wrong in four places that change the plan.

| Bead claim | Measured 2026-10-01 | Verdict |
|---|---|---|
| The daily loop is not over-capturing; the mass is one import | Correct. `mcp` source = 937 rows in ~3 months; every mcp row is a decision/pattern/etc. except 50 reference | **Right** |
| "One bulk vault import on 2026-07-16" | It is the **Intentional Cognition OS compile output** (`wiki/sources/*`, `wiki/open-questions/*`, `wiki/entities/*`), promoted by the `curator` system actor, tagged `source='import'`, in **three waves**: 06-14 (680), 06-22 (1,374), **07-16 (14,956)**, +1 on 08-17. There is no vault; the 07-16 wave is 92% of it | **Wrong in kind and in "one"** |
| 16,201 reference rows are the problem | 16,202 import-reference rows exist, but **7,135 (44%) are already retired** (6,443 superseded, 681 deprecated, 11 archived). Only **9,067 are active** | **Stale** |
| Reversible via `import_batches.rolled_back` | `import_batches` has **0 rows**, `memory_links.import_batch_id` is NULL on all 302 links. No batch exists to roll back. Reversibility must come from the lifecycle state machine instead | **Wrong** |
| 'where are secrets stored SOPS age encryption' returns 0 despite 16k reference rows | Not reproducible as a ranking symptom. A lexical simulation of `secrets SOPS age` matches 880 active rows and the top 10 are 9 curated (mcp) + 1 import (§5). The zero-result case is a query-shape problem (a sentence ANDed as one FTS expression), not corpus noise | **Wrong diagnosis** |

Bottom line: the "over-capture" premise is directionally right about the *source* (compile pipeline output, not the daily capture loop) and wrong that this is a ranking problem. Retrieval already buries the mass (reference boost 0.9 vs decision 1.2; the curated rows win the top of every sampled query). The real defects are (a) a **cold-start capture that was never curated**, (b) a **mis-firing auto-supersession** that retired thousands of distinct documents on title similarity alone, and (c) **~5,000 low-value or stale rows still active** that dilute recall and the corpus statistics.

## 2. What the import was

SQL: `select source,lifecycle,count(*),min(promoted_at),max(promoted_at) from curated_memories group by 1,2;`

- Author (all 17,011 import rows): `{"type":"ai","id":"ico","name":"Intentional Cognition OS"}`; promoted_by `{"type":"system","id":"curator"}`; `projectContext = intentional-cognition-os`.
- `metadata_json.filePaths[0]` is always `wiki/...` (16,202 reference rows): ICO-compiled wiki pages. `wiki/sources/<repo>-<path>` = one page per ingested machine file (CLAUDE.md, READMEs, 000-docs, skills, archives); `wiki/open-questions/*` = LLM-generated questions; `wiki/entities|concepts/*` = extracted entities.
- Timing (`substr(promoted_at,1,13)`): 06-14T04 132, 06-14T14 548, 06-22T06 1,374, **07-16T21 5,222, 07-16T22 8,513, 07-16T23 1,221**, 08-17T02 1. This matches the "whole-machine digest" (`~/.teamkb/corpus-machine`) compile.
- Tags: 888 of the active+retired reference rows have 0 tags; median 3-4 LLM-assigned tags. Trust level is `medium` for all.
- Provenance: every row has a `promoted` receipt by actor `curator`. `import_batches`: empty. `memory_links`: 302 rows, all `supersedes`, all by `curator`, no batch id. (The bead's own warning was right: batch attribution is only possible by `promoted_at` window and `metadata.filePaths`; there is no clean linkage.)
- Prior cleanup already happened and is receipted: 11 `archived` (07-17, owner, "Whole-machine digest junk sweep 2026-07-16 (Jeremy-directed)"), 681 `demoted` (07-17/18, owner, "GCP vendored-docs demotion 2026-07-17 (Jeremy-approved)", all `iams-gcp-resources-*` paths).

## 3. Classification (16,202 import-reference rows)

Rules are applied in order; first match wins (SQL in §7). Columns: all rows, then the active slice.

| Disposition | Rule | Rows |
|---|---|---|
| 0. Already retired | lifecycle != active | **7,135** (6,443 superseded, 681 deprecated, 11 archived) |
| 1. Stale-platform | active, path/title names gcp / google-cloud / firebase / vertex / netlify | **179** |
| 2. Archive or third-party copies | active, path in `*archive*`, `backups-`, `99-forked`, `contributing-*`, `wild-*` (forked OSS) | **1,870** |
| 3. Vendor skill-pack boilerplate | active, `plugins-saas-packs`, `*-skill`, `*-skills-*`, skill READMEs of claude-code-plugins/nixtla | **3,107** |
| 4. Open question or stub | active, `wiki/open-questions/*`, content < 300 chars, or title in {Scripts, References, Assets, Templates, Overview} | **401** |
| 5. Estate candidate (keep) | everything else: project 000-docs (2,264), other sources (704), blog (338), entities/concepts (117), CLAUDE.md snapshots (87) | **3,510** |
| Total | | 16,202 (sums exactly) |

Active total = 179 + 1,870 + 3,107 + 401 + 3,510 = **9,067**.

Duplicates: **no exact duplicates remain** (16,202 distinct `content_hash`; 9,067 distinct lower(title) among active). The curator's dedupe worked at the exact level. Content-prefix near-duplicates among active: 4 groups / 4 removable rows (first 300 chars). Near-duplication shows up instead as *template twins*: the same skill-pack README repeated per vendor (rows in bucket 3) and nixtla-010-archive copies (642 active rows). Those are low-value rather than duplicate by hash.

Stale content (term hits, not paths): of the 3,510 "keep" rows, 839 mention gcp/google cloud/firebase/vertex/bigquery/netlify/gcloud/secret manager or retired repo names (`intentional-cognition-os`, `qmd-team-intent-kb`, `governed second brain`, `compile-then-govern`); 149 of them name `gcloud` / `firebase deploy` / `netlify`. A mention is not staleness (e.g. the "GCP exodus tracker" is correctly historical, and the pre-rename repo names are historical-correct in old AARs). Treat 839 as a **review queue, not a delete list**; 149 are the likely true-stale subset.

Genuinely useful: bucket 5 (3,510, 39% of active) contains the real estate record (VPS runbooks, backup docs, AARs, decision-records, mission-control). Sampled queries in §5 show these ranking 2-6 times in the top 10 for ops topics ("VPS Contabo", "GCP exodus", "backup borg B2", "Caddy reload deploy"), i.e. they are load-bearing for ops recall, and must NOT be bulk-deprecated.

Active category totals (all sources): decision 142, architecture 164, convention 148, onboarding 23, pattern 671, troubleshooting 489, reference 9,117 (9,067 import + 50 mcp). The reference class is 85% of active rows and ~23 MB of content; decision/architecture/convention content is under 1 MB combined.

## 4. The supersession defect (bigger than the over-capture finding)

`curated_memories.supersession_json.reason` for superseded rows: "Title similarity: 1.00" 3,207; 0.60 2,149; 0.67 418; 0.75 299; 0.71 136; 0.63 84; 0.80 52... Supersession is Jaccard on **titles within a category** (matches memory `brain-relevancy-and-supersession-gap`), applied at promotion time (audit `superseded` actor `curator` on the same hour as the `promoted`). Samples from the retired set:

- `MaintainX Webhooks & Events` superseded by `MindTickle Webhooks & Events` (0.60)
- `Supabase Load & Scale` superseded by `Vercel Load & Scale` (0.60)
- `Scripts for xss-vulnerability-scanner skill` superseded by `Scripts for zapier-zap-builder skill` (0.60)
- `Scripts` by `Scripts`, `Sample Repository` by `Sample Repository` (1.00; identical boilerplate titles for different repos)

So 6,443 import-reference rows (and 2 mcp rows) were retired by a heuristic that cannot tell a different vendor from a newer version. 4,584 of the superseding rows are themselves superseded (chains), and 326 point at a deprecated and 11 at an archived row. Most of these are low-value vendor boilerplate (so the *outcome* is mostly harmless), but it means the existing "superseded" population is not evidence of curation and should not be counted as "handled". It also means that if bucket 3 is deprecated, it overlaps heavily with what is already superseded; the net corpus effect is smaller than the 3,107 suggests.

Superseded rows cannot be restored through `batch-transition` (it refuses `--to superseded`, and the legal exits from `superseded` need checking in `validateTransition`). Do not attempt reinstatement without a design pass; the recall value is low.

## 5. Retrieval ranking vs decision/architecture rows

Method: lexical simulation (the production path is BM25 + FTS5 + dense through RRF; dense/reranker was not run). Lifecycle = active, `bm25(title 5.0, content 1.0)`, then production `rerankSearchHits` factors from `registrar/packages/common/src/freshness.ts` (90-day freshness half-life, `CATEGORY_BOOST` decision 1.2 / architecture 1.15 / convention,pattern 1.1 / troubleshooting 1.0 / onboarding 0.95 / reference 0.9). Ten real estate queries, OR-joined tokens; "mcp-curated" = source mcp.

| Query | Active matches | Top 10: import-reference | Top 10: other |
|---|---|---|---|
| secrets SOPS age | 880 | 1 | 9 |
| backup borg B2 | 286 | 3 | 7 |
| Caddy reload deploy | 886 | 4 | 6 |
| beads dolt sync | 1,083 | 3 | 7 |
| VPS Contabo | 233 | 5 | 5 |
| hash-chained audit | 1,668 | 0 | 10 |
| Tailscale | 72 | 2 | 8 |
| GCP exodus | 388 | 6 | 4 |
| dense retrieval EmbeddingGemma | 404 | 2 | 8 |
| supersession | 33 | 5 | 5 |

Reading:
- Decision/architecture rows already lead every query where one exists. The ranking is not being drowned. Category boost is only a 1.33x spread, but BM25 on short dense mcp rows plus 90-day freshness (mcp rows are weeks old; import rows are 11-15 weeks old) does the rest.
- Import rows that surface are mostly the *useful* ones (runbooks, handoffs, AARs). The failure cases are **topical staleness**: "GCP exodus" returns `Intent Solutions VPS Runbook Summary`, `CLAUDE.md — Workspace Overview`, `JeremyLongshore.com README` (old host notes), and `VPS Contabo` returns `FairDB Operations Kit`. Those are the rows a stale-platform pass should fix, not rows ranking can fix.
- "Caddy reload deploy" surfaces `Contradiction in Caddy restart vs reload instructions` (an import `troubleshooting` row, a compiler-generated contradiction record) next to the real fix: contradictions are mixed in with answers.

Caveat: the original "0 results" example is a sentence query. FTS5 `MATCH` on the whole sentence is an AND of every token; `age` and `encryption` both required eliminates matches. Check that the serving path OR-joins or falls back to dense before treating it as a corpus problem.

## 6. Recommended disposition (reversible, dry-run first, receipts)

Principles: use the existing governed path only. `apps/curator batch-transition` (registrar `apps/curator/src/cli.ts`, bead 5kw.2) writes one hash-chained receipt per memory in its own transaction, supports `--ids-file` and `--dry-run` (read-only), and allows `--to deprecated|archived|active`. Never raw `UPDATE`; never touch `audit_events`; the chain is appended to, not rehashed. Soft lifecycle changes are reversible with `--to active`. Precedent: the 07-17 owner sweeps (11 archived, 681 demoted).

Do NOT: bulk-deprecate all 16k; change trust level; reinstate superseded rows; delete anything; touch `mcp` rows; touch `import_batches`.

Order of operations:

1. **Baseline first (gate).** Run the Recall@10 / nDCG@10 eval (`qmd-adapter` eval harness; floors per the Wave-1/2 notes) and record the number. Snapshot via the normal `teamkb-backup.sh` run and confirm it restores. Verify the chain: `curator verify-audit-chain --db ~/.teamkb/teamkb.db` and `verify-corpus-accounting`.
2. **Wave A, stale-platform (179 rows, high confidence).** `--ids-file ids_stale_platform.txt --to deprecated --reason "GCP/Firebase/Netlify-era doc; GCP torn down 2026-07-09" --actor <jeremy>`; `--dry-run --json` first and diff counts against 179. Re-run the eval. This is the same class as the already-approved 07-17 GCP demotion.
3. **Wave B, archive and third-party copies (1,870 rows).** Same pattern, reason "archived/backup/forked third-party copy, not estate knowledge". Spot-check 50 random rows per sub-path (`nixtla-010-archive`, `contributing-*`, `wild-*`) before running the live pass; hold back anything whose title matches an estate repo.
4. **Wave C, vendor skill-pack boilerplate (3,107 rows).** Highest volume, lowest value (templated SaaS-pack READMEs, "Scripts for X skill"). Run as its own wave; re-run eval after. If the eval regresses (e.g. skill-catalog queries), re-activate that wave with the same ids file (`--to active`).
5. **Wave D, open questions and stubs (401 rows).** Lower confidence; the open-question pages are LLM speculation, but a few rank on conceptual queries (sampled `dense retrieval`, `supersession`). Defer this wave until after A-C, and check hits on the 10 queries above before running it.
6. **Review queue, not a wave:** the 839 "keep" rows with stale-term hits (149 on `gcloud` / `firebase deploy` / `netlify`). Triage by hand or in a small bounded batch; mentioning GCP in an AAR is not staleness.
7. **Close the gap that made this possible (separate beads, not part of 39z.3):**
   - Fix the curator's title-Jaccard supersession (cross-source gate, content-similarity requirement, require same `filePath` family) so the next compile cannot repeat the 6,443 false retirements. This is the real "over-capture" fix (`gpg9`'s question, answered correctly).
   - Add an import capture gate for compile-pipeline output (brainignore already runs on import-source candidates): exclude `*archive*`, `backups-*`, `99-forked`, vendor skill-pack READMEs at ingest, so a re-run of `corpus-machine` does not re-flood.
   - Make `import_batches` real or delete the premise: tag the next import with a batch id so `rolled_back` means something.
   - Check the query path for sentence queries (AND semantics), per §5.

Expected result after A-C: active reference 9,067 -> ~3,900 (-5,156), active total 10,754 -> ~5,600. Wave D would take it to ~3,500 reference. Verify against the eval rather than relying on these numbers.

Rollback for every wave: re-run `batch-transition --to active` with the same ids file and the same actor; each wave leaves its own receipted audit trail. A wave is only live-run after a clean dry-run and a recorded eval baseline.

## 7. SQL used (all read-only against the `.backup` copy)

```sql
-- shape of the "import"
select source,category,lifecycle,trust_level,count(*) from curated_memories where category='reference' group by 1,2,3,4;
select substr(promoted_at,1,13),count(*) from curated_memories where source='import' group by 1 order by 2 desc;
select author_json,promoted_by_json,count(*) from curated_memories where source='import' group by 1,2;
select * from import_batches;                                   -- 0 rows
select link_type,source,import_batch_id,count(*) from memory_links group by 1,2,3;  -- 302, supersedes/curator/NULL

-- already-retired attribution
select action,substr(timestamp,1,10),count(*) from audit_events group by 1,2;
select json_extract(supersession_json,'$.reason'),count(*) from curated_memories where lifecycle='superseded' group by 1 order by 2 desc;

-- classification view (first match wins)
create temp view r as select rowid rid,id,title,content,lifecycle,
  json_extract(metadata_json,'$.filePaths[0]') fp, lower(title||' '||content) t
  from curated_memories where source='import' and category='reference';
-- disposition: 1 stale by path/title; 2 fp like '%archive%' / '%backups-%' / '%99-forked%' / '%contributing-%' / '%wild-%';
-- 3 fp like '%plugins-saas-packs%' / '%-skill.md' / '%-skills-%' / skill READMEs; 4 open-questions or length(content)<300 or
-- title in ('Scripts','References','Assets','Templates','Overview'); 5 remainder.

-- duplicate checks
select count(*),count(distinct content_hash) from curated_memories where source='import' and category='reference';
select count(*) groups, sum(n-1) from (select count(*) n from curated_memories ... group by substr(content,1,300) having n>1);

-- ranking simulation (per query Q, OR-joined tokens)
select m.source,m.category, -bm25(curated_memories_fts,5.0,1.0)*exp(-0.0077*(julianday('2026-10-01')-julianday(m.updated_at)))
       *case m.category when 'decision' then 1.2 when 'architecture' then 1.15 when 'convention' then 1.1 when 'pattern' then 1.1
        when 'troubleshooting' then 1.0 when 'onboarding' then 0.95 else 0.9 end as final
from curated_memories_fts join curated_memories m on m.rowid=curated_memories_fts.rowid
where curated_memories_fts match :Q and m.lifecycle='active' order by final desc limit 10;
```

Row-id lists for waves A-D were generated to the session scratchpad (`ids_1.txt` 179, `ids_2.txt` 1,870, `ids_3.txt` 3,107, `ids_4.txt` 401) and are intentionally not committed; regenerate from the classification rules when executing.

## 8. Limits of this analysis

- Ranking used FTS BM25 + production boost/freshness only; dense (EmbeddingGemma) and the reranker were not run, and queries were OR-joined. Real queries can differ; the eval harness is the gate.
- Classification is path/title/length rule-based, not a per-row read. Buckets 2 and 3 were spot-sampled (about 25 titles), not reviewed row by row. Hold-back sampling in each wave is part of the plan.
- "Stale" by term hit is an over-count; the path/title rule (179) is the high-confidence figure.
- Counts are as of the 2026-10-01 backup copy; the live DB grows daily (mcp +3-20 rows/day) but the import population is static.
- The registrar draft PR #332 ("docs(gpg9): record reference import flood decision") was not reviewed here; the bead says to adopt-or-close it. Its premise needs the corrections in §1.

- Jeremy Longshore
intentsolutions.io
