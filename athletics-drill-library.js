// Corso Athletics — selectable coaching drill library and session presets
(function () {
  'use strict';
  var STORE='rc_athletics_drill_selection';
  var D=[
    ['a-march-slow','A-March — Slow','Running Mechanics',1,'2 × 15–20 m','Walk tall with deliberate knee drive. Briefly own the A-position before stepping through.','Tall posture • Toe up • Opposite arm and leg'],
    ['a-march-fast','A-March — Fast','Running Mechanics',1,'2 × 15–20 m','Progress the march into quicker rhythmic contacts while keeping the same posture. Cones in hands are optional.','Quick contacts • Stay tall • Land under hips'],
    ['a-skip-kickback','A-Skip March & Kickback','Running Mechanics',2,'2 × 15–20 m','Use an A-skip rhythm, then recover the heel underneath the body before the next knee drive.','Rhythm first • Relax shoulders • Strike under hips'],
    ['prime-times','Prime Times','Running Mechanics',2,'2 × 15–20 m','Run tall with mostly straight legs and active downward contacts to develop upright sprint rhythm.','Tall hips • Stiff ankle • Quick down-and-back contact'],
    ['max-high-knees','Max High Knees','Running Mechanics',2,'2 × 10–15 m','Fast high-knee action over a short distance. Stop the rep before posture or rhythm deteriorates.','Fast not long • Tall torso • Arms match legs'],
    ['footchops','Footchops','Pliability',1,'2–3 × 8–10 sec','Use very fast, small contacts underneath the hips. Stay light and elastic rather than jumping high.','Quick feet • Quiet contacts • Hips tall'],
    ['tantrums','Tantrums','Pliability',1,'2 × 10–15 sec','Rapid alternating straight-leg contacts from the ankles with minimal knee bend.','Bounce from ankles • Fast contacts • Stay relaxed'],
    ['pogos','Pogo Hops','Pliability',2,'2 × 10–15 contacts','Bounce vertically using the ankle like a spring. Keep knees relatively stiff and contacts short.','Tall body • Springy ankle • Ground is hot'],
    ['lateral-hops','Lateral Hops','Pliability',2,'2 × 8–10 each way','Hop side to side over a line with controlled, quick contacts. Begin two-legged before progressing.','Control first • Soft landing • Push sideways'],
    ['single-leg-hops','Single-Leg Hops','Pliability',2,'2 × 5–8 each leg','Small forward hops on one leg. Hold alignment and stop if landing quality drops.','Knee tracks forward • Stable landing • Both legs'],
    ['snap-down-jump','Snap Down → Broad Jump','Pliability',2,'2 × 4–5 reps','Start tall with arms overhead, snap into an athletic position, then progress to a broad jump and stick.','Fast snap • Load hips • Stick landing'],
    ['wall-marches','Wall Marches','Acceleration',2,'2 × 5–8 switches/leg','Lean into a wall with a straight body line. Drive one knee forward and switch without losing the lean.','Push ground away • Strong body line • Toe up'],
    ['falling-starts','Falling Starts','Acceleration',2,'3 × 10–15 m','Stand tall and lean forward from the ankles. When balance breaks, punch the first step down and accelerate.','Fall as one piece • Attack first step • Drive forward'],
    ['push-up-starts','Push-Up Starts','Acceleration',2,'2–3 × 10–20 m','Begin in a push-up position. On cue, get to the feet quickly and accelerate through the line.','Explode up • Push back into ground • Run through'],
    ['kneeling-starts','Kneeling Starts','Acceleration',2,'2–3 × 10–20 m','Begin kneeling. On cue, project forward and progressively rise into sprinting.','Forward projection • Powerful first steps • Rise gradually'],
    ['half-kneeling-starts','Half-Kneeling Starts — Side On','Acceleration',3,'2 each side × 10–15 m','Begin half-kneeling side-on. React, turn the hips and accelerate. Complete both sides.','React then turn • Strong first step • Train both sides'],
    ['spot-running-starts','Spot Running Starts','Reaction',2,'3 × 10–15 m','Run quickly on the spot. On the cue, instantly transition into forward acceleration.','Fast feet • React instantly • Push away'],
    ['whistle-start-stop','Whistle Start & Stop','Reaction',3,'4–6 × 5–10 sec','Move on one whistle and stop/control on the next. Vary the gap between cues.','Listen • React • Stop under control'],
    ['drop-and-go','Drop & Go','Reaction',3,'3–5 reps','Coach drops a tennis ball; athlete reacts and accelerates to catch it before the second bounce. Vary starting position.','Eyes on ball • First step fast • Chase through'],
    ['partner-chase','Partner Chase','Reaction',4,'3 reps each then swap','Athletes start 1–2 m apart. Front athlete goes on cue; rear athlete tries to tag them over 10–15 m.','React • Accelerate • Run through line'],
    ['coach-point','Coach Point Reaction','Agility',3,'4–6 reps','Athletes face coach. Point left/right/forward and athletes react into a short acceleration.','Eyes up • Decisive first step • Low then go'],
    ['cone-lines','Speed & Agility Cone Lines','Agility',4,'2–3 rounds','Use short cone lines for quick feet, lateral movement and short accelerations. Change the pattern between rounds.','Quick contacts • Stay balanced • Finish fast'],
    ['compass-hops','Compass Hops','Agility',3,'3 × 20–30 sec','Place four cones around the athlete. Call front/back/left/right randomly and hop to the called direction then return.','React • Balance • Land under control'],
    ['zigzag-cuts','Zig-Zag Cuts','Agility',4,'3–4 runs','Sprint through a short zig-zag cone course. Plant outside foot and redirect without excessive steps.','Lower before turn • Plant and push • Eyes ahead'],
    ['wickets','Wickets','Max Speed',5,'3–4 × 15–25 m','Run over evenly spaced low wickets/markers to encourage upright rhythm and contacts beneath the body.','Tall hips • Step over and down • Relax at speed'],
    ['build-up-runs','Build-Up Runs','Max Speed',4,'3 × 40–60 m','Gradually increase speed through the run rather than sprinting immediately. Finish fast but relaxed.','Smooth acceleration • Relax face/hands • Tall at speed'],
    ['flying-sprints','Flying 10–20s','Max Speed',5,'3–4 reps','Use a 20 m build-up then sprint fast and relaxed through a 10–20 m fly zone. Full walk-back recovery.','Fast and relaxed • Tall hips • Do not strain'],
    ['colour-steal','Colour Steal','Game',6,'3–5 × 30–60 sec rounds','Scatter coloured cones. Call a colour and athletes race to collect/steal the correct cone, then reset.','React to call • Change direction safely • Head up'],
    ['2v1-cones','2 v 1 Cone Choice','Game',6,'4–6 rounds','One athlete chooses between two target cones while two opponents react. Rotate roles frequently.','Sell the fake • React to hips • Short explosive effort'],
    ['long-jump-runup','Long Jump — Run-Up Check','Long Jump',4,'2–3 run-throughs','Check approach rhythm and where the take-off foot lands. Adjust the start marker before full jumps.','Same start mark • Build speed • Eyes forward'],
    ['long-jump-attempts','Long Jump — Quality Attempts','Long Jump',8,'3–4 jumps each','Use full controlled attempts. Focus on approach consistency, strong take-off and landing forward. Measure the best/final attempt if useful.','Run through take-off • Punch up • Feet forward on landing'],
    ['md-200','200 m Race Rhythm','Middle Distance',6,'2 × 100 m + recovery','Practise the 200 m rhythm without a full time trial: controlled first half, then strong running home.','Do not blast first 50 • Relax • Finish strongly'],
    ['md-400','400 m Race Rhythm','Middle Distance',6,'2 × 200 m + recovery','Practise controlled 400 m rhythm. Start assertively, settle, maintain posture and finish strongly.','Controlled opening • Settle rhythm • Save a gear'],
    ['race-finish','Race Finish Practice','Middle Distance',4,'2–3 × 50–80 m','Short finishing efforts that teach athletes to change gears late while maintaining technique.','Lift cadence • Keep form • Run past line']
  ].map(function(x){return{id:x[0],title:x[1],category:x[2],minutes:x[3],work:x[4],how:x[5],cues:x[6]};});

  var S=[
    {id:'measure-prep',title:'Measure Day Prep — Pliability',focus:'Pliability + event preparation',drills:['a-march-slow','a-march-fast','footchops','tantrums','pogos','lateral-hops','single-leg-hops','push-up-starts'],note:'Ideal as the third rotation alongside Long Jump and Middle Distance. Short, elastic and low-fatigue.'},
    {id:'acceleration',title:'Acceleration & Starts',focus:'Positions → projection → acceleration',drills:['a-march-slow','a-march-fast','wall-marches','falling-starts','push-up-starts','kneeling-starts'],note:'Build the positions slowly, then apply them to increasingly explosive starts.'},
    {id:'elasticity',title:'Elasticity & Pliability',focus:'Ankle stiffness, landing control and reactive strength',drills:['footchops','tantrums','pogos','lateral-hops','single-leg-hops','snap-down-jump'],note:'Progress from small quick contacts to bilateral, lateral and unilateral jumping.'},
    {id:'top-speed',title:'Top Speed & Sprint Mechanics',focus:'Upright mechanics and relaxed speed',drills:['a-skip-kickback','prime-times','max-high-knees','wickets','build-up-runs','flying-sprints'],note:'Technical rhythm first, then wickets and fast relaxed running.'},
    {id:'reaction',title:'Reaction & Agility',focus:'Reaction, change of direction and decision-making',drills:['spot-running-starts','whistle-start-stop','coach-point','compass-hops','zigzag-cuts','2v1-cones','colour-steal'],note:'Move from simple cues into open decision-making and finish with a game.'},
    {id:'long-jump',title:'Long Jump Tune-Up',focus:'Approach consistency and quality jumping',drills:['a-march-fast','pogos','snap-down-jump','long-jump-runup','long-jump-attempts'],note:'Use as a dedicated jump station. Keep attempts high quality rather than high volume.'},
    {id:'middle-distance',title:'Middle Distance Race Prep',focus:'Pacing, rhythm and finishing',drills:['a-march-fast','prime-times','build-up-runs','md-200','md-400','race-finish'],note:'Choose the 200 m or 400 m race-rhythm drill for the athletes in the group; they do not need both.'},
    {id:'fun-speed',title:'Speed + Reaction Games',focus:'Fast running disguised as competition',drills:['falling-starts','drop-and-go','partner-chase','2v1-cones','colour-steal'],note:'A lighter, highly engaging session for acceleration and reaction without repeating the technical sessions.'}
  ];

  function byId(id){return D.find(function(d){return d.id===id;});}
  function esc(v){return String(v==null?'':v).replace(/[&<>"']/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];});}
  function selected(){try{return JSON.parse(localStorage.getItem(STORE)||'[]');}catch(e){return[];}}
  function save(ids){try{localStorage.setItem(STORE,JSON.stringify(ids));}catch(e){}}
  function total(ids){return ids.reduce(function(n,id){var d=byId(id);return n+(d?d.minutes:0);},0);}
  function addToExistingBuilder(d){
    var chip=document.querySelector('[data-component-id="'+d.id+'"]');
    if(chip){chip.click();return true;}
    return false;
  }
  function render(host,ids){
    host.innerHTML='<div class="corso-athletics-library">'+
      '<div class="corso-athletics-head"><div><h4>Athletics Sessions</h4><p>Choose a preset, then tick/untick drills. Tap a drill for the coaching breakdown.</p></div><strong id="athletics-total">'+total(ids)+' min selected</strong></div>'+
      '<div class="corso-session-grid">'+S.map(function(s){return '<button type="button" class="secondary corso-session-preset" data-session="'+s.id+'"><strong>'+esc(s.title)+'</strong><small>'+esc(s.focus)+'</small></button>';}).join('')+'</div>'+
      '<div id="corso-session-note" class="corso-session-note"></div>'+
      '<div class="corso-drill-filters"><button type="button" class="secondary corso-filter active" data-cat="all">All</button>'+Array.from(new Set(D.map(function(d){return d.category;}))).map(function(c){return '<button type="button" class="secondary corso-filter" data-cat="'+esc(c)+'">'+esc(c)+'</button>';}).join('')+'</div>'+
      '<div id="corso-drill-grid" class="corso-drill-grid">'+D.map(function(d){return '<article class="corso-drill-card" data-category="'+esc(d.category)+'"><label><input type="checkbox" class="corso-drill-check" value="'+d.id+'" '+(ids.indexOf(d.id)>=0?'checked':'')+'><span><strong>'+esc(d.title)+'</strong><small>'+esc(d.category)+' · '+d.minutes+' min · '+esc(d.work)+'</small></span></label><details><summary>How to coach it</summary><p>'+esc(d.how)+'</p><p><b>Cues:</b> '+esc(d.cues)+'</p></details></article>';}).join('')+'</div>'+
      '<div class="corso-athletics-actions"><button type="button" id="corso-add-selected">Add selected to workout</button><button type="button" class="secondary" id="corso-clear-selected">Clear</button></div></div>';
    var checks=host.querySelectorAll('.corso-drill-check');
    checks.forEach(function(c){c.addEventListener('change',function(){var x=Array.from(checks).filter(function(i){return i.checked;}).map(function(i){return i.value;});save(x);host.querySelector('#athletics-total').textContent=total(x)+' min selected';});});
    host.querySelectorAll('.corso-session-preset').forEach(function(b){b.addEventListener('click',function(){var s=S.find(function(x){return x.id===b.dataset.session;});if(!s)return;checks.forEach(function(c){c.checked=s.drills.indexOf(c.value)>=0;});save(s.drills);host.querySelector('#athletics-total').textContent=total(s.drills)+' min selected';host.querySelector('#corso-session-note').innerHTML='<strong>'+esc(s.title)+'</strong> — '+esc(s.note);});});
    host.querySelectorAll('.corso-filter').forEach(function(b){b.addEventListener('click',function(){host.querySelectorAll('.corso-filter').forEach(function(x){x.classList.remove('active');});b.classList.add('active');host.querySelectorAll('.corso-drill-card').forEach(function(card){card.hidden=b.dataset.cat!=='all'&&card.dataset.category!==b.dataset.cat;});});});
    host.querySelector('#corso-clear-selected').addEventListener('click',function(){checks.forEach(function(c){c.checked=false;});save([]);host.querySelector('#athletics-total').textContent='0 min selected';});
    host.querySelector('#corso-add-selected').addEventListener('click',function(){var chosen=Array.from(checks).filter(function(i){return i.checked;}).map(function(i){return byId(i.value);}).filter(Boolean);var title=document.getElementById('workout-builder-title');if(title&&!title.value)title.value='Athletics Training Session';var zone=document.getElementById('workout-builder-dropzone');if(zone){var summary=document.createElement('div');summary.className='corso-selected-session';summary.innerHTML='<strong>Athletics plan · '+total(chosen.map(function(d){return d.id;}))+' min</strong>'+chosen.map(function(d,i