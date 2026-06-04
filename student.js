// student.js
(function () {

  function getConfig() {
    if (!window.RUN_CLUB_CONFIG) throw new Error('Missing config.js');
    return window.RUN_CLUB_CONFIG;
  }

  var MILESTONES=[5,10,25,50,100,200,500];
  var MILESTONE_LABELS={5:'First 5 Laps',10:'10 Lap Club',25:'Quarter Century',50:'Half Century',100:'Century Club',200:'Double Century',500:'Elite Runner'};

  function lapsTokm(l){return l*0.25;}

  function fakeLogin(code) {
    return {
      success:true, demo_mode:true,
      athlete:{id:'demo-1',first_name:'Demo',last_name:'Student',year_group:'Year 5',class_id:'5B',total_laps:12,total_minutes:40,school_rank:8,class_rank:2,school_size:120,class_size:24},
      message:'Demo sign-in for code '+code
    };
  }

  function renderAthlete(a) {
    var km=lapsTokm(a.total_laps).toFixed(2);
    var minuteKm=(a.total_minutes?a.total_minutes/20:0).toFixed(2);
    document.getElementById('athlete-name').textContent='\uD83C\uDFC3 '+a.first_name+' '+a.last_name;
    document.getElementById('athlete-stats').innerHTML=
      '<div class="stat-box"><div class="stat-value">'+a.total_laps+'</div><div class="stat-label">Laps</div></div>'+
      '<div class="stat-box"><div class="stat-value">'+km+'</div><div class="stat-label">Km</div></div>'+
      '<div class="stat-box"><div class="stat-value">#'+a.school_rank+'</div><div class="stat-label">School rank</div></div>'+
      '<div class="stat-box"><div class="stat-value">#'+a.class_rank+'</div><div class="stat-label">Class rank</div></div>';

    var earned=MILESTONES.filter(function(m){return a.total_laps>=m;});
    var awardsEl=document.getElementById('athlete-awards');
    if(earned.length){
      awardsEl.innerHTML=earned.map(function(m){return '<span class="award-badge">&#127942; '+MILESTONE_LABELS[m]+'</span>';}).join('');
    } else {
      awardsEl.innerHTML='<p style="color:#888;font-size:0.85rem;">Keep running to earn your first award at 5 laps!</p>';
    }

    document.getElementById('result-card').hidden=false;
  }

  async function handleLogin(e) {
    e.preventDefault();
    var code=document.getElementById('code').value.trim().toUpperCase();
    if(!code)return;
    var cfg=getConfig();
    if(!cfg.endpoints||!cfg.endpoints.studentAuth||cfg.demoMode){
      renderAthlete(f