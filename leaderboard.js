// Public leaderboard views for whole school, divisions, and year groups.
(function () {
  'use strict';

  var Scan = window.RunClubScan;
  var DIVISIONS = [
    { id: 'senior', years: ['Year 5', 'Year 6'] },
    { id: 'intermediate', years: ['Year 3', 'Year 4'] },
    { id: 'junior', years: ['Year 1', 'Year 2'] }
  ];
  var YEAR_GROUPS = ['Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6'];

  function byDistance(a, b) {
    return Scan.totalKm(b) - Scan.totalKm(a);
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
        '<td>' + student.name + '</td>' +
        '<td>' + student.year + '</td>' +
        '<td>' + student.cls + '</td>' +
        '<td>' + student.laps + '</td>' +
        '<td>' + Scan.totalKm(student).toFixed(2) + ' km</td>' +
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

  var students = Scan.getStudents();
  renderTotalLeaderboard(students);
  renderDivisions(students);
  renderYearGroups(students);
})();
