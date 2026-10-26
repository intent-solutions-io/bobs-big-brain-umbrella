# Signed legacy audit cut-over proposal

| Field | Value |
|---|---|
| Document / type | 036-AT-DSGN / architecture and decision proposal |
| Schema / template | 1 / blueprint-docs 3.0.0, architecture + ADR |
| Status | Proposed; implementation, signer, witness and application are unapproved |
| Owner / decision authority | Jeremy Longshore; explicit owner approval required for the bound cut-over |
| Reviewers | Agent review notes incorporated; configured repository reviews tracked on PR #124 |
| Updated / review date | 2026-10-26 / before any implementation approval or application |
| Classification | Public design; private brain records, bodies and key material excluded |
| Sources | S1–S6 below; assumptions A1–A2 and unknowns U1–U4 |
| Related artifacts | Beads `compile-then-govern-eqw.8.1.2.9`, `.9.2`, `.9.3`; Registrar #421/#422; plugin #94 |
| Supersedes | Nothing; D5 and existing verifier contracts remain controlling |

Operator-reported diagnostics on a private restored copy identify historical
ordering forks; this documentation does not independently reproduce them. The proposed
cut-over preserves every old audit row and head, records a signed, dated boundary,
and verifies subsequent activity as a separate epoch. The old global chain stays
strictly unverified. This proposal creates no migration authority and does not
make a fork eligible for an exception manifest.

## Source register and decision context

| ID / evidence state | Material fact or boundary | Source |
|---|---|---|
| S1 / verified policy | D5 forbids silent rehashing and permits only an explicitly recorded, signed, externally anchored rebaseline preserving the old head. | [009 §Q5](009-AT-DECR-wiki-memory-positioning-and-adopt-decisions.md#q5--the-155-audit-chain-breaks) |
| S2 / verified source | Canonical classification keeps `CHAIN_FORK` separate and `verified: false`; exception schemas exclude forks. | [Registrar exception classifier](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/8ea12e6ecfc2e74a16a29e87b242df589e77ba63/packages/store/src/exception-manifest.ts) |
| S3 / operator-reported private snapshot | The operator reports 33,887 audit rows, 155 forks, zero tamper signatures and 847 anchors with zero mismatches from an existing restored copy. These private snapshot results are not independently reproduced by this PR or current live-state measurements. | Local operator receipt `canonical-anchor-snapshot-diagnostic.json`, SHA-256 recorded below; no private rows published |
| S4 / verified source | Audit insertion serializes predecessor read and append in an immediate transaction; positive `seq` defines write order and current writers continue the last hashed row. | [Registrar audit repository](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/8ea12e6ecfc2e74a16a29e87b242df589e77ba63/packages/store/src/repositories/audit-repository.ts) |
| S5 / verified source | Canonical verification recomputes each row and predecessor; global verification has no signed epoch contract. | [Registrar audit verifier](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/8ea12e6ecfc2e74a16a29e87b242df589e77ba63/packages/store/src/audit-verify.ts), [anchor verifier](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/8ea12e6ecfc2e74a16a29e87b242df589e77ba63/packages/store/src/audit-anchor.ts) |
| S6 / verified source / limited precedent | Existing Ed25519 merge anchors supply signing primitives, but their embedded public key does not by itself establish owner authorization for this operation. Their merge schema does not describe this cut-over. | [Registrar signed merge anchors](https://github.com/jeremylongshore/bobs-big-brain-registrar/blob/8ea12e6ecfc2e74a16a29e87b242df589e77ba63/packages/store/src/signed-merge-anchor.ts) |

S3 is the local file
`/tmp/bbb-private-brain-rehearsal-5y952gzu/canonical-anchor-snapshot-diagnostic.json`.
Its SHA-256 is `465cb8d1ec2b4f816639be676a3736990f1b7c90fea8d3eb73ac6d1cd43f479b`.
Its content is operator-reported evidence at an ephemeral local locator; it is
not a durable public artifact, an independently reproduced result or a signed
witness. Before any cut-over approval, recollect and retain the complete private
evidence in a durable, access-controlled location with exact commands, exit
status, source identities/digests and fresh verifier output. The private copied-command refusal proof is
`fixed-plugin-copied-cli-readiness-v2.json`, SHA-256
`3c6c3a0e69680e146359aaf03467644ab1d70e7ef93f2451ceb84bfea6878fac`:
`committed: false`, all working files and both database table denominators
unchanged. The operator receipt reports refusal and no observed changes. Its sanitized CLI
output does not identify the underlying refusal cause, so this document does not
independently prove fork-specific refusal. The canonical diagnostic separately
reports forks. Neither receipt establishes epoch support or completed migration.

A1 (proposed): one explicit cut-over per identified brain, with global audit
scope across its tenants. A2 (proposed): preserve the same database and existing
row identities rather than rebuild domain state in a new database. U1: authorized
signer fingerprint and key custody. U2: independently administered witness,
publication access, verification method and availability policy. U3: approval of
the epoch-qualified recovery contract. U4: complete inventory and quiescence of
all writers, including old binaries and direct administrative paths. None is
resolved by this document or by a successful signature using an arbitrary key.

## Proposed architecture and alternatives

The same `audit_events` table retains its exact historical prefix. A new boundary
event follows the actual last hashed row using the existing hash version and
write-order semantics. Its details bind a separately signed cut-over intent. A
new epoch verifier checks the sealed prefix, boundary and complete suffix;
canonical global verification remains available and retains its original result.
The epoch layer reuses the canonical full-chain verifier: every finding must
match the sealed prefix inventory exactly, and no finding may occur in the
suffix. Explicit checks also refuse any unverified suffix row. It introduces no
second hash walker and does not change the canonical serializers or classifier.

This is an explicit new acceptance contract requiring owner approval. It is not
an implementation technique for silently making today's strict verifier green.
Recovery would need a discriminated authorized-epoch result and a separately
reviewed adoption change; the [merged plugin source at `914cbd7`](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/914cbd7d84ff9098759f79a19c1222689cbcd9e6/src/recovery-audit.ts)
retains strict fork refusal. Plugin PR #94 merged as that exact commit; this is a
source-state claim, not a release, installed-version or deployment claim.

Alternatives considered: a fresh database and clean audit log would require a
new projection/import lineage, preservation of receipt references, all domain
tables and recovery store bindings. That expands the migration substantially.
An exception allowlist cannot represent forks under S2. Recomputing historical
hashes violates S1. Retaining the existing refusal remains the safe default until
all acceptance requirements below are implemented and approved.

Trust boundaries are the brain writer, owner authorization record, signing key,
and external witness. The database and local Git witness belong to the same
machine trust domain. The proposed external witness separately records signed
artifact digests. A signature authenticates a pinned signer; it does not prove
that historical content is true or that the machine was uncompromised.

## Requirements and artifact contract

All REQ records are P1, proposed, owned by the Registrar maintainer; Jeremy is
the acceptance authority. The table provides each record's rationale and test
mapping. No requirement is reported implemented.

| ID | Proposed requirement / rationale | Verification |
|---|---|---|
| REQ-01 | Preserve every historical row's raw stored fields, including `seq`, timestamp and nullable values, and preserve the original external anchor log and Git history. S1, S3. | TEST-01/02 |
| REQ-02 | Bind approval to one brain identity, source revision, exact ordered prefix digest and count, last sequence/head, exact anomaly denominator, original anchor digest/head, signer fingerprint, witness policy and intent digest. No date/range/count-only authority. S1, S2. | TEST-02/03 |
| REQ-03 | Verify a domain-separated Ed25519 signature against an independently approved key fingerprint. Reject embedded-key substitution, algorithm/version drift, duplicate fields and noncanonical encodings. S6. | TEST-03 |
| REQ-04 | Keep raw global verification false while old forks exist. Return separate legacy-preservation, boundary, current-epoch and witness results; never coerce these into generic `verified: true`. S2, S5. | TEST-04 |
| REQ-05 | Recompute the complete prefix and exact historical break set, then verify every suffix row from the boundary predecessor with canonical hash-version semantics. Refuse any new fork, tamper, null-hash row, unknown version, invalid/duplicate sequence or boundary splice. S4, S5. | TEST-02/04/05 |
| REQ-06 | Serialize boundary insertion under the shared recovery flock and SQLite writer transaction. A pending seal blocks ordinary writes and fresh recovery before each operation’s first durable database or filesystem effect across every supported writer. S4, U4. | TEST-06 |
| REQ-07 | Verify independently retrieved external witness evidence before activating the epoch. Local Git alone and a caller's URL or claimed commit do not satisfy it. S1, U2. | TEST-03/07 |
| REQ-08 | Make replay and crash recovery explicit, digest-bound and idempotent. Expose committed database truth separately from witness/epoch completion; never delete a committed boundary to pretend it did not happen. S1. | TEST-07/08 |
| REQ-09 | Prove the finite private recovery selection and exclusions plus all unrelated data denominators after epoch activation; migration approval remains separate. S3. | TEST-09 |

Proposed artifacts are strict schema-version-1 objects, with unknown properties
rejected. SHA-256 digests are lowercase 64-hex; Ed25519 public keys use SPKI DER
and signatures use their exact raw bytes, both represented as lowercase hex.
Canonical JSON uses fixed schema field order, UTF-8, no insignificant whitespace,
explicit nulls and safe nonnegative integer counts. Schema-specific serializers
are frozen and versioned. The implementation must publish canonical byte test
vectors before any signing is approved; it must not depend on object insertion
order supplied by a caller.

- `legacy-audit-prefix.jsonl`: one canonical raw-row record per positive unique
  `seq`, sorted ascending. Explicit fields are `id`, `action`, `memory_id`,
  `tenant_id`, `actor_json`, `reason`, `details_json`, `timestamp`, `entry_hash`,
  `prev_entry_hash`, `hash_version`, `seq`. JSON-bearing database fields remain
  their exact stored strings. Each record ends with one LF. Private content is
  retained privately; only its digest is suitable for public publication.
- `legacy-audit-breaks.jsonl`: exact canonical verifier break records, including
  row identity, sequence, reason, expected and actual hashes/links. This is a
  disclosure inventory, not an exception manifest. All entries must be forks;
  unexpected tamper or unverified rows block this proposed route. Canonical
  reason counts and both inventory digests are signed.
- `cutover-intent.json`: `schemaVersion`, `kind` (`legacy-audit-cutover-intent`),
  `brainId`, `epochId`, `issuedAt`, `expiresAt`, `sourceRevision`,
  `legacyPrefix` (digest, row count, last sequence, old head), `legacyBreaks`
  (digest and reason counts), `legacyAnchors` (sealed-prefix raw-byte digest and byte length, record count,
  anchor head and local Git evidence), `boundary` (reserved event ID, expected sequence,
  previous entry hash, tenant/actor and dated reason), `authorizationPolicyDigest`,
  `signerKeyFingerprint`, `witnessPolicyDigest`. Optionality is not implicit.
- `signed-intent.json`: intent digest, approved signer public key and signature
  over the UTF-8 domain prefix `bbb-audit-cutover-intent-v1\n` followed by the
  canonical intent bytes. The referenced authorization policy pins the permitted approver and signing
  authority; it contains no final intent digest and grants no application by
  itself. Possessing a private key is insufficient authority.
- `cutover-approval.json`: a distinct authenticated owner decision identifying
  the exact intent digest, authorization-policy digest, brain, environment,
  signer fingerprint, witness-policy digest, approval time and expiry. Its
  evidence must be independently bound to the owner, not self-asserted by the
  operator. The final approval digest is referenced only by the later boundary
  and seal; it is not inside the intent it approves.
- Boundary audit event: new schema-supported action, deterministic details
  containing epoch ID, intent digest, final approval digest, old head, cutoff
  sequence and signed issuance time. It uses ordinary canonical audit insertion;
  its predecessor is the old head. A schema migration/action addition is future
  implementation work, not supplied here.
- `boundary-row.json`: the complete committed raw boundary row, serialized
  exactly as a prefix row, including its timestamp and raw JSON strings. Its
  SHA-256 is bound in the seal. Check every field against the authorized intent
  or its explicitly defined derivation; v2 entry hashes exclude timestamp, so
  the event hash alone cannot seal the dated boundary.
- `epoch-seal.json`: intent digest, exact committed boundary ID/sequence/hash,
  complete raw-boundary-row digest,
  signed-intent artifact digest, final approval digest and original prefix/anchor digests, signed under
  a separate `bbb-audit-epoch-seal-v1\n` domain. Independent witness evidence binds
  this final seal digest to its configured external publication identity.

The old anchor digest covers exactly the sealed byte length ending at the
signed record boundary, not the entire subsequently growing active log. Every
verification checks those exact retained bytes and canonical validity of every
later appended anchor record, including the boundary and suffix heads. Retain
an independent original-log snapshot and its digest; require the active Git
witness to preserve the sealed commit ancestry. A legitimate later append must
not invalidate the baseline, while truncation, prefix rewrite, record splice or
replacement of history must refuse.

The intent does not include the future boundary hash. The boundary references
the intent and final approval digests; the later seal references all three. This avoids a circular hash
or signature dependency. No private key, bearer token, source body or implicit
origin-secret loader belongs in these public metadata artifacts.

## State transitions, commitment and rollback

| State | Allowed transition and evidence | Failure / recovery behavior |
|---|---|---|
| No epoch | Read-only preparation of exact prefix, anomaly inventory, intent and explicit approval. | Existing strict recovery continues refusing forks; preparation grants no writes. |
| Approved intent | Verify signer authority, authenticated final owner approval and expiry. Quiesce all writers; under flock plus immediate transaction, recompute all bindings and atomically insert the boundary with a pending-epoch record. | Any changed row/head/anchor, unexpected fork or competing boundary rolls back the transaction. No business recovery writes are included. |
| Boundary committed, seal pending | Read back exact boundary, create signed seal, publish externally outside the SQLite transaction, independently verify witness evidence. | Report `committed: true`, `epochActive: false`; all epoch-aware writers remain blocked. Resume only the same intent/boundary. |
| Active epoch | Under the same locks, reverify prefix, boundary, current suffix and witness binding; atomically record activation evidence. | Unsupported or older writers are not allowed to operate this brain. Any evidence failure refuses new recovery. |
| Recovery complete | Apply the separately reviewed, current-inode-bound recovery plan, then run strict epoch anchoring, export and actual index proof. | Postcommit maintenance failure retains commitment and requires explicit repair; an active epoch alone is not recovery completion. |

The pending-epoch guard must cover every durable writer, including API, cron,
MCP, maintenance, direct curator commands and repository-level append paths.
An old executable ignoring the guard is a deployment blocker; a local lock file
is not proof that all writers participate. No external network call occurs while
the database writer transaction is held. No external intent publication is required before boundary insertion. The
final seal is the externally witnessed artifact, and witness outage never
silently activates the epoch. Witness verification policy must define authenticated independent
retrieval and offline evidence freshness before implementation approval.

Before boundary commit, rollback means abandoning the intent and leaving data
unchanged. After commit, preserve the boundary and signed evidence; remain in
maintenance/read-only mode until resumed or an explicit abort event is designed
and approved. Do not delete, renumber or rewrite the boundary. A code rollback
must preserve the guard or keep all writers stopped: old strict recovery will
refuse the legacy chain. Restoring a pre-cut-over backup after any later writes
is a separate data-loss decision requiring owner authorization and a retained
copy of all later history. Nothing here authorizes a live restore or service stop.

## Verification plan and readiness evidence

Expected results below are proposed, not executed cut-over tests. The environment
is an isolated private copy with explicit source, signer and witness fixtures;
no test loads live keys, touches live state or publishes real external evidence.

| Test | Requirements / risk | Expected evidence |
|---|---|---|
| TEST-01 | REQ-01; historical evidence loss | Entire old prefix and original archive/log/Git bytes and row identities preserved; no UPDATE/DELETE/rehash path. |
| TEST-02 | REQ-01/02/05; baseline laundering | Row addition/deletion/reordering, any field change, tuple/head/count/break drift, changed old anchor or same count with different forks all refuse before activation; legitimate later anchor appends preserve the sealed prefix and pass canonical checks. |
| TEST-03 | REQ-02/03/07; forged authority | Invalid signature, wrong approved key, substituted embedded key, expired approval, cross-brain replay, altered witness target and local-only publication all refuse. |
| TEST-04 | REQ-04/05; false global green | Unchanged global verifier still reports all historical forks and false; qualified epoch output separately reports preserved legacy plus strictly verified current suffix. |
| TEST-05 | REQ-05; suffix amnesty | Added fork, hash rewrite, unknown hash version, duplicate/nonpositive sequence, null-hash row, timestamp-only boundary edit and missing/spliced boundary refuse; unapproved second cut-over refuses. |
| TEST-06 | REQ-06; interleaved writes | Competing SQLite writer, kernel-lock contender and every supported append entrypoint cannot interleave the boundary or write during pending seal; assert refusal before the first durable memory, candidate, spool, export or other filesystem effect, not merely at a later audit append. Old unsupported binaries fail rollout readiness. |
| TEST-07 | REQ-07/08; crash/witness outage | Crash at each transition, publication timeout, absent/stale witness and changed files leave truthful commitment, blocked activation and bounded idempotent resume; no network under transaction. |
| TEST-08 | REQ-08; destructive rollback | Replay adds no duplicate boundary; exact resume succeeds; different intent/brain/boundary refuses; rollback preserves committed evidence. |
| TEST-09 | REQ-09; unrelated state change | Actual private 67 selected + two excluded records; full source/target and unrelated inbox/quarantine/policy/spool/hold/receipt denominators; both DB integrity checks; strict exports, real indexes and restore proof. |

RISK-01 (evidence laundering), RISK-02 (key/witness substitution), RISK-03
(incomplete writer coverage) and RISK-04 (partial commit/rollback loss) have high
inherent impact. Proposed controls are REQ-01–09. Residual exposure remains
unaccepted and unmeasured until the mapped tests and independent review pass.
The Registrar maintainer owns remediation; Jeremy accepts any residual risk.
Review these risks before implementation approval and again before application.

## Decision and delivery boundary

ADR-036 is a proposal for one signed epoch boundary, with unchanged historical
rows and explicit qualified reporting. Its acceptance depends on resolving U1–U4.
The concrete owner decision will identify the approved intent digest, brain,
signer fingerprint, external witness, environment and rollback policy. Approval
of this documentation PR alone does not authorize signing, external publication,
private-copy cut-over, live migration, service changes or a release.

Bead `.9.3` tracks this design and independent review. Parent `.9` retains all
implementation, authorization and actual-copy success requirements. The next
implementation decomposition must cover canonical epoch artifacts/verifier,
transactional boundary plus all-writer guard, standalone verification, plugin
adoption, witness adapter, failure/rollback controls and actual private rehearsal.
Those remain future tracked work; no executable command is implied by the JSON
artifact names or state table above.
