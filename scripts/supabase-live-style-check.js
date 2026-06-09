const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');

function createLocalStorage() {
  const store = new Map();
  return {
    getItem(key) {
      return store.has(key) ? store.get(key) : null;
    },
    setItem(key, value) {
      store.set(key, String(value));
    }
  };
}

function requireEnv(name, aliases = []) {
  const value = [name].concat(aliases).map((key) => process.env[key]).find(Boolean);
  if (!value) {
    throw new Error(`Missing ${name}`);
  }
  return value;
}

async function main() {
  const supabaseUrl = requireEnv('SUPABASE_URL');
  const supabaseAnonKey = requireEnv('SUPABASE_ANON_KEY');
  const schoolId = requireEnv('RUN_CLUB_SCHOOL_ID', ['SUPABASE_SCHOOL_ID']);

  const window = {
    RUN_CLUB_CONFIG: {
      demoMode: false,
      syncEnabled: true,
      schoolId,
      supabaseUrl,
      supabaseAnonKey,
      endpoints: {
        studentAuth: process.env.SUPABASE_STUDENT_AUTH_URL || ''
      }
    },
    localStorage: createLocalStorage(),
    fetch
  };

  vm.runInNewContext(fs.readFileSync(path.join(root, 'backend.js'), 'utf8'), { window });

  const result = await window.RunClubBackend.liveStyleSupabaseCheck({
    studentCode: process.env.RUN_CLUB_STUDENT_CHECK_CODE || 'DEMO-CHECK',
    edgeFunction: process.env.RUN_CLUB_EDGE_FUNCTION || 'student_auth'
  });

  const safeResult = {
    ok: result.ok,
    rest: result.rest,
    edge: result.edge && {
      ok: result.edge.ok,
      status: result.edge.status,
      kind: result.edge.kind,
      error: result.edge.error
    }
  };
  console.log(JSON.stringify(safeResult, null, 2));
  if (!result.ok) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error.message);
  console.error('Required: SUPABASE_URL, SUPABASE_ANON_KEY, RUN_CLUB_SCHOOL_ID or SUPABASE_SCHOOL_ID.');
  console.error('Optional: SUPABASE_STUDENT_AUTH_URL, RUN_CLUB_STUDENT_CHECK_CODE, RUN_CLUB_EDGE_FUNCTION.');
  process.exitCode = 1;
});
