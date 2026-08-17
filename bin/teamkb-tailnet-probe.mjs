#!/usr/bin/env node
// teamkb-tailnet-probe.mjs — the SYNTHETIC TEAMMATE (bead compile-then-govern-6ps,
// Track 1). Proves a teammate is really connected to the governed brain over the
// tailnet WITHOUT bothering a real teammate: it drives the EXACT installed plugin
// runtime (governed-brain.cjs, team mode) — the same artifact a teammate's Claude
// Code loads — over MCP stdio, using a dedicated `synthetic-probe` MEMBER token,
// from a genuinely separate tailnet node (the VPS) against the live brain.
//
// It is NOT a per-PR CI test — GH runners aren't on the tailnet. It's a scheduled
// LIVENESS canary. Two tiers:
//   --tier a  (default) — one call: brain_status. Answers "is a teammate really
//                         connected, from tailscale?" cheaply, every morning.
//   --tier b  — the full governed round-trip (capture -> the govern GATE holds it
//               back -> member cannot self-approve). See runTierB below (6ps.4).
//
// HONESTY CONDITION (Kleppmann): this must run from a DIFFERENT tailnet node than
// the brain host, over a REAL per-user token. The anti-loopback guard fails closed
// if TEAMKB_API_URL is loopback — a probe that talks to localhost proves nothing
// about the tailnet.
//
// Zero dependencies (Node built-ins only) so it runs anywhere node is, incl. a bare
// VPS. Exit 0 = all assertions passed; exit 1 = a failure (the wrapper dispatches through the governed Intent OS alert floor to Buzz).

import { spawn } from 'node:child_process';
import process from 'node:process';

// ── args ─────────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
const getArg = (flag, dflt) => {
  const i = argv.indexOf(flag);
  return i >= 0 && argv[i + 1] !== undefined ? argv[i + 1] : dflt;
};
const TIER = (getArg('--tier', 'a') || 'a').toLowerCase();
const JSON_OUT = argv.includes('--json');
const CJS =
  getArg('--cjs', process.env.TEAMKB_PROBE_CJS) ||
  `${process.env.HOME}/.claude/plugins/marketplaces/claude-code-plugins-plus/plugins/mcp/governed-second-brain/plugin-runtime/governed-brain.cjs`;

const API_URL = process.env.TEAMKB_API_URL || '';
const API_TOKEN = process.env.TEAMKB_API_TOKEN || '';
const TENANT_ID = process.env.TEAMKB_TENANT_ID || '';

function isTailnetUrl(value) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return false;
    if (url.username || url.password) return false;
    const octets = url.hostname.split('.').map(Number);
    return (
      octets.length === 4 &&
      octets.every((octet) => Number.isInteger(octet) && octet >= 0 && octet <= 255) &&
      octets[0] === 100 &&
      octets[1] >= 64 &&
      octets[1] <= 127
    );
  } catch {
    return false;
  }
}

// ── report plumbing ──────────────────────────────────────────────────────────
const checks = [];
const check = (name, pass, detail) => {
  checks.push({ name, pass: !!pass, detail: detail ?? '' });
  return !!pass;
};
function finish() {
  const failed = checks.filter((c) => !c.pass);
  const ok = failed.length === 0;
  if (JSON_OUT) {
    process.stdout.write(JSON.stringify({ ok, tier: TIER, apiUrl: API_URL, checks }) + '\n');
  } else {
    process.stdout.write(`## teamkb tailnet probe — tier ${TIER.toUpperCase()} — ${ok ? 'PASS' : 'FAIL'}\n`);
    process.stdout.write(`apiUrl=${API_URL} tenant=${TENANT_ID || '(default)'} cjs=${CJS}\n`);
    for (const c of checks) process.stdout.write(`  ${c.pass ? '✓' : '✗'} ${c.name}${c.detail ? ' — ' + c.detail : ''}\n`);
    if (!ok) process.stdout.write(`FAILED: ${failed.map((c) => c.name).join(', ')}\n`);
  }
  process.exit(ok ? 0 : 1);
}
const die = (msg) => {
  check('probe-ran', false, msg);
  finish();
};

// ── pre-flight (fail closed) ─────────────────────────────────────────────────
if (!API_URL) die('TEAMKB_API_URL is unset — cannot run the tailnet probe');
if (!API_TOKEN) die('TEAMKB_API_TOKEN is unset — a real per-user token is required');
// Anti-loopback: a tailnet proof MUST NOT be talking to localhost. Tailnet IPs are
// 100.64.0.0/10 (CGNAT); fail closed outside that exact range.
if (!isTailnetUrl(API_URL)) {
  die(`anti-loopback guard: TEAMKB_API_URL=${API_URL} is not a tailnet (100.64.0.0/10) host — a loopback probe proves nothing about the tailnet`);
}

// ── minimal MCP stdio client (newline-delimited JSON-RPC 2.0) ────────────────
function mcpClient() {
  const child = spawn(process.execPath, [CJS], {
    env: { ...process.env, TEAMKB_API_URL: API_URL, TEAMKB_API_TOKEN: API_TOKEN, ...(TENANT_ID ? { TEAMKB_TENANT_ID: TENANT_ID } : {}) },
    stdio: ['pipe', 'pipe', 'pipe'],
  });
  let buf = '';
  const pending = new Map();
  let stderr = '';
  child.stderr.on('data', (d) => { stderr += d.toString(); });
  child.stdout.on('data', (d) => {
    buf += d.toString();
    let nl;
    while ((nl = buf.indexOf('\n')) >= 0) {
      const line = buf.slice(0, nl).trim();
      buf = buf.slice(nl + 1);
      if (!line) continue;
      let msg;
      try { msg = JSON.parse(line); } catch { continue; } // ignore non-JSON log noise
      if (msg.id !== undefined && pending.has(msg.id)) {
        const { resolve } = pending.get(msg.id);
        pending.delete(msg.id);
        resolve(msg);
      }
    }
  });
  let nextId = 1;
  const send = (method, params, isNotify = false) =>
    new Promise((resolve, reject) => {
      const id = isNotify ? undefined : nextId++;
      const payload = { jsonrpc: '2.0', method, ...(params ? { params } : {}), ...(isNotify ? {} : { id }) };
      if (!isNotify) {
        const timer = setTimeout(() => { pending.delete(id); reject(new Error(`timeout waiting for ${method}`)); }, 20000);
        pending.set(id, { resolve: (m) => { clearTimeout(timer); resolve(m); } });
      }
      child.stdin.write(JSON.stringify(payload) + '\n');
      if (isNotify) resolve(undefined);
    });
  return {
    child,
    getStderr: () => stderr,
    async initialize() {
      const r = await send('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'teamkb-tailnet-probe', version: '1.0.0' } });
      await send('notifications/initialized', undefined, true);
      return r;
    },
    async callTool(name, args = {}) {
      const r = await send('tools/call', { name, arguments: args });
      // tools/call result: { result: { content: [{type:'text', text:'<json>'}], isError? } }
      if (r.error) return { _rpcError: r.error };
      const content = r.result?.content ?? [];
      const text = content.find((c) => c.type === 'text')?.text ?? '';
      let parsed;
      try { parsed = JSON.parse(text); } catch { parsed = { _raw: text }; }
      return { _isError: !!r.result?.isError, ...parsed };
    },
    close() { try { child.stdin.end(); child.kill('SIGTERM'); } catch { /* ignore */ } },
  };
}

// ── Tier A: the daily connection canary ──────────────────────────────────────
async function runTierA(mcp) {
  const s = await mcp.callTool('brain_status');
  // brain_status returns { mode, apiUrl, tokenSet, healthy, version }
  check('team-mode', s.mode === 'team', `mode=${s.mode}`);
  check('healthy', s.healthy === true, `healthy=${s.healthy}`);
  check('token-set', s.tokenSet === true, `tokenSet=${s.tokenSet}`);
  check('apiUrl-is-tailnet', typeof s.apiUrl === 'string' && isTailnetUrl(s.apiUrl), `apiUrl=${s.apiUrl}`);
  check('version-present', typeof s.version === 'string' && s.version.length > 0, `version=${s.version}`);

  // Health is public and tokenSet only proves that a value exists. A small
  // search inside the token's isolated synthetic tenant is the read-only proof
  // that this member token is actually accepted, without granting it team data.
  const search = await mcp.callTool('brain_search', {
    query: 'authentication canary sentinel',
    limit: 1,
  });
  check(
    'member-token-authenticated',
    !search._isError &&
      !search._rpcError &&
      search.source === 'brain-api' &&
      Number.isInteger(search.count),
    `source=${search.source ?? 'none'} count=${search.count ?? 'none'}`,
  );
}

// ── Tier B: the full governed round-trip (fleshed out in 6ps.4) ──────────────
async function runTierB(mcp) {
  // Placeholder until 6ps.4 — run Tier A so the harness is exercised, then flag B.
  await runTierA(mcp);
  check('tier-b-implemented', false, 'Tier B round-trip lands in bead 6ps.4');
}

// ── main ─────────────────────────────────────────────────────────────────────
(async () => {
  const mcp = mcpClient();
  const guard = setTimeout(() => { check('overall-timeout', false, 'probe exceeded 45s'); mcp.close(); finish(); }, 45000);
  try {
    await mcp.initialize();
    if (TIER === 'b') await runTierB(mcp);
    else await runTierA(mcp);
  } catch (e) {
    check('probe-ran', false, `${e instanceof Error ? e.message : String(e)}; stderr tail: ${mcp.getStderr().slice(-300)}`);
  } finally {
    clearTimeout(guard);
    mcp.close();
    finish();
  }
})();
