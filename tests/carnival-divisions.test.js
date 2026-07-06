const assert=require('assert');
function autoSplitDivisions(students, times){
  // students: [{id}], times: {id: seconds|null|undefined}
  var sorted=students.slice().sort(function(a,b){
    var ta=times[a.id], tb=times[b.id];
    var ua=(ta==null||isNaN(ta)), ub=(tb==null||isNaN(tb));
    if(ua&&ub){return 0;}          // both untimed: stable
    if(ua){return 1;}              // untimed sink
    if(ub){return -1;}
    return ta-tb;                  // faster first
  });
  var bands=[]; var labels='ABCDEFGHIJ';
  for(var i=0;i<sorted.length;i+=10){
    bands.push({label:labels[bands.length]||('D'+(bands.length+1)), student_ids:sorted.slice(i,i+10).map(function(s){return s.id;})});
  }
  return bands;
}
var studs=[]; for(var i=1;i<=23;i++){studs.push({id:'s'+i});}
var times={}; studs.forEach(function(s,i){times[s.id]= i<20 ? (10+i*0.1) : null;}); // last 3 untimed
var bands=autoSplitDivisions(studs, times);
assert.strictEqual(bands.length,3,'23 students -> 3 bands');
assert.strictEqual(bands[0].student_ids.length,10,'band A has 10');
assert.strictEqual(bands[2].student_ids.length,3,'band C has remainder 3');
assert.strictEqual(bands[0].student_ids[0],'s1','fastest (s1) in A first');
// untimed (s21,s22,s23) are last
assert.deepStrictEqual(bands[2].student_ids.slice(-3),['s21','s22','s23'],'untimed sink to the last band');
console.log('carnival divisions checks passed');
