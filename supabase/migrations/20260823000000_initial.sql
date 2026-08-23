
create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null,
  role text not null default 'student' check (role in ('student','teacher','admin')),
  grade_level text,
  strand text,
  created_at timestamptz not null default now()
);
create unique index if not exists idx_users_email on public.users(email);

create table if not exists public.classrooms (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  section text not null,
  school_year text not null,
  created_at timestamptz not null default now()
);
create index if not exists idx_classrooms_teacher on public.classrooms(teacher_id);

create table if not exists public.classroom_members (
  id uuid primary key default gen_random_uuid(),
  classroom_id uuid not null references public.classrooms(id) on delete cascade,
  student_id uuid not null references public.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  unique (classroom_id, student_id)
);

create table if not exists public.courses (
  id text primary key,
  title text not null,
  description text not null,
  grade_level text not null,
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id text primary key,
  course_id text not null references public.courses(id) on delete cascade,
  unit_number integer not null,
  lesson_number integer not null,
  title text not null,
  concept_key text not null,
  content jsonb not null,
  coin_reward integer not null default 20,
  xp_reward integer not null default 50,
  secret_stage boolean not null default false,
  unique (course_id, unit_number, lesson_number)
);

create table if not exists public.questions (
  id text primary key,
  lesson_id text references public.lessons(id) on delete cascade,
  concept_key text not null,
  type text not null check (type in ('multiple_choice','true_false','numeric')),
  prompt text not null,
  choices jsonb,
  answer text not null,
  explanation text not null,
  hint_1 text not null,
  hint_2 text not null,
  partial_answer_hint text not null,
  verification boolean not null default false,
  difficulty integer not null default 1
);
create index if not exists idx_questions_concept on public.questions(concept_key, difficulty);

create table if not exists public.quiz_rooms (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.users(id) on delete cascade,
  classroom_id uuid references public.classrooms(id) on delete set null,
  title text not null,
  invite_code text not null unique,
  delivery_mode text not null check (delivery_mode in ('teacher_paced','self_paced')),
  status text not null default 'draft' check (status in ('draft','waiting','live','closed')),
  question_ids text[] not null,
  request_fullscreen boolean not null default false,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_quiz_rooms_teacher on public.quiz_rooms(teacher_id);

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  lesson_id text references public.lessons(id) on delete cascade,
  room_id uuid references public.quiz_rooms(id) on delete cascade,
  status text not null default 'active' check (status in ('active','passed','failed','abandoned')),
  score integer not null default 0,
  retry_count integer not null default 0,
  special_hint_used boolean not null default false,
  verification_required boolean not null default false,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);
create index if not exists idx_attempts_user on public.attempts(user_id, started_at desc);
create index if not exists idx_attempts_room on public.attempts(room_id);

create table if not exists public.responses (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  question_id text not null references public.questions(id) on delete cascade,
  answer text not null,
  correct boolean not null,
  hint_level integer not null default 0,
  answered_at timestamptz not null default now()
);
create index if not exists idx_responses_attempt on public.responses(attempt_id);
create unique index if not exists idx_responses_attempt_question on public.responses(attempt_id, question_id);

create table if not exists public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  lesson_id text not null references public.lessons(id) on delete cascade,
  state text not null check (state in ('locked','available','review_required','verification','completed')),
  best_score integer not null default 0,
  failure_count integer not null default 0,
  lesson_resend_count integer not null default 0,
  completed_at timestamptz,
  unique (user_id, lesson_id)
);

create table if not exists public.inventories (
  user_id uuid primary key references public.users(id) on delete cascade,
  mathio_coins integer not null default 0,
  revive_tokens integer not null default 0,
  streak_revive_tokens integer not null default 0,
  hint_tokens integer not null default 0,
  xp integer not null default 0,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_learning_date date
);

create table if not exists public.achievements (
  id text primary key,
  key text not null unique,
  title text not null,
  description text not null,
  criteria jsonb not null,
  xp_reward integer not null default 0
);

create table if not exists public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  achievement_id text not null references public.achievements(id) on delete cascade,
  earned_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);

create table if not exists public.monitoring_events (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.attempts(id) on delete cascade,
  event_type text not null check (event_type in ('visibility_hidden','focus_lost','fullscreen_exit','connection_lost')),
  occurred_at timestamptz not null default now(),
  detail jsonb
);
create index if not exists idx_monitoring_attempt on public.monitoring_events(attempt_id, occurred_at);

create table if not exists public.reward_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  kind text not null check (kind in ('coins','revive','streak_revive','hint','xp')),
  amount integer not null,
  reason text not null,
  reference_id text,
  created_at timestamptz not null default now()
);
create index if not exists idx_rewards_user on public.reward_transactions(user_id, created_at);

create table if not exists public.room_events (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.quiz_rooms(id) on delete cascade,
  actor_id uuid not null references public.users(id) on delete cascade,
  event_type text not null check (event_type in ('joined','started','question_changed','answered','closed')),
  payload jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_room_events_cursor on public.room_events(room_id, created_at);

insert into public.courses (id,title,description,grade_level,published) values
  ('general-math','General Mathematics','Functions, rational expressions, inverse functions and mathematical literacy practice.','Grade 11',true)
on conflict (id) do update set title=excluded.title,description=excluded.description,grade_level=excluded.grade_level,published=excluded.published;

insert into public.lessons (id,course_id,unit_number,lesson_number,title,concept_key,content,coin_reward,xp_reward,secret_stage) values
  ('lesson-functions','general-math',1,1,'Functions & Relations','functions','{"summary":"A function maps every input to exactly one output.","steps":["Identify the input set (domain).","Check that each input has only one output.","Evaluate by substituting the input value."],"formula":"f(x) = y"}'::jsonb,40,80,false),
  ('lesson-rational','general-math',2,1,'Rational Functions','rational','{"summary":"A rational function is a ratio of polynomials.","steps":["Set the denominator equal to zero.","Solve for excluded values.","Write the domain without those values."],"formula":"f(x) = P(x) / Q(x), Q(x) ≠ 0"}'::jsonb,55,100,false),
  ('lesson-inverse','general-math',3,1,'Inverse Functions','inverse','{"summary":"An inverse reverses the input-output relationship.","steps":["Replace f(x) with y.","Swap x and y.","Solve for y."],"formula":"f⁻¹(f(x)) = x"}'::jsonb,70,120,false),
  ('lesson-secret','general-math',4,1,'The Infinite Staircase','secret','{"summary":"A secret mixed challenge for verified masters.","steps":["Recognize the concept.","Choose an efficient representation.","Justify the result."],"formula":"Mastery = reasoning + verification"}'::jsonb,150,250,true)
on conflict (id) do update set title=excluded.title,concept_key=excluded.concept_key,content=excluded.content,coin_reward=excluded.coin_reward,xp_reward=excluded.xp_reward,secret_stage=excluded.secret_stage;

insert into public.questions (id,lesson_id,concept_key,type,prompt,choices,answer,explanation,hint_1,hint_2,partial_answer_hint,verification,difficulty) values
  ('q-functions','lesson-functions','functions','multiple_choice','Which relation is a function?','["{(1,2),(1,3)}","{(1,2),(2,3)}","{(2,1),(2,4)}","{(3,2),(3,5)}"]'::jsonb,'{(1,2),(2,3)}','Each input appears only once.','Look at the first coordinate in each ordered pair.','A repeated input with different outputs violates the function rule.','The correct set starts with {(1,2)…',false,1),
  ('q-functions-v','lesson-functions','functions','numeric','If f(x)=2x+1, what is f(4)?',null,'9','Substitute 4: 2(4)+1=9.','Replace x with 4.','Multiply before adding.','The answer is a one-digit odd number greater than 8.',true,2),
  ('q-rational','lesson-rational','rational','multiple_choice','Find the excluded value in f(x)=3/(x−2).','["x = 0","x = 2","x = −2","No exclusions"]'::jsonb,'x = 2','The denominator cannot equal zero, so x−2=0 and x=2.','A denominator cannot equal zero.','Set x−2=0 and isolate x.','The answer begins with “x = 2…”',false,1),
  ('q-rational-v','lesson-rational','rational','multiple_choice','Find the excluded value in g(x)=5/(x+4).','["x = 5","x = 4","x = −4","x = 0"]'::jsonb,'x = −4','Set x+4=0, giving x=−4.','Set the denominator equal to zero.','Undo +4 with −4.','The answer is negative.',true,2),
  ('q-inverse','lesson-inverse','inverse','multiple_choice','What is the inverse of f(x)=x+3?','["x−3","x+3","3x","x/3"]'::jsonb,'x−3','Swap x and y, then solve: y=x−3.','An inverse undoes the original operation.','Undo +3 by subtracting 3.','The expression ends in −3.',false,1),
  ('q-inverse-v','lesson-inverse','inverse','numeric','If f(x)=2x, what is f⁻¹(10)?',null,'5','The inverse divides by 2, so 10/2=5.','Undo multiplication by 2.','Divide 10 by 2.','The answer is between 4 and 6.',true,2),
  ('q-secret','lesson-secret','secret','numeric','A function doubles a number, then adds 6. Its output is 20. What was the input?',null,'7','Solve 2x+6=20, so 2x=14 and x=7.','Reverse the operations in reverse order.','Subtract 6, then divide by 2.','The answer is a single digit greater than 6.',false,3)
on conflict (id) do update set prompt=excluded.prompt,choices=excluded.choices,answer=excluded.answer,explanation=excluded.explanation,hint_1=excluded.hint_1,hint_2=excluded.hint_2,partial_answer_hint=excluded.partial_answer_hint,verification=excluded.verification,difficulty=excluded.difficulty;

insert into public.achievements (id,key,title,description,criteria,xp_reward) values
  ('ach-first','first_verified','Verified Thinker','Pass your first same-topic verification problem.','{"verified":1}'::jsonb,50),
  ('ach-comeback','comeback','Comeback Kid','Pass after three or more retries.','{"retries":3}'::jsonb,75),
  ('ach-secret','secret_scholar','Secret Scholar','Complete the secret stage.','{"secret":true}'::jsonb,150)
on conflict (id) do update set title=excluded.title,description=excluded.description,criteria=excluded.criteria,xp_reward=excluded.xp_reward;

create or replace function public.smiogl_require_user()
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_name text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  v_email := coalesce(auth.jwt()->>'email', v_user_id::text || '@user.local');
  v_name := coalesce(nullif(auth.jwt()->'user_metadata'->>'full_name',''), split_part(v_email,'@',1));
  insert into public.users (id,email,display_name,role,grade_level,strand)
  values (v_user_id,v_email,v_name,'student','Grade 11','STEM')
  on conflict (id) do update set email=excluded.email,display_name=excluded.display_name;
  insert into public.inventories (user_id,mathio_coins,revive_tokens,streak_revive_tokens,hint_tokens)
  values (v_user_id,250,1,1,2)
  on conflict (user_id) do nothing;
  insert into public.lesson_progress (user_id,lesson_id,state)
  select v_user_id,l.id,case when l.unit_number=1 then 'available' else 'locked' end
  from public.lessons l
  where l.course_id='general-math'
  on conflict (user_id,lesson_id) do nothing;
  return v_user_id;
end;
$$;

create or replace function public.smiogl_normalize_answer(p_value text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(translate(coalesce(p_value,''),'−','-')), '\s+', ' ', 'g'));
$$;

create or replace function public.smiogl_bootstrap()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := public.smiogl_require_user();
  v_role text;
  v_rooms jsonb;
  v_completed integer;
  v_total integer;
begin
  select role into v_role from public.users where id=v_user_id;
  if v_role in ('teacher','admin') then
    select coalesce(jsonb_agg(jsonb_build_object(
      'id',r.id,'title',r.title,'inviteCode',r.invite_code,'deliveryMode',r.delivery_mode,
      'status',r.status,'createdAt',extract(epoch from r.created_at)::bigint,
      'participants',(select count(*) from public.attempts a where a.room_id=r.id),
      'questionCount',cardinality(r.question_ids)
    ) order by r.created_at desc),'[]'::jsonb) into v_rooms
    from public.quiz_rooms r where r.teacher_id=v_user_id;
  else
    select coalesce(jsonb_agg(x.room order by x.created_at desc),'[]'::jsonb) into v_rooms
    from (
      select distinct on (r.id) r.created_at,jsonb_build_object(
        'id',r.id,'title',r.title,'inviteCode',r.invite_code,'deliveryMode',r.delivery_mode,
        'status',r.status,'createdAt',extract(epoch from r.created_at)::bigint,
        'questionCount',cardinality(r.question_ids)
      ) as room
      from public.quiz_rooms r join public.attempts a on a.room_id=r.id
      where a.user_id=v_user_id order by r.id,r.created_at desc
    ) x;
  end if;
  select count(*) filter (where state='completed'),count(*) into v_completed,v_total
  from public.lesson_progress where user_id=v_user_id;
  return jsonb_build_object(
    'user',(select jsonb_build_object('id',u.id,'email',u.email,'displayName',u.display_name,'role',u.role) from public.users u where u.id=v_user_id),
    'inventory',(select jsonb_build_object('coins',i.mathio_coins,'revives',i.revive_tokens,'streakRevives',i.streak_revive_tokens,'hints',i.hint_tokens,'xp',i.xp,'streak',i.current_streak,'longestStreak',i.longest_streak) from public.inventories i where i.user_id=v_user_id),
    'lessons',(select coalesce(jsonb_agg(jsonb_build_object(
      'id',l.id,'title',l.title,'unitNumber',l.unit_number,'conceptKey',l.concept_key,'contentJson',l.content::text,
      'coinReward',l.coin_reward,'xpReward',l.xp_reward,'secretStage',case when l.secret_stage then 1 else 0 end,
      'state',p.state,'bestScore',p.best_score,'failureCount',p.failure_count,'lessonResendCount',p.lesson_resend_count
    ) order by l.unit_number,l.lesson_number),'[]'::jsonb) from public.lessons l join public.lesson_progress p on p.lesson_id=l.id and p.user_id=v_user_id),
    'achievements',(select coalesce(jsonb_agg(jsonb_build_object(
      'id',a.id,'title',a.title,'description',a.description,'xpReward',a.xp_reward,
      'earned',case when ua.id is null then 0 else 1 end
    ) order by a.id),'[]'::jsonb) from public.achievements a left join public.user_achievements ua on ua.achievement_id=a.id and ua.user_id=v_user_id),
    'rooms',coalesce(v_rooms,'[]'::jsonb),
    'metrics',jsonb_build_object('completed',v_completed,'total',v_total,'progress',case when v_total=0 then 0 else round(100.0*v_completed/v_total)::int end)
  );
end;
$$;

create or replace function public.smiogl_set_role(p_role text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user();
begin
  if p_role not in ('student','teacher') then return jsonb_build_object('error','Invalid role','status',400); end if;
  update public.users set role=p_role where id=v_user_id;
  return jsonb_build_object('ok',true,'role',p_role);
end; $$;

create or replace function public.smiogl_get_lesson(p_lesson_id text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user();
  v_state text;
  v_lesson jsonb;
  v_question jsonb;
  v_verification boolean;
begin
  select p.state,jsonb_build_object(
    'id',l.id,'title',l.title,'unitNumber',l.unit_number,'contentJson',l.content::text,'content',l.content,
    'secretStage',case when l.secret_stage then 1 else 0 end,'state',p.state,
    'failureCount',p.failure_count,'lessonResendCount',p.lesson_resend_count
  ) into v_state,v_lesson
  from public.lessons l join public.lesson_progress p on p.lesson_id=l.id
  where p.user_id=v_user_id and l.id=p_lesson_id;
  if v_lesson is null then return jsonb_build_object('error','Lesson not found','status',404); end if;
  if v_state='locked' then return jsonb_build_object('error','This level is locked','status',423); end if;
  v_verification := v_state='verification';
  select jsonb_build_object('id',q.id,'prompt',q.prompt,'type',q.type,'choices',q.choices,'hint1',q.hint_1,'hint2',q.hint_2)
  into v_question from public.questions q
  where q.lesson_id=p_lesson_id and q.verification=v_verification order by q.difficulty limit 1;
  return jsonb_build_object('lesson',v_lesson,'question',v_question,'verification',v_verification);
end; $$;

create or replace function public.smiogl_review_lesson(p_lesson_id text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user();
begin
  update public.lesson_progress set state='available' where user_id=v_user_id and lesson_id=p_lesson_id and state='review_required';
  return jsonb_build_object('ok',true,'message','Review completed. The level is available again with stronger hints.');
end; $$;

create or replace function public.smiogl_revive_lesson(p_lesson_id text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user(); v_tokens integer; v_state text;
begin
  select revive_tokens into v_tokens from public.inventories where user_id=v_user_id for update;
  if coalesce(v_tokens,0)<1 then return jsonb_build_object('error','No revive tokens available','status',409); end if;
  select state into v_state from public.lesson_progress where user_id=v_user_id and lesson_id=p_lesson_id for update;
  if v_state<>'review_required' then return jsonb_build_object('error','A revive can only restart a level locked after repeated failure','status',409); end if;
  update public.inventories set revive_tokens=revive_tokens-1 where user_id=v_user_id;
  update public.lesson_progress set state='available' where user_id=v_user_id and lesson_id=p_lesson_id;
  return jsonb_build_object('ok',true,'message','Revive used. The level is available again and your accumulated hint level is preserved.');
end; $$;

create or replace function public.smiogl_shop(p_item text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user(); v_cost integer; v_coins integer;
begin
  v_cost := case p_item when 'revive' then 100 when 'streak_revive' then 150 when 'hint' then 75 else null end;
  if v_cost is null then return jsonb_build_object('error','Invalid shop item','status',400); end if;
  select mathio_coins into v_coins from public.inventories where user_id=v_user_id for update;
  if coalesce(v_coins,0)<v_cost then return jsonb_build_object('error','Not enough Math-io coins','status',409); end if;
  update public.inventories set
    mathio_coins=mathio_coins-v_cost,
    revive_tokens=revive_tokens+case when p_item='revive' then 1 else 0 end,
    streak_revive_tokens=streak_revive_tokens+case when p_item='streak_revive' then 1 else 0 end,
    hint_tokens=hint_tokens+case when p_item='hint' then 1 else 0 end
  where user_id=v_user_id;
  insert into public.reward_transactions(user_id,kind,amount,reason) values(v_user_id,p_item,-v_cost,'mathio_mart');
  return jsonb_build_object('ok',true,'item',p_item,'cost',v_cost);
end; $$;

create or replace function public.smiogl_revive_streak()
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user(); v_tokens integer;
begin
  select streak_revive_tokens into v_tokens from public.inventories where user_id=v_user_id for update;
  if coalesce(v_tokens,0)<1 then return jsonb_build_object('error','No streak-revive tokens available','status',409); end if;
  update public.inventories set streak_revive_tokens=streak_revive_tokens-1,current_streak=greatest(current_streak,1),last_learning_date=current_date where user_id=v_user_id;
  return jsonb_build_object('ok',true);
end; $$;

create or replace function public.smiogl_answer_lesson(p_lesson_id text,p_answer text,p_use_special_hint boolean default false)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user();
  v_progress record; v_question record; v_lesson record;
  v_correct boolean; v_verification boolean; v_attempt_id uuid;
  v_failures integer; v_used integer; v_hints integer; v_next_id text; v_achievement text;
  v_new_streak integer;
begin
  select * into v_progress from public.lesson_progress where user_id=v_user_id and lesson_id=p_lesson_id for update;
  if not found then return jsonb_build_object('error','Lesson not found','status',404); end if;
  if v_progress.state='locked' then return jsonb_build_object('error','This level is locked','status',423); end if;
  if v_progress.state='review_required' then return jsonb_build_object('error','Review or revive this lesson before answering again','status',409); end if;
  v_verification := v_progress.state='verification';
  select * into v_question from public.questions where lesson_id=p_lesson_id and verification=v_verification order by difficulty limit 1;
  if not found then return jsonb_build_object('error','No question is configured for this lesson','status',404); end if;
  if p_use_special_hint then
    select count(*) into v_used from public.attempts where user_id=v_user_id and lesson_id=p_lesson_id and special_hint_used;
    if v_used>0 then return jsonb_build_object('error','The special partial-answer hint was already used for this level','status',409); end if;
    select hint_tokens into v_hints from public.inventories where user_id=v_user_id for update;
    if coalesce(v_hints,0)<1 then return jsonb_build_object('error','No special hint tokens available','status',409); end if;
    update public.inventories set hint_tokens=hint_tokens-1 where user_id=v_user_id;
    insert into public.attempts(user_id,lesson_id,status,special_hint_used) values(v_user_id,p_lesson_id,'active',true);
    return jsonb_build_object('correct',false,'specialHint',v_question.partial_answer_hint,'message','Special hint used. Only part of the final answer is shown.');
  end if;
  v_correct := public.smiogl_normalize_answer(p_answer)=public.smiogl_normalize_answer(v_question.answer);
  insert into public.attempts(user_id,lesson_id,status,score,retry_count,verification_required,finished_at)
  values(v_user_id,p_lesson_id,case when v_correct then 'passed' else 'failed' end,case when v_correct then 100 else 0 end,v_progress.failure_count,v_verification,now())
  returning id into v_attempt_id;
  insert into public.responses(attempt_id,question_id,answer,correct,hint_level)
  values(v_attempt_id,v_question.id,coalesce(p_answer,''),v_correct,least(3,v_progress.failure_count));
  if not v_correct then
    v_failures := v_progress.failure_count+1;
    update public.lesson_progress set failure_count=v_failures,
      state=case when v_failures>=3 then 'review_required' else state end,
      lesson_resend_count=lesson_resend_count+case when v_failures>=3 then 1 else 0 end
    where id=v_progress.id;
    return jsonb_build_object('correct',false,'retryCount',v_failures,'reviewRequired',v_failures>=3,
      'hint',case when v_failures=1 then v_question.hint_1 when v_failures=2 then v_question.hint_2 else v_question.partial_answer_hint end,
      'message',case when v_failures>=3 then 'The level is locked until you review the full lesson again.' else 'Try again with this hint.' end);
  end if;
  if not v_verification then
    update public.lesson_progress set state='verification',best_score=100 where id=v_progress.id;
    return jsonb_build_object('correct',true,'verificationRequired',true,'explanation',v_question.explanation,'message','Level passed. Complete one different same-topic problem to verify understanding.');
  end if;
  select * into v_lesson from public.lessons where id=p_lesson_id;
  select id into v_next_id from public.lessons where course_id=v_lesson.course_id and unit_number>v_lesson.unit_number order by unit_number,lesson_number limit 1;
  update public.lesson_progress set state='completed',best_score=100,completed_at=now() where id=v_progress.id;
  select case when last_learning_date=current_date then current_streak when last_learning_date=current_date-1 then current_streak+1 else 1 end
  into v_new_streak from public.inventories where user_id=v_user_id for update;
  update public.inventories set mathio_coins=mathio_coins+v_lesson.coin_reward,xp=xp+v_lesson.xp_reward,
    current_streak=v_new_streak,longest_streak=greatest(longest_streak,v_new_streak),last_learning_date=current_date where user_id=v_user_id;
  insert into public.reward_transactions(user_id,kind,amount,reason,reference_id) values
    (v_user_id,'coins',v_lesson.coin_reward,'verified_lesson',p_lesson_id),
    (v_user_id,'xp',v_lesson.xp_reward,'verified_lesson',p_lesson_id);
  v_achievement := case when v_lesson.secret_stage then 'ach-secret' when v_progress.failure_count>=3 then 'ach-comeback' else 'ach-first' end;
  insert into public.user_achievements(user_id,achievement_id) values(v_user_id,v_achievement) on conflict(user_id,achievement_id) do nothing;
  if v_next_id is not null then update public.lesson_progress set state='available' where user_id=v_user_id and lesson_id=v_next_id and state='locked'; end if;
  return jsonb_build_object('correct',true,'completed',true,'explanation',v_question.explanation,
    'rewards',jsonb_build_object('coins',v_lesson.coin_reward,'xp',v_lesson.xp_reward),'nextLessonId',v_next_id,
    'message','Verified mastery! Rewards added and the next level is unlocked.');
end; $$;

create or replace function public.smiogl_room_code()
returns text language plpgsql volatile security definer set search_path=public as $$
declare v_code text; v_letters text := 'ABCDEFGHJKLMNPQRSTUVWXYZ';
begin
  loop
    v_code := substr(v_letters,1+floor(random()*length(v_letters))::int,1)||substr(v_letters,1+floor(random()*length(v_letters))::int,1)||substr(v_letters,1+floor(random()*length(v_letters))::int,1)||'-'||(100+floor(random()*900))::int::text;
    exit when not exists(select 1 from public.quiz_rooms where invite_code=v_code);
  end loop;
  return v_code;
end; $$;

create or replace function public.smiogl_create_room(p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user(); v_role text; v_title text; v_code text; v_room_id uuid;
  v_question_ids text[]; v_questions jsonb; v_question jsonb; v_question_id text; v_type text; v_choices jsonb; v_answer text; v_prompt text; v_index integer;
begin
  select role into v_role from public.users where id=v_user_id;
  if v_role not in ('teacher','admin') then return jsonb_build_object('error','Teacher role required','status',403); end if;
  v_title := trim(coalesce(p_payload->>'title',''));
  if length(v_title)<3 then return jsonb_build_object('error','Quiz title must be at least 3 characters','status',400); end if;
  select coalesce(array_agg(value),array['q-functions','q-rational','q-inverse']) into v_question_ids
  from jsonb_array_elements_text(coalesce(p_payload->'questionIds','[]'::jsonb));
  if jsonb_typeof(p_payload->'questions')='array' and jsonb_array_length(p_payload->'questions')>0 then
    v_questions := p_payload->'questions';
  elsif coalesce(p_payload->'question'->>'prompt','')<>'' or coalesce(p_payload->'question'->>'answer','')<>'' then
    v_questions := jsonb_build_array(p_payload->'question');
  end if;
  if v_questions is not null then
    if jsonb_array_length(v_questions)>50 then return jsonb_build_object('error','A quiz room can contain at most 50 questions','status',400); end if;
    v_index := 0;
    for v_question in select value from jsonb_array_elements(v_questions) loop
      v_index := v_index+1;
      v_prompt := trim(coalesce(v_question->>'prompt',''));
      v_answer := trim(coalesce(v_question->>'answer',''));
      v_type := case when v_question->>'type'='true_false' then 'true_false' else 'multiple_choice' end;
      v_choices := case when v_type='true_false' then '["True","False"]'::jsonb else coalesce(v_question->'choices','[]'::jsonb) end;
      if v_prompt='' or v_answer='' then return jsonb_build_object('error','Question '||v_index||' needs a prompt and correct answer','status',400); end if;
      if jsonb_typeof(v_choices)<>'array' then return jsonb_build_object('error','Question '||v_index||' choices must be a list','status',400); end if;
      select coalesce(jsonb_agg(trim(choice)), '[]'::jsonb) into v_choices from jsonb_array_elements_text(v_choices) as item(choice) where trim(choice)<>'';
      if jsonb_array_length(v_choices)<2 or not (v_choices ? v_answer) then
        return jsonb_build_object('error','Question '||v_index||' needs at least two choices and a matching correct answer','status',400);
      end if;
    end loop;
    v_question_ids := array[]::text[];
    for v_question in select value from jsonb_array_elements(v_questions) loop
      v_question_id := gen_random_uuid()::text;
      v_prompt := trim(v_question->>'prompt');
      v_type := case when v_question->>'type'='true_false' then 'true_false' else 'multiple_choice' end;
      v_answer := trim(v_question->>'answer');
      v_choices := case when v_type='true_false' then '["True","False"]'::jsonb else v_question->'choices' end;
      select coalesce(jsonb_agg(trim(choice)), '[]'::jsonb) into v_choices from jsonb_array_elements_text(v_choices) as item(choice) where trim(choice)<>'';
      insert into public.questions(id,concept_key,type,prompt,choices,answer,explanation,hint_1,hint_2,partial_answer_hint,verification,difficulty)
      values(v_question_id,'teacher_custom',v_type,v_prompt,v_choices,v_answer,'Teacher-authored assessment question.','Review the concept and eliminate unlikely choices.','Compare each choice with the rule in the prompt.','The answer starts with '||left(v_answer,1)||'…',false,1);
      v_question_ids := array_append(v_question_ids,v_question_id);
    end loop;
  end if;
  v_code := public.smiogl_room_code();
  insert into public.quiz_rooms(teacher_id,title,invite_code,delivery_mode,status,question_ids,request_fullscreen)
  values(v_user_id,v_title,v_code,case when p_payload->>'deliveryMode'='self_paced' then 'self_paced' else 'teacher_paced' end,'waiting',v_question_ids,coalesce((p_payload->>'requestFullscreen')::boolean,false))
  returning id into v_room_id;
  return jsonb_build_object('id',v_room_id,'inviteCode',v_code,'status','waiting');
end; $$;

create or replace function public.smiogl_list_rooms()
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user(); v_role text; v_rooms jsonb;
begin
  select role into v_role from public.users where id=v_user_id;
  if v_role in ('teacher','admin') then
    select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'title',r.title,'inviteCode',r.invite_code,'deliveryMode',r.delivery_mode,'status',r.status,'createdAt',extract(epoch from r.created_at)::bigint,'participants',(select count(*) from public.attempts a where a.room_id=r.id),'questionCount',cardinality(r.question_ids)) order by r.created_at desc),'[]'::jsonb)
    into v_rooms from public.quiz_rooms r where r.teacher_id=v_user_id;
  else
    select coalesce(jsonb_agg(x.room order by x.created_at desc),'[]'::jsonb) into v_rooms from (
      select distinct on(r.id) r.created_at,jsonb_build_object('id',r.id,'title',r.title,'inviteCode',r.invite_code,'deliveryMode',r.delivery_mode,'status',r.status,'createdAt',extract(epoch from r.created_at)::bigint,'questionCount',cardinality(r.question_ids)) room
      from public.quiz_rooms r join public.attempts a on a.room_id=r.id where a.user_id=v_user_id order by r.id,r.created_at desc
    ) x;
  end if;
  return jsonb_build_object('rooms',coalesce(v_rooms,'[]'::jsonb));
end; $$;

create or replace function public.smiogl_get_room(p_code text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user(); v_room record; v_attempt jsonb; v_attempt_id uuid; v_questions jsonb; v_responses jsonb := '[]'::jsonb; v_participants jsonb; v_events jsonb; v_may_view boolean;
begin
  select * into v_room from public.quiz_rooms where invite_code=upper(p_code);
  if not found then return jsonb_build_object('error','Room not found','status',404); end if;
  select a.id,jsonb_build_object('id',a.id,'status',a.status,'score',a.score) into v_attempt_id,v_attempt
  from public.attempts a where a.room_id=v_room.id and a.user_id=v_user_id order by a.started_at desc limit 1;
  v_may_view := v_user_id=v_room.teacher_id or (v_attempt is not null and (v_room.delivery_mode='self_paced' or v_room.status in ('live','closed')));
  if v_may_view then
    select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'prompt',q.prompt,'type',q.type,'choices',q.choices) order by array_position(v_room.question_ids,q.id)),'[]'::jsonb)
    into v_questions from public.questions q where q.id=any(v_room.question_ids);
  else v_questions := '[]'::jsonb; end if;
  if v_attempt_id is not null then
    select coalesce(jsonb_agg(jsonb_build_object('questionId',x.question_id,'answer',x.answer,'correct',x.correct) order by x.answered_at),'[]'::jsonb)
    into v_responses from public.responses x where x.attempt_id=v_attempt_id;
  end if;
  if v_user_id=v_room.teacher_id then
    select coalesce(jsonb_agg(jsonb_build_object('name',u.display_name,'attemptId',a.id,'status',a.status,'score',a.score,
      'answered',(select count(distinct x.question_id) from public.responses x where x.attempt_id=a.id),'signals',(select count(*) from public.monitoring_events m where m.attempt_id=a.id)) order by a.started_at),'[]'::jsonb)
    into v_participants from public.attempts a join public.users u on u.id=a.user_id where a.room_id=v_room.id;
  end if;
  select coalesce(jsonb_agg(x.event order by x.created_at desc),'[]'::jsonb) into v_events from (
    select e.created_at,jsonb_build_object('id',e.id,'eventType',e.event_type,'payloadJson',e.payload::text,'createdAt',extract(epoch from e.created_at)::bigint) event
    from public.room_events e where e.room_id=v_room.id order by e.created_at desc limit 30
  ) x;
  return jsonb_build_object(
    'room',jsonb_build_object('id',v_room.id,'teacherId',v_room.teacher_id,'title',v_room.title,'inviteCode',v_room.invite_code,'deliveryMode',v_room.delivery_mode,'status',v_room.status,'requestFullscreen',case when v_room.request_fullscreen then 1 else 0 end),
    'questions',v_questions,'responses',v_responses,'attempt',v_attempt,'participants',v_participants,'events',v_events
  );
end; $$;

create or replace function public.smiogl_room_action(p_code text,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user(); v_room record; v_action text := p_payload->>'action'; v_attempt_id uuid; v_question record; v_correct boolean; v_score integer; v_answered integer;
begin
  select * into v_room from public.quiz_rooms where invite_code=upper(p_code) for update;
  if not found then return jsonb_build_object('error','Room not found','status',404); end if;
  if v_action='join' then
    if v_room.status='closed' then return jsonb_build_object('error','This room is closed','status',409); end if;
    select id into v_attempt_id from public.attempts where room_id=v_room.id and user_id=v_user_id order by started_at desc limit 1;
    if v_attempt_id is null then
      insert into public.attempts(user_id,room_id,status) values(v_user_id,v_room.id,'active') returning id into v_attempt_id;
      insert into public.room_events(room_id,actor_id,event_type,payload) values(v_room.id,v_user_id,'joined',jsonb_build_object('name',(select display_name from public.users where id=v_user_id)));
    end if;
    return jsonb_build_object('ok',true,'attemptId',v_attempt_id,'room',jsonb_build_object('id',v_room.id,'inviteCode',v_room.invite_code,'status',v_room.status));
  end if;
  if v_action in ('start','close') then
    if v_user_id<>v_room.teacher_id then return jsonb_build_object('error','Only the room teacher can do that','status',403); end if;
    update public.quiz_rooms set status=case when v_action='start' then 'live' else 'closed' end,
      starts_at=case when v_action='start' then coalesce(starts_at,now()) else starts_at end,
      ends_at=case when v_action='close' then now() else ends_at end where id=v_room.id;
    insert into public.room_events(room_id,actor_id,event_type) values(v_room.id,v_user_id,case when v_action='start' then 'started' else 'closed' end);
    return jsonb_build_object('ok',true,'status',case when v_action='start' then 'live' else 'closed' end);
  end if;
  if v_action='answer' then
    if v_room.status='closed' or (v_room.delivery_mode='teacher_paced' and v_room.status<>'live') then return jsonb_build_object('error','The quiz is not accepting answers','status',409); end if;
    if coalesce(p_payload->>'questionId','')='' then return jsonb_build_object('error','Question required','status',400); end if;
    if not ((p_payload->>'questionId')=any(v_room.question_ids)) then return jsonb_build_object('error','Question not found in this room','status',404); end if;
    select id into v_attempt_id from public.attempts where room_id=v_room.id and user_id=v_user_id and status='active' order by started_at desc limit 1;
    if v_attempt_id is null then return jsonb_build_object('error','Join the room first','status',409); end if;
    if exists(select 1 from public.responses where attempt_id=v_attempt_id and question_id=p_payload->>'questionId') then
      return jsonb_build_object('error','You already answered this question','status',409);
    end if;
    select * into v_question from public.questions where id=p_payload->>'questionId';
    if not found then return jsonb_build_object('error','Question not found','status',404); end if;
    v_correct := public.smiogl_normalize_answer(p_payload->>'answer')=public.smiogl_normalize_answer(v_question.answer);
    insert into public.responses(attempt_id,question_id,answer,correct) values(v_attempt_id,v_question.id,coalesce(p_payload->>'answer',''),v_correct)
    on conflict (attempt_id,question_id) do nothing;
    if not found then return jsonb_build_object('error','You already answered this question','status',409); end if;
    select count(*),round(100.0*count(*) filter (where correct)/greatest(cardinality(v_room.question_ids),1))::int
    into v_answered,v_score from public.responses where attempt_id=v_attempt_id;
    update public.attempts set score=v_score where id=v_attempt_id;
    insert into public.room_events(room_id,actor_id,event_type,payload) values(v_room.id,v_user_id,'answered',jsonb_build_object('questionId',v_question.id,'correct',v_correct));
    return jsonb_build_object('correct',v_correct,'explanation',v_question.explanation,'answered',v_answered,'total',cardinality(v_room.question_ids),'score',v_score);
  end if;
  return jsonb_build_object('error','Unsupported action','status',400);
end; $$;

create or replace function public.smiogl_monitor(p_attempt_id uuid,p_event_type text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare v_user_id uuid := public.smiogl_require_user();
begin
  if p_event_type not in ('visibility_hidden','focus_lost','fullscreen_exit','connection_lost') then return jsonb_build_object('error','Invalid monitoring event','status',400); end if;
  if not exists(select 1 from public.attempts where id=p_attempt_id and user_id=v_user_id) then return jsonb_build_object('error','Attempt not found','status',404); end if;
  insert into public.monitoring_events(attempt_id,event_type,detail) values(p_attempt_id,p_event_type,jsonb_build_object('source','browser','userId',v_user_id));
  return jsonb_build_object('accepted',true,'interpretation','review_signal_not_verdict','status',202);
end; $$;

alter table public.users enable row level security;
alter table public.classrooms enable row level security;
alter table public.classroom_members enable row level security;
alter table public.courses enable row level security;
alter table public.lessons enable row level security;
alter table public.questions enable row level security;
alter table public.quiz_rooms enable row level security;
alter table public.attempts enable row level security;
alter table public.responses enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.inventories enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.monitoring_events enable row level security;
alter table public.reward_transactions enable row level security;
alter table public.room_events enable row level security;

revoke all on all tables in schema public from anon, authenticated;
revoke execute on function public.smiogl_require_user() from public, anon, authenticated;
revoke execute on function public.smiogl_normalize_answer(text) from public, anon, authenticated;
revoke execute on function public.smiogl_room_code() from public, anon, authenticated;
revoke execute on function public.smiogl_bootstrap() from public, anon;
revoke execute on function public.smiogl_set_role(text) from public, anon;
revoke execute on function public.smiogl_get_lesson(text) from public, anon;
revoke execute on function public.smiogl_review_lesson(text) from public, anon;
revoke execute on function public.smiogl_revive_lesson(text) from public, anon;
revoke execute on function public.smiogl_shop(text) from public, anon;
revoke execute on function public.smiogl_revive_streak() from public, anon;
revoke execute on function public.smiogl_answer_lesson(text,text,boolean) from public, anon;
revoke execute on function public.smiogl_create_room(jsonb) from public, anon;
revoke execute on function public.smiogl_list_rooms() from public, anon;
revoke execute on function public.smiogl_get_room(text) from public, anon;
revoke execute on function public.smiogl_room_action(text,jsonb) from public, anon;
revoke execute on function public.smiogl_monitor(uuid,text) from public, anon;

grant execute on function public.smiogl_bootstrap() to authenticated;
grant execute on function public.smiogl_set_role(text) to authenticated;
grant execute on function public.smiogl_get_lesson(text) to authenticated;
grant execute on function public.smiogl_review_lesson(text) to authenticated;
grant execute on function public.smiogl_revive_lesson(text) to authenticated;
grant execute on function public.smiogl_shop(text) to authenticated;
grant execute on function public.smiogl_revive_streak() to authenticated;
grant execute on function public.smiogl_answer_lesson(text,text,boolean) to authenticated;
grant execute on function public.smiogl_create_room(jsonb) to authenticated;
grant execute on function public.smiogl_list_rooms() to authenticated;
grant execute on function public.smiogl_get_room(text) to authenticated;
grant execute on function public.smiogl_room_action(text,jsonb) to authenticated;
grant execute on function public.smiogl_monitor(uuid,text) to authenticated;
