const assert=require('assert');
// Mirror of carnivalPointsForField's pure logic (kept in sync with admin-dashboard.js).
function carnivalPointsForField(place, fieldSize, opts){
  opts=opts||{}; var p=Number(place);
  if(opts.mode==='fixed'){ var t=opts.scheme||[10,8,6,4,2,1]; return p>=1&&p<=t.length?t[p-1]:0; }
  var offset=opts.offset||0;
  var total=opts.tier==='tiered'?(opts.total||fieldSize):fieldSize;
  var pts=total - offset - (p-1);
  return pts>0?pts:0;
}
// Independent: 1st of 8 = 8, 8th = 1
assert.strictEqual(carnivalPointsForField(1,8,{mode:'field-size',tier:'independent'}),8);
assert.strictEqual(carnivalPointsForField(8,8,{mode:'field-size',tier:'independent'}),1);
assert.strictEqual(carnivalPointsForField(9,8,{mode:'field-size',tier:'independent'}),0);
// Tiered: Div A (offset 0, total 18) 1st = 18; Div B (offset 10, total 18) 1st = 8
assert.strictEqual(carnivalPointsForField(1,10,{mode:'field-size',tier:'tiered',total:18,offset:0}),18);
assert.strictEqual(carnivalPointsForField(1,8,{mode:'field-size',tier:'tiered',total:18,offset:10}),8);
// Fixed table unchanged
assert.strictEqual(carnivalPointsForField(2,10,{mode:'fixed'}),8);
console.log('carnival points checks passed');
