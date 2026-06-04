// src/data/tracking.js
// Data tracking + reporting helpers for the Run Club platform.
// Pure functions over the shared storage (window.RunClubScan), kept separate
// from UI so reports/exports can be reused by admin, kiosk and future portals.
//
// Exposes a single global: window.RunClubData
(function (global) {
  'use strict';

  var Scan = global.RunClubScan;

  // --- Aggregations ---
  function leaderboard(filter) {
    filter = filter || {};
    var students = Scan.getStudents().slice();
    if (filter.year) { students = students.filter(function (s) { return s.year === filter.year; }); }
    if (filter.cls) { students = students.filter(function (s) { return s.cls === filter.cls; }); }
    students.sort(function (a, b) { return Scan.totalKm(b) - Scan.totalKm(a); });
    return students.map(function (s, i) {
      return { rank: i + 1, id: s.id, name: s.name, year: s.year, cls: s.cls, laps: s.laps, km: +Scan.totalKm(s).toFixed(2) };
    });
  }

  function schoolSummary() {
    var students = Scan.getStudents();
    var totalLaps = students.reduce(function (a, s) { return a + s.laps; }, 0);
    var totalKm = students.reduce(function (a, s) { return a + Scan.totalKm(s); }, 0);
    return {
      enrolled: students.length,
      active: students.filter(function (s) { return s.laps > 0; }).length,
      totalLaps: totalLaps,
      totalKm: +totalKm.toFixed(2),
      marathonEquivalents: +(totalKm / 42.2).toFixed(2)
    };
  }

  function awardList() {
    return Scan.getStudents().map(function (s) {
      return { id: s.id, name: s.name, laps: s.laps, awards: Scan.awardsFor(s.laps) };
    });
  }

  // --- Exports (browser download helpers) ---
  function download(filename, content, mime) {
    var b = new Blob([content], { type: mime });
    var u = URL.createObjectURL(b);
    var a = document.createElement('a');
    a.href = u; a.download = filename;
    document.body.appendChild(a); a.click(); a.remove();
    URL.revokeObjectURL(u);
  }

  function exportJson() {
    var data = {
      exported_at: new Date().toISOString(),
      students: Scan.getStudents(),
      activity: Scan.load(Scan.KEYS.activity, []),
      sessions: Scan.load(Scan.KEYS.sessions, []),
      events: Scan.load(Scan.KEYS.events, []),
      challenges: Scan.load(Scan.KEYS.challenges, []),
      timedRuns: Scan.load(Scan.KEYS.timedRuns, [])
    };
    download('runclub-export.json', JSON.stringify(data, null, 2), 'application/json');
    return data;
  }

  function toCsv(rows, cols) {
    var lines = [cols.join(',')];
    rows.forEach(function (r) {
      lines.push(cols.map(function (c) { return JSON.stringify(r[c] != null ? r[c] : ''); }).join(','));
    });
    return lines.join('\n');
  }

  function exportLeaderboardCsv(filter) {
    var rows = leaderboard(filter);
    download('runclub-leaderboard.csv', toCsv(rows, ['rank', 'name', 'year', 'cls', 'laps', 'km']), 'text/csv');
    return rows;
  }

  global.RunClubData = {
    leaderboard: leaderboard,
    schoolSummary: schoolSummary,
    awardList: awardList,
    exportJson: exportJson,
    exportLeaderboardCsv: exportLeaderboardCsv,
    toCsv: toCsv,
    download: download
  };
})(window);
