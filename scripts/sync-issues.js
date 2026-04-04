#!/usr/bin/env node
/**
 * Fetches unresolved Sentry errors and Firebase user feedback,
 * and writes them to tasks/issues.md for Claude Code to work through.
 *
 * Usage:  node scripts/sync-issues.js
 * Prereq: firebase login  (stores refresh token used for Firestore REST API)
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Load .env if present (for SENTRY_AUTH_TOKEN etc.)
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  fs.readFileSync(envPath, 'utf8').split('\n').forEach(line => {
    const m = line.match(/^([^#=]+)=(.*)$/);
    if (m) process.env[m[1].trim()] = m[2].trim().replace(/^['"]|['"]$/g, '');
  });
}

// ── Config ───────────────────────────────────────────────────────────────────
const FIREBASE_PROJECT = 'beerpong-companion';
const SENTRY_ORG = 'christopher-richter';
const SENTRY_PROJECT = 'flutter';
const SENTRY_HOST = 'de.sentry.io';
const ISSUES_FILE = path.join(__dirname, '..', 'tasks', 'issues.md');

// Firebase CLI OAuth2 client credentials (public, from open-source firebase-tools)
const FIREBASE_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FIREBASE_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// ── HTTP helpers ──────────────────────────────────────────────────────────────
function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, res => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch (e) { reject(new Error(`Invalid JSON (${res.statusCode}): ${data.slice(0, 200)}`)); }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

function sentryGet(apiPath, token) {
  return httpsRequest({
    hostname: SENTRY_HOST,
    path: apiPath,
    method: 'GET',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function readSentryToken() {
  if (process.env.SENTRY_AUTH_TOKEN) return process.env.SENTRY_AUTH_TOKEN;
  const propsPath = path.join(__dirname, '..', 'sentry.properties');
  const content = fs.readFileSync(propsPath, 'utf8');
  const match = content.match(/auth_token=(\S+)/);
  if (!match) throw new Error('auth_token not found in sentry.properties');
  return match[1].trim();
}

function readFirebaseRefreshToken() {
  if (process.env.GOOGLE_REFRESH_TOKEN) return process.env.GOOGLE_REFRESH_TOKEN;
  const configPath = path.join(
    os.homedir(), '.config', 'configstore', 'firebase-tools.json',
  );
  if (!fs.existsSync(configPath)) {
    throw new Error(
      'Firebase CLI credentials not found.\n' +
      '  Fix: Run `firebase login` to authenticate.',
    );
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config?.tokens?.refresh_token;
  if (!token) {
    throw new Error(
      'No refresh_token in firebase-tools.json.\n' +
      '  Fix: Run `firebase login` to re-authenticate.',
    );
  }
  return token;
}

async function getGoogleAccessToken(refreshToken) {
  const body = new URLSearchParams({
    client_id: FIREBASE_CLIENT_ID,
    client_secret: FIREBASE_CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  }).toString();

  const { status, data } = await httpsRequest(
    {
      hostname: 'oauth2.googleapis.com',
      path: '/token',
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(body),
      },
    },
    body,
  );

  if (status !== 200 || !data.access_token) {
    throw new Error(
      `Failed to refresh Google access token (${status}): ${JSON.stringify(data).slice(0, 200)}\n` +
      '  Fix: Run `firebase login --reauth` to refresh credentials.',
    );
  }
  return data.access_token;
}

// ── Firebase (Firestore REST API) ─────────────────────────────────────────────
async function fetchFirebaseFeedback() {
  const refreshToken = readFirebaseRefreshToken();
  const accessToken = await getGoogleAccessToken(refreshToken);

  const projectPath = `projects/${FIREBASE_PROJECT}/databases/(default)/documents`;
  const url = `/v1/${projectPath}/feedback?orderBy=createdAt&pageSize=50`;

  const { status, data } = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: url,
    method: 'GET',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
  });

  if (status === 401 || status === 403) {
    throw new Error(
      `Firestore permission denied (${status}).\n` +
      '  Fix: Run `firebase login --reauth` to refresh credentials.',
    );
  }
  if (status !== 200) {
    throw new Error(`Firestore API error (${status}): ${JSON.stringify(data).slice(0, 200)}`);
  }

  if (!data.documents) return [];

  return data.documents.map(doc => {
    const fields = doc.fields || {};
    const id = doc.name.split('/').pop();

    const str = key => fields[key]?.stringValue || '';
    const ts = key => {
      const v = fields[key]?.timestampValue;
      return v ? new Date(v).toISOString() : '';
    };

    return {
      id,
      source: 'firebase',
      category: str('category') || 'Other',
      username: str('username') || 'unknown',
      platform: str('platform'),
      message: str('message').replace(/\n/g, ' '),
      createdAt: ts('createdAt'),
    };
  });
}

// ── Sentry ────────────────────────────────────────────────────────────────────
async function fetchSentryIssues(token) {
  const url = `/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/issues/?query=is:unresolved&limit=25`;
  const { status, data } = await sentryGet(url, token);

  if (status === 401) throw new Error(
    'Sentry auth failed (401). Check auth_token in sentry.properties or set SENTRY_AUTH_TOKEN env var.',
  );
  if (status === 403) throw new Error(
    'Sentry permission denied (403). The token lacks "project:read" scope.\n' +
    '  Fix: Go to https://sentry.io/settings/account/api/auth-tokens/ → New Token\n' +
    '       Scopes needed: project:read, event:read\n' +
    '       Then set: SENTRY_AUTH_TOKEN=<new-token> node scripts/sync-issues.js',
  );
  if (status === 404) throw new Error(`Sentry project not found: ${SENTRY_ORG}/${SENTRY_PROJECT}`);
  if (!Array.isArray(data)) {
    throw new Error(`Unexpected Sentry response (${status}): ${JSON.stringify(data).slice(0, 200)}`);
  }

  return data.map(issue => ({
    id: issue.id,
    source: 'sentry',
    level: (issue.level || 'error').toUpperCase(),
    title: issue.title || '(no title)',
    culprit: issue.culprit || '',
    count: issue.count || 0,
    firstSeen: issue.firstSeen || '',
    lastSeen: issue.lastSeen || '',
    permalink: issue.permalink || '',
  }));
}

// ── Markdown ──────────────────────────────────────────────────────────────────
function buildMarkdown(sentryItems, firebaseItems) {
  const total = sentryItems.length + firebaseItems.length;
  const lines = [
    '# Issue Queue',
    '',
    `> **${total} item${total !== 1 ? 's' : ''}** — last synced ${new Date().toISOString()}`,
    '> Fix one at a time. After each fix run `node scripts/close-issue.js --source <source> --id <id>` then commit.',
    '',
  ];

  lines.push('## Sentry Errors', '');
  if (sentryItems.length === 0) {
    lines.push('_No unresolved issues._', '');
  } else {
    for (const issue of sentryItems) {
      lines.push(
        `### [${issue.level}] ${issue.title}`,
        `- **source**: sentry  **id**: \`${issue.id}\``,
        `- **culprit**: ${issue.culprit || '—'}`,
        `- **occurrences**: ${issue.count}  |  first: ${issue.firstSeen.slice(0, 10)}  |  last: ${issue.lastSeen.slice(0, 10)}`,
        `- **link**: ${issue.permalink}`,
        '',
        `_Close with:_ \`node scripts/close-issue.js --source sentry --id ${issue.id}\``,
        '',
      );
    }
  }

  lines.push('## User Feedback', '');
  if (firebaseItems.length === 0) {
    lines.push('_No pending feedback._', '');
  } else {
    for (const item of firebaseItems) {
      const date = item.createdAt ? item.createdAt.slice(0, 10) : '—';
      lines.push(
        `### [${item.category}] ${item.username} — ${date}`,
        `- **source**: firebase  **id**: \`${item.id}\``,
        `- **platform**: ${item.platform || '—'}`,
        `- **message**: ${item.message}`,
        '',
        `_Close with:_ \`node scripts/close-issue.js --source firebase --id ${item.id}\``,
        '',
      );
    }
  }

  return lines.join('\n');
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  let sentryItems = [];
  let firebaseItems = [];

  console.log('Fetching Sentry issues…');
  try {
    const token = readSentryToken();
    sentryItems = await fetchSentryIssues(token);
    console.log(`  ✓ ${sentryItems.length} unresolved Sentry issues`);
  } catch (e) {
    console.error(`  ✗ Sentry fetch failed: ${e.message}`);
  }

  console.log('Fetching Firebase feedback…');
  try {
    firebaseItems = await fetchFirebaseFeedback();
    console.log(`  ✓ ${firebaseItems.length} feedback entries`);
  } catch (e) {
    console.error(`  ✗ Firebase fetch failed: ${e.message}`);
  }

  const md = buildMarkdown(sentryItems, firebaseItems);
  fs.mkdirSync(path.dirname(ISSUES_FILE), { recursive: true });
  fs.writeFileSync(ISSUES_FILE, md, 'utf8');
  console.log(`\nWritten → ${ISSUES_FILE}`);
  console.log(`Total: ${sentryItems.length + firebaseItems.length} items to work through`);
}

main().catch(err => { console.error(err.message); process.exit(1); });
