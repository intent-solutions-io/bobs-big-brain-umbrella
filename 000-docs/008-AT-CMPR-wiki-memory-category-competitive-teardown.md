# 008-AT-CMPR — The "Wiki Memory" category: competitive teardown vs Governed Second Brain

**What this is:** a competitive teardown of the emerging *Wiki Memory* category — systems that use an
LLM to **compile a corpus into a navigable, queryable knowledge artifact** — measured against
Governed Second Brain (GSB). It exists because this umbrella repo's job is *"the thesis, the
competitive teardown, and the map"* (root `CLAUDE.md`). Every GSB claim below traces to the
code-grounded fact sheet [`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md); every
competitor claim is web-verified (sources inline).

> **One-line finding:** every competitor in this category is **Compile-only** — the model is judge and
> jury, and "accountability" is thin (git-blame on the *output*, a grep-able log, or nothing). GSB is
> the only entrant that adds a **deterministic Govern layer + tamper-evident Receipts**. *That is the
> moat, and it is real.* But the Compile-only crowd is **ahead on three axes** GSB must close:
> freshness-on-push, conversational Q&A, and visual diagrams.

**Honesty note (the brand is honesty):** the GSB column does not over-claim. Retrieval today is
**keyword BM25 only** (semantic is deferred); the external anchor is **git commit/push only**
(OpenTimestamps + per-actor signatures are named, not in the live path); local mode is **integrity +
ordering + rewrite-detection, not non-repudiation**. The forbidden words *tamper-proof / immutable /
non-repudiation (local) / blockchain* do not appear as GSB claims. The shipped-vs-deferred ledger is
§7.

---

## 1. The category and its three (separable) properties

"AI memory" and "auto-wiki" are marketed as one thing — better recall. They are not one thing. The
category has **three properties**, in increasing order of rarity. They are usually sold as one "spine,"
but they are **independent and separately defensible** — that distinction matters, so the matrix and
the moat are not over-bundled (Hickey's note, §8):

1. **Compile** — *derive* structured knowledge (summaries, concepts, entities, contradictions, gaps)
   from raw material, keeping raw and derived separate. **Table stakes / commodity** — everyone here
   does some version of it.
2. **Govern** — **deterministic code decides what becomes durable**: dedup, policy, secret/PII
   detection, trust levels, tenant isolation, promotion lifecycle. **Almost no one does this.** *Note
   the honest exception:* in Karpathy's pattern (§2.3) the arbiter is **a human reviewing the git
   diff** — correct, but unscalable past one person; in the *productized* competitors the model is the
   sole arbiter. This is the **keystone** property (see below).
3. **Receipts** — an **append-only, after-the-fact-verifiable** record of *that each durable fact was
   admitted by code, under which policy verdict, by whom, in what order, and not altered since.* **No
   competitor does this** — "provenance" elsewhere means git-blame on the generated output, a plain
   append-only log, or inline citations at best. (Honest scope: receipts attest **integrity +
   provenance + ordering**, *not* truth — see §4.2 and the §7 ledger.)

**These detach (Hickey).** Receipts without govern is Karpathy's `log.md`. Govern without receipts is
still a category-leading control plane. Compile is the commodity. **The keystone is govern** —
deterministic *acceptance* of durable state — and the moat is not "GSB has receipts," it is **"GSB's
receipts attest a write-path that no model touches."**

**The trust boundary is the spool (Hickey).** The deterministic/probabilistic seam is a concrete file:
ICO's `brain/spool/` JSONL handoff (deterministic UUID-v5 + manifest SHA-256). *Above* the spool,
Claude proposes (the 6 compile passes — probabilistic). *Below* the spool, **no model writes durable
state** (`005-AT-ARCH §2`: "everything downstream of the spool is replaceable without changing ICO").
Compile *straddles* the boundary; govern and receipts live entirely below it. When someone asks "but
Claude wrote all of it, so how is govern not just more LLM?", *the spool is the answer.*

The whole category is parked at rung 1 (compile). GSB is the only entrant standing on all three —
which is exactly the thesis (`005-AT-ARCH §2`: *the model proposes; the deterministic kernel owns
durable state, governance, and the audit chain*).

> **A tension this teardown surfaces but does not resolve (routed to the §9 council).** Ward
> Cunningham's review (§8) argues GSB is **not a wiki at all** — it has no human-editable page surface
> (`brain/wiki/` is machine-compiled, regenerated, never human-revised). It rejects the wiki's founding
> bet (anyone-edits + social-trust + revert) for the opposite one (a deterministic gate decides +
> a hash-chain proves). By that read the honest category name is **"Governed Memory," and GSB is the
> *anti-wiki*** — and the "Wiki Memory" frame needlessly commits GSB to a footrace on freshness/Q&A/
> diagrams (§5) it is behind on. The category-naming question is itself a **positioning decision** — so
> it is put to the council in §9, not pre-decided here. Throughout this doc, "Wiki Memory" names *the
> category the competitors occupy*; whether GSB should brand *into* it or *against* it is the open
> question.

### The four clusters

| Cluster | Players | What they optimize | Govern? | Receipts? |
|---|---|---|---|---|
| **Repo auto-wikis** | DeepWiki, AutoWiki | browsable wiki of a codebase, refreshed on push, diagrams + Q&A | ❌ | ❌ |
| **Personal LLM wiki** | Karpathy's LLM-Wiki | single-user raw→wiki, local, append-only log | ❌ | ❌ (plain log) |
| **Agent memory layers** | Mem0, Letta (MemGPT) | extract/store/recall facts across agent sessions | ❌ | ❌ |
| **Code-context / retrieval** | Cursor, Greptile, Cody | index + Q&A/review (retrieval, not durable wiki) | ❌ | ❌ |
| **— the outlier —** | **Governed Second Brain** | compile *any* corpus → **deterministic govern** → **hash-chained receipts**, local-first, team over tailnet | ✅ | ✅ |

GSB spans the work of clusters 1–3 (compile any corpus, durable governed memory, team-shared) but is
defined by a layer none of them have. It does **not** yet match cluster 1's retrieval/UX polish — see
§5–§6.

---

## 2. Per-product profiles

> Competitor facts are web-verified as of 2026-06; where a fact could not be confirmed it is marked
> *(unverified)* rather than asserted. The GSB profile is sourced to `005-AT-ARCH` file:path citations.

### 2.1 DeepWiki — Cognition / Devin *(repo auto-wiki)*
Auto-generated wiki for any public GitHub repo, generated via Devin, producing structured pages,
**architecture diagrams**, and a **conversational Q&A agent grounded in the code**. Free for public
repos; a viral, zero-friction surface (swap `github.com` → `deepwiki.com`); repos that add a badge get
an **auto-refreshed** DeepWiki. ([deepwiki.com](https://deepwiki.com/),
[cognition.com/blog/deepwiki](https://cognition.com/blog/deepwiki))
- **Compile:** ✅ (summaries, structure, diagrams). **Decides durable:** the **LLM** — judge and jury.
- **Receipts:** ❌ — no audit trail; the wiki is regenerated, not journaled.
- **Govern:** ❌ — no dedup/policy/secret-scan as a control plane.
- **Source scope:** code only. **Team/roles:** ❌ (it's a public read surface; private repos need a
  Devin account). **Freshness:** badge-gated auto-refresh / on-demand. **Q&A:** ✅ conversational,
  grounded in code. **Diagrams:** ✅. **Host:** cloud. **License:** proprietary/free-tier.
- **The threat:** best-in-class on the two axes GSB is weakest — grounded conversational Q&A and
  visual diagrams — and a viral distribution surface. **The gap they can't close:** zero governance,
  zero receipts, code-only, cloud-only.

### 2.2 AutoWiki — Factory ("Droid") *(repo auto-wiki)*
A wiki built from source and **refreshed when the repo changes**: `install-wiki` writes a CI workflow
that **refreshes on every push to the default branch** (plus an on-demand `/wiki` command and, since
April 2026, GitHub Wiki sync), so the *committed wiki output* carries git history / `git blame`.
([factory.ai/news/wiki](https://factory.ai/news/wiki),
[docs.factory.ai/cli/features/wiki/auto-refresh](https://docs.factory.ai/cli/features/wiki/auto-refresh))
- **Compile:** ✅ (organized around how the codebase works). **Decides durable:** the **LLM**.
- **Receipts:** ❌ as a control plane — but the committed wiki gets **git-blame on the output**
  (provenance of the *generated text*, not of a governance decision). This is the closest any
  competitor comes, and it is still only blame on derived prose.
- **Govern:** ❌. **Source scope:** code only. **Team:** via the repo. **Freshness:** ✅✅
  **on-push** — the category's best answer to staleness. **Q&A:** *not documented* as conversational
  (appears static-docs) — *unverified*. **Diagrams:** *not documented* — *unverified*. **Host:**
  cloud / CLI. **License:** proprietary.
- **The threat:** the **freshness-on-push** pattern (regenerate when the repo changes, wired as a
  default-branch CI workflow) is the single biggest real gap GSB has (GSB is nightly cron — see
  §2.9). **The gap they can't close:** govern + receipts; code-only.

### 2.3 LLM Wiki — Andrej Karpathy (personal pattern) *(personal LLM wiki)*
A documented personal pattern (a published [April-2026 gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)):
feed raw material to an LLM, have it compile entity/concept pages plus an `index.md` catalog, encode
conventions in a `schema.md`, run a **contradict-detection lint pass** (which *surfaces* where sources
disagree — a **compile** output, not a write-blocking gate), and keep an **append-only `log.md`** with
date-prefixed entries (`## [2026-04-02] ingest | Article Title`) — on the order of ~100 articles /
~400k words (fits in-context, so retrieval is keyword, no embeddings). Each ingest updates ~10–15
pages; raw sources (incl. images) are **write-once — never edited after ingest**. Domain-agnostic. The
intellectual ancestor of the whole category.
- **Compile:** ✅ (incl. the contradict-detection pass). **Decides durable:** the **LLM proposes; a
  human reviews the git diff and owns the commit** — *governance relocated to a primitive everyone
  already trusts: git + a human reading a diff.* That is **correct-but-unscalable** governance (one
  person), not the *absence* of governance (Karpathy's note, §8). **Source scope:** any corpus.
- **Receipts:** ❌ as a tamper-evident chain — but `log.md`-in-git inherits git's content-addressed
  history *for free*, so it already has a tamper-evident substrate (git is a Merkle DAG). What it
  lacks is **per-decision, queryable governance attestation** (which policy verdict admitted which
  fact). The honest delta GSB adds is **granularity + queryability**, not a different *kind* of hash
  (§4.2).
- **Govern:** ⚠️ *human-at-the-git-commit* — `schema.md` conventions + a human reviewing every
  ~10–15-page delta before commit. A human reviewer is a *higher-precision* arbiter than an 8-rule
  pipeline; it simply does not scale past one person. **Team:** ❌ single-user. **Freshness:** manual
  re-run. **Q&A:** LLM reads `index.md` → drills into relevant pages → synthesizes — *the same
  read-catalog-then-drill loop GSB's cited search uses* (convergent keyword-first discipline, not a
  GSB advantage). **Diagrams:** ❌. **Host:** local. **License:** personal pattern (no product).
- **Why it matters:** it is GSB's honest mirror — *same compile instinct, same raw→wiki shape, same
  append-only impulse, same keyword-first-defer-embeddings retrieval bet.* The real difference is not
  "Karpathy compiles, GSB governs." It is: **Karpathy puts a human at the git commit; GSB removes the
  human and replaces him with a deterministic pipeline + receipts.** That swap is the whole product —
  and it earns its keep *exactly* when the human can no longer review every diff (team grows, or the
  nightly autonomous compile runs with no human in the loop). At n=2 on one tailnet, much of the
  machinery is built for the team GSB is *about to have*, not the one it has — and §4/§8 say so.

### 2.4 Mem0 *(agent memory layer)*
A universal agent **memory layer**: extract salient facts from agent I/O, store them in a vector DB,
and retrieve them across sessions. Apache-2.0 OSS core (60k+ GitHub stars) + hosted platform.
([mem0.ai](https://mem0.ai/), [github.com/mem0ai/mem0](https://github.com/mem0ai/mem0))
- **Compile:** ❌ — it is a **memory/state layer, not a corpus→wiki compiler** (fact extraction, not
  synthesis into a navigable wiki). **Decides durable:** **LLM** extraction + config rules.
  **Receipts:** ❌. **Govern:** ❌ control plane — no secret-scan / policy / promotion gate (it has
  entity-linking + temporal reasoning, but those serve *retrieval*, not governance of durable state).
- **Source scope:** agent conversation I/O (no file ingestion model). **Team:** ✅ isolation by user /
  session / agent ID. **Freshness:** continuous (per-interaction). **Retrieval:** **multi-signal —
  semantic + BM25 + entity matching, fused** (notably, *already hybrid/semantic* — see §5.2).
  **Diagrams:** ❌. **Host:** cloud + self-host. **License:** Apache-2.0 + commercial.
- **Adjacency:** competes for the *"give my AI memory"* mindshare, but it is a **session-fact cache**,
  not a compiled, governed, audited knowledge base. No receipts, no deterministic govern.

### 2.5 Letta (formerly MemGPT) *(agent memory layer)*
Stateful-agent framework descended from the MemGPT paper — agents with self-editing long-term memory
(working / recall / archival tiers), an OS-like memory manager. Renamed MemGPT → **Letta**; Apache-2.0
(23k+ stars), with "Letta Code" the 2026 center of gravity.
([letta.com](https://www.letta.com/), [github.com/letta-ai/letta](https://github.com/letta-ai/letta))
- **Compile:** partial. **Decides durable:** the **LLM/agent edits its own memory** directly (via
  `core_memory_append`/`replace`). **Receipts:** ❌ (message/state history, not a tamper-evident
  chain). **Govern:** ❌ deterministic control plane.
- **Source scope:** agent I/O. **Team:** managed-agent tiers. **Freshness:** continuous. **Q&A:**
  agent-native. **Diagrams:** ❌. **Host:** cloud + self-host. **License:** Apache-2.0 + commercial.
- **Adjacency:** the **model edits durable state directly** — the *exact* anti-pattern GSB's thesis
  rejects (`005-AT-ARCH §2`: the model never writes durable state directly). Strong agent-runtime
  story; no governance/receipts substrate.

### 2.6 Cursor *(code-context / retrieval)*
AI code editor with whole-codebase **indexing** for retrieval-augmented edits/chat — chunks → embeds →
vector DB. Indexes, it does not *compile a durable wiki*. ([cursor.com](https://cursor.com/),
[secure-codebase-indexing](https://cursor.com/blog/secure-codebase-indexing))
- **Compile:** ❌ (index, not derive). **Receipts:** ❌. **Govern:** ⚠️ privacy controls only
  (paths encrypted, no plaintext code at rest, respects `.gitignore`/`.cursorignore`, indexes
  auto-expire) — *not* a knowledge-governance plane. **Source scope:** code. **Team:** ✅ (Merkle-tree
  index reuse across machines). **Freshness:** incremental on file change. **Retrieval:** **hybrid —
  exact grep + semantic** (already semantic — see §5.2). **Diagrams:** ❌. **Host:** cloud index.
  **License:** proprietary (VS Code fork).
- **Adjacency:** not really a wiki/memory product — included because it owns the *"AI knows my
  codebase"* mindshare. Retrieval, ephemeral, no durable governed artifact.

### 2.7 Greptile *(code-context / retrieval)*
Builds a **codebase graph** (every function/class/dependency) and uses it for **AI code review** (PR
reviews with inline comments + confidence scores, ~82% bug-catch claim) and a separate **Chat** Q&A.
([greptile.com](https://www.greptile.com/), [docs](https://www.greptile.com/docs/introduction))
- **Compile:** ❌ (derives a code graph, not a durable wiki). **Receipts:** ❌ (inline PR comments,
  not an audit chain). **Govern:** ❌ (it *reviews*, it doesn't *govern durable memory*). **Source
  scope:** code. **Team:** ✅ team SaaS. **Freshness:** triggered on PR (~3 min). **Q&A:** ✅ (Chat,
  priced separately). **Diagrams:** ✅ **auto-generated sequence diagrams** (call flows). **Host:**
  cloud (+ self-host enterprise). **License:** proprietary.
- **Adjacency:** retrieval/review, not durable wiki-memory. (Note: Greptile is also Intent Solutions'
  own PR-review bot — adopted as a *tool*, not a competitor to the brain.)

### 2.8 Sourcegraph Cody *(code-context / retrieval)*
Code-intelligence + AI assistant over Sourcegraph's search index (multi-repo, multi-LLM). 2025–26
posture is **enterprise-only** — free and Pro tiers were discontinued (2025); list price ~$59/user/mo.
([sourcegraph.com/docs/cody](https://sourcegraph.com/docs/cody))
- **Compile:** ❌ (consumes Sourcegraph's search index; doesn't generate a wiki). **Receipts:** ❌.
  **Govern:** ❌. **Source scope:** code. **Team:** ✅ enterprise (context across ~10 repos).
  **Freshness:** continuous index. **Q&A:** ✅ (in-IDE, multi-LLM). **Diagrams:** ❌. **Host:** cloud /
  self-managed (enterprise). **License:** open-core (Apache-2.0 public snapshot; service proprietary).
- **Adjacency:** mature code-search + assistant; not a compiled, governed knowledge base.

### 2.9 Governed Second Brain (the subject)
Compile **any corpus** (ICO's 6 passes) → **deterministic govern** (INTKB policy pipeline) →
**SHA-256 hash-chained receipts** → cited retrieval; local-first, daemon-free, team-shared over the
tailnet. *Sources: `005-AT-ARCH` throughout.*
- **Compile:** ✅ — ICO 6 passes *summarize → extract → synthesize → link → contradict → gap*,
  raw/derived strictly separated (`005-AT-ARCH §2`; ICO `packages/compiler/src/passes/`).
- **Decides durable:** **deterministic code** — INTKB `PolicyPipeline`
  (secret/length/trust/tenant/relevance/dedup) promotes into `curated_memories`; the model never
  writes durable state (`005-AT-ARCH §2`).
- **Receipts:** ✅ — `audit_events` **SHA-256 hash-chain** (`entry_hash` + `prev_entry_hash`,
  `hash_version` 1/2) + ICO `brain/audit/` chain + a **git-anchored** `audit/anchors.jsonl`; verified
  after the fact by `brain_audit_verify` / `ico audit verify` (`005-AT-ARCH §1–2`).
- **Govern:** ✅ — dedup by `content_hash` → policy pipeline → promotion lifecycle
  (`active`/`superseded`/…) with `policy_evaluations_json` proof (`005-AT-ARCH §1–2`).
- **Source scope:** ✅ **any** — `brain/raw/` is papers/notes/articles/repos (`005-AT-ARCH §1`).
- **Team/roles:** ✅ — scrypt-hashed per-user bearer tokens, member/admin, tenant isolation; one
  shared brain over the tailnet (`005-AT-ARCH §2`).
- **Freshness:** ⚠️ **nightly** — `/teamkb-compile` cron compiles the day's git/PRs/beads/decision-
  records/transcripts into governed memories (shipped, self-graduated to auto). **Not on-push**
  (that's the §6 gap).
- **Q&A:** ⚠️ **cited search, not conversational** — `brain_search` returns `qmd://`-cited hits; there
  is no "ask the brain" conversational layer yet (the §6 gap).
- **Retrieval:** ⚠️ **keyword BM25 only** (`brain_search` → `qmd search`); semantic (sqlite-vec +
  EmbeddingGemma) is **deferred** behind a 0.85-Recall@10 eval gate. *No vector/semantic search in the
  live path — do not imply otherwise.*
- **Diagrams:** ❌ — ICO compiles `brain/wiki/` Markdown (concepts/topics/entities/contradictions) but
  generates **no architecture/dependency diagrams** (the §6 gap).
- **Host:** local-first — daemon-free local stdio MCP, **zero network in local mode**; team mode is an
  opt-in tailnet proxy (`005-AT-ARCH §2`). **License:** Apache-2.0 plugin.
- **Trust model (stated honestly):** local mode = integrity + ordering + rewrite-**detection**; the
  external anchor is **git commit/push only**. OpenTimestamps + Ed25519 per-actor signatures are the
  *named upgrade*, not the live path. Local mode is **not** cross-actor non-repudiation.

---

## 3. The comparison matrix

Legend: ✅ yes · ⚠️ partial/with-caveat · ❌ no. Each dimension is tagged **[KIND]** (a categorical
difference — the competitor lacks the artifact *entirely*) or **[DEGREE]** (everyone has it; it's a
quantitative gap). *You cannot net a [KIND] win against a [DEGREE] loss* — one ✅ in a KIND row is worth
more than three in a DEGREE row (Hickey, §8). Rows are grouped: the moat (KIND) first, the gaps
(DEGREE) after.

| Dimension | DeepWiki | AutoWiki | Karpathy LLM-Wiki | Mem0 | Letta | Cursor | Greptile | Cody | **GSB** |
|---|---|---|---|---|---|---|---|---|---|
| **Who decides durable** **[KIND]** | LLM | LLM | LLM→human gate | LLM | LLM | n/a | n/a | n/a | **deterministic code** |
| **Receipts — what is attested** **[KIND]** | ❌ nothing | ⚠️ output *text* (git) | ⚠️ page *history* (git) | ❌ | ❌ | ❌ | ❌ | ❌ | **✅ the governance *decision*** (append-only chain + ext anchor) |
| **Govern** (dedup/policy/secret-scan) **[KIND]** | ❌ | ❌ | ⚠️ human-at-git | ❌ | ❌ | ⚠️ privacy-only | ❌ | ❌ | **✅ 8 deterministic rules** |
| **Human edit of durable knowledge** | ❌ | ❌ | **✅ owns commit** | ❌ agent | ❌ agent | n/a | n/a | n/a | ❌ *by design* (gate decides; supersede, not edit) |
| **Compile** (derive, not index) **[DEGREE]** | ✅ | ✅ | ✅ | ❌ | ⚠️ | ❌ | ❌ | ❌ | ✅ |
| **Source scope** | code | code | any | agent I/O | agent I/O | code | code | code | **any + daily work** |
| **Team / multi-user / roles** | ❌ | ⚠️ via repo | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ scrypt tokens + tenancy |
| **Freshness / auto-maintenance** **[DEGREE]** | ⚠️ badge refresh | **✅ on-push** | ❌ manual | ✅ continuous | ✅ continuous | ✅ continuous | ✅ on-PR | ✅ | ⚠️ **nightly cron** |
| **Retrieval mechanism** **[DEGREE]** | ? (cloud) | ? | keyword | **hybrid** (dense+BM25+entity) | agent-recall | **hybrid** (grep+dense) | code-graph | search-index | ⚠️ **keyword (BM25) only** |
| **Q&A surface** **[DEGREE]** | **✅ grounded conversational** | ⚠️ static *(unverified)* | LLM-routed keyword | API | agent | ✅ in-editor | ✅ Chat | ✅ in-IDE | ⚠️ **cited search, not conversational** |
| **Visual diagrams** **[DEGREE]** | ✅ | ⚠️ *(unverified)* | ❌ | ❌ | ❌ | ❌ | ✅ sequence | ❌ | ❌ |
| **Composable / inspectable w/o whole stack** | ❌ cloud | ❌ cloud | **✅✅ `cat log.md`** | ⚠️ OSS | ⚠️ OSS | ❌ | ❌ | ⚠️ open-core | ⚠️ *verifier in-box* (standalone reader = §6 rec) |
| **Local-first / privacy** | ❌ cloud | ❌ cloud | ✅ local | ❌ | ⚠️ | ❌ | ❌ | ⚠️ | **✅ local-first, zero-network local mode** |
| **License / openness** | proprietary | proprietary | n/a (pattern) | Apache-2.0 | Apache-2.0 | proprietary | proprietary | open-core | **Apache-2.0** |

**Reading the matrix:** GSB owns three **[KIND]** rows no competitor has a check in — *who decides
durable* (deterministic code, not LLM — all 8 rules verified to make **no model call below the spool**,
§7), *receipts* (attesting the **governance decision**, not output text or page history), and *govern*.
Those are categorical. It **trails** on **[DEGREE]** rows that are *quantitative* — *retrieval
mechanism* (keyword vs hybrid — Mem0 and Cursor already run dense), *freshness* (nightly vs on-push),
*Q&A surface* (cited search vs conversational), *diagrams* (none vs yes) — and on *composability* (the
verifier currently lives inside the system that wrote the chain; Karpathy's `cat log.md` does not).
The honest read is not "GSB wins 3, loses 4" — it is "GSB wins the rows that define a different
*category*, and trails on rows that are *features within* the old one."

---

## 4. Where GSB wins (the moat — structural, and the honest scope of it)

1. **The model proposes; deterministic code disposes — verified, not asserted.** Every productized
   competitor lets the LLM decide what becomes durable. GSB's policy pipeline runs **8 deterministic
   rules** below the spool — `secret-detection`, `sensitivity-gate` (PII/comp), `content-length`,
   `content-sanitization`, `source-trust`, `relevance-score`, `tenant-match`, `dedup-check`
   (`packages/policy-engine/src/rules/`). A natural challenge is *"is one of those secretly a model
   call?"* — checked: `scanForSecrets` is a pure regex function, `classifyContent` is regex/pattern,
   `relevance-score` states *"No LLM involvement — purely structural heuristics."* **No rule below the
   spool calls a model.** That makes "deterministic code owns durable state" a verifiable claim, not a
   slogan. *Caveat (Chip, §8): deterministic ≠ correct.* A regex secret-scan is deterministic and can
   still miss a base64-wrapped token or a key split across two lines. The pipeline's *efficacy* is not
   yet measured against an adversarial set — see §7 and the §6 eval recommendation.
2. **Receipts attest the governance *decision* — and the honest strength is tiered (Kleppmann, §8).**
   The receipt does not certify a fact is *true*; it certifies *that code admitted this fact, under
   which policy verdict, by whom, in what order, and that it has not been altered since.* Against the
   competitors the integrity guarantee is a **three-tier** claim, not a flat "tamper-evident":
   - **Tier 0 — Karpathy's `log.md` / no chain:** edit a past entry and *nothing detects it* (though
     `log.md`-in-git inherits git's own Merkle history for free).
   - **Tier 1 — GSB's local `audit_events` chain:** detects *accidental/partial* edits, reordering,
     and truncation (`ENTRY_HASH_MISMATCH` / `PREV_LINK_MISMATCH` / `HISTORY_TRUNCATED`). It makes a
     *deliberate* rewrite **expensive** (you must re-hash the whole forward chain) — but **not
     detectable on its own**: a local key-holder who edits an early row and re-hashes forward produces
     a chain that still verifies clean (`audit-anchor.ts` says exactly this).
   - **Tier 2 — GSB's externally-committed anchor:** once the chain head is pushed (git today; OTS the
     named upgrade), a full-history rewrite becomes **detectable** (`HISTORY_REWRITTEN`). *This is the
     tier where "a different kind of artifact" is actually earned.*

   So the moat over a git-backed `log.md` is **what the receipt is a receipt *of*** (a deterministic
   control-plane verdict, queryable per-memory) — a **granularity + queryability** win — plus Tier-2
   external detectability. It is **not** "we have a hash-chain and they don't" (git is already a hash
   chain).

   > **Threat model (state it plainly — a named boundary reads as competence).** *Defends against:*
   > accidental row corruption, reordering/splicing, silent truncation, and — once the anchor is pushed
   > — full-history rewrite. *Does NOT defend against:* a legitimate local writer holding the key
   > (local mode has **no cross-actor non-repudiation**; that needs the Ed25519 **merge** anchor, which
   > fires only on the demand-gated multiplayer merge path — §7). Forbidden framings honored: this is
   > tamper-**evident**, never tamper-proof; never "immutable"; never "non-repudiation" for local mode.

3. **Any corpus + the day's work, not code-only.** DeepWiki/AutoWiki/Cursor/Greptile/Cody are
   code-only. GSB compiles papers, notes, transcripts, decision records, *and* the team's daily git/PR/
   bead activity (`/teamkb-compile`) — a knowledge base, not a code wiki.
4. **Local-first, daemon-free, zero-network — the leanest claim in the doc (Ken, §8).** Local mode is
   a daemon-free stdio MCP server, **zero network** (`005-AT-ARCH §2`), reading your files and writing
   a local DB. Every competitor except Karpathy is cloud-bound. Two more structural-reliability facts
   the competitors can't match and the doc should not bury: backups are **restore-tested every run**
   (an unrestorable backup is deleted, never kept — `005-AT-ARCH §4`), and the spool carries
   **content-addressed, write-once value records** (deterministic UUID-v5 + manifest SHA-256), which is
   what makes "regenerate only the affected pages" safe for the §6.1 freshness work.
5. **Governance *is* the team story.** scrypt-hashed per-user tokens + member/admin + tenant isolation
   mean "shared brain" without "shared blast radius" — the others' team story is "same cloud index."

**Net:** GSB is not a better recall engine — it is the only **govern + receipts** engine. The
competitive axis is **accountability, not memory**.

**The honest scope of the moat (n, and autonomy).** The receipts moat is **latent** at single-user
local mode (one actor, integrity + ordering only) and becomes **active** at the team boundary and the
moment the **nightly autonomous compile** writes durable state with no human in the loop. That is the
real argument for the machinery: *not* "GSB beats a `log.md` at n=2" (at n=2, a human reviewing the git
diff is a cheaper, higher-precision gate — Karpathy, §8) but **"GSB is what a `log.md` cannot become
once you remove the human and let the pipeline write while you sleep."** Tie the machinery to
**autonomy-with-accountability**, not to abstract superiority — and concede plainly that some of it is
built for the team GSB is *about to have*, not the one it has today.

---

## 5. Where GSB is honestly behind

1. **Freshness is nightly, not on-push.** AutoWiki regenerates only affected pages on every commit by
   diffing commit hashes. GSB's `/teamkb-compile` runs once nightly and (today) recompiles the day's
   work rather than diffing deltas incrementally. **This is the biggest real gap.**
2. **Retrieval mechanism gap — keyword (BM25) only; no dense path live.** **Mem0 already fuses
   semantic + BM25 + entity matching; Cursor already runs hybrid grep + semantic.** GSB's live path is
   keyword-only (the external `qmd search` BM25; a second in-process **FTS5/BM25** backend exists but
   is not the default — `0t9.2`). Honest calibration (Reimers, §8): this is a **mechanism** gap (they
   run dense, GSB doesn't), **not a measured *quality* gap** — there is **no Recall/nDCG number on
   either side yet**, so the doc must not claim GSB is quantitatively behind on quality; it claims a
   missing mechanism, which the eval will settle. The named failure mode of keyword-only, stated out
   loud: **on a paraphrase/synonym query, BM25 can return a confident, cited, *wrong* answer with no
   signal it missed** (the eval's seed set encodes exactly this case: *"how do I make the brain forget
   something outdated"* → a doc titled *"retire/deprecate a memory"*, which BM25 likely misses). The
   defensible reason BM25 may nonetheless suffice is **corpus shape, not receipts**: ~2,000 governed,
   deduplicated, **LLM-compiled (vocabulary-normalized)** memories have a *smaller* query↔doc lexical
   gap than raw chat logs — so retire the false dichotomy "BM25-with-receipts beats
   semantic-without-receipts" (receipts and retrieval mechanism are **orthogonal axes**; governance
   does not make keyword search find a paraphrase). The bet is "small compiled corpus + an eval gate,"
   and the only thing between "we believe BM25 suffices" and a real number is **labeling effort, not
   engineering** — the harness, pinned weights, and a keyword backend already ship (§7).
3. **Q&A surface gap (a *separate* gap from retrieval mechanism).** DeepWiki answers conversationally,
   grounded in the source — a *synthesis layer* (retrieve → read → answer) on top of retrieval. GSB's
   `brain_search` is **retrieval itself** — ranked `qmd://`-cited hits, single-shot, no synthesis
   layer. This is a **product-surface** gap, not a retrieval-mechanism one; the §6.2 "Ask the brain"
   recommendation closes it as UX.
4. **No visual diagrams.** DeepWiki/Greptile auto-draw architecture / sequence diagrams (AutoWiki's
   diagram support is unverified); GSB compiles Markdown pages with no diagram generation.
5. **Distribution/virality.** DeepWiki's "swap the URL, get a free public wiki" is a viral growth
   surface. GSB has no equivalent public showcase yet.
6. **Composability / circular trust (Ken, §8).** Karpathy's receipt is `cat log.md` — any human reads
   it with no dependency on his stack. GSB's audit chain is verified by `brain_audit_verify` /
   `ico audit verify`, which are *part of the same codebase that wrote the chain* — a verifier in the
   box. A standalone, dependency-light verifier (plus pushing the external anchor into the live path)
   converts this from a weakness into a teardown win (§6).
7. **The evaluated-vs-trusted gap (Chip, §8).** The one cited eval gate (retrieval, Recall@10) covers
   the *least* consequential decision. The **govern decisions** (secret/PII precision, dedup) and the
   **compile passes** (faithfulness of the synthesis to `brain/raw/`) have **no published eval**. The
   receipt attests integrity, *not* faithfulness — so a hallucinated synthesis or a missed secret can
   be promoted, exported, cited, and receipted clean. *Determinism is not correctness.*

Stating these plainly is the point — the brand is honesty, and the moat (§4) holds *despite* these
gaps, because none of them is governance or receipts. But note (Chip + Karpathy, §8): gaps **6** and
**7** are *not* mere features-behind — a circular verifier and an unevaluated govern layer touch the
*credibility of the moat itself*, which is why §6 ranks them above the UX gaps.

---

## 6. Candidate adopt items (the council in §9 ratifies — nothing here is pre-filed)

> These are **candidates**, not commitments. Adopt-item beads are filed **only after** the exec-council
> (§9) ratifies them. The canon reviewers (§8) **disagreed on priority** — that disagreement is the
> council's input, surfaced inline. Each item says what to adopt *and* what to keep deterministic.

> **Invariant box — binding on every item below (Hickey, §8).** Every candidate is **read-side or
> proposal-side only.** None may grant any model component **write access below the spool.**
> Conversational answers and incremental recompiles enter governance at `candidates`, pass the **full**
> deterministic pipeline, and get a receipt — **no fast-path, no exception.** This is the Letta
> anti-pattern (§2.5) the whole product exists to refuse; state it as a hard rule, not a parenthetical.

**Cluster A — close the competitive gaps (gap-driven):**

1. **Freshness-on-push + incremental compile.** Adopt AutoWiki's **on-push refresh** pattern (a
   default-branch CI workflow that regenerates when the repo changes), implemented the natural way —
   commit-hash-diff → regenerate-only-affected (the deterministic UUID-v5/manifest-SHA spool makes
   "only affected" safe). **Keep the govern + receipt on each delta.** *Closes §5.1.* **Reviewers
   agree this is the one Cluster-A item worth building** (Ken: "the only one that earns its keep");
   **Chip flags: attach an inference-cost-per-push model *before* filing** — on-push at 40 pushes/day
   can turn a $50–200/mo compile into an unbudgeted bill.
2. **Conversational "Ask the brain."** A `/brain` synthesis surface over GSB's already-cited search;
   every answer carries `qmd://`. *Closes §5.3.* **Contested:** Ken would **cut it** ("UX, not
   substance — `brain_search` already returns cited hits; the MCP client *is* the REPL"); Chip warns
   it is **the unbounded-inference cost center** (per-query, multi-turn) and is *not* "just UX" from a
   reliability seat. If adopted, price-per-query first.
3. **Browsable wiki + diagrams** from ICO's compiled `brain/wiki/`, each page keeping provenance +
   `qmd://`. *Closes §5.4.* **Contested:** Ken would **cut it** ("a downstream renderer script, not a
   system capability; no single diagram fits a paper, a transcript, and a decision record").
4. **Public governed-wiki showcase** — a public, browsable **governed** wiki of an open repo **with the
   receipts visible** (`audit verify` ok, chain + citations on display). *Turns the moat into the
   demo.* **Reframed:** Ken (and the marketing-vs-architecture split) says this is a **GTM/distribution
   decision, not a system feature** — file it in a go-to-market doc, not the architecture roadmap.

**Cluster B — strengthen the moat itself (reviewer-surfaced; Ken/Chip/Kleppmann rank these ABOVE
Cluster A's UX items, because they touch the credibility of govern + receipts, not feature parity):**

5. **Push the external anchor into the live single-writer path + ship a standalone verifier** (Ken,
   Kleppmann). Today the chain head is git-pushed but the *verifier lives in-box*; an external anchor
   (OTS) + a dependency-light reader (ideally a different language) is what makes "verify after the
   fact" non-circular and lifts the receipt from Tier-1 to Tier-2 (§4.2). **Ken: prioritize above all
   §6.1–6.4 UX.**
6. **Build a govern-decision eval harness** (Chip) — labeled adversarial set (split keys, encoded
   tokens, PII in odd fields; known-negatives) → published per-check precision/recall for
   secret/PII/dedup; gate promotion-pipeline changes on it the way retrieval is gated. *Turns "govern:
   shipped" into "govern: shipped + measured."* Extends the existing `0t9` eval epic (backend-agnostic).
7. **Add a compile-faithfulness eval** (Chip) — sampled groundedness score per compiled page against
   its `brain/raw/` source, recorded in `state.db` `compilations`. The receipt attests integrity, not
   faithfulness; this is the only thing that catches a hallucinated synthesis before it's receipted.
8. **Emit a nightly govern-quality digest** for the auto `/teamkb-compile` loop (Chip) — per-check
   rejection counts, faithfulness distribution, near-threshold promotions → `prod-health` ntfy. Keeps
   the autonomous loop **observable on quality, not just liveness** (consistent with the
   self-management doctrine: auto by default, *alert on quality drift*).
9. **Run the first real retrieval number** (Reimers) — a 20–50-query hand-labeled set (stratified
   lexical/semantic, weighted semantic) through the **already-shipped** harness against the live
   `qmd-index/`, reporting Recall@10 **and** nDCG@10. Converts "we believe BM25 suffices" into a number.

**Explicitly DO NOT adopt:** (a) model-as-sole-judge — that *is* the moat; (b) cloud-only hosting —
local-first is the differentiator; (c) "freshness" that ungoverns the write path to go faster;
(d) any conversational/incremental write-path that bypasses the spool (the invariant box).

---

## 7. Honesty ledger — GSB shipped / deferred / **evaluated** (so the columns above are auditable)

Chip's correction (§8): "shipped" answers *does it run*, not *does it work under adversarial load* —
so the ledger carries a separate **Evaluated?** column. Today almost everything reads **shipped but
unevaluated**, and the doc says so.

| GSB capability | Shipped? | Evaluated? | Source / note |
|---|---|---|---|
| ICO 6-pass compile (any corpus) | **shipped** | **N** — no faithfulness eval (§6.7) | `005-AT-ARCH §2`, ICO `compiler/src/passes/` |
| Deterministic govern — **8 rules, all verified no-model-below-spool** | **shipped** | **N** — no per-check precision/recall on adversarial input (§6.6) | `packages/policy-engine/src/rules/` (secret/sensitivity/length/sanitization/trust/relevance/tenant/dedup); `secret-scanner.ts` "pure function", `relevance-score-rule.ts` "No LLM involvement" |
| `audit_events` SHA-256 chain (the receipts) | **shipped** | partial | `005-AT-ARCH §1–2`; tier-1 local (§4.2) |
| Chain verifier `*_audit_verify` | **shipped** | ⚠️ **reports 155 pre-existing breaks** | see disclosure ↓ |
| Single-writer external anchor — **git commit/push of the chain head** | **shipped, live path** | — | `audit-anchor.ts` (tier-2 detectability source) |
| Per-actor **Ed25519 signed *merge* anchor** | **shipped code, merge-path-tested** (20k brute-force sigs, 0 forged) but **gated behind the demand-deferred multiplayer merge path** (`8da`) | tested | `packages/store/src/signed-merge-anchor.ts`; memory `epic0-epic1-merge-gate-shipped` |
| **OpenTimestamps** anchor | **named, not built** | — | `CLAUDE.md` trust-model box |
| Team mode (scrypt tokens, tenancy, tailnet) | **shipped** (only read tool `brain_search` proxied remotely today) | — | `005-AT-ARCH §2` |
| `/teamkb-compile` nightly freshness | **shipped (nightly, auto)** | **N** — liveness-observed, not quality-observed (§6.8) | memory `teamkb-compile-nightly-job` |
| Retrieval — keyword **BM25** (live = external `qmd search`) | **shipped** | **N** — no Recall/nDCG number yet (§6.9) | `005-AT-ARCH §2` |
| Retrieval — in-process **FTS5/BM25** backend | **shipped, not the default route** | — | `qmd-adapter/src/native` (`0t9.2`) |
| Retrieval eval harness (Recall@10 **+ nDCG@10 + MRR**, lexical/semantic-stratified) | **shipped** | self | `qmd-adapter/src/eval` (`0t9.6`) |
| Retrieval — **semantic** (sqlite-vec + EmbeddingGemma-300M) | **activation-gated** — harness (`0t9.6`) + SHA-256-pinned fail-closed weights (`0t9.5`) + native keyword backend (`0t9.2`) all shipped; the dense path builds when the eval shows BM25 < ~0.85 Recall@10 *and* a real recall miss is logged | — | INTKB ADR `038-AT-DECR` |
| Freshness **on-push / incremental** | **not built** (candidate §6.1) | — | — |
| Conversational "Ask the brain" Q&A | **not built** (candidate §6.2) | — | — |
| Visual diagrams | **not built** (candidate §6.3) | — | — |

**Disclosure — the verifier currently reports 155 pre-existing chain breaks** (memory
`governed-brain-audit-chain-preexisting-breaks`). `brain_audit_verify` returns `ok:false` /
"TAMPER DETECTED" for 155 historical events (2026-06-14 ×99 & 2026-06-22 ×56, idx 24–2345, **0 anchor
breaks**) — a **known hash-version migration artifact from the merge-gate work, not fresh tampering**;
**new writes verify clean.** The verifier *discriminates* benign states (`CHAIN_FORK` same-timestamp
ordering, pre-migration `unverified` rows) from tamper signatures (`ENTRY_HASH_MISMATCH` /
`PREV_LINK_MISMATCH`). In a brand whose entire pitch is honesty, disclosing this *strengthens* the
claim — a competitor running the verifier during diligence will see `ok:false`, and the doc must own
why. (Open decision for the council/CTO: re-hash the historical chain forward — itself the
tamper-evident event the trust box warns about — or carry the breaks forever with a documented
exception. Decide deliberately *before* publish.)

**Trust-model line (verbatim discipline):** local mode = integrity + ordering + rewrite-**detection**
(tier-1; deliberate single-writer rewrite is *expensive*, detectable only at tier-2 with the external
anchor — §4.2); **not** non-repudiation. Cross-actor non-repudiation = the Ed25519 **merge** anchor
(shipped, merge-path-gated). Today's live retrieval is **model-free BM25** — no embedding weights in
the path; the deferred semantic backend's weights are pinned fail-closed, so "ships verified" means
**the binary is what we pinned**, *not* that semantic retrieval is accurate (two different
verifications — Chip).

---

## 8. Canon-thinker review

Seven canon reviewers critiqued an earlier draft of this teardown from their lens — each read the doc,
the grounded fact sheet, and (most) the actual engine code, read-only. Their corrections are **already
folded into §1–§7 above**; this section preserves the verbatim pull-quotes and records what changed.

### What they converged on

1. **The moat is real but *latent* at n=2, *active* at scale-and-autonomy.** Ward, Karpathy, and Hickey
   independently landed here: at one tailnet with two users, a human reviewing the git diff (or a
   `log.md`) is a cheaper, higher-precision gate than the 8-rule pipeline. The machinery earns its keep
   the moment the human leaves the loop — team growth or the **nightly autonomous compile**. The doc
   was rewritten (§4 close) to tie the machinery to **autonomy-with-accountability**, not abstract
   superiority, and to concede plainly that some of it is built for the team GSB is *about to have*.
2. **Honesty calibration — several half-step over-claims, each caught and corrected.** The receipts
   "different *kind* of artifact" line (Kleppmann/Karpathy), the "retrieval *quality* gap" with no
   number (Reimers), the "8-check" vs "6-check" drift (Hickey/Ken/Chip), the "Ed25519 named-not-built"
   *under*-claim (Kleppmann), and the silent omission of the 155 chain breaks (Hickey/Kleppmann/Ken).
   In a brand whose pitch is honesty, every one of these *strengthens* the doc by being fixed.
3. **The doc bundled three separable properties and under-defended the seam.** Hickey: compile / govern
   / receipts detach; **govern is the keystone**; name the **spool** as the trust boundary. Folded into
   §1.

### Verbatim pull-quotes

**Ward Cunningham (invented the wiki):**
> "I built the wiki on a bet — that letting anyone edit, backed by social trust and the revert button,
> would keep shared knowledge honest. Governed Second Brain takes the opposite bet: no one edits the
> page, a deterministic gate decides what becomes durable, and a hash-chain proves it afterward. That
> isn't a wiki with governance bolted on — it's the *anti-wiki*, and it's the stronger position. Stop
> borrowing my word for warmth you don't need; name the category for what you actually built — the
> audited knowledge base — and the three things you're 'behind' on stop mattering."

**Andrej Karpathy (author of the LLM-Wiki pattern, §2.3):**
> "The honest mirror isn't 'Karpathy compiles, GSB governs.' It's 'Karpathy puts a human at the git
> commit; GSB removes the human and replaces him with a deterministic pipeline plus receipts.' That
> swap is the whole product — and it only earns its keep once the human can't review every diff
> anymore. At n=2 on one tailnet, a `log.md` in git is *also* a tamper-evident hash chain, for free,
> with 18 years of tooling. So sell the machinery as what unlocks **autonomy-with-accountability** —
> compile-while-you-sleep that you can still audit — not as receipts-beat-logs in the abstract. And
> measure it: run my corpus through both and show me the bad writes the PolicyPipeline caught that a
> human reviewing the diff would have waved through."

**Rich Hickey (deterministic/probabilistic boundary; simple vs easy):**
> "The teardown competes on the right axis — *who is allowed to write the ledger*, not how well a model
> remembers — and that is the essential complexity, not an incidental feature. But 'compile → govern →
> receipts' is sold as one spine when it is three separable things: govern without receipts is still a
> category-leading control plane; receipts without govern is Karpathy's `log.md`. The keystone is
> *govern* — deterministic acceptance below the spool — and the moat is not that GSB has receipts, but
> that its receipts attest a write-path no model touches. Defend the seam, not the bundle: name the
> spool as the trust boundary, prove every check below it is deterministic, and disclose that the
> verifier reports 155 historical breaks — because in a brand whose entire pitch is honesty, the
> omission is the only thing that can actually falsify it."

**Martin Kleppmann (append-only / audit / evidence substrate):**
> "The receipts claim is stated honestly where it is load-bearing — the trust-model line and the §7
> ledger are correct — but the '§4.2 different *kind* of artifact' headline runs a half-step ahead of
> the substrate. A bare local hash-chain does not detect a deliberate single-writer rewrite: the chain
> re-anchors on each stored hash, so a writer who edits an early row and re-hashes forward verifies
> clean (`audit-anchor.ts` says exactly this). The 'different kind' only fully materialises once the
> chain head is committed externally. State the three-tier model — Karpathy's unprotected log, GSB's
> locally-expensive-to-rewrite chain, GSB's externally-anchored detectable chain — and name the
> adversary each tier stops. That tiering *is* the moat, and naming its boundary is what makes the
> honesty brand a moat rather than a slogan."

**Nils Reimers (retrieval quality / embeddings / eval):**
> "Receipts and retrieval mechanism are orthogonal axes — governance does not make keyword search find
> a paraphrase, so 'BM25-with-receipts beats semantic-without-receipts' is a false dichotomy that
> should be retired. The defensible bet isn't that BM25 beats dense; it's that on a *small,
> LLM-compiled, vocabulary-normalized* corpus of ~2,000 governed memories, BM25 may *clear* the bar
> dense would also clear — and that is an empirical claim the eval settles, not a positioning claim the
> doc asserts. Until a real labeled set produces a number, the doc has a *mechanism* gap (no dense
> path), not a measured *quality* gap. Name the paraphrase failure mode out loud — keyword search can
> return a confident, cited, *wrong* answer on a synonym query — because admitting it is more honest."

**Chip Huyen (production / eval / governance posture):**
> "'Deterministic' answers *who decides*, not *whether the decision is correct* — and this teardown
> evaluates the cheapest decision in the stack (retrieval, 0.85 Recall@10) while leaving the
> consequential ones unmeasured: the 8 govern checks have no published precision/recall against
> adversarial input, and the 6 Claude compile passes have no faithfulness eval at all. The receipt
> faithfully attests that code admitted a fact and that no one edited it since — it does not attest the
> fact is true. Until there's a govern-decision eval and a compile-faithfulness eval, the hash-chain is
> an accountability layer vouching for content the pipeline never checked, and the most-costly failure
> is silent: a hallucinated synthesis, or a missed secret, promoted into the shared brain with a clean
> receipt the whole way."

**Ken Thompson (minimalism / composability / Unix philosophy):**
> "The teardown's own one-line finding is the whole strategy: govern + receipts is the moat, 'and it is
> real.' Then Section 6 recommends adopting four features that chase the crowd it just proved GSB
> doesn't belong to. Three of them — conversational Q&A, diagrams, public showcase — are surface, not
> substance; the doc even admits the Q&A is 'UX, not a new control plane.' Delete those three, keep
> governed freshness-on-push, and spend the saved effort moving the audit anchor from 'named, not in
> the live path' into the live path — because a receipt whose only verifier lives inside the system
> that wrote it is a trust chain that closes on itself, and that is the one defect a competitor's
> `cat log.md` doesn't have."

### Corrections applied as a result (traceable)

- **§1** — recast the "spine" as **three separable properties**; named **govern as the keystone** and
  the **spool** as the deterministic/probabilistic trust boundary; fixed the "model is sole arbiter"
  over-claim (Karpathy's arbiter is a human at git). *(Hickey, Karpathy)*
- **§2.3** — moved the **contradict-detection pass to Compile** (it surfaces, doesn't gate); reframed
  Karpathy's govern as **"human review at the git commit — correct but unscalable"**; removed the word
  **"immutable"** (forbidden); corrected Karpathy's retrieval from "grep" to **LLM-routed keyword**,
  the same loop GSB uses. *(Karpathy, Ward)*
- **§3 matrix** — tagged every row **[KIND]** vs **[DEGREE]**; added rows **human-edit**,
  **retrieval-mechanism**, **composable-standalone**; reframed Receipts to **"what is attested."**
  *(Hickey, Ward, Ken, Kleppmann, Reimers)*
- **§4.2** — replaced "different *kind* of artifact" with the **three-tier integrity model** + a
  **threat-model box** (defended vs undefended adversary); added that all 8 rules are **verified
  deterministic** (no model below the spool) *and* that **deterministic ≠ correct**. *(Kleppmann,
  Hickey, Chip)*
- **§5** — split the **retrieval-mechanism gap** from the **Q&A-surface gap**; downgraded the
  unmeasured "quality" gap to a "mechanism" gap; led the BM25 defense with **corpus shape, not
  receipts**; named the **paraphrase failure mode**; added the **composability** and
  **evaluated-vs-trusted** gaps. *(Reimers, Ken, Chip)*
- **§6** — added the **below-the-spool invariant box**; surfaced the reviewers' **cut/keep
  disagreement** on the UX adopts; added **Cluster B** moat-strengthening candidates (external anchor
  into live path, standalone verifier, govern-decision eval, compile-faithfulness eval, nightly
  govern-quality digest, first real retrieval number). *(Ken, Chip, Kleppmann, Reimers)*
- **§7** — added an **Evaluated?** column; **split the Ed25519 row** into shipped-unsigned-single-writer
  vs shipped-but-merge-gated vs unbuilt-OTS; **disclosed the 155 pre-existing chain breaks**; stated the
  **real eval rigor** (nDCG@10 + MRR + stratification); reworded semantic retrieval to
  **activation-gated**. *(Kleppmann, Hickey, Ken, Chip, Reimers)*

### Tensions the reviewers raised that are *not* resolved here — routed to the §9 council

1. **Category name** — Ward: rename "Wiki Memory" → **"Governed Memory" (anti-wiki)**. A positioning
   decision (CMO/VP-DevRel).
2. **The adopt list** — Ken: cut the three UX items, keep only governed freshness-on-push, move showcase
   to GTM, prioritize the **external anchor into the live path** + a **standalone verifier** above all
   UX. Chip: build the **govern-decision eval** + **compile-faithfulness eval** and **price the
   inference economics** of on-push/Q&A *before* committing. A scope/sequencing decision (CTO/CFO).
3. **The circular-verifier / external-anchor priority** — Ken, Kleppmann: is moving the anchor into the
   live single-writer path P0, ahead of every feature? A risk/integrity decision (CISO/CTO).
4. **Disposition of the 155 chain breaks** — re-hash forward (itself a tamper-evident event) vs carry
   with a documented exception. A receipts-integrity decision (CISO/CTO), to be made *before* publish.
5. **Delete the second hash-chain?** — Karpathy/Ken floated collapsing to one git-anchored chain;
   Kleppmann's read is that ICO's compile-side chain and INTKB's govern-side chain **attest different
   layers** and are not redundant copies. A simplicity-vs-completeness decision (CTO).

---

## 9. Executive-council decision record (ratified)

The strategic forks above were put to the 7-seat ISEDC exec council (CTO·GC·CMO·CFO·CSO·CISO·VP-DevRel).
The durable record — verbatim seat positions, vote tallies, decision tree, and preserved dissent — is
[`009-AT-DECR`](009-AT-DECR-wiki-memory-positioning-and-adopt-decisions.md). **Ratified decisions:**

- **D1 — Positioning:** lead with **"Governed Memory"** (the audited knowledge base; the
  provenance/attestation lineage), *not* "Wiki Memory" (7/7). Developer-natural README hero; "wiki
  memory" only a lowercase generic SEO bridge; **no UX-parity copy**; every "audited" claim carries the
  trust-model disclaimer.
- **D2 — Cluster A:** ADOPT **(a) freshness-on-push** (P1, gated on a per-push cost model); **DEFER (b)**
  conversational Q&A; **CUT (c)** diagrams to a renderer script; **ADOPT (d) showcase** as gated GTM
  (own/permissive corpus, no competitor named, gated on (e)+(f)+Q5).
- **D3 — Cluster B:** COMMIT **(e)** anchor+verifier [P0], **(f)** govern-eval [P1], **(i)** first
  retrieval number [P1], **(h)** govern-quality digest [P2], **(g)** compile-faithfulness [P2, sampled —
  no public faithfulness claim until shipped].
- **D4 — Anchor priority:** **(e) mechanism is P0**, ahead of all UX (6/7; CFO dissent: P1-but-pre-gated).
  Standards-*claim* deferred — ship standards-*shaped* (DSSE/in-toto + OpenTimestamps), don't boast.
- **D5 — The 155 breaks:** **carry-with-documented-exception, never silently re-hash (UNANIMOUS 7/7;
  the most-costly-to-recover-from decision, 6/7).** Discriminated 3-state verifier + signed,
  externally-anchored exception manifest + showcase on a fresh brain.

---

## 10. References

- GSB grounded system map (every GSB claim above): [`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md)
- Repo topology / working surface: [`007-AT-SMAP`](007-AT-SMAP-repo-topology-and-working-surface.md)
- Ecosystem thesis ("Compile, Then Govern"): `034-AT-NTRP-ecosystem-thesis.md` (in both flagships)
- Retrieval backend decision (BM25-today / semantic-deferred): root `CLAUDE.md` § "Retrieval backend decision"
- `/teamkb-compile` nightly freshness job: auto-memory `teamkb-compile-nightly-job`
