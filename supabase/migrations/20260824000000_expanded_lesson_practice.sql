-- Expand every lesson into a multi-problem practice and verification stage.
-- Existing question IDs are preserved so current attempts and evidence remain valid.

insert into public.questions
  (id,lesson_id,concept_key,type,prompt,choices,answer,explanation,hint_1,hint_2,partial_answer_hint,verification,difficulty)
values
  ('q-functions-02','lesson-functions','functions','numeric','If f(x)=3x-2, what is f(5)?',null,'13','Substitute 5: 3(5)-2=13.','Replace x with 5.','Multiply 3 by 5 before subtracting 2.','The answer is between 12 and 14.',false,1),
  ('q-functions-03','lesson-functions','functions','multiple_choice','Which relation is not a function?','["{(1,4),(2,6),(3,8)}","{(1,4),(1,6),(2,8)}","{(-1,0),(0,1),(1,2)}","{(2,5),(3,5),(4,5)}"]'::jsonb,'{(1,4),(1,6),(2,8)}','The input 1 is paired with two different outputs.','Inspect the first coordinate in each pair.','Look for an input that repeats with different outputs.','The incorrect relation begins with {(1,4)...',false,1),
  ('q-functions-04','lesson-functions','functions','multiple_choice','What is the set of all possible inputs of a function called?','["Domain","Range","Output","Relation"]'::jsonb,'Domain','The domain contains every allowed input value.','Inputs are x-values.','Recall the name for the collection of x-values.','The answer begins with D.',false,1),
  ('q-functions-05','lesson-functions','functions','numeric','If f(x)=x^2+1, what is f(-3)?',null,'10','Square -3 first, then add 1: 9+1=10.','Substitute -3 for x.','A negative number squared is positive.','The answer has two digits and ends in 0.',false,2),
  ('q-functions-06','lesson-functions','functions','numeric','A rule pairs x=-2, 0, 3 with y=5, 1, 7 respectively. What output is paired with x=0?',null,'1','The ordered pairing shows that the input 0 maps to the output 1.','Find x=0 in the listed inputs.','Read the output in the same position.','The answer is the first positive integer.',false,2),
  ('q-functions-07','lesson-functions','functions','multiple_choice','Which graph fails the vertical line test?','["A vertical line x=4","A horizontal line y=4","The line y=2x+1","The curve y=x^2"]'::jsonb,'A vertical line x=4','A vertical line contains many outputs for the single input x=4.','Imagine drawing vertical test lines.','One option is already vertical.','The answer fixes x at 4.',false,2),
  ('q-functions-08','lesson-functions','functions','numeric','If g(t)=2t+5, what is g(-2)?',null,'1','Substitute -2: 2(-2)+5=-4+5=1.','Replace t with -2.','Multiply before adding 5.','The result is positive and less than 2.',false,3),
  ('q-functions-v02','lesson-functions','functions','numeric','For h(x)=4x-3, find h(6).',null,'21','Substitute 6: 4(6)-3=21.','Replace x with 6.','Compute 24-3.','The answer is an odd number in the twenties.',true,2),
  ('q-functions-v03','lesson-functions','functions','multiple_choice','Which set of ordered pairs defines a function?','["{(0,1),(0,2)}","{(2,3),(2,4)}","{(-1,2),(0,2),(1,2)}","{(5,1),(5,1),(5,2)}"]'::jsonb,'{(-1,2),(0,2),(1,2)}','Different inputs may share one output; each input still has exactly one output.','Check each first coordinate.','Repeated outputs are allowed, but repeated inputs with different outputs are not.','The correct relation uses inputs -1, 0, and 1.',true,3),
  ('q-functions-v04','lesson-functions','functions','numeric','If p(x)=x^2-4, what is p(5)?',null,'21','Substitute 5: 5^2-4=25-4=21.','Replace x with 5.','Square 5 before subtracting 4.','The result is the same as 25-4.',true,3),

  ('q-rational-02','lesson-rational','rational','multiple_choice','Find the excluded value in f(x)=2/(x+3).','["x = -3","x = 3","x = 2","x = 0"]'::jsonb,'x = -3','Set x+3=0, which gives x=-3.','The denominator cannot be zero.','Undo +3 by subtracting 3.','The excluded value is negative.',false,1),
  ('q-rational-03','lesson-rational','rational','multiple_choice','Which value is excluded from the domain of g(x)=(x+1)/(x-5)?','["x = -5","x = -1","x = 1","x = 5"]'::jsonb,'x = 5','The denominator is zero when x-5=0, so x=5 is excluded.','Use only the denominator to find restrictions.','Solve x-5=0.','The answer is positive.',false,1),
  ('q-rational-04','lesson-rational','rational','numeric','For f(x)=6/x, find f(3).',null,'2','Substitute 3 into the denominator: 6/3=2.','Replace x with 3.','Divide 6 by 3.','The answer is an even number less than 4.',false,1),
  ('q-rational-05','lesson-rational','rational','multiple_choice','Which values are excluded from h(x)=1/((x-2)(x+1))?','["x = 2 only","x = -1 only","x = 2 and x = -1","x = 0 and x = 1"]'::jsonb,'x = 2 and x = -1','Each denominator factor can equal zero, giving x=2 and x=-1.','Set each factor equal to zero.','Solve x-2=0 and x+1=0 separately.','There are two excluded values.',false,2),
  ('q-rational-06','lesson-rational','rational','multiple_choice','What is the domain of r(x)=(x+4)/x?','["All real numbers","All real numbers except 0","Positive numbers only","All real numbers except -4"]'::jsonb,'All real numbers except 0','The denominator x cannot be zero.','Look only for values that make the denominator zero.','Set x=0 in the denominator.','Zero is the only excluded input.',false,2),
  ('q-rational-07','lesson-rational','rational','numeric','For r(x)=(x+2)/(x-1), find r(2).',null,'4','Substitute 2: (2+2)/(2-1)=4/1=4.','Replace every x with 2.','Evaluate the numerator and denominator separately.','The denominator becomes 1.',false,2),
  ('q-rational-08','lesson-rational','rational','numeric','Which x-value makes the denominator of 7/(2x-6) equal to zero?',null,'3','Solve 2x-6=0: 2x=6, so x=3.','Set the denominator equal to zero.','Add 6, then divide by 2.','The answer is between 2 and 4.',false,3),
  ('q-rational-v02','lesson-rational','rational','multiple_choice','Find the excluded value in k(x)=4/(x+7).','["x = -7","x = 7","x = 4","x = 0"]'::jsonb,'x = -7','Set x+7=0, yielding x=-7.','Make the denominator zero.','Undo +7.','The value is negative.',true,2),
  ('q-rational-v03','lesson-rational','rational','multiple_choice','Which values are excluded from p(x)=(x-2)/(x^2-9)?','["x = 3 only","x = -3 only","x = -3 and x = 3","x = -9 and x = 9"]'::jsonb,'x = -3 and x = 3','Factor x^2-9=(x-3)(x+3); both 3 and -3 make it zero.','Factor the difference of squares.','Solve both denominator factors.','The exclusions are opposites.',true,3),
  ('q-rational-v04','lesson-rational','rational','multiple_choice','Evaluate m(x)=(2x+1)/(x+1) at x=1.','["1","3/2","2","3"]'::jsonb,'3/2','Substitute 1: (2+1)/(1+1)=3/2.','Replace x with 1 in both parts.','The numerator is 3 and the denominator is 2.','The answer is a fraction between 1 and 2.',true,3),

  ('q-inverse-02','lesson-inverse','inverse','multiple_choice','What is the inverse of f(x)=x-5?','["x-5","x+5","5-x","x/5"]'::jsonb,'x+5','The inverse undoes subtraction by adding 5.','Reverse the original operation.','Undo -5 with +5.','The expression ends with +5.',false,1),
  ('q-inverse-03','lesson-inverse','inverse','multiple_choice','What is the inverse of f(x)=3x?','["3x","x-3","x/3","1/(3x)"]'::jsonb,'x/3','The inverse of multiplying by 3 is dividing by 3.','Think of the operation that undoes multiplication.','Divide the input by 3.','The answer contains /3.',false,1),
  ('q-inverse-04','lesson-inverse','inverse','multiple_choice','Which expression is f^-1(x) when f(x)=2x+4?','["(x-4)/2","(x+4)/2","2x-4","x/2+4"]'::jsonb,'(x-4)/2','Swap x and y, subtract 4, then divide by 2.','Undo operations in reverse order.','Subtract 4 before dividing by 2.','The numerator contains x-4.',false,2),
  ('q-inverse-05','lesson-inverse','inverse','numeric','If f(x)=x/4, what is f^-1(3)?',null,'12','The inverse multiplies by 4, so f^-1(3)=12.','Undo division by 4.','Multiply 3 by 4.','The answer is a multiple of 4.',false,2),
  ('q-inverse-06','lesson-inverse','inverse','numeric','If f maps 2 to 9, what value does f^-1 map 9 to?',null,'2','An inverse reverses the ordered pair, so 9 maps back to 2.','Reverse the input and output.','The pair (2,9) becomes (9,2).','The answer is the original input.',false,2),
  ('q-inverse-07','lesson-inverse','inverse','multiple_choice','What is the inverse of f(x)=x^3?','["x^3","cube root of x","x/3","3x"]'::jsonb,'cube root of x','Cubing is undone by taking the cube root.','Choose the operation that reverses a cube.','A cube root reverses a third power.','The answer mentions a root.',false,3),
  ('q-inverse-08','lesson-inverse','inverse','multiple_choice','The function f(x)=-x+6 is its own inverse.','["True","False"]'::jsonb,'True','Solving y=-x+6 after swapping x and y gives the same rule.','Swap x and y, then solve.','The rearranged equation remains y=-x+6.','The statement is true.',false,3),
  ('q-inverse-v02','lesson-inverse','inverse','numeric','If f(x)=3x-6, find f^-1(9).',null,'5','Solve 3x-6=9: 3x=15, so x=5.','Set the function output equal to 9.','Add 6, then divide by 3.','The answer is between 4 and 6.',true,2),
  ('q-inverse-v03','lesson-inverse','inverse','numeric','If f(x)=x/2+1, find f^-1(6).',null,'10','Solve x/2+1=6: x/2=5, so x=10.','Set the original function equal to 6.','Subtract 1, then multiply by 2.','The answer has two digits.',true,3),
  ('q-inverse-v04','lesson-inverse','inverse','multiple_choice','Which is the inverse of f(x)=4x-7?','["(x+7)/4","(x-7)/4","4x+7","x/4-7"]'::jsonb,'(x+7)/4','Undo -7 by adding 7, then undo multiplication by dividing by 4.','Reverse the two operations.','Add 7 before dividing by 4.','The numerator contains x+7.',true,3),

  ('q-secret-02','lesson-secret','secret','numeric','A function triples a number and adds 2. What is the output when the input is 4?',null,'14','Compute 3(4)+2=14.','Substitute 4 for the input.','Multiply before adding.','The answer is an even two-digit number.',false,2),
  ('q-secret-03','lesson-secret','secret','multiple_choice','Which value is excluded from (x+1)/(x-4)?','["x = -4","x = -1","x = 1","x = 4"]'::jsonb,'x = 4','The denominator x-4 is zero at x=4.','Use the denominator.','Solve x-4=0.','The answer is positive.',false,2),
  ('q-secret-04','lesson-secret','secret','numeric','If f(x)=2x+1, find f^-1(11).',null,'5','Solve 2x+1=11: 2x=10, so x=5.','Set the output equal to 11.','Subtract 1, then divide by 2.','The answer is one digit.',false,2),
  ('q-secret-05','lesson-secret','secret','multiple_choice','Which relation is a function?','["{(1,2),(1,5)}","{(0,3),(1,3),(2,3)}","{(4,1),(4,2)}","{(-1,0),(-1,1)}"]'::jsonb,'{(0,3),(1,3),(2,3)}','Every input in the correct relation appears exactly once.','Inspect the first coordinates.','Different inputs may share one output.','The correct set uses inputs 0, 1, and 2.',false,3),
  ('q-secret-06','lesson-secret','secret','numeric','At which x-value is 3/(x-1) undefined?',null,'1','The denominator is zero when x-1=0, so x=1.','Set the denominator equal to zero.','Solve x-1=0.','The excluded value is the first positive integer.',false,3),
  ('q-secret-07','lesson-secret','secret','numeric','Let f(x)=x+2 and g(x)=3x. Find f(g(2)).',null,'8','First g(2)=6, then f(6)=8.','Evaluate the inside function first.','Find g(2), then add 2.','The answer is an even number.',false,3),
  ('q-secret-08','lesson-secret','secret','numeric','Which input is excluded from y=1/(x+5)?',null,'-5','The denominator becomes zero when x+5=0, so x=-5.','Set x+5 equal to zero.','Undo +5.','The answer is negative.',false,4),
  ('q-secret-v01','lesson-secret','secret','numeric','A linear function gives 4x-7=21. What is x?',null,'7','Add 7 to get 4x=28, then divide by 4 to get x=7.','Undo subtraction first.','Add 7, then divide by 4.','The answer is a single digit.',true,3),
  ('q-secret-v02','lesson-secret','secret','multiple_choice','Which inputs are excluded from (x+2)/(x^2-16)?','["x = -4 and x = 4","x = -2 and x = 2","x = 4 only","x = 16 only"]'::jsonb,'x = -4 and x = 4','Factor x^2-16=(x-4)(x+4), so both 4 and -4 are excluded.','Factor the denominator.','Use the difference of squares.','The two values are opposites.',true,3),
  ('q-secret-v03','lesson-secret','secret','numeric','If f(x)=5x+10, find f^-1(35).',null,'5','Solve 5x+10=35: 5x=25, so x=5.','Set the function output to 35.','Subtract 10, then divide by 5.','The answer is one digit.',true,4),
  ('q-secret-v04','lesson-secret','secret','multiple_choice','Which relation fails to define a function?','["{(-2,1),(-1,1),(0,1)}","{(1,0),(2,0),(3,0)}","{(2,3),(2,5),(4,7)}","{(0,0),(1,1),(2,4)}"]'::jsonb,'{(2,3),(2,5),(4,7)}','The input 2 has two different outputs, 3 and 5.','Look for a repeated first coordinate.','One input is paired with two outputs.','The failing set begins with (2,3).',true,4)
on conflict (id) do update set
  lesson_id=excluded.lesson_id,
  concept_key=excluded.concept_key,
  type=excluded.type,
  prompt=excluded.prompt,
  choices=excluded.choices,
  answer=excluded.answer,
  explanation=excluded.explanation,
  hint_1=excluded.hint_1,
  hint_2=excluded.hint_2,
  partial_answer_hint=excluded.partial_answer_hint,
  verification=excluded.verification,
  difficulty=excluded.difficulty;

create or replace function public.smiogl_get_lesson(p_lesson_id text)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user();
  v_state text;
  v_lesson jsonb;
  v_question jsonb;
  v_verification boolean;
  v_stage_completed integer := 0;
  v_stage_total integer := 0;
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
  select count(*) into v_stage_total from public.questions q
  where q.lesson_id=p_lesson_id and q.verification=v_verification;
  select count(distinct q.id) into v_stage_completed
  from public.questions q
  join public.responses r on r.question_id=q.id and r.correct
  join public.attempts a on a.id=r.attempt_id
  where a.user_id=v_user_id and a.lesson_id=p_lesson_id and q.verification=v_verification;
  if v_state<>'completed' and v_state<>'review_required' then
    select jsonb_build_object('id',q.id,'prompt',q.prompt,'type',q.type,'choices',q.choices,'hint1',q.hint_1,'hint2',q.hint_2)
    into v_question from public.questions q
    where q.lesson_id=p_lesson_id and q.verification=v_verification
      and not exists(
        select 1 from public.responses r join public.attempts a on a.id=r.attempt_id
        where r.question_id=q.id and r.correct and a.user_id=v_user_id and a.lesson_id=p_lesson_id
      )
    order by q.difficulty,q.id limit 1;
  end if;
  return jsonb_build_object(
    'lesson',v_lesson,'question',v_question,'verification',v_verification,
    'stageProgress',jsonb_build_object(
      'completed',v_stage_completed,'required',v_stage_total,'total',v_stage_total,
      'current',least(v_stage_completed+1,greatest(v_stage_total,1))
    )
  );
end; $$;

create or replace function public.smiogl_answer_lesson(p_lesson_id text,p_answer text,p_use_special_hint boolean default false)
returns jsonb language plpgsql security definer set search_path=public,auth as $$
declare
  v_user_id uuid := public.smiogl_require_user();
  v_progress record; v_question record; v_lesson record;
  v_correct boolean; v_verification boolean; v_attempt_id uuid;
  v_failures integer; v_used integer; v_hints integer; v_next_id text; v_achievement text;
  v_new_streak integer; v_stage_completed integer; v_stage_total integer;
begin
  select * into v_progress from public.lesson_progress where user_id=v_user_id and lesson_id=p_lesson_id for update;
  if not found then return jsonb_build_object('error','Lesson not found','status',404); end if;
  if v_progress.state='locked' then return jsonb_build_object('error','This level is locked','status',423); end if;
  if v_progress.state='review_required' then return jsonb_build_object('error','Review or revive this lesson before answering again','status',409); end if;
  if v_progress.state='completed' then return jsonb_build_object('error','This level is already completed','status',409); end if;
  v_verification := v_progress.state='verification';
  select count(*) into v_stage_total from public.questions where lesson_id=p_lesson_id and verification=v_verification;
  select q.* into v_question from public.questions q
  where q.lesson_id=p_lesson_id and q.verification=v_verification
    and not exists(
      select 1 from public.responses r join public.attempts a on a.id=r.attempt_id
      where r.question_id=q.id and r.correct and a.user_id=v_user_id and a.lesson_id=p_lesson_id
    )
  order by q.difficulty,q.id limit 1;
  if not found then return jsonb_build_object('error','No unanswered question is configured for this stage','status',404); end if;
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
  select count(distinct q.id) into v_stage_completed
  from public.questions q
  join public.responses r on r.question_id=q.id and r.correct
  join public.attempts a on a.id=r.attempt_id
  where a.user_id=v_user_id and a.lesson_id=p_lesson_id and q.verification=v_verification;
  if v_stage_completed<v_stage_total then
    return jsonb_build_object(
      'correct',true,'stageContinues',true,'explanation',v_question.explanation,
      'stageProgress',jsonb_build_object('completed',v_stage_completed,'required',v_stage_total,'total',v_stage_total,'current',v_stage_completed+1),
      'message',case when v_verification then 'Verified. The next verification problem is ready.' else 'Correct. The next practice problem is ready.' end
    );
  end if;
  if not v_verification then
    update public.lesson_progress set state='verification',best_score=100 where id=v_progress.id;
    return jsonb_build_object('correct',true,'verificationRequired',true,'explanation',v_question.explanation,
      'message','Practice set complete. Finish the same-topic verification set to confirm mastery.');
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

revoke execute on function public.smiogl_get_lesson(text) from public, anon;
revoke execute on function public.smiogl_answer_lesson(text,text,boolean) from public, anon;
grant execute on function public.smiogl_get_lesson(text) to authenticated;
grant execute on function public.smiogl_answer_lesson(text,text,boolean) to authenticated;
