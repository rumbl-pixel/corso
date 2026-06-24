(function () {
  'use strict';

  var STORAGE_KEY = 'gp_run_club_theme';
  var BRANDING_KEY = 'rc_theme_settings';
  var DEFAULT_APP_TITLE = 'Corso';
  var DEFAULT_LOGO = 'assets/corso-logo.png';
  var DEFAULT_SCHOOL_BLUE = '#003880';
  var DEFAULT_UNIFORM_GOLD = '#c99722';
  var root = document.documentElement;
  var savedTheme = localStorage.getItem(STORAGE_KEY);
  var activeTheme = savedTheme === 'dark' ? 'dark' : 'light';

  function brandingSettings() {
    try {
      var saved = JSON.parse(localStorage.getItem(BRANDING_KEY) || '{}');
      var logoDataUrl = saved.logoDataUrl === 'assets/corso-logo.svg' ? DEFAULT_LOGO : saved.logoDataUrl;
      return {
        appTitle: String(saved.appTitle || DEFAULT_APP_TITLE).trim() || DEFAULT_APP_TITLE,
        schoolBlue: saved.schoolBlue || DEFAULT_SCHOOL_BLUE,
        uniformGold: saved.uniformGold || DEFAULT_UNIFORM_GOLD,
        logoDataUrl: logoDataUrl || DEFAULT_LOGO,
        logoName: saved.logoName || ''
      };
    } catch (error) {
      return { appTitle: DEFAULT_APP_TITLE, schoolBlue: DEFAULT_SCHOOL_BLUE, uniformGold: DEFAULT_UNIFORM_GOLD, logoDataUrl: DEFAULT_LOGO, logoName: '' };
    }
  }

  function applyBrandColors(settings) {
    root.style.setProperty('--school-blue', settings.schoolBlue);
    root.style.setProperty('--school-blue-2', 'color-mix(in srgb, ' + settings.schoolBlue + ' 86%, #ffffff 14%)');
    root.style.setProperty('--school-blue-3', 'color-mix(in srgb, ' + settings.schoolBlue + ' 76%, #ffffff 24%)');
    root.style.setProperty('--obsidian-navy', 'color-mix(in srgb, ' + settings.schoolBlue + ' 72%, #071426 28%)');
    root.style.setProperty('--obsidian-navy-2', 'color-mix(in srgb, ' + settings.schoolBlue + ' 56%, #071426 44%)');
    root.style.setProperty('--obsidian-navy-3', 'color-mix(in srgb, ' + settings.schoolBlue + ' 82%, #ffffff 18%)');
    root.style.setProperty('--uniform-gold', settings.uniformGold);
    root.style.setProperty('--uniform-gold-dark', 'color-mix(in srgb, ' + settings.uniformGold + ' 74%, #071426 26%)');
    root.style.setProperty('--uniform-gold-soft', 'color-mix(in srgb, ' + settings.uniformGold + ' 28%, transparent)');
    root.style.setProperty('--uniform-gold-wash', 'color-mix(in srgb, ' + settings.uniformGold + ' 10%, transparent)');
    root.style.setProperty('--uniform-gold-hover', 'color-mix(in srgb, ' + settings.uniformGold + ' 22%, transparent)');
    root.style.setProperty('--gold-glass-wash', 'color-mix(in srgb, ' + settings.uniformGold + ' 8%, transparent)');
    root.style.setProperty('--gold-glass-line', 'color-mix(in srgb, ' + settings.uniformGold + ' 34%, transparent)');
  }

  function replaceTextNode(parent, value) {
    var textNode = Array.prototype.find.call(parent.childNodes, function (node) {
      return node.nodeType === 3 && node.textContent.trim();
    });
    if (textNode) {
      textNode.textContent = value;
    } else {
      parent.appendChild(document.createTextNode(value));
    }
  }

  function applyBrandingSettings() {
    var settings = brandingSettings();
    applyBrandColors(settings);
    document.querySelectorAll('.brand h1').forEach(function (el) {
      el.textContent = settings.appTitle;
    });
    document.querySelectorAll('.brand-logo, .kiosk-brand-logo').forEach(function (img) {
      img.src = settings.logoDataUrl || DEFAULT_LOGO;
      img.alt = settings.logoName ? settings.appTitle + ' emblem' : 'Corso';
    });
    document.querySelectorAll('.kiosk-brand').forEach(function (el) {
      replaceTextNode(el, settings.appTitle);
    });
    if (document.title && /^Corso\b/.test(document.title) === false) { return; }
    if (document.title) {
      document.title = document.title.replace(/^Corso\b/, settings.appTitle);
    }
  }

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

  function renderBetaShareBanner() {
    var cfg = window.RUN_CLUB_CONFIG || {};
    var betaEnabled = cfg.betaShareMode !== false && (cfg.betaShareMode || cfg.demoMode !== false);
    if (!betaEnabled || document.querySelector('[data-beta-share-banner]')) { return; }
    var header = document.querySelector('.site-header');
    if (!header) { return; }
    var banner = document.createElement('div');
    banner.className = 'beta-share-banner';
    banner.setAttribute('data-beta-share-banner', '');
    banner.innerHTML = '<span class="beta-share-banner__status">Beta demo</span><span>' + (cfg.betaShareMessage || 'No real student data. Production use needs school approval and backend readiness.') + '</span>';
    header.insertAdjacentElement('afterend', banner);
  }

  function updateFeedbackLinks() {
    var page = (document.title || 'Corso page').replace(/\s+/g, ' ').trim();
    var path = window.location.pathname.split('/').pop() || 'index.html';
    document.querySelectorAll('.feature-suggestion-btn').forEach(function (link) {
      var subject = encodeURIComponent('Corso feedback - ' + page);
      var body = encodeURIComponent('Page: ' + path + '\nDevice/browser:\nWhat felt confusing or broken:\nSuggested improvement:\n');
      link.setAttribute('href', 'mailto:support@gwynneparkrunclub.com.au?subject=' + subject + '&body=' + body);
      if (/Feature Suggestion/i.test(link.textContent || '')) {
        link.textContent = 'Send Feedback';
      }
    });
  }

  root.setAttribute('data-theme', activeTheme);

  document.addEventListener('DOMContentLoaded', function () {
    applyBrandingSettings();
    updateFeedbackLinks();
    if (document.body.classList.contains('page-kiosk')) { return; }
    renderBetaShareBanner();

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

    document.body.classList.add('mobile-header-compact');
    updateToggle();
  });
})();
