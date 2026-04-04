#!/usr/bin/env node
/**
 * Fetches unresolved Sentry errors and Firebase user feedback,
 * and writes them to tasks/issues.md for Claude Code to work through.
 *
 * Usage:  node scripts/sync-issues.js
 * Prereq: firebase login (sets up Application Default Credentials)
 */

const admin = require('firebase-admin');
const https = require('https');
const fs = require('fs');
const path = require('path');

// ── Config ───────────────────────────────────────────────────────────────────
const FIREBASE_PROJECT = 'beerpong-companion';
const SENTRY_ORG = 'christopher-richter';
const SENTRY_PROJECT = 'flutter';
const SENTRY_HOST = 'de.sentry.io';
const ISSUES_FILE = path.join(__dirname, '..', 'tasks', 'issues.md');

// ── Helpers ───────────────────────────────────────────────────────────────────
function readSentryToken() {
  // Env var takes priority — useful when sentry.properties token lacks read scopes
  if (process.env.SENTRY_AUTH_TOKEN) return process.env.SENTRY_AUTH_TOKEN;
  const propsPath = path.join(__dirname, '..', 'sentry.properties');
  const content = fs.readFileSync(propsPath, 'utf8');
  const match = content.match(/auth_token=(\S+)/);
  if (!match) throw new Error('auth_token not found in sentry.properties');
  return match[1].trim();
}

function sentryGet(apiPath, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SENTRY_HOST,
      path: apiPath,
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    let body = '';
    const req = https.request(options, res => {
      res.on('data', chunk => { body += chunk; });
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(body) }); }
        catch (e) { reject(new Error(`Invalid JSON from Sentry: ${body.slice(0, 200)}`)); }
      });
    });
    req.on('error', reject);
    req.end();
  });
}

// ── Firebase ──────────────────────────────────────────────────────────────────
async function fetchFirebaseFeedback() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: FIREBASE_PROJECT });
  }
  const db = admin.firestore();
  const snap = await db
    .collection('feedback')
    .orderBy('createdAt', 'asc')
    .get();

  return snap.docs.map(doc => {
    const d = doc.data();
    return {
      id: doc.id,
      source: 'firebase',
      category: d.category || 'Other',
      username: d.username || 'unknown',
      platform: d.platform || '',
      message: (d.message || '').replace(/\n/g, ' '),
      createdAt: d.createdAt?.toDate?.()?.toISOString() || '',
    };
  });
}

// ── Sentry ────────────────────────────────────────────────────────────────────
async function fetchSentryIssues(token) {
  const url = `/api/0/projects/${SENTRY_ORG}/${SENTRY_PROJECT}/issues/?query=is:unresolved&limit=25`;
  const { status, data } = await sentryGet(url, token);

  if (status === 401) throw new Error(
    'Sentry auth failed (401). Check auth_token in sentry.properties or set SENTRY_AUTH_TOKEN env var.'
  );
  if (status === 403) throw new Error(
    'Sentry permission denied (403). The token in sentry.properties was created for symbol uploads ' +
    'and lacks "project:read" scope.\n' +
    '  Fix: Go to https://sentry.io/settings/account/api/auth-tokens/ → New Token\n' +
    '       Scopes needed: project:read, event:read\n' +
    '       Then set: SENTRY_AUTH_TOKEN=<new-token> node scripts/sync-issues.js'
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

  // Sentry section
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

  // Firebase section
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
    console.error('    Run: firebase login  (to set up Application Default Credentials)');
  }

  const md = buildMarkdown(sentryItems, firebaseItems);
  fs.mkdirSync(path.dirname(ISSUES_FILE), { recursive: true });
  fs.writeFileSync(ISSUES_FILE, md, 'utf8');
  console.log(`\nWritten → ${ISSUES_FILE}`);
  console.log(`Total: ${sentryItems.length + firebaseItems.length} items to work through`);
}

main().catch(err => { console.error(err.message); process.exit(1); });
