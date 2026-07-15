'use strict';
// Behavioural check for the kiosk's context-aware success-banner copy (T18).
// bannerCopyFor lives inside the kiosk.js IIFE and can't be imported, so it is
// mirrored here byte-for-byte. If you change one, change both.
var assert = require('assert');

function bannerCopyFor(s, res, praise, km) {
  if (s.laps === 1) {
    return { title: '🎉 First lap for ' + s.name + '!', sub: 'Welcome to the run club • ' + km };
  }
  if (res.milestone) {
    return { title: '🏅 ' + res.milestone + ' milestone, ' + s.name + '!', sub: praise + ' • Lap ' + s.laps + ' • ' + km };
  }
  if (s.laps % 10 === 0) {
    return { title: '✓ ' + s.laps + ' laps for ' + s.name + '!', sub: 'Round number! • ' + praise + ' • ' + km };
  }
  return { title: '✓ Lap logged for ' + s.name, sub: praise + ' • Lap ' + s.laps + ' • ' + km };
}

// First lap wins over everything, even if it were also "round" (1 is not, but
// guards the precedence intent) — welcome copy, no lap count.
var first = bannerCopyFor({ name: 'Ada', laps: 1, km: 0.4 }, {}, 'Nice lap', '0.40 km');
assert(/First lap for Ada/.test(first.title), 'lap 1 shows first-lap title');
assert(/Welcome to the run club/.test(first.sub), 'first lap shows welcome copy');

// Milestone beats round-number.
var milestone = bannerCopyFor({ name: 'Bo', laps: 50, km: 20 }, { milestone: 'Marathon' }, 'Strong', '20.00 km');
assert(/Marathon milestone, Bo/.test(milestone.title), 'milestone title used when present');

// Round-number lap (every 10th) when not a milestone and not first.
var round = bannerCopyFor({ name: 'Cy', laps: 30, km: 12 }, {}, 'Great pace', '12.00 km');
assert(/30 laps for Cy/.test(round.title), 'round-number lap called out in title');
assert(/Round number!/.test(round.sub), 'round-number lap shows round-number copy');

// Ordinary lap → default copy with the lap count.
var normal = bannerCopyFor({ name: 'Di', laps: 7, km: 2.8 }, {}, 'Keep moving', '2.80 km');
assert(/Lap logged for Di/.test(normal.title), 'ordinary lap uses default title');
assert(/Lap 7/.test(normal.sub), 'ordinary lap shows the lap number');

console.log('kiosk banner copy checks passed');
