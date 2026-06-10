(function () {
  'use strict';

  var STORAGE_KEY = 'gp_run_club_theme';
  var root = document.documentElement;
  var savedTheme = localStorage.getItem(STORAGE_KEY);
  var activeTheme = savedTheme === 'dark' ? 'dark' : 'light';

  function applyTheme(theme) {
    activeTheme = theme === 'dark' ? 'dark' : 'light';
    root.setAttribute('data-theme', activeTheme);
    localStorage.setItem(STORAGE_KEY, activeTheme);
    updateToggle();
  }

  function updateToggle() {
    var toggle = document.querySelector('[data-theme-toggle]');
    if (!toggle) { return; }
    var isDark = activeTheme === 'dark';
    toggle.setAttribute('aria-pressed', String(isDark));
    toggle.setAttribute('aria-label', isDark ? 'Switch to light mode' : 'Switch to dark mode');
    toggle.querySelector('[data-theme-toggle-thumb]').textContent = isDark ? '☾' : '☀';
  }

  root.setAttribute('data-theme', activeTheme);

  document.addEventListener('DOMContentLoaded', function () {
    if (document.body.classList.contains('page-kiosk')) { return; }

    var header = document.querySelector('.site-header');
    var headerInner = document.querySelector('.site-header .header-inner');
    if (!header || !headerInner) { return; }

    if (!document.querySelector('[data-theme-toggle]')) {
      var toggle = document.createElement('button');
      toggle.type = 'button';
      toggle.className = 'theme-toggle';
      toggle.setAttribute('data-theme-toggle', '');
      toggle.innerHTML = '<span class="theme-toggle-track"><span data-theme-toggle-thumb class="theme-toggle-thumb">☀</span></span>';
      toggle.addEventListener('click', function () {
        applyTheme(activeTheme === 'dark' ? 'light' : 'dark');
      });
      headerInner.appendChild(toggle);
    }

    if (!document.querySelector('[data-mobile-menu-toggle]')) {
      var menuToggle = document.createElement('button');
      menuToggle.type = 'button';
      menuToggle.className = 'mobile-menu-toggle';
      menuToggle.setAttribute('data-mobile-menu-toggle', '');
      menuToggle.setAttribute('aria-expanded', 'false');
      menuToggle.setAttribute('aria-label', 'Open menu');
      menuToggle.innerHTML = '<span></span><span></span><span></span>';
      menuToggle.addEventListener('click', function () {
        var open = !document.body.classList.contains('mobile-nav-open');
        document.body.classList.toggle('mobile-nav-open', open);
        menuToggle.setAttribute('aria-expanded', String(open));
        menuToggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
      });
      headerInner.appendChild(menuToggle);
    }

    function updateCompactHeader() {
      var scrollProgress = Math.max(0, Math.min(1, window.scrollY / 132));
      var isPhone = window.matchMedia && window.matchMedia('(max-width: 640px)').matches;
      var start = isPhone ? {
        top: 0.75,
        bottom: 1,
        innerTop: 3,
        gap: 0.75,
        logo: 64,
        title: 1.2
      } : {
        top: 1,
        bottom: 1.25,
        innerTop: 0,
        gap: 0.75,
        logo: 86,
        title: 1.4
      };
      var end = isPhone ? {
        top: 0.45,
        bottom: 0.45,
        innerTop: 0,
        gap: 0.5,
        logo: 40,
        title: 0.95
      } : {
        top: 0.45,
        bottom: 0.45,
        innerTop: 0,
        gap: 0.65,
        logo: 44,
        title: 1.05
      };
      function mix(a, b) { return a + ((b - a) * scrollProgress); }
      root.style.setProperty('--header-pad-top', mix(start.top, end.top).toFixed(3) + 'rem');
      root.style.setProperty('--header-pad-bottom', mix(start.bottom, end.bottom).toFixed(3) + 'rem');
      root.style.setProperty('--header-inner-pad-top', mix(start.innerTop, end.innerTop).toFixed(3) + 'rem');
      root.style.setProperty('--header-gap', mix(start.gap, end.gap).toFixed(3) + 'rem');
      root.style.setProperty('--header-logo-size', Math.round(mix(start.logo, end.logo)) + 'px');
      root.style.setProperty('--header-title-size', mix(start.title, end.title).toFixed(3) + 'rem');
      root.style.setProperty('--header-tagline-max', (2.8 * (1 - scrollProgress)).toFixed(3) + 'rem');
      root.style.setProperty('--header-tagline-margin', (0.5 * (1 - scrollProgress)).toFixed(3) + 'rem');
      root.style.setProperty('--header-tagline-opacity', (0.88 * (1 - scrollProgress)).toFixed(3));
      root.style.setProperty('--header-tagline-y', (-4 * scrollProgress).toFixed(1) + 'px');
      var currentlyCompact = document.body.classList.contains('mobile-header-compact');
      var compact = currentlyCompact ? window.scrollY > 32 : window.scrollY > 132;
      document.body.classList.toggle('mobile-header-compact', compact);
      if (!compact && document.body.classList.contains('mobile-nav-open')) {
        document.body.classList.remove('mobile-nav-open');
        var btn = document.querySelector('[data-mobile-menu-toggle]');
        if (btn) {
          btn.setAttribute('aria-expanded', 'false');
          btn.setAttribute('aria-label', 'Open menu');
        }
      }
    }

    var scrollQueued = false;
    function requestCompactHeaderUpdate() {
      if (scrollQueued) { return; }
      scrollQueued = true;
      window.requestAnimationFrame(function () {
        scrollQueued = false;
        updateCompactHeader();
      });
    }

    window.addEventListener('scroll', requestCompactHeaderUpdate, { passive: true });
    window.addEventListener('resize', updateCompactHeader);
    updateCompactHeader();
    updateToggle();
  });
})();
