// Public leaderboard views for whole school, divisions, and year groups.
(function () {
  'use strict';

  var Scan = window.RunClubScan;
  var Backend = window.RunClubBackend;
  var DIVISIONS = [
    { id: 'senior', years: ['Year 5', 'Year 6'] },
    { id: 'intermediate', years: ['Year 3', 'Year 4'] },
    { id: 'junior', years: ['Year 1', 'Year 2'] }
  ];
  var YEAR_GROUPS = ['Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6'];
  var HOUSE_LABELS = ['Gold', 'Blue', 'Red', 'Green'];

  function byDistance(a, b) {
    return totalKm(b) - totalKm(a);
  }

  function escapeHtml(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' })[c];
    });
  }

  function cleanYear(value) {
    var text = String(value == null ? '' : value).trim();
    return /^Year\s+/i.test(text) ? text.replace(/^year/i, 'Year') : 'Year ' + text;
  }

  function totalKm(student) {
    if (student.total_km != null) { return Number(student.total_km) || 0; }
    if (student.km != null) { return Number(student.km) || 0; }
    return Scan.totalKm(student);
  }

  function totalLaps(student) {
    return Number(student.total_laps != null ? student.total_laps : student.laps) || 0;
  }

  function publicStudentName(student) {
    var pseudonym = String(student.pseudonym || student.preferred_name || '').trim();
    if (pseudonym) { return pseudonym; }
    if (student.hide_public_name || student.consent_status === 'declined') {
      return 'Runner ' + String(student.barcode || student.id || '').slice(-4);
    }
    return student.name || student.student_name || 'Student';
  }

  function loadLocal(key, fallback) {
    try {
      var raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (_) {
      return fallback;
    }
  }

  function privacyMetadataFor(row) {
    var id = row.student_id || row.id || row.barcode;
    var barcode = row.barcode || row.student_id || row.id;
    var name = row.student_name || row.name || row.preferred_name;
    return loadLocal('rc_students', []).find(function (student) {
      return student.id === id || student.barcode === barcode || student.name === name;
    }) || {};
  }

  function normalizeLeaderboardRow(row) {
    var privacy = privacyMetadataFor(row);
    return {
      id: row.student_id || row.id || row.barcode,
      barcode: row.barcode || row.student_id || row.id,
      name: row.student_name || row.name || row.preferred_name || 'Student',
      pseudonym: row.pseudonym || privacy.pseudonym || row.preferred_name || privacy.preferred_name || '',
      preferred_name: row.preferred_name || privacy.preferred_name || row.pseudonym || privacy.pseudonym || '',
      consent_status: row.consent_status || privacy.consent_status || 'pending',
      hide_public_name: !!(row.hide_public_name || privacy.hide_public_name),
      share_certificates_publicly: !!(row.share_certificates_publicly || privacy.share_certificates_publicly),
      year: cleanYear(row.year_group || row.year),
      cls: row.class_name || row.cls || '',
      house: row.house || row.house_name || '',
      team: row.team || row.team_name || '',
      laps: totalLaps(row),
      total_km: totalKm(row)
    };
  }

  function renderBackendStatus(message) {
    var el = document.getElementById('leaderboard-backend-status');
    if (el) { el.textContent = message || ''; }
  }

  function renderTable(targetId, students) {
    var target = document.getElementById(targetId);
    var sorted = students.slice().sort(byDistance);
    if (!sorted.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No runners yet.</p>';
      return;
    }
    var rows = sorted.map(function (student, index) {
      return '<tr>' +
        '<td class="leaderboard-rank">#' + (index + 1) + '</td>' +
        '<td>' + escapeHtml(publicStudentName(student)) + '</td>' +
        '<td>' + escapeHtml(student.year) + '</td>' +
        '<td>' + escapeHtml(student.cls) + '</td>' +
        '<td>' + totalLaps(student) + '</td>' +
        '<td>' + totalKm(student).toFixed(2) + ' km</td>' +
      '</tr>';
    }).join('');
    target.innerHTML =
      '<table class="leaderboard-table">' +
        '<thead><tr><th>Rank</th><th>Student</th><th>Year</th><th>Class</th><th>Laps</th><th>Distance</th></tr></thead>' +
        '<tbody>' + rows + '</tbody>' +
      '</table>';
  }

  function renderTotalLeaderboard(students) {
    renderTable('total-leaderboard', students);
  }

  function houseName(student) {
    return String(student.house || '').trim() || 'Unassigned';
  }

  function houseLeaderboardRows(students) {
    var groups = {};
    students.forEach(function (student) {
      var house = houseName(student);
      if (!groups[house]) {
        groups[house] = { house: house, students: 0, laps: 0, total_km: 0 };
      }
      groups[house].students += 1;
      groups[house].laps += totalLaps(student);
      groups[house].total_km += totalKm(student);
    });
    return Object.keys(groups).map(function (key) { return groups[key]; }).sort(function (a, b) {
      return b.total_km - a.total_km || b.laps - a.laps || a.house.localeCompare(b.house);
    });
  }

  function renderHouseLeaderboard(students) {
    var target = document.getElementById('house-leaderboard');
    var rows = houseLeaderboardRows(students);
    if (!rows.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No house totals yet.</p>';
      return;
    }
    target.innerHTML = '<table class="leaderboard-table">' +
      '<thead><tr><th>Rank</th><th>House</th><th>Students</th><th>Laps</th><th>Distance</th></tr></thead><tbody>' +
      rows.map(function (row, index) {
        return '<tr><td class="leaderboard-rank">#' + (index + 1) + '</td><td>' + escapeHtml(row.house) + '</td><td>' + row.students + '</td><td>' + row.laps + '</td><td>' + row.total_km.toFixed(2) + ' km</td></tr>';
      }).join('') +
      '</tbody></table>';
  }

  function teamName(student) {
    return String(student.team || '').trim() || 'Unassigned';
  }

  function teamLeaderboardRows(students) {
    var groups = {};
    students.forEach(function (student) {
      var team = teamName(student);
      if (!groups[team]) {
        groups[team] = { team: team, students: 0, laps: 0, total_km: 0 };
      }
      groups[team].students += 1;
      groups[team].laps += totalLaps(student);
      groups[team].total_km += totalKm(student);
    });
    return Object.keys(groups).map(function (key) { return groups[key]; }).sort(function (a, b) {
      return b.total_km - a.total_km || b.laps - a.laps || a.team.localeCompare(b.team);
    });
  }

  function renderTeamLeaderboard(students) {
    var target = document.getElementById('team-leaderboard');
    var rows = teamLeaderboardRows(students);
    if (!rows.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No team totals yet.</p>';
      return;
    }
    target.innerHTML = '<table class="leaderboard-table">' +
      '<thead><tr><th>Rank</th><th>Team</th><th>Students</th><th>Laps</th><th>Distance</th></tr></thead><tbody>' +
      rows.map(function (row, index) {
        return '<tr><td class="leaderboard-rank">#' + (index + 1) + '</td><td>' + escapeHtml(row.team) + '</td><td>' + row.students + '</td><td>' + row.laps + '</td><td>' + row.total_km.toFixed(2) + ' km</td></tr>';
      }).join('') +
      '</tbody></table>';
  }

  function className(student) {
    return String(student.cls || '').trim() || 'Unassigned';
  }

  function classLeaderboardRows(students) {
    var groups = {};
    students.forEach(function (student) {
      var cls = className(student);
      if (!groups[cls]) {
        groups[cls] = { cls: cls, students: 0, laps: 0, total_km: 0 };
      }
      groups[cls].students += 1;
      groups[cls].laps += totalLaps(student);
      groups[cls].total_km += totalKm(student);
    });
    return Object.keys(groups).map(function (key) { return groups[key]; }).sort(function (a, b) {
      return b.total_km - a.total_km || b.laps - a.laps || a.cls.localeCompare(b.cls);
    });
  }

  function renderClassLeaderboard(students) {
    var target = document.getElementById('class-leaderboard');
    var rows = classLeaderboardRows(students);
    if (!rows.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No class totals yet.</p>';
      return;
    }
    target.innerHTML = '<table class="leaderboard-table">' +
      '<thead><tr><th>Rank</th><th>Class</th><th>Students</th><th>Laps</th><th>Distance</th></tr></thead><tbody>' +
      rows.map(function (row, index) {
        return '<tr><td class="leaderboard-rank">#' + (index + 1) + '</td><td>' + escapeHtml(row.cls) + '</td><td>' + row.students + '</td><td>' + row.laps + '</td><td>' + row.total_km.toFixed(2) + ' km</td></tr>';
      }).join('') +
      '</tbody></table>';
  }

  function yearLevelLeaderboardRows(students) {
    var groups = {};
    students.forEach(function (student) {
      var year = student.year || 'Unassigned';
      if (!groups[year]) {
        groups[year] = { year: year, students: 0, laps: 0, total_km: 0 };
      }
      groups[year].students += 1;
      groups[year].laps += totalLaps(student);
      groups[year].total_km += totalKm(student);
    });
    return Object.keys(groups).map(function (key) { return groups[key]; }).sort(function (a, b) {
      return b.total_km - a.total_km || b.laps - a.laps || a.year.localeCompare(b.year);
    });
  }

  function renderYearLevelLeaderboard(students) {
    var target = document.getElementById('year-level-leaderboard');
    var rows = yearLevelLeaderboardRows(students);
    if (!rows.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No year-level totals yet.</p>';
      return;
    }
    target.innerHTML = '<table class="leaderboard-table">' +
      '<thead><tr><th>Rank</th><th>Year</th><th>Students</th><th>Laps</th><th>Distance</th></tr></thead><tbody>' +
      rows.map(function (row, index) {
        return '<tr><td class="leaderboard-rank">#' + (index + 1) + '</td><td>' + escapeHtml(row.year) + '</td><td>' + row.students + '</td><td>' + row.laps + '</td><td>' + row.total_km.toFixed(2) + ' km</td></tr>';
      }).join('') +
      '</tbody></table>';
  }

  function parseChallengeGoal(goal) {
    var text = String(goal || '').toLowerCase();
    var amountMatch = text.match(/(\d+(?:\.\d+)?)/);
    var amount = amountMatch ? Number(amountMatch[1]) : 0;
    var metric = /km|kilometre|kilometer/.test(text) ? 'km' : 'laps';
    return { amount: amount, metric: metric };
  }

  function challengeTarget(challenge) {
    if (challenge.target != null && Number(challenge.target) > 0) {
      return { amount: Number(challenge.target), metric: challenge.metric || 'laps' };
    }
    return parseChallengeGoal(challenge.goal);
  }

  function challengeProgressRows(students) {
    var challenges = loadLocal('rc_challenges', []);
    var schoolLaps = students.reduce(function (sum, student) { return sum + totalLaps(student); }, 0);
    var schoolKm = students.reduce(function (sum, student) { return sum + totalKm(student); }, 0);
    return challenges.map(function (challenge) {
      var target = challengeTarget(challenge);
      var current = target.metric === 'km' ? schoolKm : schoolLaps;
      var percent = target.amount ? Math.min(100, Math.round((current / target.amount) * 100)) : 0;
      return {
        name: challenge.name || 'Club challenge',
        goal: challenge.goal || '',
        metric: target.metric,
        current: current,
        target: target.amount,
        percent: percent
      };
    });
  }

  function renderClubChallengeProgress(students) {
    var target = document.getElementById('club-challenge-progress');
    var rows = challengeProgressRows(students);
    if (!rows.length) {
      target.innerHTML = '<p style="color:#888;font-size:0.85rem;">No club-wide challenges yet.</p>';
      return;
    }
    target.innerHTML = '<div class="challenge-progress-list">' + rows.map(function (row) {
      var currentText = row.metric === 'km' ? row.current.toFixed(2) + ' km' : Math.round(row.current) + ' laps';
      var targetText = row.target ? (row.metric === 'km' ? row.target + ' km' : row.target + ' laps') : escapeHtml(row.goal);
      return '<div class="challenge-progress-card"><div class="challenge-progress-head"><strong>' + escapeHtml(row.name) + '</strong><span>' + row.percent + '%</span></div>' +
        '<div class="training-meta">' + currentText + ' of ' + targetText + '</div>' +
        '<div class="goal-bar"><div class="goal-bar-fill" style="width:' + row.percent + '%"></div></div></div>';
    }).join('') + '</div>';
  }

  function renderDivisions(students) {
    DIVISIONS.forEach(function (division) {
      renderTable('division-' + division.id, students.filter(function (student) {
        return division.years.indexOf(student.year) !== -1;
      }));
    });
  }

  function renderYearGroups(students) {
    YEAR_GROUPS.forEach(function (year) {
      renderTable('year-' + year.split(' ')[1], students.filter(function (student) {
        return student.year === year;
      }));
    });
  }

  function renderAll(students) {
    renderTotalLeaderboard(students);
    renderHouseLeaderboard(students);
    renderTeamLeaderboard(students);
    renderClassLeaderboard(students);
    renderYearLevelLeaderboard(students);
    renderClubChallengeProgress(students);
    renderDivisions(students);
    renderYearGroups(students);
  }

  function localStudents() {
    return Scan.getStudents().map(normalizeLeaderboardRow);
  }

  function loadLeaderboardStudents() {
    if (Backend && Backend.isConfigured && Backend.isConfigured() && Backend.backendDataAccess && Backend.backendDataAccess.leaderboardTotals) {
      renderBackendStatus('Checking fake backend leaderboard...');
      return Backend.backendDataAccess.leaderboardTotals().then(function (result) {
        var rows = Array.isArray(result) ? result : (result && result.data);
        rows = Array.isArray(rows) ? rows.map(normalizeLeaderboardRow) : [];
        if (rows.length) {
          renderBackendStatus('Showing fake backend leaderboard data.');
          return rows;
        }
        renderBackendStatus('Fake backend is connected, but public RLS returned no leaderboard rows. Showing local demo data.');
        return localStudents();
      }).catch(function () {
        renderBackendStatus('Fake backend unavailable. Showing local demo data.');
        return localStudents();
      });
    }
    renderBackendStatus('Showing local demo leaderboard data.');
    return Promise.resolve(localStudents());
  }

  loadLeaderboardStudents().then(renderAll);
})();
