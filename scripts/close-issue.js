#!/usr/bin/env node
/**
 * Closes a single issue after it has been fixed:
 *   - Sentry:   marks the issue as resolved via the API
 *   - Firebase: deletes the feedback document via Firestore REST API
 *
 * Usage:
 *   node scripts/close-issue.js --source sentry   --id 123456789
 *   node scripts/close-issue.js --source firebase --id abc123defg
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

const FIREBASE_PROJECT = 'beerpong-companion';
const SENTRY_HOST = 'de.sentry.io';

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
      res.on('end', () => { resolve({ status: res.statusCode, body: data }); });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
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
    throw new Error('Firebase CLI credentials not found. Run `firebase login`.');
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config?.tokens?.refresh_token;
  if (!token) throw new Error('No refresh_token found. Run `firebase login`.');
  return token;
}

async function getGoogleAccessToken(refreshToken) {
  const body = new URLSearchParams({
    client_id: FIREBASE_CLIENT_ID,
    client_secret: FIREBASE_CLIENT_SECRET,
    refresh_token: refreshToken,
    grant_type: 'refresh_token',
  }).toString();

  const { status, body: resBody } = await httpsRequest(
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

  const data = JSON.parse(resBody);
  if (status !== 200 || !data.access_token) {
    throw new Error(
      `Failed to refresh Google access token (${status}): ${resBody.slice(0, 200)}\n` +
      '  Fix: Run `firebase login --reauth`.',
    );
  }
  return data.access_token;
}

// ── Closers ───────────────────────────────────────────────────────────────────
async function closeFirebase(docId) {
  const refreshToken = readFirebaseRefreshToken();
  const accessToken = await getGoogleAccessToken(refreshToken);

  const docPath = `/v1/projects/${FIREBASE_PROJECT}/databases/(default)/documents/feedback/${docId}`;

  // Check existence first
  const { status: getStatus } = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: docPath,
    method: 'GET',
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (getStatus === 404) {
    console.warn(`Warning: Firebase doc "${docId}" not found — already deleted?`);
    return;
  }

  const { status: delStatus, body: delBody } = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: docPath,
    method: 'DELETE',
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (delStatus < 200 || delStatus >= 300) {
    throw new Error(`Firestore DELETE failed (${delStatus}): ${delBody.slice(0, 200)}`);
  }
  console.log(`✓ Deleted Firebase feedback doc: ${docId}`);
}

async function closeSentry(issueId) {
  const token = readSentryToken();
  const data = JSON.stringify({ status: 'resolved' });
  const { status, body } = await httpsRequest(
    {
      hostname: SENTRY_HOST,
      path: `/api/0/issues/${issueId}/`,
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    },
    data,
  );
  if (status < 200 || status >= 300) {
    throw new Error(`Sentry API ${status}: ${body.slice(0, 300)}`);
  }
  console.log(`✓ Resolved Sentry issue: ${issueId}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const args = process.argv.slice(2);
  const get = flag => { const i = args.indexOf(flag); return i !== -1 ? args[i + 1] : null; };

  const source = get('--source');
  const id = get('--id');

  if (!source || !id) {
    console.error('Usage: node scripts/close-issue.js --source <sentry|firebase> --id <id>');
    process.exit(1);
  }

  if (source === 'firebase') {
    await closeFirebase(id);
  } else if (source === 'sentry') {
    await closeSentry(id);
  } else {
    console.error(`Unknown source "${source}". Use "firebase" or "sentry".`);
    process.exit(1);
  }
}

main().catch(err => { console.error(`Error: ${err.message}`); process.exit(1); });
