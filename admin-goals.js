// src/goals/admin-goals.js
// Inline per-student goals manager for the admin dashboard.
// Coaches add/edit/delete COACH-owned goals and can log PB results.
// Student-owned goals are shown read-only here (coaches don't edit those).
// Self-contained: builds its own modal, exposes window.AdminGoals.open(student).
(function (global) {
  'use strict';

  var Goals = global.RunClubGoals;
  var modal, body, titleEl, current;

  function ensureModal() {
    if (modal) { return; }
    modal = document.createElement('div');
    modal.className = 'ag-overlay';
    modal.hidden = true;
    modal.innerHTML =
      '<div class="ag-modal">' +
        '<div class="ag-head"><h3 id="ag-title">Goals</h3><button id="ag-close" class="ag-close">×</button></div>' +
        '<div id="ag-body"></div>' +
        '<div class="ag-add">' +
          '<h4>Assign a coach goal</h4>' +
          '<form id="ag-form">' +
            '<select id="ag-metric"></select>' +
            '<input type="number" id="ag-target" step="any" min="0" placeholder="Target" required />' +
            '<input type="text" id="ag-title-in" placeholder="Name (optional)" />' +
            '<input type="date" id="ag-deadline" />' +
            '<button type="submit">Assign goal</button>' +
          '</form>' +
        '</div>' +
      '</div>';
    document.body.appendChild(modal);
    titleEl = modal.querySelector('#ag-title');
    body = modal.querySelector('#ag-body');
    modal.querySelector('#ag-close').addEventListener('click', close);
    modal.addEventListener('click', function (e) { if (e.target === modal) { close(); } });

    modal.querySelector('#ag-form').addEventListener('submit', function (e) {
      e.preventDefault();
      var metric = modal.querySelector('#ag-metric').value;
      var target = modal.querySelector('#ag-target').value;
      var title = modal.querySelector('#ag-title-in').value;
      var deadline = modal.querySelector('#ag-deadline').value;
      if (!target || isNaN(Number(target))) { return; }
      Goals.addGoal(current.id, 'coach', { metric: metric, target: target, title: title, deadline: deadline });
      e.target.reset();
      render();
    });
  }

  function row(g) {
    var p = Goals.progress(current.id, g);
    var info = Goals.metricInfo(g.metric);
    var who = g.owner === 'coach' ? '👨‍🏫 Coach' : '🏃 Student';
    var nowTxt = p.current == null ? '—' : p.current + ' ' + g.unit;
    var progressLabel = info.kind === 'cumulative' ? 'since set' : 'best';
    var status = p.met ? ' ✓' : '';
    var ctrls = '';
    if (g.owner === 'coach') {
      var logBtn = !info.auto ? '<button class="link-btn" data-act="log" data-id="' + g.id + '">Log result</button>' : '';
      ctrls = logBtn + ' <button class="link-btn" data-act="del" data-id="' + g.id + '">Delete</button>';
    } else {
      ctrls = '<span style="color:#888;font-size:0.78rem;">read-only</span>';
    }
    return '<div class="ag-row"><div><strong>' + who + '</strong>: ' + g.title +
      ' — ' + g.target + ' ' + g.unit + ' (' + progressLabel + ' ' + nowTxt + status + ', ' + p.percent + '%)</div>' +
      '<div class="ag-ctrls">' + ctrls + '</div></div>';
  }

  function render() {
    modal.querySelector('#ag-metric').innerHTML = Goals.visibleMetrics().map(function (metric) {
      return '<option value="' + metric.key + '">' + metric.label + ' (' + metric.unit + ')</option>';
    }).join('');
    var goals = Goals.goalsFor(current.id).filter(function (goal) { return Goals.isMetricVisible(goal.metric); });
    body.innerHTML = goals.length
      ? goals.map(row).join('')
      : '<p style="color:#888;">No goals yet for this student.</p>';
    body.querySelectorAll('[data-act]').forEach(function (btn) {
      btn.onclick = function () {
        var id = btn.dataset.id;
        if (btn.dataset.act === 'del') {
          if (confirm('Delete this coach goal?')) { Goals.deleteGoal(current.id, id); render(); }
        } else if (btn.dataset.act === 'log') {
          var v = prompt('Log result for ' + current.name + ' (number only):');
          if (v !== null && v.trim() && !isNaN(Number(v))) { Goals.logResult(current.id, id, v); render(); }
        }
      };
    });
  }

  function open(student) {
    ensureModal();
    current = student;
    titleEl.textContent = '🎯 Goals — ' + student.name;
    render();
    modal.hidden = false;
  }
  function close() { if (modal) { modal.hidden = true; } }

  global.AdminGoals = { open: open, close: close };
})(window);
