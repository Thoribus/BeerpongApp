#!/usr/bin/env node
/**
 * Closes a single issue after it has been fixed:
 *   - Sentry:   marks the issue as resolved via the API
 *   - Firebase: deletes the feedback document
 *
 * Usage:
 *   node scripts/close-issue.js --source sentry   --id 123456789
 *   node scripts/close-issue.js --source firebase --id abc123defg
 */

const admin = require('firebase-admin');
const https = require('https');
const fs = require('fs');
const path = require('path');

const FIREBASE_PROJECT = 'beerpong-companion';
const SENTRY_HOST = 'de.sentry.io';

// ── Helpers ───────────────────────────────────────────────────────────────────
function readSentryToken() {
  if (process.env.SENTRY_AUTH_TOKEN) return process.env.SENTRY_AUTH_TOKEN;
  const propsPath = path.join(__dirname, '..', 'sentry.properties');
  const content = fs.readFileSync(propsPath, 'utf8');
  const match = content.match(/auth_token=(\S+)/);
  if (!match) throw new Error('auth_token not found in sentry.properties');
  return match[1].trim();
}

function sentryPut(apiPath, token, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const options = {
      hostname: SENTRY_HOST,
      path: apiPath,
      method: 'PUT',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };
    let responseBody = '';
    const req = https.request(options, res => {
      res.on('data', chunk => { responseBody += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseBody);
        } else {
          reject(new Error(`Sentry API ${res.statusCode}: ${responseBody.slice(0, 300)}`));
        }
      });
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

// ── Closers ───────────────────────────────────────────────────────────────────
async function closeFirebase(docId) {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: FIREBASE_PROJECT });
  }
  const db = admin.firestore();
  const ref = db.collection('feedback').doc(docId);
  const snap = await ref.get();
  if (!snap.exists) {
    console.warn(`Warning: Firebase doc "${docId}" not found — already deleted?`);
    return;
  }
  await ref.delete();
  console.log(`✓ Deleted Firebase feedback doc: ${docId}`);
}

async function closeSentry(issueId) {
  const token = readSentryToken();
  await sentryPut(`/api/0/issues/${issueId}/`, token, { status: 'resolved' });
  console.log(`✓ Resolved Sentry issue: ${issueId}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const args = process.argv.slice(2);

  const get = (flag) => {
    const idx = args.indexOf(flag);
    return idx !== -1 ? args[idx + 1] : null;
  };

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
