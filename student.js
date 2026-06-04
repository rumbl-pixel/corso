// student.js
// Student portal: login + profile + awards + goals (self-set & coach-assigned) + home activity.
// Local-first: uses the shared RunClubScan roster so student IDs and laps match
// the admin dashboard and kiosk. Goals come from RunClubGoals.
(function () {
  'use strict';

  var Scan = window.RunClubScan;
  var Goals = window.RunClubGoals;

  var MILESTONE_LABELS = { 5: 'First 5 Laps', 10: '10 Lap Club', 25: 'Quarter Century', 50: 'Half Century', 100: 'Century Club', 200: 'Double Century', 500: 'Elite Runner' };

  var currentStudent = null;

  // --- Login: look up the code against the shared roster ---
  function findStudent(code) {
    var c = String(code || '').trim().toUpperCase();
    return Scan.getStudents().find(function (s) {
      return s.id.toUpperCase() === c || (s.barcode && s.barcode.toUpperCase() === c);
    });
  }

  function renderAthlete(s) {
    var km = Scan.lapsToKm(s.laps).toFixed(2);
    document.getElementById('athlete-name').textContent = '🏃 ' + s.name;

    // Compute simple ranks from the roster.
    var roster = Scan.getStudents().slice().sort(function (a, b) { return b.laps - a.laps; });
    var schoolRank = roster.findIndex(function (x) { return x.id === s.id; }) + 1;
    var classmates = roster.filter(function (x) { return x.cls === s.cls; });
    var classRank = classmates.findIndex(function (x) { return x.id === s.id; }) + 1;

    document.getElementById('athlete-stats').innerHTML =
      '<div class="stat-box"><div class="stat-value">' + s.laps + '</div><div class="stat-label">Laps</div></div>' +
      '<div class="stat-box"><div class="stat-value">' + km + '</div><div class="stat-label">Km</div></div>' +
      '<div class="stat-box"><div class="stat-value">#' + schoolRank + '</div><div class="stat-label">School rank</div></div>' +
      '<div class="stat-box"><div class="stat-value">#' + classRank + '</div><div class="stat-label">Class rank</div></div>';

    var earned = Scan.MILESTONES.filter(function (m) { return s.laps >= m; });
    var awardsEl = document.getElementById('athlete-awards');
    awardsEl.innerHTML = earned.length
      ? earned.map(function (m) { return '<span class="award-badge">🏆 ' + (MILESTONE_LABELS[m] || (m + ' laps')) + '</span>'; }).join('')
      : '<p style="color:#888;font-size:0.85rem;">Keep running to earn your first award at 5 laps!</p>';

    document.getElementById('result-card').hidden = false;
    renderGoals();
  }

  // --- Goals rendering ---
  function goalRow(g, editable) {
    var p = Goals.progress(currentStudent.id, g);
    var info = Goals.metricInfo(g.metric);
    var currentTxt = p.current == null ? '—' : p.current + ' ' + g.unit;
    var lock = editable ? '' : '<span title="Set by your coach" style="margin-left:6px;">🔒</span>';
    var status = p.met ? '<span class="award-badge">✓ Achieved</span>' : '';
    var deadline = g.deadline ? '<span style="color:#888;font-size:0.78rem;">by ' + g.deadline + '</span>' : '';

    var actions = '';
    if (editable) {
      actions = '<button class="link-btn" data-act="del" data-id="' + g.id + '">Delete</button>';
    }
    // PB metrics let you log a result (student can log own; coach goals are read-only here).
    var logBtn = (!info.auto && editable)
      ? '<button class="link-btn" data-act="log" data-id="' + g.id + '">Log result</button>' : '';

    return '<div class="goal-item">' +
      '<div class="goal-head"><strong>' + g.title + '</strong> ' + lock + ' ' + status + '</div>' +
      '<div class="goal-meta">Target: ' + g.target + ' ' + g.unit + ' · Now: ' + currentTxt + ' ' + deadline + '</div>' +
      '<div class="goal-bar"><div class="goal-bar-fill" style="width:' + p.percent + '%"></div></div>' +
      '<div class="goal-actions">' + logBtn + ' ' + actions + '</div>' +
      '</div>';
  }

  function renderGoals() {
    var all = Goals.goalsFor(currentStudent.id);
    var mine = all.filter(function (g) { return g.owner === 'student'; });
    var coach = all.filter(function (g) { return g.owner === 'coach'; });

    document.getElementById('my-goals-list').innerHTML = mine.length
      ? mine.map(function (g) { return goalRow(g, true); }).join('')
      : '<p style="color:#888;font-size:0.85rem;">No personal goals yet. Tap “+ Add goal” to set one.</p>';

    document.getElementById('coach-goals-list').innerHTML = coach.length
      ? coach.map(function (g) { return goalRow(g, false); }).join('')
      : '<p style="color:#888;font-size:0.85rem;">Your coach hasn’t set you a goal yet.</p>';

    bindGoalActions();
  }

  function bindGoalActions() {
    document.querySelectorAll('#my-goals-list [data-act]').forEach(function (btn) {
      btn.onclick = function () {
        var id = btn.dataset.id;
        if (btn.dataset.act === 'del') {
          if (confirm('Delete this goal?')) { Goals.deleteGoal(currentStudent.id, id); renderGoals(); }
        } else if (btn.dataset.act === 'log') {
          var v = prompt('Log your result (number only):');
          if (v !== null && v.trim() && !isNaN(Number(v))) { Goals.logResult(currentStudent.id, id, v); renderGoals(); }
        }
      };
    });
  }

  // --- Add-goal form (the "+" button) ---
  function buildMetricOptions() {
    return Object.keys(Goals.METRICS).map(function (k) {
      return '<option value="' + k + '">' + Goals.METRICS[k].label + ' (' + Goals.METRICS[k].unit + ')</option>';
    }).join('');
  }

  function wireAddGoal() {
    document.getElementById('metric').innerHTML = buildMetricOptions();
    var panel = document.getElementById('add-goal-panel');
    document.getElementById('add-goal-btn').addEventListener('click', function () {
      panel.hidden = !panel.hidden;
    });
    document.getElementById('add-goal-form').addEventListener('submit', function (e) {
      e.preventDefault();
      var metric = document.getElementById('metric').value;
      var target = document.getElementById('goal-target').value;
      var deadline = document.getElementById('goal-deadline').value;
      var title = document.getElementById('goal-title').value;
      if (!target || isNaN(Number(target))) { return; }
      Goals.addGoal(currentStudent.id, 'student', { metric: metric, target: target, deadline: deadline, title: title });
      e.target.reset();
      panel.hidden = true;
      renderGoals();
    });
  }

  // --- Home activity self-report (kept from original) ---
  function wireSelfReport() {
    document.getElementById('self-report-form').addEventListener('submit', function (e) {
      e.preventDefault();
      var type = document.getElementById('sr-type').value;
      var minutes = document.getElementById('sr-minutes').value;
      if (!type || !minutes) { return; }
      var queue = Scan.load('rc_selfreports', []);
      queue.push({ id: 'sr-' + Date.now(), studentId: currentStudent.id, name: currentStudent.name, type: type, minutes: Number(minutes), status: 'pending', date: new Date().toISOString() });
      Scan.save('rc_selfreports', queue);
      var el = document.getElementById('sr-result');
      el.hidden = false;
      el.textContent = 'Submitted “' + type + '” (' + minutes + ' min). Your teacher will approve it.';
      e.target.reset();
    });
  }

  function handleLogin(e) {
    e.preventDefault();
    var code = document.getElementById('code').value.trim().toUpperCase();
    if (!code) { return; }
    var student = findStudent(code);
    if (!student) {
      alert('Code not recognised. Check your barcode card or ask your teacher.');
      return;
    }
    currentStudent = student;
    renderAthlete(student);
  }

  // --- Init ---
  document.getElementById('student-form').addEventListener('submit', handleLogin);
  wireAddGoal();
  wireSelfReport();
})();
