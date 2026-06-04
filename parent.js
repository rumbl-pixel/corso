// Parent portal: read-only progress view plus home-activity submission.
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

  function goalRow(goal) {
    var p = Goals.progress(currentStudent.id, goal);
    var owner = goal.owner === 'coach' ? 'Coach' : 'Student';
    var current = p.current == null ? 'No result yet' : p.current + ' ' + goal.unit;
    var status = p.met ? '<span class="award-badge">Achieved</span>' : '';
    return '<div class="goal-item">' +
      '<div class="goal-head"><strong>' + goal.title + '</strong> <span style="color:#888;font-size:0.78rem;">' + owner + '</span> ' + status + '</div>' +
      '<div class="goal-meta">Target: ' + goal.target + ' ' + goal.unit + ' · Now: ' + current + '</div>' +
      '<div class="goal-bar"><div class="goal-bar-fill" style="width:' + p.percent + '%"></div></div>' +
      '</div>';
  }

  function renderGoals(student) {
    var goals = Goals.goalsFor(student.id);
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

})();
