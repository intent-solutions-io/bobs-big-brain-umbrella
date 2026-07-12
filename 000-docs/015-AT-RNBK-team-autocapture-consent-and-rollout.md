# 015-AT-RNBK — Team auto-capture: consent, transparency & rollout (2026-07-11)

| | |
|---|---|
| **Audience** | The 6 team leaders who read/feed the one governed brain (Ezekiel · Tim · Ope · Max · Pablo · Jeremy) |
| **Status** | Ready to socialize. Auto-capture ships **built, off, opt-in**; rollout is **gated on this doc + each person's explicit consent** — never a silent push. |
| **What this governs** | The auto-capture Stop hook (`governed-second-brain-plugin` `hooks/`, bead `compile-then-govern-jfv.7`). |
| **Decision it implements** | [`014-AT-DECR`](014-AT-DECR-agent-reviewed-capture-inbox-and-r8-evolution.md) (agent-reviewed capture) — the govern + receipts guarantee that makes auto-capture safe. |
| **Companion** | [`011-AT-RNBK`](011-AT-RNBK-teammate-brain-onboarding.md) (how you plug into the brain in the first place). |

> **The one-line pitch:** turn on auto-capture and the durable learnings from your
> daily Claude Code work flow into the team brain **by themselves** — no remembering to
> `/brain-save` — while every write still passes deterministic governance, gets reviewed,
> and leaves a receipt. **You stay in control: it's opt-in, transparent, and pausable.**

---

## 1. Why this exists (the honest version)

The brain is only as good as what reaches it. Today it stays current two ways: Jeremy's
nightly compile (his box only), and whoever remembers to `/brain-save`. That misses the
biggest source of team knowledge — **the decisions and gotchas that happen inside your
Claude Code sessions on your own machine.** Those never reach the brain unless you stop
and save them by hand, and nobody does that reliably.

Auto-capture closes that gap: when a session ends, a background job reads *that session's*
transcript, pulls out a handful of genuinely-durable learnings, and proposes them to the
brain. It is the automatic version of the `/brain-save` you'd do by hand — nothing more.

**We are asking, not telling.** This doc exists because rolling this out without you
understanding exactly what it does would be exactly the wrong way to build a *governed*,
*trustworthy* brain. So: here's precisely what it does, what it does **not** do, and how
you stay in control. Turn it on only when that sits right with you.

## 2. What it does — precisely

1. A Claude Code **Stop/SessionEnd hook** fires when one of your sessions ends.
2. It launches a **background** distiller (detached — it never blocks or slows your work)
   that reads **that session's transcript**.
3. The distiller extracts **at most 5** durable, transferable learnings — decisions made,
   patterns that emerged, gotchas worth not relearning, conventions adopted.
4. For each, it calls `brain_capture` → the learning lands in the team brain's **inbox**
   as a **proposal**.
5. Overnight, the deterministic govern pipeline + an agent reviewer decide what's actually
   kept ([`014-AT-DECR`](014-AT-DECR-agent-reviewed-capture-inbox-and-r8-evolution.md)),
   each with a hash-chained receipt.

That's the whole loop. It is `/brain-save`, on autopilot, for the durable stuff.

## 3. What it does **NOT** do — the guarantees

These are enforced by code, not by promise:

| Concern | The guarantee |
|---|---|
| "Does my whole transcript get uploaded?" | **No.** Your raw transcript never leaves your machine. Only the distilled learnings the model judges durable are sent. |
| "Will it capture my secrets / API keys / PII?" | **No.** The distiller is instructed to strip them, **and** the server's deterministic disclosure gate blocks any secret/PII/credential as a hard backstop — a capture carrying one is refused, not stored. |
| "Can it write straight into the brain?" | **No.** Your token is a **member** token: it can only *propose*. Every proposal lands **quarantined** and is governed + agent-reviewed before anything becomes durable memory — with a receipt naming who/what decided. |
| "Will it slow down or break my session?" | **No.** The distiller runs **detached in the background**; the hook itself does nothing but launch it and exit. Any error goes to a local log, never your terminal. |
| "Does it run all the time / on my personal stuff?" | Only in **team mode** (your `TEAMKB_API_URL` + token set), only after **you** enabled it, and you can pause it in one command. |
| "Is it on the moment I install the plugin?" | **No.** It is **not** a plugin hook — installing the plugin does nothing. It runs only after you deliberately run the enable script and consent. |

## 4. You stay in control

> Run these from the **plugin's directory** — where the `governed-second-brain-plugin`
> is checked out / installed (the `hooks/` folder lives there) — or give the full path
> to `hooks/enable-autocapture.mjs`. It edits only your own `~/.claude/settings.json`.

```bash
# Enable — prints the full disclosure, then asks you to type  I CONSENT
node hooks/enable-autocapture.mjs

# Is it on? where are the logs?
node hooks/enable-autocapture.mjs --status

# Pause it (removes the hook + the opt-in marker)
node hooks/enable-autocapture.mjs --off

# Pause AND delete the local per-session logs
node hooks/enable-autocapture.mjs --off --purge
```

- **See what ran:** `~/.teamkb/autocapture-logs/` (one log per session).
- **See what was proposed:** it's in the team inbox — ask Jeremy (the admin reviews it),
  and your proposals are tagged to your token.
- **Regret a proposal?** Ask the admin to reject it — nothing is destroyed, it's a marker;
  and nothing durable was written without review anyway.

Enabling edits only **your own** `~/.claude/settings.json` (a backup is written first) and
drops a marker at `~/.teamkb/autocapture.enabled`. It never touches the brain.

## 5. The trade-off, stated plainly

Auto-capture runs a short **headless Claude distiller per session on your plan** — that's
a real (small) token cost, and it's why it's opt-in rather than on-by-default. In return
you never have to remember to `/brain-save`, and the team brain gets materially richer.
If the cost or the noise isn't worth it for how you work, **don't turn it on** — the
brain still works, and you can `/brain-save` by hand anytime.

## 6. Rollout sequence (how we actually turn this on)

This is **change management, not a deploy**. The order matters:

1. **Merge + deploy the code** (the Track 1–4 PRs): the review agent, the hardened
   capture path (idempotency + durable outbox), and the hook itself — all landed and
   green, but the hook **off** everywhere.
2. **Share this doc** with the six of us. Everyone reads §2–§4. Questions get answered
   *before* anyone enables anything.
3. **Opt in individually, when ready.** Each person runs `enable-autocapture.mjs`, reads
   the disclosure, and consents — or doesn't. No pressure, no default-on, no "we flipped
   it for you."
4. **Watch it for a few days.** The nightly digest surfaces the review-agent's decisions
   (promoted / held / rejected) so we can see it's behaving before anyone leans on it.
   Jeremy spot-checks; anyone can pause instantly.
5. **Iterate.** If the distiller is too eager or too quiet, we tune the prompt — the
   governance + receipts don't change, so tuning is cheap and safe.

There is no step where auto-capture turns on without the person it runs for having read
this and said yes.

## 7. FAQ

- **"Can Jeremy see my transcripts?"** No. He sees the *proposals* that reach the inbox
  (the distilled learnings), the same as if you'd `/brain-save`d them — never the raw
  session. Claude Code transcripts are local-only by design.
- **"What if the network's down when my session ends?"** The proposal is queued to a
  durable outbox and sent on the next successful capture — it's neither lost nor
  duplicated (Track 2 / `jfv.9`).
- **"Can I try it on one session and then decide?"** Yes — enable, work a session, run
  `--status` and read the log, then `--off` if it's not for you.
- **"Who reviews what it proposes?"** The nightly agent reviewer promotes the clearly-useful,
  **holds** anything ambiguous for a human, and rejects noise — every decision receipted
  and visible in the digest ([`014-AT-DECR`](014-AT-DECR-agent-reviewed-capture-inbox-and-r8-evolution.md)).

---

## References

- [`014-AT-DECR`](014-AT-DECR-agent-reviewed-capture-inbox-and-r8-evolution.md) — the agent-reviewed-capture decision (the govern + receipts guarantee).
- [`011-AT-RNBK`](011-AT-RNBK-teammate-brain-onboarding.md) — plugging into the brain (team mode, tokens).
- `governed-second-brain-plugin` `hooks/` — the hook, the consent-gated enable flow, and their README.

- Jeremy Longshore
intentsolutions.io
