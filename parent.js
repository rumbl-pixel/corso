// Parent portal: read-only progress view.
(function () {
  'use strict';

  var Scan = window.RunClubScan;
  var Goals = window.RunClubGoals;
  var currentStudent = null;
  var MILESTONE_LABELS = { 5: 'First 5 Laps', 10: '10 Lap Club', 25: 'Quarter Century', 50: 'Half Century', 100: 'Century Club', 200: 'Double Century', 500: 'Elite Runner' };

  function findStudent(code) {
    var c = String(code || '').trim().toUpperCase();
    if (c === 'DEMO') {
      return Scan.getStudents()[0] || null;
    }
    return Scan.getStudents().find(function (s) {
      return s.id.toUpperCase() === c || (s.barcode && s.barcode.toUpperCase() === c);
    });
  }

  function renderStats(student) {
    var km = Scan.lapsToKm(student.laps).toFixed(2);
    var totalKm = Scan.totalKm(student).toFixed(2);
    document.getElementById('parent-athlete-name').textContent = student.name;
    document.getElementById('parent-athlete-stats').innerHTML =
      '<div class="stat-box"><div class="stat-value">' + student.laps + '</div><div class="stat-label">Laps</div></div>' +
      '<div class="stat-box"><div class="stat-value">' + km + '</div><div class="stat-label">Track km</div></div>' +
      '<div class="stat-box"><div class="stat-value">' + totalKm + '</div><div class="stat-label">Total km</div></div>' +
      '<div class="stat-box"><div class="stat-value">' + student.cls + '</div><div class="stat-label">Class</div></div>';
  }

  function renderAwards(student) {
    var earned = Scan.MILESTONES.filter(function (m) { return student.laps >= m; });
    document.getElementById('parent-awards').innerHTML = earned.length
      ? earned.map(function (m) { return '<span class="award-badge">&#127942; ' + (MILESTONE_LABELS[m] || (m + ' laps')) + '</span>'; }).join('')
      : '<p style="color:#888;font-size:0.85rem;">No awards yet. The first milestone is 5 laps.</p>';
  }

  function printParentCertificate() {
    if (!currentStudent) { return; }
    var earned = Scan.MILESTONES.filter(function (m) { return currentStudent.laps >= m; });
    var awardCopy = earned.length
      ? earned.map(function (m) { return '<span class="badge">&#127942; ' + (MILESTONE_LABELS[m] || (m + ' laps')) + '</span>'; }).join('')
      : '<p>Keep running toward the first 5 lap milestone.</p>';
    var win = window.open('', '_blank');
    if (!win) { return; }
    var html = '<html><head><title>' + currentStudent.name + ' Award Certificate</title><style>body{font-family:Arial,sans-serif;padding:2rem;color:#102a43;}.cert{border:4px solid #f59e0b;padding:2.5rem;text-align:center;min-height:70vh;display:flex;flex-direction:column;align-items:center;justify-content:center;}h1{color:#0c5aa8;font-size:2.4rem;margin:0 0 0.5rem;}h2{font-size:2rem;margin:0.4rem 0;}.badge{display:inline-block;padding:0.35rem 0.8rem;border-radius:999px;background:#fff8e1;border:1px solid #f59e0b;margin:0.25rem;font-size:0.95rem;}@media print{@page{margin:1cm;}}</style></head><body>';
    html += '<div class="cert"><h1>Gwynne Park Run Club</h1><p>Award Certificate</p><h2>' + currentStudent.name + '</h2><p>' + currentStudent.year + ' / Class ' + currentStudent.cls + '</p><p>Total laps: <strong>' + currentStudent.laps + '</strong> (' + Scan.lapsToKm(currentStudent.laps).toFixed(2) + ' km)</p><div>' + awardCopy + '</div><p style="margin-top:1.5rem;color:#64748b;">Keep building momentum.</p></div>';
    html += '</body></html>';
    win.document.write(html);
    win.document.close();
    win.print();
  }

  function goalRow(goal) {
    var p = Goals.progress(currentStudent.id, goal);
    var info = Goals.metricInfo(goal.metric);
    var owner = goal.owner === 'coach' ? 'Coach' : 'Student';
    var current = p.current == null ? 'No result yet' : p.current + ' ' + goal.unit;
    var progressLabel = info.kind === 'cumulative' ? 'Since set' : 'Best';
    var status = p.met ? '<span class="award-badge">Achieved</span>' : '';
    return '<div class="goal-item">' +
      '<div class="goal-head"><strong>' + goal.title + '</strong> <span style="color:#888;font-size:0.78rem;">' + owner + '</span> ' + status + '</div>' +
      '<div class="goal-meta">Target: ' + goal.target + ' ' + goal.unit + ' · ' + progressLabel + ': ' + current + '</div>' +
      '<div class="goal-bar"><div class="goal-bar-fill" style="width:' + p.percent + '%"></div></div>' +
      '</div>';
  }

  function renderGoals(student) {
    var goals = Goals.goalsFor(student.id).filter(function (goal) { return Goals.isMetricVisible(goal.metric); });
    document.getElementById('parent-goals').innerHTML = goals.length
      ? goals.map(goalRow).join('')
      : '<p style="color:#888;font-size:0.85rem;">No goals have been set yet.</p>';
  }

  function render(student) {
    currentStudent = student;
    renderStats(student);
    renderAwards(student);
    renderGoals(student);
    document.getElementById('parent-result').hidden = false;
  }

  document.getElementById('parent-form').addEventListener('submit', function (e) {
    e.preventDefault();
    var errorEl = document.getElementById('parent-error');
    errorEl.textContent = '';
    var student = findStudent(document.getElementById('parent-code').value);
    if (!student) {
      errorEl.textContent = 'Code not recognised. Check the barcode card or ask the school.';
      return;
    }
    render(student);
  });

  document.getElementById('print-parent-certificate-btn').addEventListener('click', printParentCertificate);

})();
