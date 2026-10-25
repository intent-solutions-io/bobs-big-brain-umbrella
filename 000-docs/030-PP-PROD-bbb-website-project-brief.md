---
blueprint:
  documentId: DOC-BBB-WEBSITE.PROJECT-BRIEF
  documentType: project-brief
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-25'
  sourceRefs: [029-PP-PROD-bbb-product-record.md, intent-solutions-landing 000-docs/084-AT-DSGN-brand-family-contract.md]
  relatedArtifacts: [029, 031, 032, 033, 034, 035]
  humanReview: {required: true, status: not-started}
---

# Project brief: the Bob's Big Brain website

## Objective

**OBJ-1.** Publish Bob's Big Brain as a product site at `https://intentsolutions.io/bbb/`, inside the
Intent Solutions master brand, so a Claude Code builder understands what it is, trusts how it
works, installs local mode, and a team lead can ask for a governed team brain. [provided, owner 2026-10-25]

**OBJ-2.** Every claim on the site is backed by code at a named commit or by the dated clean-room
run; every known limit is named on the site. [provided, owner: "code being the source of truth"]

## Scope

| In | Out |
|---|---|
| Five routes under `/bbb/` (overview, how it works, receipts, install, status) on the landing Astro site | The WordPress site at `bobsbigbrain.com` (no estate ownership evidence; not touched) |
| A beta tag and a status page listing what is proven and what is not | Team onboarding details (API address, tenant, token issuer) |
| Replacing the landing catalog link (`public-experiences.mjs`) with `/bbb/` | Changes to the plugin or engines (tracked separately in compile-then-govern-eqw) |
| Route contract, sitemap and indexability registration | Paid acquisition, analytics dashboards |

The legacy `demos.intentsolutions.io/bbb/` page stays reachable until a separate change retires it;
it exposes the team API tailnet address and must be cleaned (consistency audit, web slice).

## Audience and actions

- Primary: Claude Code builders → **Install local mode** (primary action).
- Secondary: team leads → **Request a team brain** (`/contact/?door=outcome`).
[provided, owner 2026-10-25: "1 and 2"]

## Constraints

- **Brand:** contract 084 (Syne display, Inter body, charcoal, orange signal); polished casual voice; "beta, under development" on every page. [provided]
- **Honesty:** tamper-evident wording only; the umbrella forbidden-word lint applies to every page. [verified]
- **Code truth:** facts carry a verified-at date and a source; volatile facts (versions) live in one data module. [derived from OBJ-2]
- **Design process:** Hallmark floor and sweep, Impeccable craft floor, detector and finish review, frontend-design self-critique. The owner delegates taste decisions. [provided]
- **Ship gate:** the site claims only what passed the 2026-10-25 proof pass (umbrella issue #122). [provided, owner: "prove it, then build"]
- **Accessibility:** WCAG 2.2 AA. [Blueprint quality contract]

## Decision authority

Owner: Jeremy Longshore (approves claims and publication). Design direction: delegated to Claude,
recorded in 034. Deploy: landing `main` → `deploy-vps.yml` after required checks and `safe-merge`.

## Delivery stage

Draft. Evidence gathered; build in progress on landing branch `feat/bbb-product-page`.

## Unknowns

- **UNK-1:** Whether the demos page should redirect to `/bbb/` once live (owner decision after launch).
- **UNK-2:** Release version the install instructions should pin to after compile-then-govern-eqw.5.

## Next human approval

Owner review of the claims register (031) and the live preview before merge.
