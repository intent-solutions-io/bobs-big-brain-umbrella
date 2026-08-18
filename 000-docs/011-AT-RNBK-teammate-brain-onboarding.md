# 011 · AT · RNBK — Teammate onboarding: plug into the big brain

**Audience:** Intent Solutions teammates and future invitees.

**Goal:** connect a desktop Claude to the one governed team brain in about five minutes.

**Status:** the tailnet-only API and public plugin are live. A teammate still needs to accept a
one-time Tailscale invite and receive an individual brain token over a trusted channel.

## What you are joining

Bob's Big Brain is one shared, governed knowledge system. Teammates use the public
`governed-second-brain` plugin in **team mode** to reach it over Tailscale. The same plugin runs in
local mode when team configuration is absent.

- `brain_search` reads governed memories and returns `qmd://` citations.
- `brain_capture` proposes a memory for server-side governance.
- Admin review tools handle the shared inbox; members cannot perform admin transitions.

## Prerequisites

1. A desktop Claude: Claude Code or Cowork is recommended. A browser or phone app cannot reach a
   local plugin over the private network.
2. Tailscale installed on the teammate's computer.
3. A distinct one-time Tailscale invite for that teammate.
4. The teammate's individual Bob's Big Brain bearer token, delivered privately.

GitHub organization membership and the retired private team marketplace are **not** prerequisites.
The plugin repository and marketplace are public.

## Step 1 — join the team tailnet without Google Workspace

1. Open the one-time invite in a private or incognito browser window.
2. Sign in with a passkey or a current identity provider. The login does **not** need to end in
   `@intentsolutions.io`, and no Gmail account is required.
3. Open the Tailscale client and select the tailnet labeled `intentsolutions.io` (`tail70fc2c`).
4. Confirm that the brain is reachable:

```bash
curl -fsS http://100.109.119.103:3847/api/health
```

A healthy JSON response proves private-network reachability. It does not prove token or plugin
configuration yet.

Tailscale invitations are one-time links. Do not reuse or post them. See Tailscale's
[invite guide](https://tailscale.com/docs/features/sharing/how-to/invite-any-user) and
[passkey guide](https://tailscale.com/docs/integrations/identity/passkeys).

## Step 2 — install and configure the plugin

### macOS Claude Code

Download and double-click the public plugin's
[`install-bobs-big-brain.command`](https://github.com/jeremylongshore/bobs-big-brain-plugin/blob/main/onboarding/install-bobs-big-brain.command).
It checks tailnet reachability, accepts the token without echoing it, writes the team configuration
at mode `600`, and installs the plugin.

### Claude Code or Cowork by hand

Install from the public plugin marketplace:

```text
/plugin marketplace add jeremylongshore/bobs-big-brain-plugin
/plugin install governed-second-brain@governed-second-brain
```

Write `~/.teamkb/team.json` (Windows: `%USERPROFILE%\.teamkb\team.json`) with owner-only
permissions:

```json
{
  "apiUrl": "http://100.109.119.103:3847",
  "apiToken": "<the teammate's individual token>",
  "tenantId": "intent-solutions"
}
```

The plugin reads each setting in this order:

```text
real environment variable -> ~/.teamkb/team.json -> absent means local mode
```

`team.json` is the reliable desktop path because Dock- and GUI-launched applications do not source
shell profiles. The plugin fails closed if the file is readable by other users, unreadable, or
invalid JSON; it does not silently turn a broken team configuration into local mode.

Fully restart the desktop Claude after configuration.

## Step 3 — prove cited retrieval

In a new Claude Code or Cowork session, run:

```text
/brain backup restore
```

Done means the answer contains one or more `qmd://` citations. Use strong topic keywords if the
first query has no hits; retrieval is lexical today.

The proof has two independent parts:

1. `/api/health` succeeds: the device is on the correct tailnet and can reach the API.
2. `/brain` returns cited hits: the plugin selected team mode and the individual bearer token works.

## Day-to-day use

- **Read:** use `/brain <keywords>` or `brain_search`; preserve the returned citation when acting.
- **Propose:** use `/brain-save` or `brain_capture`; the proposal enters governance before it can
  become durable team knowledge.
- **Admin review:** only an admin token can approve, reject, or transition shared memories.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Health request times out | Wrong tailnet or Tailscale is disconnected | Run `tailscale switch`; choose `intentsolutions.io` (`tail70fc2c`) |
| Invite opens the old Google flow | Existing browser session selected the old identity | Sign out and reopen the one-time invite in a private window; choose passkey or another current IdP |
| `unconfigured — set TEAMKB_API_URL` | Team configuration was not loaded | Check `~/.teamkb/team.json`, mode `600`, then fully restart Claude |
| `team token rejected` | Token is mistyped, revoked, or expired | Ask the admin to verify or reissue that teammate's token privately |
| Plugin not listed | Public marketplace install did not finish | Re-run the two `/plugin` commands and restart Claude |
| Zero hits with healthy status | Query terms did not match | Try concrete keywords such as `backup`, `deploy`, or `govern` |

## Admin handoff checklist

- Create one one-time Tailscale **member** invite per teammate; never use a reusable device auth key
  for a human.
- Deliver the invite, individual brain token, and installer over the established trusted channel.
- Confirm the teammate appears as an individual Tailscale user and their device is authorized.
- Record only invite IDs and test receipts in Beads—never invitation URLs or bearer tokens.
- Prove member access to TCP `3847` and retain the deny-by-default policy; do not widen the ACL to
  work around identity enrollment.

The non-Google identity migration and rollback procedure is
[`022-AT-RNBK`](022-AT-RNBK-tailscale-non-google-identity-migration.md). Live completion for Tim is
tracked by Beads `compile-then-govern-jfv.1.9`; the durable identity-provider migration is
`compile-then-govern-jfv.1.10`.
