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

revoke execute on function public.smiogl_create_room(jsonb) from public, anon;
grant execute on function public.smiogl_create_room(jsonb) to authenticated;

-- A student gets one recorded response per room question. Keep the earliest
-- response if this upgrade is applied to a database that already has repeats.
with ranked_responses as (
  select id,row_number() over (partition by attempt_id,question_id order by answered_at,id) as response_number
  from public.responses
)
delete from public.responses r
using ranked_responses ranked
where r.id=ranked.id and ranked.response_number>1;

create unique index if not exists idx_responses_attempt_question
on public.responses(attempt_id,question_id);

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

revoke execute on function public.smiogl_list_rooms() from public, anon;
revoke execute on function public.smiogl_get_room(text) from public, anon;
revoke execute on function public.smiogl_room_action(text,jsonb) from public, anon;
grant execute on function public.smiogl_list_rooms() to authenticated;
grant execute on function public.smiogl_get_room(text) to authenticated;
grant execute on function public.smiogl_room_action(text,jsonb) to authenticated;
