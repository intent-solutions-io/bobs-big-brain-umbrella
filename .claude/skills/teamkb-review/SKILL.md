---
name: teamkb-review
description: |
  Nightly "review the team inbox." An agent reviewer for the QUARANTINED capture queue — the
  member-authored proposals the govern sweep holds back from auto-promotion (R8). It calls
  brain_inbox, judges each held candidate (promote / hold / reject) CONSERVATIVELY, and disposes it
  via brain_approve / brain_reject. The agent only RECOMMENDS; the deterministic pipeline OWNS the
  transition — brain_approve re-runs dedupe/policy/secret-scan server-side as a hard floor the agent
  cannot override, and every decision is a hash-chained receipt naming this agent as the actor
  (014-AT-DECR). Team mode only (talks to the governed brain API over the tailnet with a dedicated
  admin token). Side-effecting — invoke via the nightly cron wrapper after /teamkb-compile.
  Trigger with "/teamkb-review".
allowed-tools: 'Read, Bash(command:*), mcp__governed-brain__brain_inbox, mcp__governed-brain__brain_approve, mcp__governed-brain__brain_reject, mcp__governed-brain__brain_search, mcp__governed-brain__brain_status'
version: 1.0.0
author: Jeremy Longshore <jeremy@intentsolutions.io>
license: Proprietary
tags:
- brain
- governance
- capture
- review
- second-brain
argument-hint: '[--dry-run]'
model: opus
compatibility: 'Designed for Claude Code. Runs on the box that can reach the governed brain API over the tailnet. Requires the governed-brain MCP server in TEAM mode (bobs-big-brain-plugin) with a dedicated ADMIN token — the cron wrapper passes it via --mcp-config scripts/review-mcp-config.json and exports TEAMKB_REVIEW_AGENT_TOKEN + TEAMKB_API_URL. If the token is not provisioned the wrapper SKIPS this phase cleanly.'
disable-model-invocation: true
---
# teamkb-review

## Overview

A member's `brain_capture` proposal lands in the team brain **`quarantined`** — held back from
auto-promotion by the govern sweep (R8), awaiting review. Without a reviewer it rots *in quarantine*:
never re-read, no exit. This skill is that reviewer, **as an agent** (`014-AT-DECR`): it reads the
quarantined queue, judges each proposal, and disposes it — promote the clearly-useful, **hold** the
ambiguous for a human, reject the noise.

**The load-bearing rule — the agent RECOMMENDS, the deterministic system OWNS the write:**

- You (the agent) decide a *verdict*. You do **not** write durable memory.
- `brain_approve` performs the promotion **through the deterministic govern gate** — it re-runs
  dedupe · policy · secret/disclosure scan server-side as a **hard floor you cannot override**. If
  the rules refuse (a secret, a duplicate), the promotion does not happen and you get a 422. You
  **cannot launder** anything past the rules.
- Every decision (approve *and* reject) writes a **hash-chained receipt naming this agent** as the
  actor + your reason. A human reviews these in aggregate via the nightly digest and can retire any
  promotion with `brain_transition`.

This is the frontier principle: *Claude does the judgment; deterministic code builds the courthouse.*

## Modes

`$ARGUMENTS`:
- *(none)* — **live**: judge each quarantined candidate and dispose it (`brain_approve`/`brain_reject`).
- `--dry-run` — judge and PRINT the verdicts, make **no** `brain_approve`/`brain_reject` calls. For
  soak/inspection.

## Prerequisites

- **Team mode with an ADMIN token.** The cron wrapper passes `scripts/review-mcp-config.json` (boots
  the plugin in team mode) and exports `TEAMKB_API_URL` + `TEAMKB_REVIEW_AGENT_TOKEN` (a dedicated
  `teamkb-review-agent` admin token, minted + scrypt-hashed like every other team token — see
  *Provisioning* below). If the token is absent, the wrapper skips this phase; run standalone only
  when the env is set.

### Authentication

The existing team-mode MCP configuration maps `TEAMKB_REVIEW_AGENT_TOKEN` to the
client's API token. Use the dedicated provisioned actor and the configured API
URL; do not print its value or substitute another administrator's token. Missing
authentication is a missing prerequisite, not an empty inbox. See Provisioning
for the existing activation process; editing or validating this skill does not
activate it.

## Instructions

**Phase markers (for cron diagnosability)** — emit one Bash echo before each phase:
`echo "[phase: <name>] <one-line context>"`. Names in order: `setup`, `inbox`, `review`, `summary`.

### Phase 0 — Setup

Emit `[phase: setup] ...`. Resolve the mode (`--dry-run` present or not). Call **`brain_status`** to
confirm you are in **team** mode, reachable, with a token set (`{ mode:'team', healthy:true,
tokenSet:true }`). If not team mode or unhealthy, STOP and report — do not fabricate.

### Phase 1 — Read the quarantined queue

Emit `[phase: inbox] ...`. Call **`brain_inbox`** `{ limit: 100 }`. It returns the quarantined
member proposals `{ id, title, category, author, capturedAt }`. If the queue is **empty**, that is
the common, correct outcome — emit a "0 to review" summary and stop (no writes).

### Phase 2 — Judge each candidate (CONSERVATIVE by construction)

Emit `[phase: review] ...`. For each candidate, first do **search-before-approve**: call
**`brain_search`** `{ query: "<title> <key terms>", scope: "all" }` to see what the brain already
knows. Then assign one verdict:

| Verdict | When | Action |
|---|---|---|
| **promote** | High-confidence, clearly-useful, transferable, **non-sensitive**, not already covered. A teammate finds it useful in 30 days with zero context. | `brain_approve { candidateId, reason }` |
| **hold** | Ambiguous, borderline, half-baked, possibly-sensitive, needs a human eye, or you are unsure. **Default here when in doubt.** | *do nothing* — it stays quarantined for a human |
| **reject** | Clear noise: duplicate of existing memory, ephemeral status/chatter, test/scratch content, obviously not durable. | `brain_reject { candidateId, reason }` |

**Hard rules:**
- **When unsure, HOLD.** Promotion is reserved for the clearly-useful; holding costs nothing (a human
  sees it in the digest). Over-promoting is the failure mode to avoid.
- **Never try to promote something sensitive** — if a candidate looks like it carries a secret,
  credential, PII, or private specifics, **reject** or **hold**, never approve. (The server's
  disclosure gate is a backstop, not your primary judgment — a refused approval means you misjudged.)
- **A 422 from `brain_approve` is the govern layer working** — the deterministic rules refused it
  (secret/duplicate). Record it as *held-by-the-rules*; do not retry or route around it.
- **`reason` is mandatory and lands on the audit chain** — write a specific one-line justification
  (why promote / why reject), not "looks good."
- One verdict per candidate. Process every candidate in the queue.

### Phase 3 — Summary

Emit `[phase: summary] ...`. Print a compact summary for the cron wrapper to fold into the digest:
`reviewed N · promoted P · held H · rejected R · refused-by-rules X`, then a one-line-per-decision
list (`<verdict> — <title> — <reason>`). In `--dry-run`, print the would-be verdicts and note **no
writes were made**.

## Output

| Artifact | Location |
|---|---|
| Per-decision receipts (approve/reject) | the governed brain's audit chain (actor = `teamkb-review-agent`) |
| Promoted memories | the governed brain (`brain_approve`; cited `qmd://…` next day) |
| Review summary (stdout) | captured by the cron wrapper → the nightly digest/email |

## Examples

These are invocation examples, not run receipts.

- `/teamkb-review --dry-run`: inspect the quarantined queue, search for existing
  coverage and print proposed promote/hold/reject decisions. Do not call approve
  or reject; report that no disposition requests were made.
- Expected outcome for an authenticated empty inbox: a zero-review summary with no writes.
  A failed inbox request must not be reported as an empty queue.
- Expected behavior during an explicitly authorized live invocation: a candidate with uncertain
  sensitivity stays held. A deterministic approval refusal is recorded as a
  refusal, not counted as a promotion.

## Error Handling

| Situation | Response |
|---|---|
| Missing token, authentication failure, wrong mode or unhealthy status | Stop and report the missing prerequisite; do not substitute credentials. |
| Inbox or search request fails | Report incomplete review; never invent candidates or treat failure as no results. |
| Approval is refused by deterministic rules | Keep the refusal in the summary; do not bypass it or retry through another tool. |
| A write request times out or its outcome is ambiguous | Do not blindly repeat it. Report the uncertain result and inspect authoritative state before any retry. |
| Only part of the queue was processed | Report confirmed outcomes and the unprocessed remainder; do not claim full review. |
| Candidate may contain sensitive content | Hold or reject; never promote merely to test the server's disclosure gate. |

## Guardrails

- You **recommend**; the deterministic pipeline **owns** the durable write. Never treat a verdict as
  a write.
- **Conservative default is HOLD.** A small, honest set of promotions beats an eager one.
- Never approve sensitive content; a server 422 means you misjudged — hold it.
- Every approve/reject carries a specific `reason` (it is recorded in the audit receipt).

## Provisioning (one-time, per environment — the activation gate)

The review agent runs under a **dedicated `teamkb-review-agent` admin token** so its decisions are a
distinct, filterable actor on the audit chain. It is **not** provisioned by default — the nightly
wrapper skips this phase until it is, which is the deliberate activation gate.

Before provisioning on the box that owns `~/.teamkb`, keep scheduled review
launchers disabled and wait for any existing review to finish. These are operator
instructions; this source change adds no automatic activation gate. The wrapper's
token-file presence check alone is not acceptance evidence.

For a separately authorized activation:

1. Mint a token value (any high-entropy string) and add a **scrypt-hashed** admin record for actor
   `teamkb-review-agent` to the brain's token registry (`~/.teamkb/tokens.json`) — the same
   `scrypt$salt$hash` format the other team tokens use — then redeploy/reload the API so it loads the
   new record.
2. Store the **plaintext** token value in `~/.teamkb/.review-agent-token` (mode `600`). The wrapper
   reads it into `TEAMKB_REVIEW_AGENT_TOKEN`.
3. **Basic wiring/connectivity check:** with the provisioned `TEAMKB_API_URL`
   and `TEAMKB_REVIEW_AGENT_TOKEN` already set without printing their values,
   run the requested dry-run with the reviewed MCP configuration. `brain_status`
   should report team mode, token presence and service health. Its health request
   is authentication-free: this does **not** validate the token, dedicated actor
   identity, or administrative authority.
4. Before enabling scheduled review, obtain separately authorized acceptance
   evidence for the dedicated actor: an authenticated inbox read and approve/reject
   checks against operator-owned fixture candidates, with resulting audit receipts
   bound to `teamkb-review-agent`. Include refusal checks for an invalid token and
   a non-admin actor. Verify identity against the authoritative server token/actor
   records without publishing token values. Do not use unrelated queued team
   proposals as activation fixtures. Decision014's audited-actor and deterministic
   refusal requirements still apply.
5. Keep review launchers disabled if actor binding, authenticated reads, fixture
   write authority or receipts are unverified. Only enable them after that evidence
   has been reviewed under the existing activation authority.

The wrapper skips review when the token file is absent. A present file can enable
its review phase, so keep launchers disabled throughout preparation and failed
verification. These instructions do not claim the wrapper enforces all acceptance
steps automatically, or that any environment has passed them.

## Related

- `/teamkb-compile` — the nightly compile this runs after (compiles *my* day; this reviews *the
  team's* proposals).
- `brain_inbox` / `brain_approve` / `brain_reject` (governed-second-brain plugin, team mode) — the
  admin tools this skill drives.
- `000-docs/014-AT-DECR` (umbrella) — the decision record this skill implements.
