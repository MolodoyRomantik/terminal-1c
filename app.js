const app=document.querySelector('#app');
const modules=['Знакомство с 1С','Устройство базы','Встроенный язык','Формы и отладка','Складской учёт','Запросы к данным','Отчёты и обработки','Чужая конфигурация','Будни разработчика','Выпускная работа'];
const ends=[6,12,20,26,33,40,45,51,57,60];
const icons=['M2 3h20v14H2z M8 21h8 M12 17v4 M6 7l3 3-3 3 M12 13h5','M3 5l9-3 9 3-9 3z M3 5v14l9 3 9-3V5 M12 8v14','M8 6l-6 6 6 6 M16 6l6 6-6 6 M14 4l-4 16','M2 3h20v18H2z M2 8h20 M6 12h5 M6 16h10','M2 8l10-5 10 5 M4 8v13h16V8 M8 21v-9h8v9','M3 4h18v16H3z M3 9h18 M9 9v11','M4 21V3 M4 21h17 M8 17v-5 M13 17V8 M18 17V5','M3 6h7l2 3h9v11H3z','M3 7h18v13H3z M8 7V4h8v3 M3 12h18','M6 22V3 M6 4h13l-3 4 3 4H6'];
let state={quiz:{},pc:{},good:0,total:0};
try{Object.assign(state,JSON.parse(localStorage.getItem('terminal-course-v1')||'{}'))}catch{}
function save(){try{localStorage.setItem('terminal-course-v1',JSON.stringify(state))}catch{}}
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const done=i=>state.quiz[i]&&state.pc[i];
const lessons=window.lessons;
const count=()=>lessons.filter((_,i)=>done(i)).length;
const pad=n=>String(n).padStart(2,'0');
function progress(){return '<div class="progress"><span>Прогресс курса</span><div class="track"><i style="width:'+count()/60*100+'%"></i></div><span>'+count()+' / 60</span></div>'}
function stats(){app.innerHTML='<div class="page"><h1>Статистика</h1>'+progress()+'<div class="grid">'+[['Проверки уроков',Object.values(state.quiz).filter(Boolean).length+' / 60'],['Практика в 1С',Object.values(state.pc).filter(Boolean).length+' / 60'],['Верные ответы в играх',state.good+' / '+state.total]].map(([k,v])=>'<section class="box"><div class="statsnum">'+v+'</div>'+k+'</section>').join('')+'</div><p class="muted">Прогресс хранится в этом браузере на устройстве.</p></div>'}

function home(){
 const i=Math.min(59,Math.max(0,state.at??lessons.findIndex((_,j)=>!done(j))));
 const k=ends.findIndex(n=>i<n);
 app.innerHTML='<section class="deck"><div class="topline"><span class="eyebrow">Мой путь</span><a class="link" href="#module-'+(k+1)+'">Все уроки ☰</a></div><div class="display"><span>1С / УЧЕБНЫЙ ЦЕХ</span><img src="computer.svg" alt="Советский персональный компьютер"></div><div class="info"><small>МОДУЛЬ '+pad(k+1)+' · '+modules[k]+'</small><div class="lessonno">Урок '+pad(i+1)+' <span>/ 60</span></div><h1>'+esc(lessons[i].title)+'</h1></div><a class="primary launch" href="#lesson-'+(i+1)+'-'+(state.step?.[i]||1)+'">'+(state.at===undefined?'Начать урок':'Продолжить урок')+'</a>'+progress()+'</section>'
}
function catalogue(k){
 const start=k?ends[k-1]:0;
 app.innerHTML='<section class="deck"><a class="back" href="#path">‹ Мой путь</a><h1>Уроки</h1><label for="module">Модуль курса</label><select id="module">'+modules.map((m,j)=>'<option '+(j===k?'selected':'')+' value="'+(j+1)+'">'+pad(j+1)+' · '+m+'</option>').join('')+'</select><div class="items">'+lessons.slice(start,ends[k]).map((l,j)=>'<a class="row" href="#lesson-'+(start+j+1)+'-1"><b>'+pad(start+j+1)+'</b>'+esc(l.title)+'<span>'+(done(start+j)?'✓':'›')+'</span></a>').join('')+'</div></section>';
 document.querySelector('#module').onchange=e=>location.hash='module-'+e.target.value
}
const steps=['Разобрать','Записать','Сделать в 1С','Проверить'];
function lesson(i,s){
 state.at=i;(state.step??={})[i]=s;save();const l=lessons[i],next=i<59?'#lesson-'+(i+2)+'-1':'#stats';
 app.innerHTML='<section class="deck"><div class="topline"><a class="back" href="#path">‹ Мой путь</a><small>УРОК '+pad(i+1)+' / 60</small></div><div class="steps">'+steps.map((t,j)=>'<a href="#lesson-'+(i+1)+'-'+(j+1)+'" aria-label="'+t+'" class="'+(s===j+1?'now':'')+'"></a>').join('')+'</div><small>ШАГ '+s+' / 4 · '+steps[s-1]+'</small><h1>'+esc(l.title)+'</h1><div class="reading">'+esc([l.theory,l.note,l.practice,l.question][s-1])+'</div>'+(s===3?'<label class="check"><input id="pc" type="checkbox" '+(state.pc[i]?'checked':'')+'> Практика выполнена</label>':'')+(s===4?'<div class="choices">'+l.choices.map((c,j)=>'<button data-answer="'+j+'">'+esc(c)+'</button>').join('')+'</div><p id="result" role="status">'+(state.quiz[i]?'✓ Проверка пройдена':'')+'</p>':'')+'<a class="primary launch" href="'+(s<4?'#lesson-'+(i+1)+'-'+(s+1):next)+'">'+(s<4?steps[s]:i<59?'Следующий урок':'Статистика')+'</a></section>';
 if(s===3)document.querySelector('#pc').onchange=e=>{state.pc[i]=e.target.checked;save()};
 document.querySelectorAll('[data-answer]').forEach(b=>b.onclick=()=>{const yes=+b.dataset.answer===l.answer;if(yes){state.quiz[i]=true;save()}document.querySelector('#result').textContent=yes?'✓ Верно':'Попробуй ещё раз'})
}
function render(){
 const r=location.hash.slice(1),g=r==='games',t=r==='stats',m=/^module-(\d+)$/.exec(r),l=/^lesson-(\d+)(?:-([1-4]))?$/.exec(r);
 document.querySelectorAll('nav a').forEach(a=>{const active=a.hash===(g?'#games':t?'#stats':'#path');a.classList.toggle('active',active);if(active)a.setAttribute('aria-current','page');else a.removeAttribute('aria-current')});
 if(g){app.innerHTML='<section class="deck" id="games"></section>';window.renderGames(document.querySelector('#games'),ok=>{state.total++;if(ok)state.good++;save()})}
 else if(t)stats();else if(m&&+m[1]>=1&&+m[1]<=10)catalogue(+m[1]-1);else if(l&&+l[1]>=1&&+l[1]<=60)lesson(+l[1]-1,+(l[2]||1));else home();
 app.scrollTop=0;
}
addEventListener('hashchange',render);render();
addEventListener('load',()=>{const tg=window.Telegram?.WebApp;if(tg?.initData){tg.ready();tg.expand()}});
