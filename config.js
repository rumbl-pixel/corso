// Safe public demo configuration.
// Do not put private keys or service-role credentials in browser-delivered files.
window.RUN_CLUB_CONFIG = {
  demoMode: true,
  betaShareMode: true,
  betaShareMessage: 'Demo beta only. No real student data. Production use needs school approval, live staff accounts, and backend readiness.',
  syncEnabled: false,
  liveDataMode: false,
  schoolId: '',
  siteCode: '',
  schoolSites: {},
  authUsernameDomain: 'corso.local',
  supabaseUrl: '',
  supabaseAnonKey: '',
  endpoints: {
    studentAuth: '',
    csvImport: ''
  }
};
