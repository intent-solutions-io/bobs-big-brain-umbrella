# 022 · AT · RNBK — Tailscale non-Google identity migration

**Purpose:** remove the retired Google Workspace login as a dependency for administering or joining
the Intent Solutions tailnet without locking out the team.

**Tracked work:** `compile-then-govern-jfv.1.9` (Tim recovery) and
`compile-then-govern-jfv.1.10` (primary identity migration).

**Status on 2026-08-18:** recovery path prepared; human acceptance and replacement-IdP choice remain.

## Verified starting state

- Tailnet: `intentsolutions.io`, MagicDNS suffix `tail70fc2c.ts.net`.
- The brain API is healthy at `100.109.119.103:3847` and is not public.
- Jeremy is the only owner; Opeyemi is an admin. Both privileged logins still use the retired
  `@intentsolutions.io` Google identity path.
- Max and Pablo are members. Tim is not yet present in the live Tailscale user/device inventory.
- Tim's Bob's Big Brain member credential successfully authenticated from an enrolled node and
  returned cited search results. His remaining blocker is Tailscale invite acceptance on his own
  device.
- A one-time member invite exists for Tim. A separate one-time **Admin** invite exists for a
  passkey recovery identity. Invitation URLs are deliberately absent from this repository and Beads.
- The current policy was read and hashed before migration. No ACL mutation or public exposure is part
  of this procedure.

## Decisions already made

1. **Immediate teammate enrollment uses one-time external invites.** Invitees can authenticate with
   a passkey or their current identity provider; mail hosting is irrelevant.
2. **A passkey admin is the recovery control.** It remains independent of the primary SSO provider.
3. **Do not switch the primary IdP until that passkey admin has accepted and logged in.** An open
   invite is not a recovery account.
4. **Do not change the tailnet's primary domain during the IdP switch.** Identity-provider and domain
   migration are separate operations.
5. **Do not widen the network policy.** Identity repair changes authentication, not authorization.

Tailscale explicitly recommends a passkey-capable admin for SSO recovery; follow its
[passkey admin procedure](https://tailscale.com/docs/reference/tailnet-passkey-admin).

## Replacement IdP decision gate

The repository and deployed configuration contain no existing human Entra, Okta, OneLogin,
Authentik, Zitadel, or Keycloak tenant. MXroute provides email, not identity. The existing Tailscale
OIDC credential is for CI workload identity and must not be reused for human login.

Select exactly one path before changing the tailnet:

1. **Microsoft Entra ID** — preferred if Intent Solutions already owns and administers a Microsoft
   tenant for all team identities.
2. **Another existing managed OIDC provider** — acceptable when it already owns the team's human
   identities and meets Tailscale's discovery, signing, and claim requirements.
3. **A deliberately operated custom OIDC provider** — valid only after an owner, backup admin,
   lifecycle/runbook, monitoring, backups, and recovery credentials are named. Do not deploy a new
   IdP as an emergency shortcut.

Passkey invitations are the safe bridge, but they do not by themselves change the tailnet's primary
IdP. The primary migration bead stays open until an IdP is selected and switched.

For custom OIDC, verify Tailscale's current
[OIDC requirements](https://tailscale.com/kb/1240/sso-custom-oidc/) before implementation.

## Pre-cutover gates

All gates must be green in the same change window:

- [ ] The one-time Admin invite was accepted in a private browser using a passkey.
- [ ] The new `*@passkey` identity appears as active Admin and can open the admin console in a
      separate session.
- [ ] The owner and existing admin sessions are both live on separate devices.
- [ ] Current users, devices, tags, policy, and open invites were inventoried.
- [ ] The policy payload hash and the list of online critical devices were recorded.
- [ ] CI workload identity was tested independently; it is not part of human IdP authentication.
- [ ] The replacement IdP has at least two recoverable administrators.
- [ ] Issuer URL, client ID, client secret custody, redirect URI, scopes, signing algorithms, and
      domain discovery were verified without committing secrets.
- [ ] Tailscale's primary domain remains `intentsolutions.io` for the switch.
- [ ] A stop condition and the rollback operator are named.

## Cutover

Only a Tailscale owner performs this sequence:

1. Keep the passkey-admin session and one existing owner session open on separate devices.
2. In the admin console, open **User management -> Identity Provider -> Switch**.
3. Select the chosen provider and complete its discovery/client configuration.
4. Confirm only after Tailscale validates the provider. Do not delete old identities or revoke old
   sessions during the change window.
5. Capture the configuration-log event ID and timestamp; do not store client credentials in Beads.

Use Tailscale's current
[identity-provider switch procedure](https://tailscale.com/docs/integrations/identity/switch-identity-provider)
as the authoritative UI sequence.

## Post-cutover acceptance

Verify every row before declaring the migration complete:

| Surface | Proof |
|---|---|
| Recovery admin | Fresh private-window passkey login reaches the admin console |
| Owner/admin | Both privileged humans can authenticate through the replacement IdP |
| Existing humans | Jeremy, Opeyemi, Max, and Pablo retain device connectivity |
| Tim/new user | A fresh one-time invite joins without Google Workspace |
| Brain network | Enrolled member reaches `http://100.109.119.103:3847/api/health` |
| Brain auth | Individual member token returns a `qmd://`-cited `brain_search` result |
| Least privilege | Member cannot reach dev-box SSH and cannot call admin brain transitions |
| Policy | Post-cutover policy hash matches the pre-cutover hash |
| CI | GitHub Actions workload identity still reaches only its intended Tailscale resources |
| Audit | Tailscale configuration log and Beads contain IDs/timestamps, not secrets |

## Abort and rollback

- **Before confirmation:** abort the provider switch. No ACL, user, token, or device change is needed.
- **After confirmation with broken human login:** use the independent passkey admin, keep existing
  devices online, and initiate a supported switch back to the prior provider or a corrected provider.
  Contact Tailscale support if the console will not offer a safe reverse switch.
- Do not delete the passkey admin, old Google identities, or old provider configuration until the
  full acceptance matrix has passed and a second post-cutover login has been observed.
- If brain access fails but Tailscale health is intact, diagnose the plugin/team token separately;
  do not alter the tailnet policy as a workaround.

## Evidence bundle for closing the Beads

Record:

- passkey admin user ID and role;
- replacement IdP and decision owner;
- switch configuration-log event ID and timestamp;
- pre/post policy hashes;
- existing-user and CI verification results;
- Tim/new-user invite ID, device ID, health result, cited query URI, and negative SSH/admin proof;
- rollback readiness and any blueprint-versus-actual delta.

Never record invitation URLs, bearer tokens, client secrets, passkeys, or recovery codes.
