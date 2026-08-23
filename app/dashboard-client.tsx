'use client';

import { useCallback, useEffect, useState } from 'react';
import { MathAnswerField, MathFormula } from './math-field';
import { getSupabaseBrowserClient } from '@/lib/supabase-client';
import { BrandLogo } from './brand-logo';
import { ThemeToggle } from './theme-toggle';

type AuthUser={id:string;email:string;name:string};
type Lesson={id:string;title:string;unitNumber:number;conceptKey:string;contentJson:string;coinReward:number;xpReward:number;secretStage:number;state:'locked'|'available'|'review_required'|'verification'|'completed';bestScore:number;failureCount:number;lessonResendCount:number};
type Inventory={coins:number;revives:number;streakRevives:number;hints:number;xp:number;streak:number;longestStreak:number};
type Room={id:string;title:string;inviteCode:string;deliveryMode:string;status:string;participants?:number;questionCount?:number};
type Bootstrap={user:{id:string;email:string;displayName:string;role:'student'|'teacher'|'admin'};inventory:Inventory;lessons:Lesson[];achievements:Array<{id:string;title:string;description:string;xpReward:number;earned:number}>;rooms:Room[];metrics:{completed:number;total:number;progress:number}};
type LessonDetail={lesson:Lesson&{content:{summary:string;steps:string[];formula:string}};question:{id:string;prompt:string;type:string;choices:string[]|null;hint1:string;hint2:string}|null;verification:boolean;stageProgress?:{completed:number;required:number;total:number;current:number}};
type RoomResponse={questionId:string;answer:string;correct:boolean};
type RoomDetail={room:Room&{teacherId:string;requestFullscreen:number};questions:Array<{id:string;prompt:string;type:string;choices:string[]|null}>;responses?:RoomResponse[];attempt?:{id:string;status:string;score:number}|null;participants?:Array<{name:string;attemptId:string;status:string;score:number;answered:number;signals:number}>;events:Array<{id:string;eventType:string;payloadJson:string;createdAt:number}>};
type TeacherQuestion={id:number;prompt:string;type:'multiple_choice'|'true_false';choices:string;answer:string};

async function api<T>(url:string,options?:RequestInit):Promise<T>{
  const {data:{session}}=await getSupabaseBrowserClient().auth.getSession();
  if(!session?.access_token) throw new Error('Your session expired. Please sign in again.');
  const response=await fetch(url,{...options,headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.access_token}`,...(options?.headers||{})}});
  const body=await response.json().catch(()=>({})) as Record<string,unknown>;
  if(!response.ok) throw new Error(typeof body.error==='string'?body.error:'Request failed');
  return body as T;
}

function lessonFormulaToLatex(formula:string){
  const known:Record<string,string>={
    'f(x) = y':'f(x)=y',
    'f(x) = P(x) / Q(x), Q(x) ≠ 0':'\\displaystyle f(x)=\\frac{P(x)}{Q(x)},\\quad Q(x)\\ne 0',
    'f⁻¹(f(x)) = x':'f^{-1}(f(x))=x',
    'Mastery = reasoning + verification':'\\text{Mastery}=\\text{reasoning}+\\text{verification}',
  };
  return known[formula]??formula.replaceAll('⁻¹','^{-1}').replaceAll('≠','\\ne ');
}

export default function DashboardClient({authenticatedUser}:{authenticatedUser:AuthUser}){
  const [data,setData]=useState<Bootstrap|null>(null);
  const [active,setActive]=useState('Dashboard');
  const [toast,setToast]=useState('');
  const [error,setError]=useState('');
  const [lesson,setLesson]=useState<LessonDetail|null>(null);
  const [room,setRoom]=useState<RoomDetail|null>(null);
  const [busy,setBusy]=useState(false);
  const [mobileMenuOpen,setMobileMenuOpen]=useState(false);
  const notify=(message:string)=>{setToast(message);setTimeout(()=>setToast(''),2800)};
  const signOut=async()=>{setMobileMenuOpen(false);await getSupabaseBrowserClient().auth.signOut()};
  const load=useCallback(async()=>{try{setError('');setData(await api<Bootstrap>('/api/bootstrap'));}catch(e){setError(e instanceof Error?e.message:'Unable to load');}},[]);
  useEffect(()=>{let mounted=true;api<Bootstrap>('/api/bootstrap').then(value=>{if(mounted)setData(value)}).catch(e=>{if(mounted)setError(e instanceof Error?e.message:'Unable to load')});return()=>{mounted=false}},[]);

  const setRole=async(role:'student'|'teacher')=>{setBusy(true);try{await api('/api/profile',{method:'POST',body:JSON.stringify({role})});setActive('Dashboard');await load();notify(`Switched to ${role} workspace`);}catch(e){setError(String(e))}finally{setBusy(false)}};
  const openLesson=async(id:string)=>{setBusy(true);try{setLesson(await api<LessonDetail>(`/api/lessons/${id}`));}catch(e){notify(e instanceof Error?e.message:'Could not open lesson')}finally{setBusy(false)}};
  const openRoom=useCallback(async(code:string)=>{try{setRoom(await api<RoomDetail>(`/api/rooms/${code}`));}catch(e){notify(e instanceof Error?e.message:'Could not open room')}},[]);

  const activeRoomCode=room?.room.inviteCode;
  useEffect(()=>{
    if(!activeRoomCode) return;
    const timer=setInterval(()=>void openRoom(activeRoomCode),2000);
    return()=>clearInterval(timer);
  },[activeRoomCode,openRoom]);

  useEffect(()=>{
    const attemptId=room?.attempt?.id;
    if(!attemptId||room?.room.status!=='live') return;
    const send=(eventType:string)=>void api('/api/monitoring',{method:'POST',body:JSON.stringify({attemptId,eventType})}).catch(()=>undefined);
    const visibility=()=>{if(document.hidden)send('visibility_hidden')};
    const blur=()=>send('focus_lost');
    const fullscreen=()=>{if(!document.fullscreenElement)send('fullscreen_exit')};
    document.addEventListener('visibilitychange',visibility);window.addEventListener('blur',blur);document.addEventListener('fullscreenchange',fullscreen);
    return()=>{document.removeEventListener('visibilitychange',visibility);window.removeEventListener('blur',blur);document.removeEventListener('fullscreenchange',fullscreen)};
  },[room?.attempt?.id,room?.room.status]);

  useEffect(()=>{
    if(!mobileMenuOpen)return;
    const close=(event:KeyboardEvent)=>{if(event.key==='Escape')setMobileMenuOpen(false)};
    const previousOverflow=document.body.style.overflow;
    document.body.style.overflow='hidden';
    document.addEventListener('keydown',close);
    return()=>{document.body.style.overflow=previousOverflow;document.removeEventListener('keydown',close)};
  },[mobileMenuOpen]);

  if(!data)return <main className="loading"><div className="loading-brand"><BrandLogo priority /><small>Preparing {authenticatedUser.name}&apos;s learning space…</small></div>{error&&<button onClick={()=>void load()}>Retry</button>}</main>;
  const role=data.user.role==='teacher'?'teacher':'student';
  const initials=data.user.displayName.split(/\s+/).map(x=>x[0]).join('').slice(0,2).toUpperCase();
  const navigate=(section:string)=>{setActive(section);setMobileMenuOpen(false);window.scrollTo({top:0,behavior:'smooth'})};

  return <main className="shell">
    <aside className="sidebar">
      <div className="sidebar-brand"><BrandLogo priority /></div>
      <nav>{[['⌂','Dashboard'],['◫','Learn'],['⚡','Quiz rooms'],['♜','Achievements'],['▥','Progress'],['◉','Math-io Mart']].map(([i,t])=><button key={t} onClick={()=>navigate(t)} className={active===t?'active':''}><i>{i}</i>{t}</button>)}</nav>
      <div className="sidebottom">
        <div className="role"><button disabled={busy} onClick={()=>void setRole('student')} className={role==='student'?'on':''}>Student</button><button disabled={busy} onClick={()=>void setRole('teacher')} className={role==='teacher'?'on':''}>Teacher</button></div>
        <div className="profile"><span>{initials}</span><div><b>{data.user.displayName}</b><small>{role==='student'?'STEM STUDENT':'Mathematics teacher'}</small></div><button className="signout" onClick={()=>void signOut()}>Sign out</button></div>
      </div>
    </aside>
    <section className="content">
      <header><div className="mobilelogo"><BrandLogo /></div><div className="wallet"><span>🔥 <b>{data.inventory.streak}</b><small>day streak</small></span><span>◉ <b>{data.inventory.coins}</b><small>coins</small></span><span>💡 <b>{data.inventory.hints}</b><small>hints</small></span><ThemeToggle /><button aria-label="Notifications">♢<i/></button></div></header>
      <div className="page">
        {error&&<div className="errorbar">{error}<button onClick={()=>setError('')}>×</button></div>}
        {active==='Dashboard'?(role==='teacher'?<TeacherHome data={data} openRoom={openRoom} setActive={setActive}/>:<StudentHome data={data} openLesson={openLesson} setActive={setActive}/>)
        :active==='Learn'?<Learn data={data} openLesson={openLesson}/>
        :active==='Quiz rooms'?<Rooms data={data} refresh={load} openRoom={openRoom} notify={notify}/>
        :active==='Achievements'?<Achievements data={data}/>
        :active==='Progress'?<Progress data={data}/>
        :<Mart data={data} refresh={load} notify={notify}/>}
      </div>
    </section>
    <nav className="mobile-nav" aria-label="Primary navigation">
      {([['⌂','Dashboard','Home'],['◫','Learn','Learn'],['⚡','Quiz rooms','Rooms'],['♜','Achievements','Awards']] as const).map(([icon,target,label])=><button key={target} onClick={()=>navigate(target)} className={active===target?'active':''}><i>{icon}</i><span>{label}</span></button>)}
      <button aria-expanded={mobileMenuOpen} aria-controls="mobile-account-menu" onClick={()=>setMobileMenuOpen(true)} className={active==='Progress'||active==='Math-io Mart'?'active':''}><i>☰</i><span>More</span></button>
    </nav>
    {mobileMenuOpen&&<div className="mobile-menu-backdrop" onClick={()=>setMobileMenuOpen(false)}>
      <section id="mobile-account-menu" className="mobile-menu-panel" role="dialog" aria-modal="true" aria-label="More navigation and account options" onClick={event=>event.stopPropagation()}>
        <div className="mobile-menu-profile"><span>{initials}</span><div><b>{data.user.displayName}</b><small>{role==='student'?'STEM STUDENT':'Mathematics teacher'}</small></div><button className="mobile-menu-close" aria-label="Close menu" onClick={()=>setMobileMenuOpen(false)}>×</button></div>
        <div className="mobile-menu-links"><button className={active==='Progress'?'active':''} onClick={()=>navigate('Progress')}><i>▥</i><span><b>Progress</b><small>Mastery and learning history</small></span></button><button className={active==='Math-io Mart'?'active':''} onClick={()=>navigate('Math-io Mart')}><i>◉</i><span><b>Math-io Mart</b><small>Spend your earned coins</small></span></button></div>
        <div className="mobile-role"><span>Workspace</span><div><button disabled={busy} onClick={()=>void setRole('student')} className={role==='student'?'on':''}>Student</button><button disabled={busy} onClick={()=>void setRole('teacher')} className={role==='teacher'?'on':''}>Teacher</button></div></div>
        <button className="mobile-signout" onClick={()=>void signOut()}>Sign out</button>
      </section>
    </div>}
    {lesson&&<LessonModal detail={lesson} data={data} close={()=>setLesson(null)} reload={async()=>{await openLesson(lesson.lesson.id);await load()}} notify={notify}/>}
    {room&&<RoomModal detail={room} role={role} close={()=>setRoom(null)} reload={()=>openRoom(room.room.inviteCode)} notify={notify}/>}
    {busy&&<div className="busy">Saving…</div>}{toast&&<div className="toast">✓ {toast}</div>}
  </main>;
}

function StudentHome({data,openLesson,setActive}:{data:Bootstrap;openLesson:(id:string)=>void;setActive:(x:string)=>void}){
  const next=data.lessons.find(l=>l.state!=='locked'&&l.state!=='completed');
  return <><section className="greeting"><div><p>YOUR LEARNING SPACE</p><h1>Ready for the next challenge, {data.user.displayName.split(' ')[0]}?</h1><span>Your progress, rewards, and verification results are saved automatically.</span></div><button className="outline" onClick={()=>setActive('Quiz rooms')}>⌁ Join a room</button></section>
  <section className="stats"><Stat icon="◆" cls="violet" label="COURSE PROGRESS" value={`${data.metrics.progress}%`} note={`${data.metrics.completed} of ${data.metrics.total} levels`}/><Stat icon="★" cls="gold" label="TOTAL XP" value={String(data.inventory.xp)} note="Verified learning rewards"/><Stat icon="◉" cls="mint" label="MATH-IO COINS" value={String(data.inventory.coins)} note="Spend in Math-io Mart"/><Stat icon="🔥" cls="peach" label="CURRENT STREAK" value={`${data.inventory.streak} days`} note={`Best: ${data.inventory.longestStreak}`}/></section>
  <div className="grid"><section><div className="title"><div><p>CONTINUE LEARNING</p><h2>General Mathematics</h2></div><button onClick={()=>setActive('Learn')}>View path →</button></div><div className="lessons">{data.lessons.filter(l=>!l.secretStage).map(l=><LessonRow key={l.id} lesson={l} openLesson={openLesson}/>)}</div></section><aside className="right"><div className="title mini"><div><p>NEXT UP</p><h2>{next?.state==='verification'?'Verification check':'Guided practice'}</h2></div><span>Saved</span></div><article className="challenge"><div className="art"><span>f(x)</span><i>?</i><b>3</b><em>+</em></div><h3>{next?.title??'Course complete'}</h3><p>{next?stateCopy(next):'You verified every core level. The secret stage is waiting.'}</p>{next&&<button onClick={()=>openLesson(next.id)}>Open level <b>→</b></button>}</article></aside></div></>;
}
function TeacherHome({data,openRoom,setActive}:{data:Bootstrap;openRoom:(c:string)=>void;setActive:(s:string)=>void}){
  const live=data.rooms.filter(r=>r.status==='live').length; const participants=data.rooms.reduce((a,r)=>a+(r.participants??0),0);
  return <section className="feature"><div className="featurehead"><div><p>TEACHER DASHBOARD</p><h1>General Mathematics classroom</h1><span>Create assessments, share invitation codes, and monitor browser-safe review signals.</span></div><button className="primary" onClick={()=>setActive('Quiz rooms')}>＋ New quiz room</button></div><div className="teacherstats"><Stat label="QUIZ ROOMS" value={String(data.rooms.length)} note="Saved assessments"/><Stat label="LIVE NOW" value={String(live)} note="Teacher-monitored"/><Stat label="PARTICIPANTS" value={String(participants)} note="Across your rooms"/><Stat label="QUESTION BANK" value="6" note="Core + verification"/></div><div className="history"><h2>Your rooms</h2>{data.rooms.length?data.rooms.map(r=><div key={r.id}><b>{r.title}</b><span>{r.inviteCode} · {r.status}</span><button onClick={()=>openRoom(r.inviteCode)}>Manage →</button></div>):<p>No rooms yet. Create one from Quiz rooms.</p>}</div></section>;
}
function Stat({icon='◆',cls='violet',label,value,note}:{icon?:string;cls?:string;label:string;value:string;note:string}){return <article><i className={cls}>{icon}</i><div><small>{label}</small><strong>{value}</strong><p>{note}</p></div></article>}
function LessonRow({lesson,openLesson}:{lesson:Lesson;openLesson:(id:string)=>void}){return <article className={lesson.state==='available'||lesson.state==='verification'||lesson.state==='review_required'?'current':''}><span className="num">{lesson.state==='completed'?'✓':lesson.state==='locked'?'⌕':lesson.unitNumber}</span><div><small>{lesson.secretStage?'SECRET STAGE':lesson.state.replace('_',' ').toUpperCase()}</small><h3>{lesson.title}</h3><p>{stateCopy(lesson)}</p></div>{lesson.state!=='locked'?<button onClick={()=>openLesson(lesson.id)}>{lesson.state==='completed'?'Review':'Open'} <b>→</b></button>:<i>›</i>}</article>}
function stateCopy(l:Lesson){if(l.state==='completed')return `Mastered · ${l.bestScore}% · review anytime`;if(l.state==='verification')return 'Same-topic verification set in progress';if(l.state==='review_required')return `Full lesson review required · resent ${l.lessonResendCount}×`;if(l.state==='locked')return 'Complete and verify the previous level';return `${l.coinReward} coins · ${l.xpReward} XP`;}

function Learn({data,openLesson}:{data:Bootstrap;openLesson:(id:string)=>void}){return <section className="feature"><div className="featurehead"><div><p>LEARNING PATH</p><h1>General Mathematics</h1><span>Each level includes a full practice set followed by different-example verification.</span></div><div className="tokenrow"><b>◉ {data.inventory.coins}</b><b>◆ {data.inventory.revives} revives</b><b>💡 {data.inventory.hints} hints</b></div></div><div className="path">{data.lessons.map(l=><article key={l.id} className={`unit ${l.state==='completed'?'done':l.state==='locked'?'locked':'open'}`}><span>{l.state==='completed'?'✓':l.state==='locked'?'⌕':l.unitNumber}</span><div><small>{l.secretStage?'SECRET STAGE':l.state.replace('_',' ').toUpperCase()}</small><h2>{l.title}</h2><p>{stateCopy(l)}</p></div>{l.state!=='locked'&&<button onClick={()=>openLesson(l.id)}>{l.state==='completed'?'Review':'Open'}</button>}</article>)}</div></section>}

function Rooms({data,refresh,openRoom,notify}:{data:Bootstrap;refresh:()=>Promise<void>;openRoom:(c:string)=>void;notify:(m:string)=>void}){
  const [code,setCode]=useState('');
  const [title,setTitle]=useState('Functions mastery check');
  const [delivery,setDelivery]=useState('teacher_paced');
  const [fullscreen,setFullscreen]=useState(true);
  const [busy,setBusy]=useState(false);
  const [questions,setQuestions]=useState<TeacherQuestion[]>([{id:1,prompt:'Which relation is a function?',type:'multiple_choice',choices:'{(1,2),(1,3)}\n{(1,2),(2,3)}\n{(2,1),(2,4)}',answer:'{(1,2),(2,3)}'}]);
  const blankQuestion=(id:number):TeacherQuestion=>({id,prompt:'',type:'multiple_choice',choices:'',answer:''});
  const updateQuestion=(id:number,patch:Partial<Omit<TeacherQuestion,'id'>>)=>setQuestions(current=>current.map(question=>question.id===id?{...question,...patch}:question));
  const addQuestion=()=>setQuestions(current=>current.length>=50?current:[...current,blankQuestion(Math.max(...current.map(question=>question.id),0)+1)]);
  const setQuestionCount=(requested:number)=>setQuestions(current=>{
    const count=Math.max(1,Math.min(50,Number.isFinite(requested)?Math.floor(requested):1));
    if(count<=current.length)return current.slice(0,count);
    const firstId=Math.max(...current.map(question=>question.id),0)+1;
    return [...current,...Array.from({length:count-current.length},(_,offset)=>blankQuestion(firstId+offset))];
  });
  const removeQuestion=(id:number)=>setQuestions(current=>current.length===1?current:current.filter(question=>question.id!==id));
  const choicesFor=(question:TeacherQuestion)=>question.type==='true_false'?['True','False']:question.choices.split('\n').map(value=>value.trim()).filter(Boolean);
  const validQuestions=questions.every(question=>{const choices=choicesFor(question);return Boolean(question.prompt.trim()&&question.answer.trim()&&choices.length>=2&&choices.includes(question.answer.trim()))});
  const create=async()=>{setBusy(true);try{const payloadQuestions=questions.map(question=>({prompt:question.prompt.trim(),type:question.type,choices:choicesFor(question),answer:question.answer.trim()}));const r=await api<{inviteCode:string}>('/api/rooms',{method:'POST',body:JSON.stringify({title,deliveryMode:delivery,requestFullscreen:fullscreen,questions:payloadQuestions})});await refresh();notify(`Room ${r.inviteCode} created with ${questions.length} question${questions.length===1?'':'s'}`);openRoom(r.inviteCode)}catch(e){notify(e instanceof Error?e.message:'Could not create room')}finally{setBusy(false)}};
  const join=async()=>{setBusy(true);try{await api(`/api/rooms/${code.toUpperCase()}`,{method:'POST',body:JSON.stringify({action:'join'})});await refresh();openRoom(code.toUpperCase())}catch(e){notify(e instanceof Error?e.message:'Could not join room')}finally{setBusy(false)}};
  return <section className="feature"><div className="featurehead"><div><p>{data.user.role==='teacher'?'ASSESSMENT STUDIO':'LIVE & SELF-PACED'}</p><h1>Quiz rooms</h1><span>{data.user.role==='teacher'?'Create a persistent room and share its invitation code.':'Enter the invitation code shared by your teacher.'}</span></div></div>
  {data.user.role==='teacher'?<article className="createcard"><div className="createcard-heading"><div><h2>Create a quiz room</h2><p>Choose the number of problems, then complete every question card.</p></div><span>{questions.length} question{questions.length===1?'':'s'}</span></div><div className="formgrid"><label>Quiz title<input value={title} onChange={e=>setTitle(e.target.value)}/></label><label>Number of questions<input type="number" min={1} max={50} value={questions.length} onChange={event=>setQuestionCount(Number(event.target.value))}/></label><label>Delivery<select value={delivery} onChange={e=>setDelivery(e.target.value)}><option value="teacher_paced">Teacher paced</option><option value="self_paced">Self paced</option></select></label></div><div className="question-list">{questions.map((question,index)=>{const choices=choicesFor(question);return <section className="question-editor" key={question.id}><div className="question-editor-heading"><div><small>QUESTION {index+1}</small><h3>Problem details</h3></div>{questions.length>1&&<button className="remove-question" type="button" onClick={()=>removeQuestion(question.id)}>Remove</button>}</div><label>Question prompt<input value={question.prompt} onChange={event=>updateQuestion(question.id,{prompt:event.target.value})}/></label><label>Question type<select value={question.type} onChange={event=>{const type=event.target.value as TeacherQuestion['type'];updateQuestion(question.id,{type,choices:type==='true_false'?'True\nFalse':question.choices==='True\nFalse'?'':question.choices,answer:type==='true_false'?(question.answer==='False'?'False':'True'):question.answer})}}><option value="multiple_choice">Multiple choice</option><option value="true_false">True or false</option></select></label>{question.type==='multiple_choice'&&<label>Choices · one per line<textarea value={question.choices} onChange={event=>{const choicesText=event.target.value;const nextChoices=choicesText.split('\n').map(value=>value.trim()).filter(Boolean);updateQuestion(question.id,{choices:choicesText,answer:nextChoices.includes(question.answer)?question.answer:''})}} rows={4}/></label>}<label>Correct answer<select value={question.answer} onChange={event=>updateQuestion(question.id,{answer:event.target.value})}><option value="">Select the correct answer</option>{choices.map(choice=><option value={choice} key={choice}>{choice}</option>)}</select></label></section>})}</div><div className="question-actions"><button className="add-question" type="button" disabled={questions.length>=50} onClick={addQuestion}>＋ Add another question</button><small>{questions.length}/50 questions</small></div><label className="check"><input type="checkbox" checked={fullscreen} onChange={e=>setFullscreen(e.target.checked)}/> Request fullscreen during live play</label><button disabled={busy||title.trim().length<3||!validQuestions} onClick={()=>void create()}>Create room with {questions.length} question{questions.length===1?'':'s'}</button></article>:<article className="joincard"><label>Invitation code<input value={code} onChange={e=>setCode(e.target.value.toUpperCase())} placeholder="ABC-123" maxLength={7}/></label><button disabled={busy||code.length<7} onClick={()=>void join()}>Join room</button></article>}
  <div className="roomgrid cards">{data.rooms.map(r=><article className="livecard" key={r.id}><div><span className={r.status==='live'?'live':''}>{r.status==='live'?'● LIVE':r.status.toUpperCase()}</span><small>{r.inviteCode}</small></div><h2>{r.title}</h2><p>{r.deliveryMode.replace('_',' ')}{r.questionCount!==undefined?` · ${r.questionCount} question${r.questionCount===1?'':'s'}`:''}{r.participants!==undefined?` · ${r.participants} participants`:''}</p><button onClick={()=>openRoom(r.inviteCode)}>{data.user.role==='teacher'?'Manage room':'Open room'}</button></article>)}</div>
  <div className="notice"><b>Fair assessment, careful interpretation</b><p>The system can record visibility loss, focus loss, fullscreen exits, and connection loss. These events provide context for review, but they do not prove dishonesty or identify any specific external app or website.</p></div></section>;
}

function Achievements({data}:{data:Bootstrap}){return <section className="feature"><div className="featurehead"><div><p>ACHIEVEMENT BOARD</p><h1>Your trophy cabinet</h1><span>Achievements are awarded from saved verification and retry events.</span></div><b className="levelbadge">Level {Math.floor(data.inventory.xp/250)+1}</b></div><div className="badges">{data.achievements.map(a=><article className={a.earned?'earned':''} key={a.id}><span>{a.earned?'★':'⌕'}</span><h3>{a.title}</h3><p>{a.description}</p><small>{a.earned?'EARNED':`+${a.xpReward} XP`}</small></article>)}</div></section>}
function Progress({data}:{data:Bootstrap}){const done=data.lessons.filter(l=>l.state==='completed');const focus=data.lessons.find(l=>l.state!=='completed'&&l.state!=='locked');return <section className="feature"><div className="featurehead"><div><p>LEARNING ANALYTICS</p><h1>Progress & mastery</h1><span>Evidence comes from server-recorded lessons, attempts, and verification problems.</span></div></div><div className="mastery"><article><small>VERIFIED PROGRESS</small><b>{data.metrics.progress}%</b><div className="ring">{data.metrics.progress}</div></article><article><small>VERIFIED LEVELS</small><h2>{done.length} of {data.lessons.length}</h2><b className="good">{done.length?'Mastery recorded':'Begin your first level'}</b></article><article><small>FOCUS NEXT</small><h2>{focus?.title??'Secret stage'}</h2><b className="warn">{focus?stateCopy(focus):'All core work complete'}</b></article></div><div className="history"><h2>Level evidence</h2>{data.lessons.map(l=><div key={l.id}><b>{l.title}</b><span>{l.state.replace('_',' ')}</span><small>{l.failureCount} failures · {l.lessonResendCount} lesson resends</small></div>)}</div></section>}
function Mart({data,refresh,notify}:{data:Bootstrap;refresh:()=>Promise<void>;notify:(m:string)=>void}){const buy=async(item:string)=>{try{await api('/api/shop',{method:'POST',body:JSON.stringify({item})});await refresh();notify('Purchase complete')}catch(e){notify(e instanceof Error?e.message:'Purchase failed')}};const reviveStreak=async()=>{try{await api('/api/streak/revive',{method:'POST'});await refresh();notify('Streak restored')}catch(e){notify(e instanceof Error?e.message:'Could not restore streak')}};return <section className="feature"><div className="featurehead"><div><p>MATH-IO MART</p><h1>Power-ups with purpose</h1><span>Use coins earned through verified learning. Tokens support persistence without replacing reasoning.</span></div><b className="levelbadge">◉ {data.inventory.coins}</b></div><div className="badges shop">{[['◆','Revive token','Restart a locked difficult level while keeping adaptive hints.','revive','100'],['🔥','Streak-revive','Restore a broken learning streak without adding fake activity.','streak_revive','150'],['💡','Special hint','Reveal only a small portion of a final answer, once per level.','hint','75']].map(([icon,title,desc,item,cost])=><article className="earned" key={item}><span>{icon}</span><h3>{title}</h3><p>{desc}</p><button onClick={()=>void buy(item)}>Buy · ◉ {cost}</button></article>)}</div><button className="outline revive-streak" onClick={()=>void reviveStreak()}>Use one streak-revive token ({data.inventory.streakRevives} owned)</button></section>}

function LessonModal({detail,data,close,reload,notify}:{detail:LessonDetail;data:Bootstrap;close:()=>void;reload:()=>Promise<void>;notify:(m:string)=>void}){
  const [answer,setAnswer]=useState('');const [answerLatex,setAnswerLatex]=useState('');const [feedback,setFeedback]=useState<{correct?:boolean;message?:string;hint?:string;specialHint?:string;explanation?:string;reviewRequired?:boolean;completed?:boolean}|null>(null);const [busy,setBusy]=useState(false);
  const stageProgress=detail.stageProgress??{completed:0,required:1,total:1,current:1};
  const submit=async(useSpecialHint=false)=>{setBusy(true);try{const result=await api<typeof feedback>(`/api/lessons/${detail.lesson.id}/answer`,{method:'POST',body:JSON.stringify({answer,useSpecialHint})});setFeedback(result);notify(result?.message||result?.specialHint||'Saved');if(result?.correct){setAnswer('');setAnswerLatex('');await reload()}}catch(e){notify(e instanceof Error?e.message:'Could not save answer')}finally{setBusy(false)}};
  const review=async()=>{await api(`/api/lessons/${detail.lesson.id}/review`,{method:'POST'});await reload();notify('Lesson reviewed and level reopened')};
  const revive=async()=>{await api(`/api/lessons/${detail.lesson.id}/revive`,{method:'POST'});await reload();notify('Revive token used')};
  return <div className="modalback" role="dialog" aria-modal="true"><section className="modal"><button className="close" onClick={close}>×</button><p className="eyebrow">{detail.verification?'SAME-TOPIC VERIFICATION':detail.lesson.secretStage?'SECRET STAGE':`UNIT ${detail.lesson.unitNumber}`}</p><h1>{detail.lesson.title}</h1><div className="lessoncopy"><b>{detail.lesson.content.summary}</b><ol>{detail.lesson.content.steps.map(s=><li key={s}>{s}</li>)}</ol><div className="formula-panel"><span>LATEX FORMULA</span><MathFormula latex={lessonFormulaToLatex(detail.lesson.content.formula)} label={`${detail.lesson.title} formula`}/></div></div>
  {detail.lesson.state==='review_required'?<div className="reviewgate"><h3>Full review required</h3><p>After three failures, the level was locked and this lesson was resent. Read it completely, then reopen practice—or use a revive token.</p><div><button onClick={()=>void review()}>I completed the review</button><button disabled={!data.inventory.revives} onClick={()=>void revive()}>Use revive ({data.inventory.revives})</button></div></div>:detail.question&&<div className="question"><div className="quizprogress lesson-progress"><span>{detail.verification?'Verification':'Practice'} problem {stageProgress.current} of {stageProgress.required}</span><span>{stageProgress.completed} solved</span></div><h2>{detail.question.prompt}</h2>{detail.question.choices?<div className="answers">{detail.question.choices.map(c=><button className={answer===c?'chosen':''} onClick={()=>setAnswer(c)} key={c}>{c}</button>)}</div>:<MathAnswerField value={answerLatex} onChange={(latex,plainText)=>{setAnswerLatex(latex);setAnswer(plainText)}}/>}{feedback&&<div className={feedback.correct?'feedback correct':'feedback'}>{feedback.message||feedback.hint||feedback.specialHint}{feedback.explanation&&<p>{feedback.explanation}</p>}</div>}<div className="modalactions"><button className="outline" disabled={busy||!data.inventory.hints} onClick={()=>void submit(true)}>💡 Special hint ({data.inventory.hints})</button><button className="primary" disabled={busy||!answer} onClick={()=>void submit(false)}>Check answer</button></div></div>}</section></div>;
}

function RoomModal({detail,role,close,reload,notify}:{detail:RoomDetail;role:string;close:()=>void;reload:()=>Promise<void>;notify:(m:string)=>void}){
  const [index,setIndex]=useState(0);
  const [draftAnswers,setDraftAnswers]=useState<Record<string,string>>({});
  const [draftLatex,setDraftLatex]=useState<Record<string,string>>({});
  const [questionFeedback,setQuestionFeedback]=useState<Record<string,string>>({});
  const [busy,setBusy]=useState(false);
  const teacher=role==='teacher';
  const q=detail.questions[index];
  const responses=detail.responses??[];
  const storedResponse=q?responses.find(response=>response.questionId===q.id):undefined;
  const answer=storedResponse?.answer??(q?draftAnswers[q.id]??'':'');
  const answerLatex=q?draftLatex[q.id]??'':'';
  const feedback=q?(questionFeedback[q.id]??(storedResponse?`${storedResponse.correct?'Correct':'Not quite'}. Answer recorded.`:'')):'';
  const setCurrentAnswer=(value:string)=>{if(q)setDraftAnswers(current=>({...current,[q.id]:value}))};
  const setCurrentLatex=(value:string)=>{if(q)setDraftLatex(current=>({...current,[q.id]:value}))};
  const moveTo=(nextIndex:number)=>setIndex(nextIndex);
  const act=async(action:string)=>{try{await api(`/api/rooms/${detail.room.inviteCode}`,{method:'POST',body:JSON.stringify({action})});await reload();notify(`Room ${action}ed`)}catch(e){notify(e instanceof Error?e.message:'Room action failed')}};
  const submit=async()=>{if(!q||storedResponse)return;setBusy(true);try{const r=await api<{correct:boolean;explanation:string;answered:number;total:number;score:number}>(`/api/rooms/${detail.room.inviteCode}`,{method:'POST',body:JSON.stringify({action:'answer',questionId:q.id,answer})});setQuestionFeedback(current=>({...current,[q.id]:`${r.correct?'Correct':'Not quite'}. ${r.explanation}`}));await reload();notify(`Answer ${r.answered} of ${r.total} saved · score ${r.score}%`)}catch(e){notify(e instanceof Error?e.message:'Answer failed')}finally{setBusy(false)}};
  const copy=()=>{void navigator.clipboard.writeText(detail.room.inviteCode);notify('Invitation code copied')};
  const allAnswered=detail.questions.length>0&&responses.length===detail.questions.length;
  return <div className="modalback" role="dialog" aria-modal="true"><section className="modal roommodal"><button className="close" onClick={close}>×</button><p className="eyebrow">{detail.room.status.toUpperCase()} · {detail.room.deliveryMode.replace('_',' ')}</p><h1>{detail.room.title}</h1><button className="codebutton" onClick={copy}>{detail.room.inviteCode} · copy</button>
  {teacher?<><div className="modalactions"><button className="primary" disabled={detail.room.status==='live'||detail.room.status==='closed'} onClick={()=>void act('start')}>Start live quiz</button><button className="outline" disabled={detail.room.status==='closed'} onClick={()=>void act('close')}>Close room</button></div><div className="room-question-summary"><p>QUIZ CONTENT · {detail.questions.length} QUESTION{detail.questions.length===1?'':'S'}</p><ol>{detail.questions.map(question=><li key={question.id}>{question.prompt}</li>)}</ol></div><div className="monitor"><div><p>LIVE MONITOR</p><h2>Participants</h2></div><div className="monitorhead"><span>Student</span><span>Answered</span><span>Score</span><span>Review signals</span></div>{detail.participants?.length?detail.participants.map(p=><div className="monitorrow" key={p.attemptId}><b>{p.name}</b><span>{p.answered} / {detail.questions.length}</span><span>{p.score}%</span><small className={p.signals?'signal':'clear'}>{p.signals}</small></div>):<p className="empty">Waiting for students to join…</p>}<footer>Signals are contextual indicators for review, not automated cheating verdicts.</footer></div></>:detail.room.status==='waiting'&&detail.room.deliveryMode==='teacher_paced'?<div className="waiting"><b>You’re in the room.</b><p>Waiting for the teacher to start. This screen updates automatically.</p></div>:detail.room.status==='closed'?<div className="waiting"><b>Room closed</b><p>Your recorded score is {detail.attempt?.score??0}%.</p></div>:q?<>{allAnswered&&<div className="quiz-complete"><b>All questions answered.</b><span>Current score: {detail.attempt?.score??0}%</span></div>}<div className="question"><div className="quizprogress"><span>Question {index+1} of {detail.questions.length}</span><span>{responses.length} answered</span></div><h2>{q.prompt}</h2>{q.choices?<div className="answers">{q.choices.map(c=><button disabled={Boolean(storedResponse)} className={answer===c?'chosen':''} onClick={()=>setCurrentAnswer(c)} key={c}>{c}</button>)}</div>:<MathAnswerField value={answerLatex} onChange={(latex,plainText)=>{if(!storedResponse){setCurrentLatex(latex);setCurrentAnswer(plainText)}}} label="Enter your quiz answer"/>}{feedback&&<div className={storedResponse?.correct?'feedback correct':'feedback'}>{feedback}</div>}<div className="modalactions"><button className="outline" disabled={index===0} onClick={()=>moveTo(index-1)}>Previous</button><button className="primary" disabled={busy||!answer||Boolean(storedResponse)} onClick={()=>void submit()}>{storedResponse?'Answer submitted':'Submit answer'}</button><button className="outline" disabled={index===detail.questions.length-1} onClick={()=>moveTo(index+1)}>Next</button></div></div></>:null}</section></div>;
}
