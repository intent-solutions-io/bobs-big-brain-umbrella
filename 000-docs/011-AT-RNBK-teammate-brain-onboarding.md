# 011 · AT · RNBK — Teammate onboarding: plug into "the big brain"

**Audience:** Pablo, Ope, Ezekiel, Tim, Max (and any future teammate).
**Goal:** in ~5 minutes, read and feed the one governed team brain from your own Claude Code.
**Status:** the brain API is live on the tailnet; per-user tokens are minted. This is the
reusable "here's how you plug in" doc for the all-at-once kickoff (rollout epic A, bead
`compile-then-govern-jfv.1.3`).

---

## What "the big brain" is

One governed knowledge brain for Intent Solutions. It is **not** each of us running a private
copy — there is exactly **one** brain, and you reach it over the tailnet. You can:

- **Search it** — every hit comes back with a `qmd://` citation you can trace.
- **Feed it** — propose a memory; a deterministic nightly pass governs it (dedupe → policy →
  secret-scan → promotion) and it shows up in search the next day. The model proposes; code
  decides what becomes durable, and every promotion leaves a hash-chained receipt.

You talk to it through three tools inside Claude Code: `brain_search` (read), `brain_capture`
(propose), and `brain_transition` (admins only).

---

## Prerequisites (one-time)

0. **GitHub access.** You must be a member of the `intent-solutions-io` GitHub org (or a
   collaborator on `team-intent-claude-plugins`) with `gh auth login` / git credentials working on
   your machine — otherwise Step 2's `/plugin marketplace add` fails with "repository not found."
   Ask Jeremy to add you first.
1. **Tailscale installed + on the Intent Solutions tailnet.** Install Tailscale
   (<https://tailscale.com/download>), accept Jeremy's invite, then `tailscale status` should list
   the `dev` node. The brain is **tailnet-only** — not reachable from the public internet.
2. **Claude Code installed** (a recent version — private marketplaces + plugin env interpolation
   need a current build) and you can log in and run it. **Launch it from a terminal** (see the
   desktop caveat in Step 1).
3. **Your token.** Jeremy hands you a per-user bearer token privately. It identifies you in the
   brain's audit trail — don't share it, don't paste it in chat or a repo.

---

## Step 1 — set two environment variables

Add these to your shell profile (`~/.zshrc` or `~/.bashrc`), then open a new terminal:

```bash
export TEAMKB_API_URL="http://dev.tail70fc2c.ts.net:3847"
export TEAMKB_API_TOKEN="<the token Jeremy gave you>"
```

That's the whole switch: **`TEAMKB_API_URL` being set is what puts the plugin in team mode** and
points it at the one shared brain. (With it unset, the same plugin runs in *local* mode over your
own files — that's the solo/showcase mode, not the team brain.)

> ⚠️ **Launch Claude Code from a terminal** where `echo $TEAMKB_API_URL` prints the URL. A
> desktop/Dock-launched app does **not** read your `~/.zshrc`/`~/.bashrc`, so the env vars won't be
> set and the plugin silently falls back to *local* mode (searching an empty brain on your laptop).
> If `echo $TEAMKB_API_URL` is blank, re-open the terminal after editing your profile, then start `claude`.

## Step 2 — install the plugin from the private marketplace

Inside Claude Code:

```
/plugin marketplace add intent-solutions-io/team-intent-claude-plugins
/plugin install governed-second-brain@intent-solutions-io
```

Then **restart Claude Code** so it loads the plugin and reads your env vars.

## Step 3 — smoke test (you're in)

**First, the reliable check** (works even if the plugin is misconfigured) — from your terminal:

```bash
curl -fsS http://dev.tail70fc2c.ts.net:3847/api/health
# → {"status":"healthy",...}   the brain is reachable and you're on the tailnet
# curl error / hang            you're NOT on the tailnet (fix Tailscale) or the API is down (ping Jeremy)
```

Then, inside Claude Code, ask:

> Use brain_search to find what we've decided about governance and receipts.

**Done = you get results with `qmd://` citations.** If you instead see
`team token rejected — check TEAMKB_API_TOKEN`, your token is wrong or expired — ping Jeremy.
If you see `unconfigured — set TEAMKB_API_URL`, your env vars didn't load (re-open the terminal
after editing your profile, or you started Claude Code before setting them).

---

## Using the brain day-to-day

- **Read:** `brain_search` — ask questions; cite the `qmd://` result when you act on it.
- **Feed:** `brain_capture` — propose a durable memory (a decision, a gotcha, a convention).
  It lands in the shared inbox and is **governed automatically overnight** — you don't promote it
  yourself, and duplicates/secrets are caught by code, not vibes. Check `brain_search` the next
  day to see it promoted.
- **Admins only:** `brain_transition` — lifecycle changes. Members get a clean permission error;
  that's expected.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `unconfigured — set TEAMKB_API_URL` | env vars not loaded | Re-open the terminal after editing your profile; restart Claude Code |
| `team token rejected — check TEAMKB_API_TOKEN` | wrong/expired token | Ask Jeremy for a fresh token |
| Connection refused / timeout | not on the tailnet | `tailscale status`; reconnect Tailscale |
| Plugin not listed | marketplace/install step skipped | Re-run Step 2, restart Claude Code |
| `brain_search` returns nothing for a real query | the brain may not have that topic yet | Feed it with `brain_capture` |

---

## For the record

- **Brain API:** `http://dev.tail70fc2c.ts.net:3847` (tailnet MagicDNS; IP `100.109.119.103:3847`).
  Health probe (no token): `curl http://dev.tail70fc2c.ts.net:3847/api/health` → `{"status":"healthy"}`.
- **Auth:** per-user scrypt-hashed bearer tokens; unknown token → 401. Roles: admin (Jeremy, Pablo)
  may write/promote and transition; member (Ope, Max, Ezekiel, Tim) may search and propose.
- **Where the brain lives:** one directory (`~/.teamkb`) on the dev-box VPS; see
  [`005-AT-ARCH`](005-AT-ARCH-grounded-system-map-and-backup-scope.md) for the full data map and
  [`006-AT-RNBK`](006-AT-RNBK-brain-backup-and-restore-runbook.md) for backup/restore.
- **Local (solo) mode** — leave `TEAMKB_API_URL` unset and the same plugin runs entirely over your
  own `~/.teamkb`, no network. That's the outsider showcase, not the team brain.

_Reference: repo topology [`007-AT-SMAP`](007-AT-SMAP-repo-topology-and-working-surface.md)._
