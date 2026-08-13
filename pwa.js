(function () {
  'use strict';

  // Load the optional athletics coaching library on dashboard pages. It enhances
  // the existing Coach Hub workout builder and safely no-ops elsewhere.
  if (document.getElementById('training-library-list')) {
    var athletics = document.createElement('script');
    athletics.src = 'athletics-drill-library.js?v=1';
    athletics.defer = true;
    document.head.appendChild(athletics);
  }

  if (!('serviceWorker' in navigator)) { return; }
  if (!/^https?:$/.test(window.location.protocol)) { return; }

  window.addEventListener('load', function () {
    navigator.serviceWorker.register('service-worker.js').catch(function () {
      // The app remains usable if a browser blocks service workers.
    });
  });
})();
