(function () {
  'use strict';

  // Load the optional athletics coaching library on dashboard pages. It enhances
  // the existing Coach Hub workout builder and safely no-ops elsewhere.
  if (document.getElementById('training-library-list')) {
    var athletics = document.createElement('script');
    athletics.src = 'athletics-drill-library.js?v=2';
    athletics.defer = true;
    athletics.onload = function () {
      var equipment = document.createElement('script');
      equipment.src = 'athletics-equipment.js?v=1';
      equipment.defer = true;
      document.head.appendChild(equipment);
    };
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
