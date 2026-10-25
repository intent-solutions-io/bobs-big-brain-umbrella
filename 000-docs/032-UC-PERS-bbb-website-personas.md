---
blueprint:
  documentId: DOC-BBB-WEBSITE.PERSONAS
  documentType: personas
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-25'
  sourceRefs: [029-PP-PROD-bbb-product-record.md, 030-PP-PROD-bbb-website-project-brief.md]
  assumptions: [Personas are derived from the owner's audience statement and the product's install path; no interview research was performed.]
  relatedArtifacts: [033, 034]
  humanReview: {required: true, status: not-started}
---

# Personas: the Bob's Big Brain website

Evidence state: **derived** from the owner's audience decision (2026-10-25) and the product's real
requirements. No user interviews exist; these personas must not be cited as research.

## PER-1 · The Claude Code builder (primary)

- **Situation:** works in Claude Code or Cowork daily; has a growing pile of decisions, runbooks and
  conventions that the agent keeps re-deriving or contradicting.
- **Job:** "Make my agent answer from what I already decided, and show me where it got it."
- **Evaluates by:** reading the install steps, the tool list and the source before installing;
  distrusts marketing claims; looks for the catch.
- **Needs from the site:** a one-paste install; exact requirements (Node, npm, optional qmd); what
  leaves the machine; a straight answer on what a receipt proves.
- **Would leave if:** the page reads like generic "AI memory", hides requirements, or claims more
  than the code does.
- **Success:** installs local mode, saves a fact, gets it back with a `qmd://` citation.

## PER-2 · The team lead (secondary)

- **Situation:** runs a small engineering or operations team using Claude; knowledge is scattered and
  teammates' agents disagree.
- **Job:** "Give my team one governed brain where saves are reviewed and nothing is quietly rewritten."
- **Evaluates by:** governance model (who can write, who approves), auditability, where data lives.
- **Needs from the site:** a clear description of team mode and its permission model, an honest beta
  status, a way to ask for help setting it up.
- **Success:** submits a team-brain request through the contact form.

## PER-3 · The skeptical evaluator (influencer)

- **Situation:** security-minded engineer asked to vet the tool for PER-1 or PER-2.
- **Needs from the site:** the trust model in tiered language, the verification commands, the
  limits list, licenses and repositories.
- **Success:** reproduces a verification and finds the site's claims match the code.
