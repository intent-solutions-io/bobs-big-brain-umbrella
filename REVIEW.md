# REVIEW.md

Repository-specific guidance for the advisory MiniMax pull-request reviewer.

This is the **Bob's Big Brain umbrella / landing repo** — a **docs-only** brand surface. The README
is the product page; the rest is 000-docs records, governance files, `assets/`, [`repos.yml`](repos.yml),
and `bin/` helpers. **No application code lives here** — code, tests, and features belong in the
flagship engines (ICO, INTKB) and the plugin repo. So the reviewer's job is not defect-hunting in a
codebase; it is guarding **honesty, thesis fidelity, and map accuracy** on a brand surface. Report only
findings introduced by the pull request and verify each against surrounding source.

## Review objective

Review for four things, in priority order: (1) the **honesty invariant** — no brand claim the trust
model forbids; (2) **thesis fidelity** — the "compile, then govern" framing stays precise, neither
softened nor over-claimed; (3) **map/state accuracy** — docs match the code-verified system map; (4)
**disclosure safety** — no secret in the diff. Plus the **scope boundary**: this repo takes only
ecosystem-level doc fixes.

## Authority and truth hierarchy

Read this repo's [`CLAUDE.md`](CLAUDE.md) and [`AGENTS.md`](AGENTS.md) first. The grounded, code-verified
authorities are [`000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md`](000-docs/005-AT-ARCH-grounded-system-map-and-backup-scope.md)
(where the state lives), [`000-docs/007-AT-SMAP-repo-topology-and-working-surface.md`](000-docs/007-AT-SMAP-repo-topology-and-working-surface.md)
(which repos exist), and [`repos.yml`](repos.yml) (the machine-readable topology). The forbidden-words
discipline is recorded in the honesty-lint header and the README trust-model box.

1. Explicit owner decisions and ratified decision records govern intended architecture and messaging.
2. The code-verified maps (005-AT-ARCH, 007-AT-SMAP, repos.yml) decide what the system actually is;
   a doc claim that contradicts them is drift, not a new fact.
3. The real flagship repo tags decide version/status; this repo's status table is a mirror of them,
   never the source — a version here that outruns the flagship release is wrong.
4. Historical records describe what was known then. Require a dated correction or a successor doc
   instead of rewriting them to fit today's narrative.
5. Green CI proves only the checks that ran (the forbidden-words lint, markdownlint, link check) —
   not that a status, version, or architectural claim in prose is true.

Flag silent boundary changes, a second source of truth, or a proposal presented as settled authority.

## The honesty invariant — highest-risk boundary

This is the differentiator of the whole brand, and it is CI-enforced by
[`scripts/lint-forbidden-words.sh`](scripts/lint-forbidden-words.sh) via `.github/workflows/docs-honesty.yml`.
The receipt chain is **tamper-EVIDENT** (integrity + ordering + rewrite-detection), and the README
carries an honest "what the receipt does *not* do" trust-model box. A brand surface must never *assert*
the words the trust model forbids.

- **Forbidden words (never claim these): tamper-proof, immutable, non-repudiation (for local mode),
  blockchain.** They may appear only when negated or discussed *as* forbidden.
  The honest disclaimer form ("not tamper-proof") is fine; the correct positive term is tamper-EVIDENT.
- Do not duplicate the mechanical lint — it already catches the literal words. Your added value is the
  **synonym or paraphrase the regex cannot see**: "cannot be altered", "permanent record",
  "cryptographically unchangeable", "provably un-forgeable", "irrefutable proof of authorship". Flag
  those.
- A bare "append-only" or "ordered log" claim must carry an honest qualifier (by protocol /
  hash-chained / tamper-evident / disclosed same-timestamp forks); flag one that does not.
- Flag **over-claims about recall or AI-memory sophistication** — the competitive axis is govern plus
  receipts, never better recall. Marketing that reframes the product as smarter memory misses the thesis.

## Thesis fidelity

The pitch rests on one constraint: **the model proposes; the deterministic system owns durable state
and control.** Preserve its precision.

- **Compile, don't index** — ICO *derives* knowledge and keeps raw and derived strictly separate with
  provenance. Flag edits that blur that separation.
- **Govern by code, not by model** — dedupe, policy, secret-detection, trust levels, and promotion are
  deterministic in INTKB's kernel; the model never writes durable state directly.
- **Receipts are the wedge** — a hash-chained, tamper-evident audit trail plus `qmd://` citations.
- Flag edits that soften "deterministic", "append-only", or "hash-chained" into vague memory-marketing,
  AND edits that overclaim beyond what the ICO/INTKB engines actually do. Both directions are drift.

## Map and state accuracy

005-AT-ARCH, 007-AT-SMAP, and repos.yml are the grounded system map. Flag any claim that contradicts
their code-verified facts:

- The live brain is **ONE directory, `~/.teamkb`**, on the dev box; the production VPS holds no brain.
  Flag a doc that misstates where data lives or what is source-of-truth vs derived.
- The **team bridge is the authenticated INTKB HTTP API** (tailnet-bound, per-user tokens) — **not**
  Cloudflare R2. R2 is **backup-only** (encrypted blobs). Flag the R2-is-the-bridge confusion.
- The 5-repo / 2-org topology and the local-dir==remote-name mapping are fixed in repos.yml; flag a doc
  that renames, re-orgs, or re-points a repo inconsistently with it.
- Flag a version or status in this repo's status table that drifts from the actual flagship release tags.

## Disclosure and secret safety

Treat any leaked secret as this repo's other critical boundary.

- Never permit a credential, token, API key, personal compensation figure, or plaintext secret in the
  diff. Client and revenue amounts are allowed; personal pay is not.
- Never reproduce a suspected secret in a review comment — identify only its location and the required
  remediation (remove, rotate, move to SOPS).

## Scope boundary — docs only

This repo is the map, not the territory. Per `CONTRIBUTING.md`, only ecosystem-level doc fixes (this
README, the dependency map, the status table, the diagrams, 000-docs records) belong here.

- Flag a PR trying to add **application code, tests, or product features** here — they belong in the
  flagship engine repos or the plugin repo. The `bin/` scripts are orchestration/mapping over the
  sub-repos, not product code; net-new product logic is out of scope.
- Assets are committed binaries/SVG; the SVG is the source of truth and the PNG is a regenerated 2x
  raster. Flag a hand-edited PNG that diverges from its SVG, or an asset change with no rationale.

## Severity calibration

- **Critical:** a forbidden claim-word (literal or synonym) asserted on a brand surface that would slip
  past the mechanical lint; a leaked secret; a status/version claim that materially misrepresents what
  the engines ship; a map claim that inverts a code-verified fact (e.g. R2 as the bridge); application
  code added to this docs-only repo.
- **Warning:** a softened-thesis edit; a bare append-only/ordered-log claim not carrying its hash-chained qualifier; a
  version-table drift from the flagship tags; an over-claim about recall; a doc contradicting 005/007
  without a dated correction; a missing rationale on an asset or structural change.
- **Info:** a concrete accuracy or clarity improvement with real future cost. Use sparingly, never for
  personal preference.

Do not flag formatting-only differences or failures already enforced and reported by tooling
(forbidden-words lint, markdownlint, link check). Severity follows credible impact on honesty and
accuracy, not file importance. Docs-only does not mean low risk — on a brand surface a dishonest or
inaccurate claim is the highest-cost defect there is.

## Comments and summary

Comment on an exact changed line only when actionable. Inspect enough context to prove the issue; do not
post speculative or duplicate findings. Explain the impact and the smallest safe correction — usually the
honest rewording. On a re-review after new pushes the bar does not rise (anti-ratchet): drop findings the
update resolved and do not invent new objections on lines you previously accepted. If no actionable
finding remains and the change is accurate and honest, respond with `lgtm` and nothing else. Both lanes
are **advisory only** and never block a merge.
