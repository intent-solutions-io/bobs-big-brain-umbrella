---
blueprint:
  documentId: DOC-BBB-WEBSITE.FRONTEND-SPEC
  documentType: frontend-specification
  templateVersion: 3.0.0
  schemaVersion: 1.0.0
  status: draft
  classification: public
  owner: Jeremy Longshore
  reviewers: [Jeremy Longshore]
  updatedAt: '2026-10-25'
  sourceRefs: [029, 030, 031, 032, 033, intent-solutions-landing 000-docs/084 and 085, astro-site/src/data/site-map.mjs]
  relatedArtifacts: [035]
  humanReview: {required: true, status: not-started}
---

# Frontend specification: the Bob's Big Brain website

## Platform and stack

- Landing repository `intent-solutions-io/intent-solutions-landing`, `astro-site/` (Astro 5, static
  output, Caddy `file_server` on the VPS). [verified: landing CLAUDE.md]
- Shared chrome: `Layout.astro`, `SiteNav.astro`, `Footer.tsx`, tokens in `src/styles/global.css`.
- New: `src/pages/bbb/{index,how-it-works,receipts,install,status}.astro`, a `BbbFrame.astro`
  wrapper (product bar + beta tag), `src/styles/bbb.css`, and `src/data/bbb.mjs` (REQ-07).
- No client framework. Two inline scripts: copy-to-clipboard and the receipt-chain demonstration
  (Web Crypto `SHA-256`). Content renders without JavaScript.

## Site map

| Route | Mode | Visitor question | Primary next step | Index |
|---|---|---|---|---|
| `/bbb/` | Persuade | What is it, and why should I trust it? | `/bbb/install/` | yes |
| `/bbb/how-it-works/` | Read | What runs where, and what leaves my machine? | `/bbb/install/` | yes |
| `/bbb/receipts/` | Read | What does a receipt prove, and how do I check it? | `/bbb/status/` | yes |
| `/bbb/install/` | Operate | How do I get it running in Claude Code? | first `/brain-save` | yes |
| `/bbb/status/` | Read | What works today, what doesn't, checked when? | `/bbb/install/` or `/contact/?door=outcome` | yes |

Product bar (under the master nav, every route): product name, "Beta" tag linking to
`/bbb/status/`, links Overview, How it works, Receipts, Install, Status; current page by text weight
and `aria-current`, never colour alone (contract 084). Route contract entries are added to
`site-map.mjs`; the catalog entry `bobs-big-brain` in `public-experiences.mjs` points to `/bbb/`.

## Page anatomy

**`/bbb/` (overview)**: 1 hero (head, one sentence, Install local mode / Request a team brain;
the four-layer index beside it) · 2 a real cited answer, captured 2026-10-25 · 3 the receipt chain
demonstration · 4 two modes, local and team · 5 what beta means (four limits, link to status) ·
6 the source table (four repositories + qmd, licences) · 7 closing band with both actions.

**`/bbb/how-it-works/`**: pipeline diagram of the real system with a textual inventory; one section
per layer (compile, govern, retrieve, package); "what leaves your machine" table; team permission table.

**`/bbb/receipts/`**: one receipt's fields; the two chains (compile trace, governance chain) and their
verifiers; the anchor log; verify-it-yourself commands; "what a receipt does not prove".

**`/bbb/install/`**: requirements; the local install prompt (copy); manual commands; first run
(a 25+ character save, then keyword search); the standing-order snippet (copy); troubleshooting;
team mode needs and the request path.

**`/bbb/status/`**: the beta statement; what the clean-room run proved (dated); known limits with
tracking links; versions and source commits with the verified-at date.

## Components and states

| Component | States |
|---|---|
| Copy button | rest, hover, focus-visible, active, copied (text "Copied" for 2 s, `aria-live`), failed (selects the text, says "Press Ctrl+C") |
| Receipt chain demo | intact, edited (row marked changed), verify-failed (first broken link named), re-hashed (chain passes), anchor-caught (anchor mismatch named), reset; no-JS: static explanation; reduced motion: no transitions |
| Product bar | default, current page, narrow (links scroll horizontally; no wrap) |
| Install switcher (local / team) | local selected (default, no-JS visible), team selected |

## Data, security, privacy

No forms on these routes (the team request uses the existing contact form). No team API address,
tenant id or operator name anywhere (REQ-04). The real cited answer is trimmed to a public-safe
excerpt of the public thesis. The demo hashes illustrative records in the browser only.

## Accessibility

WCAG 2.2 AA: semantic landmarks, one `h1` per route, heading levels in order, visible focus at 3:1,
44 px targets, `prefers-reduced-motion` honoured, demo controls are real buttons with live-region
results, colour never the only signal (states carry words).

## Direction contract

THESIS: The overview opens on the machine itself, an honest index of compile, govern, retrieve and
package, refusing the category default of a memory-brain hero illustration with three feature tiles.

OWN-WORLD: Intent master brand held fixed: charcoal ink (`--intent-ink`), raised panels, Syne
display, Inter body, one orange signal on the primary action and focus; hashes, `qmd://` citations
and commands set in mono because they are code; hairline rules carry structure.

STORY: A builder sees what each layer does, reads a real cited answer, breaks a receipt chain with
their own hands and watches it get caught, learns the limits in plain words, then installs local
mode; a team lead takes the team request.

FIRST VIEWPORT: Product bar with the beta tag; on columns 1–5 the head "Your agent, with receipts.",
one sentence and the two actions; on columns 7–12 a four-row ordered index of the layers, each row
a verb-led line and a link, set large with hairline separators; the chain demonstration starts below
the fold.

FORM: Index of layers, position 6 on the ranked list of seven grounded structures, dealt as the lead
by Impeccable concept-seed key `a7c59586` (mode persuade, surface scope); locked 2026-10-25.

AMENDMENT (2026-10-25, after the fresh-context Hallmark hero review returned `fix`): the first-viewport
index reads Govern, Retrieve, Verify, Package, and each row carries a real proof line (a receipt hash
link and an audit-verify result from the clean-room install, a `qmd://` citation from the owner's
brain, the plugin id). The citation is the index's single accent. Compile moved to How it works so the
index does not open on a hedge.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Traceability

| From | Relationship | To |
|---|---|---|
| REQ-01, REQ-10 | implemented-by | site map and route contract |
| REQ-02 | implemented-by | product bar |
| REQ-03, REQ-04 | implemented-by | `/bbb/install/` |
| REQ-06, REQ-07 | implemented-by | `/bbb/status/`, `src/data/bbb.mjs` |
| REQ-08 | implemented-by | `/bbb/receipts/` |
| REQ-09 | implemented-by | receipt chain demo |
| REQ-11, REQ-12 | verified-by | 035 acceptance criteria |
