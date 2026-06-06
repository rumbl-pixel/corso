// src/kiosk/kiosk.js
// Tablet-optimized self-scan kiosk. Uses the shared RunClubScan module so lap
// logging behaves identically to the admin dashboard scanner.
//
// Design goals (locked-down kid/volunteer-friendly station):
//  - One job: scan a card to log a lap.
//  - Hidden input always refocused so Bluetooth (HID) scanners "just beep & go".
//  - Big high-contrast green/red feedback with name + lap number.
//  - Auto-reset to "Ready to scan" after a couple of seconds.
//  - Idle attract state after inactivity.
//  - Admin-gated entry so kiosk mode stays a staff/volunteer tool.
(function () {
  'use strict';

  function getAdminSession() {
    try { return JSON.parse(localStorage.getItem('runClubAdminSession')); }
    catch (e) { return null; }
  }

  if (!getAdminSession()) {
    window.location.href = 'admin.html';
    return;
  }

  var Scan = window.RunClubScan;
  var input = document.getElementById('kiosk-scan-input');
  var banner = document.getElementById('kiosk-banner');
  var bannerTitle = document.getElementById('kiosk-banner-title');
  var bannerSub = document.getElementById('kiosk-banner-sub');
  var sessionLabel = document.getElementById('kiosk-session');
  var lastScanLabel = document.getElementById('kiosk-last-scan');
  var lapCountLabel = document.getElementById('kiosk-lap-count');
  var undoBtn = document.getElementById('kiosk-undo');
  var cameraBtn = document.getElementById('camera-scan-btn');
  var cameraPanel = document.getElementById('camera-scan-panel');
  var cameraPreview = document.getElementById('camera-preview');
  var cameraStatus = document.getElementById('camera-scan-status');

  var PRAISE_MESSAGES = [
    'Great pace',
    'Strong running',
    'Keep moving',
    'Brilliant effort',
    'Nice lap',
    'You are building momentum'
  ];
  var sessionLaps = 0;
  var lastResult = null;
  var resetTimer = null;
  var idleTimer = null;
  var cameraStream = null;
  var cameraTimer = null;
  var barcodeDetector = null;
  var lastCameraCode = '';
  var lastCameraScanAt = 0;

  sessionLabel.textContent = 'Session: Run Club — ' + new Date().toISOString().slice(0, 10);

  function setBanner(state, title, sub) {
    banner.className = 'kiosk-banner kiosk-banner--' + state;
    bannerTitle.textContent = title;
    bannerSub.textContent = sub || '';
  }

  function ready() {
    setBanner('ready', 'Ready to scan', 'Hold your barcode under the scanner');
  }

  function attract() {
    setBanner('attract', 'Tap to start', 'Scan your card to log a lap');
  }

  function scheduleReset() {
    if (resetTimer) clearTimeout(resetTimer);
    resetTimer = setTimeout(ready, 2500);
  }

  function scheduleIdle() {
    if (idleTimer) clearTimeout(idleTimer);
    idleTimer = setTimeout(attract, 45000);
  }

  function handleScan(value) {
    var res = Scan.logLap(value);
    if (res.success) {
      lastResult = res;
      sessionLaps += 1;
      var s = res.student;
      var praise = PRAISE_MESSAGES[sessionLaps % PRAISE_MESSAGES.length];
      var sub = praise + ' • Lap ' + s.laps + ' • ' + s.km.toFixed(2) + ' km';
      if (res.milestone) { sub += ' • 🏅 ' + res.milestone + ' milestone!'; }
      setBanner('success', '✓ Lap logged for ' + s.name, sub);
      lastScanLabel.textContent = 'Last: ' + s.name + ' at ' + new Date().toLocaleTimeString();
      lapCountLabel.textContent = 'Laps this session: ' + sessionLaps;
      undoBtn.hidden = false;
    } else {
      lastResult = null;
      setBanner('error', '! ' + (res.error || 'Scan error'), 'Please try again or see a teacher');
    }
    scheduleReset();
    scheduleIdle();
  }

  function stopCameraScan() {
    if (cameraTimer) {
      clearInterval(cameraTimer);
      cameraTimer = null;
    }
    if (cameraStream) {
      cameraStream.getTracks().forEach(function (track) { track.stop(); });
      cameraStream = null;
    }
    cameraPreview.srcObject = null;
    cameraPanel.hidden = true;
    cameraBtn.textContent = 'Tap to start camera scan';
    input.focus();
  }

  function handleCameraCodes(codes) {
    if (!codes || !codes.length) { return; }
    var code = String(codes[0].rawValue || '').trim();
    var now = Date.now();
    if (!code || (code === lastCameraCode && now - lastCameraScanAt < 1800)) { return; }
    lastCameraCode = code;
    lastCameraScanAt = now;
    cameraStatus.textContent = 'Scanned ' + code;
    handleScan(code);
  }

  async function startCameraScan() {
    if (!('mediaDevices' in navigator) || !navigator.mediaDevices.getUserMedia) {
      cameraStatus.textContent = 'Camera scanning is not available in this browser.';
      cameraPanel.hidden = false;
      return;
    }
    if (!('BarcodeDetector' in window)) {
      cameraStatus.textContent = 'This browser does not support camera barcode scanning yet. Use a Bluetooth scanner or Chrome on Android.';
      cameraPanel.hidden = false;
      return;
    }
    try {
      barcodeDetector = new BarcodeDetector({ formats: ['code_39', 'code_128', 'qr_code', 'ean_13', 'upc_a'] });
      cameraStream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' }, audio: false });
      cameraPreview.srcObject = cameraStream;
      await cameraPreview.play();
      cameraPanel.hidden = false;
      cameraBtn.textContent = 'Stop camera scan';
      cameraStatus.textContent = 'Point the camera at a student barcode.';
      cameraTimer = setInterval(async function () {
        if (!barcodeDetector || cameraPreview.readyState < 2) { return; }
        try {
          handleCameraCodes(await barcodeDetector.detect(cameraPreview));
        } catch (e) {
          cameraStatus.textContent = 'Camera scan paused. Try again or use the Bluetooth scanner.';
        }
      }, 350);
    } catch (e) {
      cameraStatus.textContent = 'Camera permission was not granted or the camera could not start.';
      cameraPanel.hidden = false;
    }
  }

  // Undo last lap (in case of a wrong card scan).
  undoBtn.addEventListener('click', function () {
    if (!lastResult || !lastResult.student) { return; }
    if (!confirm('Undo last lap for ' + lastResult.student.name + '?')) { return; }
    var students = Scan.getStudents();
    var st = students.find(function (x) { return x.id === lastResult.student.id; });
    if (st && st.laps > 0) {
      st.laps -= 1;
      Scan.saveStudents(students);
      sessionLaps = Math.max(0, sessionLaps - 1);
      lapCountLabel.textContent = 'Laps this session: ' + sessionLaps;
    }
    lastResult = null;
    undoBtn.hidden = true;
    ready();
    input.focus();
  });

  // Exit back to the home page. Kiosk entry remains admin-gated.
  document.getElementById('kiosk-exit').addEventListener('click', function () {
    stopCameraScan();
    window.location.href = 'index.html';
  });

  cameraBtn.addEventListener('click', function () {
    if (cameraStream) { stopCameraScan(); }
    else { startCameraScan(); }
  });

  banner.addEventListener('click', function () {
    if (!cameraStream) { startCameraScan(); }
  });

  // Keep the hidden input focused so hardware scanners always land here.
  document.addEventListener('click', function () { input.focus(); });
  window.addEventListener('focus', function () { input.focus(); });

  Scan.bindScannerInput(input, handleScan, { debounceMs: 120, autoRefocus: true });

  ready();
  scheduleIdle();
})();
