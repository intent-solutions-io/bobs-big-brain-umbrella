# 018-RL-RSRC: Research Bibliography

**What this is:** the working bibliography for the GSB upgrade initiative and the competitive article. Every entry is a 2026 (or late-2025) paper surfaced and adversarially verified during the research pass (a six-axis harvest-and-verify workflow plus a federation research agent, all against Semantic Scholar). Grouped by the seven upgrade axes of `016-AT-PLAN`. Each entry gives the citation key used across the docs, title, date, source id/url, and what it supports (plus its honest limit where one was found). Authors are listed where captured. This is the citation source of truth for `019-PP-PLAN` and the article.

Convention: `[key]` Title . date . id/url . what-it-supports (+ honest limit).

Written dash-free on purpose.

---

## Axis 1: Retrieval (BM25 to a two-stage retriever)

- `[ret-scifact]` **A Multi-Stage Hybrid Retrieval Framework for the Scientific Literature with Cross-Encoder Re-Ranking** . 2026-05-12 . https://www.semanticscholar.org/paper/8d06b6ebc6ccaaee66897559f66149d9f49b57fa . Cross-encoder rerank is the "primary driver" of final retrieval performance (best config Hybrid SciNCL+BM25 + Cross-Encoder, NDCG@10 0.523); RRF hybrid fusion did NOT consistently beat the best dense retriever and can dilute strong rankings on harder queries. Sets ship-order: reranker first, dense+RRF conditional. Limit: single benchmark (SciFact) plus cross-domain checks.

- `[ret-clinical]` **Optimising clinical information extraction: a comparative study of retrieval-augmented generation techniques in clinical notes** . 2026-05-01 . Journal of Biomedical Informatics (peer-reviewed) . https://www.semanticscholar.org/paper/753233eb3033d44f67eee29c13405a9b18a38964 . Repeated-measures ANOVA over six retrieval strategies: reranking and hybrid-ensemble significantly beat BOTH standalone BM25 and standalone dense. Limit: clinical NER, n=208/task, winning config flips between tasks.

- `[ret-bm25crag]` **From BM25 to Corrective RAG: Benchmarking Retrieval Strategies for Text-and-Table Documents** . 2026-04-02 . arXiv 2604.01733 . https://www.semanticscholar.org/paper/2d0b4b34f319de8da4296b1853d2f4903d71a75c . Ten strategies over 23,088 financial QA queries: two-stage hybrid + neural rerank reached Recall@5 0.816, MRR@3 0.605, beating every single-stage method; separately BM25 beat state-of-the-art dense on these documents. Anchor for the two-stage upgrade AND for not over-conceding BM25. Limit: lexically-favorable numeric domain.

- `[ret-piserini]` **Rethinking Agentic Search with Pi-Serini: Is Lexical Retrieval Sufficient?** . 2026-05-11 . arXiv 2605.10848 . https://www.semanticscholar.org/paper/3cfce98315b0a42f4cdf9aa39fdc80d06907bbd6 . On BrowseComp-Plus, a well-tuned BM25 retriever at sufficient depth plus a capable reasoning LLM reached 83.1% answer accuracy, 94.7% evidence recall, beating released dense-retriever agents. Defends keeping and tuning BM25. Critical caveat: used gpt-5.5 (frontier), NOT a local model, so it does NOT license skipping dense/rerank on a local commodity model.

## Axis 2: Govern (name the seam, symbolic lifecycle, gate ordering)

- `[gov-ssgm]` **Governing Evolving Memory in LLM Agents: Risks, Mechanisms, and the Stability and Safety Governed Memory (SSGM) Framework** . 2026-03-12 . arXiv 2603.11768 (C. Lam, Jiaxin Li, Ling Zhang, Kuo Zhao) . https://arxiv.org/abs/2603.11768 . Decouples memory evolution from execution by enforcing consistency verification, temporal decay modeling, and dynamic access control PRIOR to any memory consolidation. The single most-cited paper in the set; validates the govern-before-durable thesis. Register: design-thesis claim only (self-described conceptual, no benchmark).

- `[gov-neusymms]` **NeuSymMS: A Hybrid Neuro-Symbolic Memory System for Persistent, Self-Curating LLM Agents** . 2026-05-17 . arXiv 2605.17596 (M. Sultan, Sri Thuraisamy, D. Rajaratnam) . https://arxiv.org/abs/2605.17596 . Neural extraction coupled with a CLIPS symbolic expert system that classifies, dedups, and reconciles facts under explicit lifecycle rules, with access-based promotion and time-based pruning; argues for "trustworthy, auditable memory." A deterministic rule engine below an LLM extractor is a published pattern. Register: feasibility claim only.

- `[gov-memclaw]` **Governed Shared Memory for Multi-Agent LLM Systems (MemClaw / ArgusFleet)** . 2026-06-23 . arXiv 2606.24535 . https://arxiv.org/abs/2606.24535 . Production finding: a synchronous near-duplicate admission gate prematurely rejected contradictory writes before the async contradiction detector ran (a pipeline-ordering failure); also reconstructed 100% of depth-four derivation chains with correct writer identity. Concedes GSB's nightly-batch visibility as a real gap. (Also the lead federation paper, see Axis 7.)

- `[gov-agl1]` **AGL-1: The Enterprise AI Governance Layer as a Control Plane** . 2026-07-03 . arXiv 2607.03516 . https://arxiv.org/abs/2607.03516 . Seven governance domains including provenance management, memory governance, and knowledge-integrity monitoring, distinct from identity-aware retrieval. Positioning and vocabulary only.

## Axis 3: Receipts (the integrity ladder above the hash chain)

- `[rec-aegon]` **Aegon: Auditable AI Content Access with Ledger-Bound Tokens and Hardware-Attested Mobile Receipts** . 2026-04-08 . arXiv 2604.06693 (Amrish Baskaran, Nirbhay Pherwani, R. Krishnan) . https://www.semanticscholar.org/paper/b416c4cf39f00afd9dc0e87f579efd73889c3b3c . Certificate-Transparency-style Merkle tree over an append-only ledger; auditors verify records were recorded and not retroactively modified; a signed provenance event log tracks content through chunking, embedding, retrieval, citation (maps onto compile to govern to promote). Reference for a LATER Tier 2. The hardware-attestation part is the conceded limit.

- `[rec-apex]` **Auditable Zero-Trust Sensor-Cloud Repositories: Append-Only Logging and Anomaly Detection for Misbehavior Discovery (APEX)** . 2026-05-08 . https://www.semanticscholar.org/paper/11037d3ea33f16a9092262c5149469cf54f71c75 . Hash-chained log entries plus periodic signed checkpoints give verifiable evolution of repository states under an explicitly zero-trust host. Grounds Tier 1 self-signed checkpoints.

- `[rec-taf]` **Enhancing Legal Document Security and Accessibility with a Trust-Anchoring Framework (TAF)** . NDSS 2026 . https://www.semanticscholar.org/paper/789a2e2142448115fb0f34314e5b6b87b30296dc . First system for a threat model where the attacker fully controls the hosting repository; builds on top of Git + TUF, proving Git-or-TUF-alone is insufficient and a signed time-bound state layer must sit on top. Hinge citation for external anchoring.

- `[rec-dtl]` **Decentralised Trust Layers for the Web: Towards Transparent AI-Powered Platforms (DTL)** . 2026-05-28 . The Web Conference 2026 . https://www.semanticscholar.org/paper/6acf2262c0a7c88445b0904ba20782f0d7a1c59e . Measured microsecond-scale receipt generation and logarithmic proof sizes: the Merkle-log upgrade is cheap for a nightly-batch local box.

- `[rec-dht]` **DHT-Backed Ancestor-Assisted Merkle Verification for Scalable Log Integrity in Cloud Data Lakes** . 2026 . https://www.semanticscholar.org/paper/d65676ef3b6df522c43da2238f9a8021496777e1 . Anchor ONLY the epoch root-of-roots externally, keeping per-record proofs local, with constant external storage across epoch sizes. Cite the root-only design; substitute git-tag/OpenTimestamps for its public ledger (GSB never makes that anchoring claim).

- `[rec-vct]` **VCT: Verifiable Transcript System for LLM Conversations** . 2026-06-22 . paperId 4976e16e3de4dc50b0b8157c17dc6778a9ab99a1 . What the strongest rung would cost: joint user-plus-server signatures plus fork-detecting gossip. Cited to keep that top rung explicitly out of scope for GSB.

## Axis 4: Threat model (write-time provenance)

- `[threat-smsr]` **SMSR: Certified Defence Against Runtime Memory Poisoning in Persistent LLM Agent Systems** . 2026-06-10 . arXiv 2606.12703 . https://arxiv.org/abs/2606.12703 . Formally proves no provenance-free retrieval-time filter can certify against adaptive injection; write-time HMAC-SHA256 provenance cut unsigned-injection attack success from 93 to 100 percent down to 0 percent across 15 scenarios (3,150 trials); an authenticated adversary is held to 8.0% only by a second query-time ablation-voting component GSB does not implement. The strongest adversarial citation in the set.

- `[threat-untrusted]` **From Untrusted Input to Trusted Memory: A Systematic Study of Memory Poisoning Attacks in LLM Agents** . 2026-06-03 . arXiv 2606.04329 (Pritam Dash, Tongyu Ge, Aditi Jain, Tanmay A. Shah, Zhiwei Shang) . https://arxiv.org/abs/2606.04329 . Four memory write channels, nine structural vulnerabilities; aggressive-write agents are more exploitable; existing prompt-injection defenses fail to cover memory poisoning. Justifies a restrictive deterministic admission gate.

- `[threat-mempoison]` **MemPoison: Uncovering Persistent Memory Threats and Structural Blind Spots in LLM Agents** . 2026-07-16 . arXiv 2607.14651 . https://arxiv.org/abs/2607.14651 . Write-time defenses suppress single-record (L1) corruption but fail on compositional multi-record (L2) and context-triggered dormant (L3) corruption. The honesty anchor for named out-of-scope residual risk.

## Axis 5: Freshness (event-driven incremental recompile on push)

- `[fresh-etl]` **Measuring Retrieval Freshness and Accuracy Degradation in Continuous ETL-Driven RAG Systems** . 2026-02-13 . https://www.semanticscholar.org/paper/9c69b1e1f8f46d9f8ecd947534ed829c5395e67f . Retrieval freshness is a first-order determinant of end-to-end accuracy; substantial staleness can eliminate or reverse the value of retrieval augmentation; the field is moving from ad hoc refresh to principled freshness management. The why behind the freshness upgrade.

- `[fresh-serverless]` **Serverless Architecture Patterns for Enterprise AI Agents** . 2026 . https://www.semanticscholar.org/paper/e95908388432d0a927e6317443c19e74cee22680 . Incremental knowledge-base updates without full reindexing, driven by syncing code repos and issue trackers on change, as a first-class operational requirement (the exact input shape GSB governs). Architectural validation; borrow the pattern, not the AWS infra.

- `[fresh-eventdriven]` **Real-Time RAG-Based CRM Using Event-Driven Knowledge Updates and Vector Embeddings** . 2026-02-24 . https://www.semanticscholar.org/paper/3bdf1bb52430a41f053278a2efa8b89c168a0005 . Event-driven streaming cut mean document-to-query propagation to 3.1 seconds, 75 to 150x faster than 5 to 10 minute batch cycles, holding retrieval quality (MRR 0.938, NDCG@10 0.942). Single empirical latency anchor; caveat: their Kafka+Rust+pgvector+GPT-4 stack, an existence-proof, not a GSB promise.

## Axis 6: Eval (a decoupled three-layer harness on a CI gate)

- `[eval-atma]` **A-TMA: Decoupling State-Aware Memory Failures in Long-Term Agent Memory** . 2026-07-02 . https://www.semanticscholar.org/paper/59a6b3f56ec0268d2a36b2e5b5b9eef608668869 . Measure memory at three decoupled levels (bank maintenance, retrieval, answer-time resolution) because final QA accuracy hides where failure occurs (a temporal F1 of 0.0295 while the aggregate looked healthy). Core three-layer harness design.

- `[eval-probe]` **PROBE: Release-Gate Evaluation for Regulated Enterprise RAG** . 2026-05-18 . https://www.semanticscholar.org/paper/05a112d952e24a00d6a5ae03268ff956be064a2a . A composite release-gate score jointly measuring grounding plus conflict correlated with human-adjudicated acceptability at Spearman rho 0.72, vs 0.47 for NDCG@10 and 0.58 for RAGAS faithfulness alone. Cite WITH the Readiness Harness (low-tier venue).

- `[eval-readiness]` **LLM Readiness Harness: Evaluation, Observability, and CI Gates for LLM/RAG Applications** . 2026-03-28 . https://www.semanticscholar.org/paper/81b7fc8a239364c0ccd1748df4f51a0fa6ef4563 . Multi-metric CI gates (workflow success, policy compliance, groundedness, retrieval hit-rate, cost, p95) that auto-reject unsafe release variants; readiness is not a single metric. Carries the evidentiary weight for the composite-gate claim.

- `[eval-groupmem]` **GroupMemBench: Benchmarking LLM Agent Memory in Multi-Party Conversations** . 2026-05-14 . https://www.semanticscholar.org/paper/469cd86992948b1b4d4286d1bbf5a7e2a779ff33 . A plain BM25 baseline matched or exceeded most agent-memory systems when ingestion is clean; the bottleneck is what admission preserves, not retrieval sophistication. Defends the BM25 floor and mandates the control arm.

## Axis 7: Federation (team brains to a master brain)

- `[fed-memclaw]` **Governed Shared Memory for Multi-Agent LLM Systems (MemClaw / ArgusFleet)** . 2026 . arXiv 2606.24535 . https://arxiv.org/abs/2606.24535 . Formalizes the fleet-memory problem and names four merge failure modes (unauthorized leakage, stale propagation, contradiction persistence, provenance collapse); primitives are scoped retrieval, temporal supersession, provenance tracking, policy-governed propagation; 100% depth-4 provenance reconstruction; zero cross-fleet leakage under scoped retrieval; discloses a real sub-tenant GET-by-id scope bug.

- `[fed-gatemem]` **GateMem: Benchmarking Memory Governance in Multi-Principal Shared-Memory Agents** . 2026 . arXiv 2606.18829 . https://arxiv.org/abs/2606.18829 . No memory method simultaneously achieves utility, access control, and reliable forgetting: the empirical case for re-scanning policy and secret/PII at each merge boundary rather than inheriting a source verdict.

- `[fed-misattribution]` **The Misattribution Gap: When Memory Poisoning Looks Like Model Failure** . 2026 . arXiv 2605.22842 . https://arxiv.org/abs/2605.22842 . Documents Semantic Norm Drift and the Trust Laundering Chain (a policy-formatted document loses provenance and reappears as trusted system context); across 64 failures four safety classifiers produced ZERO detections across 510 checkpoints; Memory-Persistent Information-Flow Control blocked 97% of attacks at the cross-session boundary. The core "why Compile-only cannot defend" evidence.

- `[fed-superlocal]` **SuperLocalMemory: Privacy-Preserving Multi-Agent Memory with Bayesian Trust Defense** . 2026 . arXiv 2603.02240 . https://arxiv.org/abs/2603.02240 . Cloud memory creates centralized attack surfaces where poisoned memories propagate across sessions and users; defends with architectural isolation plus per-agent provenance plus Bayesian trust scoring, with no LLM inference calls in the defense path. The closest published architecture to GSB.

- `[fed-aggregation]` **Federated Memory Aggregation for Poisoning-Resilient Multi-Agent Collaboration** . 2026 . https://www.semanticscholar.org/paper/330969e9f72ac375c36d77eb1277e0994ee880fc . A trimmed-mean merge rule that discards extreme updates: under a 25% poisoning rate, direct sharing dropped 44.2% while the trimmed-mean merge held loss to 13.6%. Trust-weighting plus hub aggregation.

- `[fed-repair]` **Memory Poisoning Propagation and Repair Mechanism in Multi-Agent Collaborative Environments** . 2026 . https://www.semanticscholar.org/paper/3e84c6dbe0f008725472b85ae20fd9baa7222699 . An evidence graph keyed on source credibility plus content consistency hits AUC 0.94 on poisoned-memory detection and cuts cross-agent propagation by 78.1%. Merge-time dedup and contradiction check.

- `[fed-traceability]` **Temporal Traceability and Source Attribution of Memory Poisoning in Distributed Multi-Agent Systems** . 2026 . https://www.semanticscholar.org/paper/bdfcfb8925deb3542afb11366cf01cee0d7cff15 . Localized poisoning origins across distributed agents at 91.2% source-attribution accuracy and cut secondary contamination 54.6%. Cross-brain provenance and revoke-by-origin.

- `[fed-topologies]` **Controlled Benchmarking of Memory Topologies in LLM-Based Multi-Agent Systems** . 2026 . https://www.semanticscholar.org/paper/a96ec007ce6b034623afb6778eb67f99350b0c8d . Tested no-memory / local-per-agent / shared / hybrid-with-crystallization: the winner is a hybrid where only validated and depersonalized facts and rules are promoted to shared storage. The promotion-not-sync boundary.

- `[fed-governai]` **GovernAI: Policy-Driven Model Governance for Dynamic and Multi-Tenant AI Systems** . 2025 . https://www.semanticscholar.org/paper/6543c27b4830c20ee79e0feb5a7226526eb19816 . Declarative policy plus tenant-aware access plus lineage tracking plus real-time audit cut policy violations 45%. The merge-time policy layer.

- `[fed-ethical]` **Ethical AI Governance Models for Federated Multi-Agent Ecosystems** . 2026 . https://www.semanticscholar.org/paper/0b3f4bb14032d516863cbe76526d17a1b2ddd8bf . Recommends governance controls at BOTH the local-agent and the global-federation level. Two-tier hierarchical topology.

- `[fed-clusterbrain]` **Adaptive Semantic Compression for Cognitive Knowledge Coordination in a Hierarchical LLM-Agents System** . 2026 . https://www.semanticscholar.org/paper/bf91f479d860cf62a17c1e2b3d01dccb09fb3ae3 . A "cluster brain" hub fed by lower-level agents that ship compressed KB updates upward. The hub-and-spoke = master-brain vocabulary.

- `[fed-fedse]` **Fed-SE: Federated Self-Evolution for Privacy-Constrained Multi-Environment LLM Agents** . 2025 . arXiv 2512.08870 . https://arxiv.org/abs/2512.08870 . A local-evolution / global-aggregation paradigm under privacy constraints; spokes ship vetted updates, not raw stores.

- `[fed-transfer]` **Integrating Federated Transfer Learning for Secure Multi-Tenant Data Management** . 2026 . https://www.semanticscholar.org/paper/ba94b4c61c77287b3ef3cc3c2d75e0b51f1019e3 . A tenant-aware mechanism that dynamically assesses trust levels for secure workload allocation. Trust-weighting reuse.

- `[fed-torra]` **Memory Poisoning and Secure Multi-Agent Systems (Torra and Bras-Amoros)** . 2026 . arXiv 2603.20357 . https://arxiv.org/abs/2603.20357 . A memory-type taxonomy; agent-to-agent interaction is itself a poisoning vector that is hard to formalize. Argues against a peer topology; secure-by-design.

- `[fed-tfxmarl]` **Zero-Shot Policy Transfer via Trusted Federated Explainability (TFX-MARL)** . 2025 . https://www.semanticscholar.org/paper/c2232e68cc1fba2d5fe166c86a8315e81f41440e . A trust metric built from provenance plus update consistency plus safety-compliance; trust-aware aggregation beats plain averaging under adversarial participants.

---

## Improvement theory (framing, not a peer-reviewed paper)

- `[imp-grounding]` Carlos E. Perez (@IntuitMachine), **the "loops to graphs" essay on self-improvement** (2026) . https://x.com/IntuitMachine/status/2068808668393451770 . The independent, improvement-theory-lineage statement of the GSB thesis. A single improvement loop fails four ways (Goodhart, blindness-to-its-own-target, conflict, measurement decay); a graph of loops helps but fails circularly ("everything consistent, nothing verified; no loop touches the ground"); the real axis is ungrounded vs grounded, which needs three things no arrangement of loops supplies: anchors (measurements that cannot be argued with), frozen rules the optimizer cannot tune (like a held-out set), and a definition of "better" chosen from outside the machine by people. Maps one-to-one onto GSB: receipts + completeness = anchors, the seam firewall = the frozen rule, `017` + human GOVERN policy = the outside judgment. Use as the article's framing on-ramp (open on the loops-vs-graphs meme, land the grounded-vs-ungrounded axis, show GSB as the concrete answer) and as the rationale for blueprint bead C5. Honest register: a popular essay, cited for framing and lineage, not as empirical evidence.

## Competitor grounding (products, not peer-reviewed papers)

- Cerebras, **How Cerebras Built Its Enterprise Knowledge Base** . https://www.cerebras.ai/blog/how-we-built-our-knowledge-base . The foil: Postgres+pgvector (3072-dim HNSW), LLM distillation, hybrid lexical+vector+IDF+recency, RRF, cross-encoder rerank, synthesis with citations, a deterministic SIGNAL-threshold admission gate, and access-auditing.
- Mem0, **State of AI Agent Memory 2026** . https://mem0.ai/blog/state-of-ai-agent-memory-2026 . Multi-scope memory (user/agent/run/app/org ids) marketed as isolation; scope tags are metadata filters, not a gate.
- Zep, Letta, Cognee (comparison roundups) . the model is in the write path; none interpose a deterministic admission gate between a source store and a shared one.

---

## Notes on rigor

- Every axis-1-through-6 entry was adversarially verified in the workflow: a second agent checked that the paper's actual claim supports the mapped GSB upgrade, and dropped citation-laundering candidates (for example, a rigorous chunking-taxonomy paper was dropped from Axis 1 because it does not test the two-stage retriever being shipped).
- Citation counts and venues were captured at research time (mid-2026); several strong entries are recent preprints with low counts, flagged as "feasibility" or "design-thesis" register rather than "benchmark" where appropriate.
- Where GSB substitutes a lighter mechanism for a paper's heavier one (git-tag/OpenTimestamps for a public ledger; no per-record signatures), the bibliography records the substitution so the article never inherits a claim the paper makes but GSB does not.
