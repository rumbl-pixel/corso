const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

function runCheck(label, command, args) {
  const resolved = resolveCommand(command, args);
  try {
    const output = execFileSync(resolved.command, resolved.args, {
      cwd: root,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe']
    }).trim();
    return { label, ok: true, detail: output.split(/\r?\n/)[0] || 'available' };
  } catch (error) {
    const message = [error.stderr, error.stdout, error.message].filter(Boolean).join(' ').trim();
    return { label, ok: false, detail: summarizeFailure(message) || 'not available' };
  }
}

function resolveCommand(command, args) {
  if (command === 'supabase-local') {
    return {
      command: process.execPath,
      args: [path.join(root, 'node_modules', 'supabase', 'dist', 'supabase.js')].concat(args)
    };
  }
  return { command, args };
}

function summarizeFailure(message) {
  if (/dockerDesktopLinuxEngine|daemon is running|failed to connect to the docker API/i.test(message)) {
    return 'Docker Desktop Linux engine is not running.';
  }
  if (/ENOENT/i.test(message)) {
    return 'command was not found on PATH.';
  }
  return message.split(/\r?\n/).find(Boolean) || message;
}

function hasEnv(name, aliases = []) {
  const key = [name].concat(aliases).find((candidate) => process.env[candidate]);
  return { label: name, ok: Boolean(key), detail: key ? `set via ${key}` : 'missing' };
}

function fileCheck(file) {
  const fullPath = path.join(root, file);
  return { label: file, ok: fs.existsSync(fullPath), detail: fs.existsSync(fullPath) ? 'present' : 'missing' };
}

function printRow(check) {
  const mark = check.ok ? 'OK ' : 'NO ';
  console.log(`${mark} ${check.label}: ${check.detail}`);
}

const checks = [
  runCheck('Supabase CLI', 'supabase-local', ['--version']), // supabase --version
  runCheck('Docker engine', 'docker', ['info']), // docker info
  fileCheck('supabase/config.toml'),
  fileCheck('supabase/seed.staging.sql'),
  fileCheck('docs/staging-coach-staff.sql'),
  hasEnv('SUPABASE_URL'),
  hasEnv('SUPABASE_ANON_KEY'),
  hasEnv('RUN_CLUB_SCHOOL_ID', ['SUPABASE_SCHOOL_ID'])
];

console.log('Corso staging readiness');
console.log('No secret values are printed by this check.\n');
checks.forEach(printRow);

const blockers = checks.filter((check) => !check.ok);
if (blockers.length) {
  console.log('\nNext fixes:');
  blockers.forEach((check) => {
    if (check.label === 'Docker engine') {
      console.log('- Start Docker Desktop and make sure the Linux engine is running before local Supabase commands.');
    } else if (check.label === 'Supabase CLI') {
      console.log('- Run npm install so the local Supabase CLI package is available through npx.');
    } else if (check.label === 'SUPABASE_URL') {
      console.log('- Set SUPABASE_URL to your hosted staging project URL.');
    } else if (check.label === 'SUPABASE_ANON_KEY') {
      console.log('- Set SUPABASE_ANON_KEY to the public anon key from Supabase API settings.');
    } else if (check.label === 'RUN_CLUB_SCHOOL_ID') {
      console.log('- Set RUN_CLUB_SCHOOL_ID to the staging school id from docs/supabase-staging-checklist.md.');
    } else {
      console.log(`- Restore or create ${check.label}.`);
    }
  });
  process.exitCode = 1;
}
