(function () {
  'use strict';

  if (!('serviceWorker' in navigator)) { return; }
  if (!/^https?:$/.test(window.location.protocol)) { return; }

  window.addEventListener('load', function () {
    navigator.serviceWorker.register('service-worker.js').catch(function () {
      // The app remains usable if a browser blocks service workers.
    });
  });
})();
