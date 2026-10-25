---
blueprint:
  documentId: DOC-BBB-WEBSITE.USER-JOURNEYS
  documentType: user-journeys
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-25'
  sourceRefs: [032-UC-PERS-bbb-website-personas.md, 031-PP-PROD-bbb-website-prd.md]
  relatedArtifacts: [034, 035]
  humanReview: {required: true, status: not-started}
---

# User journeys: the Bob's Big Brain website

Each step names the route and the requirement it exercises. Evidence state: **derived**.

## JRN-1 · Builder installs local mode (PER-1)

| Step | Route | What the visitor does | Requirement |
|---|---|---|---|
| 1 | `/bbb/` | Reads the head and the four-layer index; understands compile, govern, retrieve, package. | REQ-01, REQ-05 |
| 2 | `/bbb/` | Sees a real cited answer and plays with the receipt chain. | REQ-09 |
| 3 | `/bbb/install/` | Checks requirements, copies the local install prompt, pastes it into Claude. | REQ-03 |
| 4 | Claude Code | Restarts, runs `/brain-save` with a fact of 25+ characters, then `/brain` with keywords. | REQ-03 |
| 5 | `/bbb/status/` | Checks what is proven and what is not before relying on it. | REQ-06 |

Failure points the site must pre-empt: missing Node/npm (stated on install); a too-short first save
being rejected (example save is 25+ characters); full-sentence queries (guidance says keywords).

## JRN-2 · Team lead asks for a team brain (PER-2)

| Step | Route | What the visitor does | Requirement |
|---|---|---|---|
| 1 | `/bbb/` | Reads the two-modes section. | REQ-05 |
| 2 | `/bbb/how-it-works/` | Reads the team permission model (members propose, admins approve). | CLM-08 |
| 3 | `/bbb/status/` | Reads the beta limits. | REQ-06 |
| 4 | `/contact/?door=outcome` | Requests a team brain. | REQ-04 |

## JRN-3 · Evaluator verifies the claims (PER-3)

| Step | Route | What the visitor does | Requirement |
|---|---|---|---|
| 1 | `/bbb/receipts/` | Reads what a receipt proves and does not prove. | REQ-08 |
| 2 | `/bbb/receipts/` | Runs the verification commands locally. | CLM-04 |
| 3 | `/bbb/status/` | Matches each claim to the commit it was checked at; follows tracking links. | REQ-06, REQ-07 |
