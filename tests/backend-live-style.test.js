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

function createBackend(fetchImpl, endpoints = {}) {
  const window = {
    RUN_CLUB_CONFIG: {
      demoMode: false,
      syncEnabled: true,
      schoolId: 'school-live-style',
      supabaseUrl: 'https://example.supabase.co/',
      supabaseAnonKey: 'anon-live-style',
      endpoints
    },
    localStorage: createLocalStorage(),
    fetch: fetchImpl
  };
  vm.runInNewContext(fs.readFileSync(path.join(root, 'backend.js'), 'utf8'), { window });
  return window.RunClubBackend;
}

function response(status, body) {
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText: status === 200 ? 'OK' : 'Error',
    text: () => Promise.resolve(body == null ? '' : JSON.stringify(body))
  };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

(async () => {
  const calls = [];
  const backend = createBackend((url, options) => {
    calls.push({ url, options });
    if (url.includes('/rest/v1/students')) {
      return Promise.resolve(response(200, [{
        id: 'student-1',
        barcode: 'STAGING1',
        first_name: 'Staging',
        last_name: 'Student',
        year_group: 5,
        class_name: '5A',
        lap_count: 8
      }]));
    }
    if (url.includes('/functions/v1/student_auth')) {
      return Promise.resolve(response(200, { ok: true, student_id: 'student-1', dry_run: true }));
    }
    return Promise.resolve(response(404, { error: 'missing route' }));
  });

  assert(typeof backend.callEdgeFunction === 'function', 'backend should expose callEdgeFunction for Supabase Edge Functions');
  assert(typeof backend.liveStyleSupabaseCheck === 'function', 'backend should expose a live-style Supabase check');

  const edge = await backend.callEdgeFunction('student_auth', { code: 'DEMO-CHECK' });
  assert(edge.ok === true, 'edge function call should resolve successful responses');
  assert(edge.data.student_id === 'student-1', 'edge function call should parse response data');
  assert(calls[0].url === 'https://example.supabase.co/functions/v1/student_auth', 'edge function should use Supabase functions URL by default');
  assert(calls[0].options.method === 'POST', 'edge function should POST JSON payloads');
  assert(calls[0].options.headers.apikey === 'anon-live-style', 'edge function should use anon key header');
  assert(calls[0].options.headers.Authorization === 'Bearer anon-live-style', 'edge function should use bearer anon auth');
  assert(calls[0].options.headers['X-School-Id'] === 'school-live-style', 'edge function should send school scope header');
  assert(JSON.parse(calls[0].options.body).school_id === 'school-live-style', 'edge payload should include school id');

  const check = await backend.liveStyleSupabaseCheck({ studentCode: 'DEMO-CHECK' });
  assert(check.ok === true, 'live-style check should pass when REST and Edge Function probes pass');
  assert(check.rest.ok === true && check.rest.count === 1, 'live-style check should verify Supabase REST student access');
  assert(check.edge.ok === true, 'live-style check should verify Supabase Edge Function access');
  assert(calls.some((call) => call.url.includes('/rest/v1/students')), 'live-style check should call Supabase REST');
  assert(calls.some((call) => call.url.includes('/functions/v1/student_auth')), 'live-style check should call a Supabase Edge Function');

  const customCalls = [];
  const customBackend = createBackend((url, options) => {
    customCalls.push({ url, options });
    return Promise.resolve(response(200, { ok: true }));
  }, { studentAuth: 'https://functions.example.test/student_auth' });
  await customBackend.callEdgeFunction('studentAuth', { code: 'CUSTOM' });
  assert(customCalls[0].url === 'https://functions.example.test/student_auth', 'edge function should honour configured endpoint aliases');

  console.log('backend live-style checks passed');
})();
