// admin.js
(function () {
  var cfg = window.RUN_CLUB_CONFIG || {};
  var form = document.getElementById('admin-login-form');
  var errorEl = document.getElementById('admin-error');
  var allowedRoles = ['owner','admin','coach'];

  function configured() {
    return !!(cfg.supabaseUrl && cfg.supabaseAnonKey && cfg.schoolId);
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

  function staffRoleFor(authData) {
    var user = authData && authData.user;
    if (!user || !user.id || !authData.access_token) {
      return Promise.reject(new Error('Could not confirm staff account.'));
    }
    var query = 'school_id=eq.' + encodeURIComponent(cfg.schoolId) +
      '&user_id=eq.' + encodeURIComponent(user.id) +
      '&role=in.(owner,admin,coach)' +
      '&select=school_id,role' +
      '&limit=1';
    return fetch(baseUrl() + '/rest/v1/school_users?' + query, {
      method: 'GET',
      headers: authHeaders(authData.access_token)
    }).then(parseJsonResponse).then(function (rows) {
      var role = Array.isArray(rows) && rows[0] ? rows[0].role : '';
      if (allowedRoles.indexOf(role) === -1) {
        throw new Error('This account has not been invited as school staff yet.');
      }
      return {
        email: user.email || '',
        mode: 'live',
        user_id: user.id,
        school_id: cfg.schoolId,
        role: role,
        access_token: authData.access_token,
        refresh_token: authData.refresh_token || '',
        expires_at: authData.expires_at || null
      };
    });
  }

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    errorEl.textContent = '';

    var email = document.getElementById('admin-email').value.trim();
    var password = document.getElementById('admin-password').value.trim();
    var demoBypass = email.toUpperCase() === 'DEMO' || password.toUpperCase() === 'DEMO';

    // Demo mode: skip real auth, store session, go to dashboard.
    if (demoBypass || cfg.demoMode !== false) {
      if (demoBypass && cfg.demoMode === false) {
        errorEl.textContent = 'Demo login is disabled for live mode.';
        return;
      }
      window.localStorage.setItem(
        'runClubAdminSession',
        JSON.stringify({ email: demoBypass ? 'DEMO' : email, mode: 'demo', access_token: 'demo-token' })
      );
      window.location.href = 'admin-dashboard.html';
      return;
    }

    if (!configured()) {
      errorEl.textContent = 'Live staff login needs Supabase URL, anon key, and school ID in config.js.';
      return;
    }

    signInWithSupabase(email, password)
      .then(staffRoleFor)
      .then(function (session) {
        window.localStorage.setItem('runClubAdminSession', JSON.stringify(session));
        window.location.href = 'admin-dashboard.html';
      })
      .catch(function (error) {
        errorEl.textContent = error && error.message ? error.message : 'Staff login failed.';
      });
  });
})();
