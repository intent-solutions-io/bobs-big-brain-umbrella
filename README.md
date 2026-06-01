# Intent Knowledge OS

> A local-first knowledge stack that **compiles** raw corpus into **governed**, citation-backed memory for humans and agents. Compile knowledge for the machine. Distill understanding for the human.

This repo is the umbrella for the **Compile-Then-Govern** constellation. Each component is its own independently developed and released repository under `jeremylongshore/*`; this repo holds the ecosystem-level documentation, the pipeline map, and the per-repo status table.

**Live work →** [intentional-cognition-os](https://github.com/jeremylongshore/intentional-cognition-os) · [qmd-team-intent-kb](https://github.com/jeremylongshore/qmd-team-intent-kb)

---

## The thesis: Compile, Then Govern

Agent memory is having a moment — and most of it stops at recall. A better memory means an agent *remembers* more. It says nothing about what the agent *did* with what it remembered, whether that knowledge was ever vetted, or whether you can prove any of it after the fact.

**Memory is not accountability.** Recall is necessary; it is not sufficient. The hard problem — the one that matters the second something goes wrong — is the **receipt**: what was retrieved, what was used, where it came from, provable later, tamper-evident.

This ecosystem is built around that gap. Knowledge is **compiled** (derived, not dumped), **governed** (vetted before it's trusted), and **served with receipts** (every answer cites its source; every step is hash-chained). The compilation/governance split is the abstraction; search, retrieval, and presentation are pluggable underneath it.

## The problem it solves

| | Vector-store memory | RAG-over-raw-docs | **Compile-Then-Govern** |
|---|---|---|---|
| **Recall** | Yes | Yes | Yes |
| **Derived knowledge** (summaries, concepts, contradictions) | No — raw chunks | No — raw chunks | **Yes — compiled** |
| **Governance** (dedupe, policy, promotion) | No | No | **Yes — deterministic** |
| **Provenance** (where did this come from) | Partial | Partial | **Yes — tracked end-to-end** |
| **Receipts** (what the agent actually used) | No | No | **Yes — hash-chained audit + `qmd://` citations** |
| **Runs offline / on-device** | Varies | Varies | **Yes — local-first** |

## What's in the ecosystem

| Repo | Layer | What it does |
|------|-------|--------------|
| [intentional-cognition-os](https://github.com/jeremylongshore/intentional-cognition-os) (`ico`) | **Compile** | Local-first knowledge OS. Ingests raw corpus and compiles it into semantic knowledge through six passes (sources → concepts → topics → links → contradictions → gaps), creates episodic task workspaces, and emits a governance spool. Deterministic kernel (SQLite + JSONL), probabilistic compiler (Claude). 5 workspace packages. |
| [qmd-team-intent-kb](https://github.com/jeremylongshore/qmd-team-intent-kb) (INTKB) | **Govern** | Governed team-memory platform. Consumes ICO's spool, runs candidates through dedupe → policy → promotion, keeps an append-only audit log, and exports curated memory to a searchable tree. The model proposes; the deterministic control plane decides. 6 apps + 8 packages. |
| [qmd](https://github.com/tobi/qmd) (`@tobilu/qmd`, upstream) | **Retrieve** | On-device hybrid search for markdown — BM25 + vector + LLM reranking. The retrieval substrate. Every result is a `qmd://<collection>/<path>` URI — the citation. |

## The pipeline

```
  raw corpus  (PDFs · markdown · web clips)
       │
       ▼
  ICO — compile ───────────────►  workspace/wiki   (semantic knowledge, 6 passes)
  intentional-cognition-os        workspace/outputs (durable artifacts)
       │
       │  spool emit  — JSONL candidate contract · tenant-scoped · SHA-256 manifest
       ▼
  INTKB — govern ──────────────►  curated team memory
  qmd-team-intent-kb              dedupe → policy → promote · append-only audit
       │
       │  git-exporter — category-routed markdown tree
       ▼
  qmd — retrieve ──────────────►  qmd:// citations
  @tobilu/qmd (upstream)          BM25 + vector · on-device · no API key
       │
       ▼
  MCP / REST ──►  agents + humans
       ▲
       └── every hop hash-chained (SHA-256 prev_hash) → tamper-evident receipts
```

## Three layers

**1. Compilation (probabilistic).** ICO derives — it doesn't index. Summaries, concepts, backlinks, and contradictions are *computed* from sources, not stored as opaque chunks. Raw and derived stay separate; provenance is tracked from the first byte.

**2. Governance (deterministic).** INTKB is the control plane. Every candidate is deduped, run through a policy engine, and either promoted or rejected — by code, not by a model. Secret detection, trust levels, and tenant isolation live here. The model never writes durable state directly.

**3. Retrieval + receipts.** qmd serves citation-backed answers offline. Every retrieval, promotion, and compile is written to an append-only JSONL trace where each event carries the SHA-256 of the previous one — so tampering with any record breaks a verifiable chain. `ico audit verify` walks it.

## The constraint that makes it work

> The model proposes. The deterministic system owns durable state and control.

The model never directly writes to audit, policy, or promotion. Compilation, synthesis, and contradiction-detection are probabilistic and live in the compiler. File storage, governance, permissions, audit, and promotion rules are deterministic and live in the kernel. This boundary is the whole design — it's what lets a probabilistic system produce an auditable record.

## Is it real? — the receipts

The differentiator isn't a claim, it's a trail:

- **End-to-end proof.** `scripts/demo-e2e.sh` drives the full chain on a real corpus — compile → spool → govern → index → search → audit verify. Latest run: 7/7 stages green, 21 candidates promoted, 20 `qmd://` citations returned, 61 audit-chain events with 0 breaks.
- **Continuous guard.** A key-free nightly CI smoke replays the deterministic half (govern → retrieve → cite) off a frozen fixture, so any regression in the chain trips a red build — no API calls, no secrets.
- **Public dog-food trail.** ICO eats its own cooking against real corpora and publishes the citation-verify-rate trend over time. The metrics are public; the source content stays private.

## Status

| Repo | Version | License |
|------|---------|---------|
| [intentional-cognition-os](https://github.com/jeremylongshore/intentional-cognition-os) | v1.10.0 | MIT |
| [qmd-team-intent-kb](https://github.com/jeremylongshore/qmd-team-intent-kb) | v0.6.0 | MIT |
| [qmd](https://github.com/tobi/qmd) (upstream dependency) | 2.5.3 — pinned, Dependabot-tracked, integration-test-gated | MIT |

## Documentation

- **Ecosystem thesis** — *"Compile, Then Govern"*, peer-reviewed, Semantic-Scholar-grounded — lives byte-identical in both repos at `000-docs/034-AT-NTRP-ecosystem-thesis.md`.
- **Build-direction decision record** — `000-docs/035-AT-DECR-post-thesis-build-direction-2026-05-23.md` (both repos).
- Per-repo architecture, standards, and ADRs live in each repo's `000-docs/`.

## License

MIT on both flagship repos. See each repo's `LICENSE`.

---

Intent Solutions — [intentsolutions.io](https://intentsolutions.io)
