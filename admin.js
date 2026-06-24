// admin.js
(function () {
  var cfg = window.RUN_CLUB_CONFIG || {};
  var form = document.getElementById('admin-login-form');
  var errorEl = document.getElementById('admin-error');
  var schoolStaffRole = 'coach';
  var defaultUsernameDomain = 'corso.local';
  var activeSchoolId = cfg.schoolId || '';

  function authConfigured() {
    return !!(cfg.supabaseUrl && cfg.supabaseAnonKey);
  }

  function baseUrl() {
    return String(cfg.supabaseUrl || '').replace(/\/+$/, '');
  }

  function authHeaders(token) {
    return {
      apikey: cfg.supabaseAnonKey,
      Authorization: 'Bearer ' + (token || cfg.supabaseAnonKey),
      'Content-Type': 'application/json'
    };
  }

  function parseJsonResponse(response) {
    return response.text().then(function (text) {
      var data = text ? JSON.parse(text) : {};
      if (!response.ok) {
        var message = data.error_description || data.msg || data.message || response.statusText || 'Request failed';
        throw new Error(message);
      }
      return data;
    });
  }

  function signInWithSupabase(email, password) {
    return fetch(baseUrl() + '/auth/v1/token?grant_type=password', {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ email: email, password: password })
    }).then(parseJsonResponse);
  }

  function loginIdentifierToAuthEmail(identifier) {
    var value = String(identifier || '').trim();
    if (value.indexOf('@') !== -1) {
      return value.toLowerCase();
    }
    var username = value.toLowerCase().replace(/[^a-z0-9._-]+/g, '');
    var domain = String(cfg.authUsernameDomain || defaultUsernameDomain).trim().replace(/^@+/, '').toLowerCase();
    if (!username || !domain) { return ''; }
    return username + '@' + domain;
  }

  function siteCodeFromInput(value) {
    return String(value || '').replace(/\D+/g, '').slice(0, 4);
  }

  function resolveSchoolIdForSite(siteCode) {
    var schoolsBySite = cfg.schoolSites || {};
    if (siteCode && schoolsBySite[siteCode]) {
      return schoolsBySite[siteCode];
    }
    if (siteCode && cfg.siteCode && siteCode === String(cfg.siteCode) && cfg.schoolId) {
      return cfg.schoolId;
    }
    if (!cfg.siteCode && (!schoolsBySite || Object.keys(schoolsBySite).length === 0) && cfg.schoolId) {
      return cfg.schoolId;
    }
    return '';
  }

  function platformAdminFor(authData, loginIdentifier, siteCode) {
    var user = authData && authData.user;
    if (!user || !user.id || !authData.access_token) {
      return Promise.resolve(null);
    }
    var query = 'user_id=eq.' + encodeURIComponent(user.id) +
      '&active=eq.true' +
      '&select=user_id,role,active' +
      '&limit=1';
    return fetch(baseUrl() + '/rest/v1/platform_admins?' + query, {
      method: 'GET',
      headers: authHeaders(authData.access_token)
    }).then(parseJsonResponse).then(function (rows) {
      if (!Array.isArray(rows) || !rows[0]) { return null; }
      return {
        email: user.email || '',
        username: loginIdentifier || '',
        mode: 'live',
        access_scope: 'platform',
        user_id: user.id,
        school_id: activeSchoolId || '',
        site_code: siteCode || '',
        role: 'platform_admin',
        platform_role: rows[0].role || 'platform_admin',
        access_token: authData.access_token,
        refresh_token: authData.refresh_token || '',
        expires_at: authData.expires_at || null
      };
    });
  }

  function staffRoleFor(authData, loginIdentifier, siteCode) {
    var user = authData && authData.user;
    if (!user || !user.id || !authData.access_token) {
      return Promise.reject(new Error('Could not confirm staff account.'));
    }
    if (!activeSchoolId) {
      return Promise.reject(new Error('Coach login needs a valid 4-digit Site code so access can stay school-scoped.'));
    }
    var query = 'school_id=eq.' + encodeURIComponent(activeSchoolId) +
      '&user_id=eq.' + encodeURIComponent(user.id) +
      '&role=eq.' + schoolStaffRole +
      '&select=school_id,role' +
      '&limit=1';
    return fetch(baseUrl() + '/rest/v1/school_users?' + query, {
      method: 'GET',
      headers: authHeaders(authData.access_token)
    }).then(parseJsonResponse).then(function (rows) {
      var role = Array.isArray(rows) && rows[0] ? rows[0].role : '';
      if (role !== schoolStaffRole) {
        throw new Error('This account has not been invited as a coach for this school yet.');
      }
      return {
        email: user.email || '',
        username: loginIdentifier || '',
        mode: 'live',
        access_scope: 'school',
        user_id: user.id,
        school_id: activeSchoolId,
        site_code: siteCode || '',
        role: schoolStaffRole,
        access_token: authData.access_token,
        refresh_token: authData.refresh_token || '',
        expires_at: authData.expires_at || null
      };
    });
  }

  function liveRoleFor(authData, loginIdentifier, siteCode) {
    return platformAdminFor(authData, loginIdentifier, siteCode).then(function (platformSession) {
      return platformSession || staffRoleFor(authData, loginIdentifier, siteCode);
    });
  }

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    errorEl.textContent = '';

    var siteCode = siteCodeFromInput(document.getElementById('admin-site-code').value);
    var loginIdentifier = document.getElementById('admin-username').value.trim();
    var password = document.getElementById('admin-password').value.trim();
    var demoBypass = loginIdentifier.toUpperCase() === 'DEMO' || password.toUpperCase() === 'DEMO';
    activeSchoolId = resolveSchoolIdForSite(siteCode);

    // Demo mode: skip real auth, store session, go to dashboard.
    if (demoBypass || cfg.demoMode !== false) {
      if (demoBypass && cfg.demoMode === false) {
        errorEl.textContent = 'Demo login is disabled for live mode.';
        return;
      }
      window.localStorage.setItem(
        'runClubAdminSession',
        JSON.stringify({ email: demoBypass ? 'DEMO' : loginIdentifier, username: demoBypass ? 'DEMO' : loginIdentifier, mode: 'demo', access_scope: 'demo', role: 'demo', school_id: activeSchoolId || 'demo-local', site_code: siteCode || 'DEMO', access_token: 'demo-token' })
      );
      window.location.href = 'admin-dashboard.html';
      return;
    }

    if (!authConfigured()) {
      errorEl.textContent = 'Live staff login needs Supabase URL and anon key in config.js.';
      return;
    }

    if (!/^\d{4}$/.test(siteCode)) {
      errorEl.textContent = 'Enter your 4-digit Site code.';
      return;
    }

    if (!activeSchoolId) {
      errorEl.textContent = 'That Site code is not configured for this Corso login yet.';
      return;
    }

    var authEmail = loginIdentifierToAuthEmail(loginIdentifier);
    if (!authEmail) {
      errorEl.textContent = 'Enter your assigned staff username.';
      return;
    }

    signInWithSupabase(authEmail, password)
      .then(function (authData) { return liveRoleFor(authData, loginIdentifier, siteCode); })
      .then(function (session) {
        window.localStorage.setItem('runClubAdminSession', JSON.stringify(session));
        window.location.href = 'admin-dashboard.html';
      })
      .catch(function (error) {
        errorEl.textContent = error && error.message ? error.message : 'Staff login failed.';
      });
  });
})();
