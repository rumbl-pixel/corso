#!/usr/bin/env node
// Pre-deploy safety gate. Scans the BUILT bundle that is about to be published
// (dist-pages by default) for the two failures that must never reach the public
// beta: a config that is not demo-locked, and any service-role credential in a
// browser-delivered file.
//
// This is deliberately narrow and dependency-free: it guards what actually
// ships, not whether the live backend is ready (that is
// supabase-production-readiness-check.js). It is wired into the deploy path so a
// deploy cannot proceed while either failure is present.
//
// Override for an explicitly approved live launch:
//   CORSO_ALLOW_LIVE_CONFIG=YES

'use strict';

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const bundleDir = path.join(root, process.argv[2] || 'dist-pages');

// A Supabase JWT or a service-role marker. anon keys are also JWTs, so we only
// flag the service-role marker plus obvious secret env-var names — the anon key
// is public-safe by design and lives in config at launch time.
const SERVICE_ROLE_PATTERN = /SUPABASE_SERVICE_ROLE_KEY|service_role[_-]?key/i;
const liveOverride = process.env.CORSO_ALLOW_LIVE_CONFIG === 'YES';

function fail(msg) {
  console.error('✗ pre-deploy safety check FAILED');
  console.error('  ' + msg);
  console.error('\nRefusing to deploy. Fix the bundle, or set CORSO_ALLOW_LIVE_CONFIG=YES only for an approved live launch.');
  process.exit(1);
}

if (!fs.existsSync(bundleDir)) {
  fail('bundle directory not found: ' + bundleDir + ' (run `npm run build:cloudflare` first)');
}

// 1. config.js in the bundle must be demo-locked.
const configPath = path.join(bundleDir, 'config.js');
if (!fs.existsSync(configPath)) {
  fail('config.js missing from the bundle');
}
const configText = fs.readFileSync(configPath, 'utf8');
const demoLocked =
  /demoMode:\s*true/.test(configText) &&
  /syncEnabled:\s*false/.test(configText) &&
  /liveDataMode:\s*false/.test(configText) &&
  /supabaseUrl:\s*['"]{2}/.test(configText) &&
  /supabaseAnonKey:\s*['"]{2}/.test(configText);

if (!demoLocked && !liveOverride) {
  fail('bundled config.js is not demo-locked (need demoMode:true, syncEnabled:false, liveDataMode:false, empty supabaseUrl/anonKey)');
}

// 2. No service-role credential anywhere in the bundle.
function walk(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) { out.push(...walk(full)); }
    else if (/\.(js|html|css|json|webmanifest)$/i.test(entry.name)) { out.push(full); }
  }
  return out;
}

const flagged = walk(bundleDir).filter((file) =>
  SERVICE_ROLE_PATTERN.test(fs.readFileSync(file, 'utf8'))
);

if (flagged.length) {
  fail('service-role credential marker found in bundle files:\n    ' +
    flagged.map((f) => path.relative(bundleDir, f)).join('\n    '));
}

const configNote = demoLocked
  ? 'config demo-locked'
  : 'config override accepted via CORSO_ALLOW_LIVE_CONFIG=YES';
console.log('✓ pre-deploy safety check passed — ' + configNote + ', no service-role markers in ' + path.basename(bundleDir));
