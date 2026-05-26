alter table public.nudge_templates
  add column if not exists mission_profile_key varchar(24),
  add column if not exists mission_goal varchar(80),
  add column if not exists mission_state_label varchar(80),
  add column if not exists is_random_eligible boolean not null default true,
  add column if not exists selection_weight smallint not null default 1,
  add column if not exists sort_order smallint not null default 100;

alter table public.nudge_deliveries
  add column if not exists delivery_category varchar(16) not null default 'comfort',
  add column if not exists selection_source varchar(16),
  add column if not exists matched_mission_profile varchar(24);

update public.nudge_deliveries nd
set delivery_category = coalesce(nt.category, 'comfort')
from public.nudge_templates nt
where nt.id = nd.template_id
  and nd.delivery_category <> coalesce(nt.category, 'comfort');

create unique index if not exists uq_nudge_deliveries_user_local_date_mission
on public.nudge_deliveries (user_id, delivery_local_date, delivery_category)
where delivery_category = 'mission';

create index if not exists idx_nudge_templates_mission_profile
on public.nudge_templates (category, is_active, mission_profile_key, is_random_eligible, sort_order);

update public.nudge_templates
set
  is_active = false,
  is_random_eligible = false,
  mission_profile_key = null,
  mission_goal = null,
  mission_state_label = null,
  sort_order = 999
where type in ('mission_walk', 'mission_grounding', 'mission_hydration');

insert into public.nudge_templates (
  type,
  title,
  body,
  is_active,
  category,
  subtitle,
  duration_minutes,
  checklist_json,
  cta_label,
  accent_icon,
  accent_start_color,
  accent_end_color,
  mission_profile_key,
  mission_goal,
  mission_state_label,
  is_random_eligible,
  selection_weight,
  sort_order
)
select
  x.type,
  x.title,
  x.body,
  true,
  'mission',
  x.subtitle,
  x.duration_minutes,
  x.checklist_json,
  '미션 시작하기',
  x.accent_icon,
  x.accent_start_color,
  x.accent_end_color,
  x.mission_profile_key,
  x.mission_goal,
  x.mission_state_label,
  x.is_random_eligible,
  x.selection_weight,
  x.sort_order
from (
  values
    (
      'mission_energized_walk_5',
      '5분 동안 가볍게 걷기',
      '에너지가 있을 때는 크게 몰아쓰지 말고, 몸이 기분 좋게 풀리는 정도로만 움직여 보세요.',
      '움직일 힘이 있는 지금, 몸을 가볍게 흔들며 리듬을 정리해 보세요.',
      5::smallint,
      '["신발을 신거나 제자리에서 몸을 가볍게 풀기","5분 동안 천천히 걷거나 몸을 흔들기","끝나고 숨이 너무 차지 않는지 확인하기"]'::jsonb,
      'directions_walk_rounded',
      'amber',
      'orange',
      'energized',
      '에너지를 가볍게 풀어주기',
      '움직일 힘이 있음',
      true,
      1::smallint,
      10::smallint
    ),
    (
      'mission_energized_small_task',
      '지금 끝낼 수 있는 작은 일 하나',
      '에너지가 있을 때는 복잡한 계획보다, 바로 끝낼 수 있는 일을 하나 정리하는 편이 더 가볍습니다.',
      '큰 목표 말고 지금 바로 끝낼 수 있는 한 가지에만 집중해 보세요.',
      5::smallint,
      '["2분 안에 끝낼 수 있는 일을 하나 고르기","그 일만 바로 처리하기","끝난 뒤 체크 표시나 완료 메모 남기기"]'::jsonb,
      'task_alt_rounded',
      'orange',
      'amber',
      'energized',
      '에너지를 가볍게 풀어주기',
      '움직일 힘이 있음',
      true,
      1::smallint,
      11::smallint
    ),
    (
      'mission_calm_warm_tea',
      '따뜻한 물이나 차를 천천히 마시기',
      '평온한 상태는 크게 흔들지 않고 오래 유지하는 것이 좋습니다. 천천히 마시는 감각에 집중해 보세요.',
      '지금의 잔잔함을 오래 가져갈 수 있도록 몸의 속도도 같이 낮춰 보세요.',
      5::smallint,
      '["따뜻한 물이나 차를 준비하기","한 모금씩 천천히 마시기","급하게 넘기지 않고 온도와 감각 느끼기"]'::jsonb,
      'local_cafe_outlined',
      'sky',
      'indigo',
      'calm',
      '안정된 감각을 오래 유지하기',
      '천천히 숨 고르는 중',
      true,
      1::smallint,
      20::smallint
    ),
    (
      'mission_calm_three_good_things',
      '지금 괜찮은 것 세 가지 떠올리기',
      '평온한 순간에는 억지로 더 좋아지려 하기보다, 이미 괜찮은 감각을 또렷하게 붙잡는 편이 좋습니다.',
      '지금 괜찮은 것들을 조용히 떠올리며 안정된 감각을 붙잡아 보세요.',
      5::smallint,
      '["눈을 감거나 시선을 잠시 멈추기","지금 괜찮은 것 3가지를 천천히 떠올리기","마지막에 가장 고마운 한 가지를 마음속으로 다시 보기"]'::jsonb,
      'self_improvement_rounded',
      'indigo',
      'sky',
      'calm',
      '안정된 감각을 오래 유지하기',
      '천천히 숨 고르는 중',
      true,
      1::smallint,
      21::smallint
    ),
    (
      'mission_depressed_water_and_stand',
      '물 한 컵 마시고 몸 조금 일으키기',
      '가라앉을 때는 억지로 밝아지려 하기보다, 몸을 아주 조금 움직이는 쪽이 더 현실적입니다.',
      '작게라도 떠오를 수 있게, 몸을 한 번만 가볍게 일으켜 보세요.',
      5::smallint,
      '["물 한 컵을 준비해 천천히 마시기","등이나 어깨를 조금 세우기","한 번만 자리에서 몸을 바로 세워 보기"]'::jsonb,
      'water_drop_outlined',
      'sky',
      'violet',
      'depressed',
      '억지로 밝아지기보다, 아주 작게 떠오르기',
      '가라앉는 기분',
      true,
      1::smallint,
      30::smallint
    ),
    (
      'mission_depressed_light_3min',
      '밝은 곳 가까이 3분 있기',
      '우울한 상태에서는 생각을 바꾸기보다, 빛과 자세 같은 환경 자극을 조금 조정하는 편이 부담이 적습니다.',
      '햇빛이나 밝은 조명 가까이 3분만 머물러 보세요.',
      3::smallint,
      '["커튼을 열거나 밝은 조명 쪽으로 이동하기","3분 동안 그 자리에 머물기","끝나면 오늘 버틴 나에게 한 문장 남기기"]'::jsonb,
      'wb_sunny_outlined',
      'amber',
      'violet',
      'depressed',
      '억지로 밝아지기보다, 아주 작게 떠오르기',
      '가라앉는 기분',
      true,
      1::smallint,
      31::smallint
    ),
    (
      'mission_lethargic_release_shoulders',
      '앉은 자리에서 어깨 힘 빼기',
      '무기력할 때는 더 움직이려 하기보다, 지금 자세에서 힘을 덜 쓰는 행동이 더 맞을 수 있습니다.',
      '에너지를 아끼면서도 할 수 있는 가장 작은 움직임부터 해 보세요.',
      3::smallint,
      '["호흡을 한 번 길게 내쉬기","턱과 어깨에 들어간 힘을 천천히 풀기","지금 자세가 조금 편해졌는지 확인하기"]'::jsonb,
      'airline_seat_recline_normal_rounded',
      'indigo',
      'sky',
      'lethargic',
      '에너지 소모를 줄이고 최소 행동만 하기',
      '기운이 잘 안 남',
      true,
      1::smallint,
      40::smallint
    ),
    (
      'mission_lethargic_wash_hands',
      '손만 가볍게 씻기',
      '산책이나 운동처럼 큰 행동은 지금 상태에서 부담이 될 수 있습니다. 아주 짧은 정리 행동으로 충분합니다.',
      '세수까지 가지 않아도 괜찮아요. 손만 가볍게 씻어도 됩니다.',
      3::smallint,
      '["세면대나 화장실로 가기","손을 물에 적시고 가볍게 씻기","수건이나 옷에 손을 닦고 다시 쉬기"]'::jsonb,
      'wash_rounded',
      'sky',
      'indigo',
      'lethargic',
      '에너지 소모를 줄이고 최소 행동만 하기',
      '기운이 잘 안 남',
      true,
      1::smallint,
      41::smallint
    ),
    (
      'mission_anxious_breathing',
      '4초 들이마시고 6초 내쉬기',
      '불안할 때는 생각을 멈추는 것보다 몸의 속도를 먼저 늦추는 편이 도움이 됩니다.',
      '몸의 호흡 리듬부터 천천히 낮춰 보세요.',
      5::smallint,
      '["어깨를 내려놓고 편한 자세 찾기","4초 들이마시고 6초 내쉬는 호흡 5번 하기","숨이 조금 느려졌는지 확인하기"]'::jsonb,
      'air',
      'sky',
      'violet',
      'anxious',
      '생각보다 몸의 속도를 먼저 낮추기',
      '마음이 조급함',
      true,
      1::smallint,
      50::smallint
    ),
    (
      'mission_anxious_five_objects',
      '눈에 보이는 것 다섯 개 말해보기',
      '조급한 마음이 커질수록 감각으로 돌아오는 행동이 더 직접적으로 도움이 됩니다.',
      '지금 보이는 것들을 천천히 확인하며 현재 감각으로 돌아와 보세요.',
      5::smallint,
      '["주변을 천천히 둘러보기","눈에 보이는 물건 5개를 하나씩 말해보기","마지막에 발바닥 감각을 한 번 느끼기"]'::jsonb,
      'visibility_rounded',
      'violet',
      'indigo',
      'anxious',
      '생각보다 몸의 속도를 먼저 낮추기',
      '마음이 조급함',
      true,
      1::smallint,
      51::smallint
    ),
    (
      'mission_irritated_mute_notifications',
      '알림 끄고 잠시 조용한 곳으로 이동하기',
      '예민한 상태에서는 새로운 자극을 더 받지 않는 것이 먼저입니다.',
      '반응하기 전에 자극부터 조금 줄여 보세요.',
      5::smallint,
      '["휴대폰 알림을 잠시 끄기","가능하면 조금 더 조용한 곳으로 이동하기","몸이 덜 거슬리는지 1분만 살펴보기"]'::jsonb,
      'notifications_off_outlined',
      'rose',
      'indigo',
      'irritated',
      '자극을 줄이고 반응을 늦추기',
      '작은 일도 거슬림',
      true,
      1::smallint,
      60::smallint
    ),
    (
      'mission_irritated_delay_reply',
      '답장이나 반응을 10분 미루기',
      '짜증이 올라와 있을 때는 바로 반응하지 않는 것만으로도 상황을 덜 키울 수 있습니다.',
      '지금 답하지 않아도 되는 일이라면 10분만 뒤로 미뤄 보세요.',
      5::smallint,
      '["지금 바로 답해야 하는 일인지 확인하기","가능하면 10분 뒤에 다시 보기로 정하기","그 사이 턱과 손의 힘을 한 번 풀기"]'::jsonb,
      'schedule_send_outlined',
      'indigo',
      'rose',
      'irritated',
      '자극을 줄이고 반응을 늦추기',
      '작은 일도 거슬림',
      true,
      1::smallint,
      61::smallint
    )
) as x(
  type,
  title,
  body,
  subtitle,
  duration_minutes,
  checklist_json,
  accent_icon,
  accent_start_color,
  accent_end_color,
  mission_profile_key,
  mission_goal,
  mission_state_label,
  is_random_eligible,
  selection_weight,
  sort_order
)
where not exists (
  select 1
  from public.nudge_templates nt
  where nt.type = x.type
);

drop function if exists public.get_today_mission(boolean);

create or replace function public.get_today_mission(
  p_mark_opened boolean default false,
  p_selected_emotion_profile varchar(24) default null
)
returns table (
  delivery_id uuid,
  template_id bigint,
  mission_type varchar(32),
  title varchar(80),
  subtitle varchar(120),
  body varchar(240),
  duration_minutes smallint,
  checklist_json jsonb,
  cta_label varchar(32),
  accent_icon varchar(32),
  accent_start_color varchar(16),
  accent_end_color varchar(16),
  delivery_local_date date,
  opened_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  selection_source varchar(16),
  matched_mission_profile varchar(24),
  mission_goal varchar(80),
  mission_state_label varchar(80)
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_timezone varchar(64);
  v_is_active boolean;
  v_date_local date;
  v_delivery_id uuid;
  v_selected_emotion_profile varchar(24);
  v_template_id bigint;
  v_selection_source varchar(16);
  v_matched_mission_profile varchar(24);
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  select p.timezone, p.is_active
  into v_timezone, v_is_active
  from public.profiles p
  where p.id = v_user_id;

  if v_timezone is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if v_is_active is false then
    perform public.raise_app_error('FORBIDDEN');
  end if;

  v_date_local := (now() at time zone v_timezone)::date;
  v_selected_emotion_profile := nullif(trim(lower(coalesce(p_selected_emotion_profile, ''))), '');

  if v_selected_emotion_profile is not null
    and v_selected_emotion_profile not in ('energized', 'calm', 'depressed', 'lethargic', 'anxious', 'irritated') then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select nd.id
  into v_delivery_id
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.user_id = v_user_id
    and nd.delivery_local_date = v_date_local
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission'
  order by nd.delivered_at desc
  limit 1;

  if v_delivery_id is null then
    if v_selected_emotion_profile is not null then
      select nt.id, 'emotion'::varchar(16), nt.mission_profile_key
      into v_template_id, v_selection_source, v_matched_mission_profile
      from public.nudge_templates nt
      where nt.category = 'mission'
        and nt.is_active = true
        and nt.mission_profile_key = v_selected_emotion_profile
      order by random(), nt.sort_order asc, nt.id asc
      limit 1;
    else
      select nt.id, 'random'::varchar(16), nt.mission_profile_key
      into v_template_id, v_selection_source, v_matched_mission_profile
      from public.nudge_templates nt
      where nt.category = 'mission'
        and nt.is_active = true
        and nt.is_random_eligible = true
      order by random(), nt.sort_order asc, nt.id asc
      limit 1;
    end if;

    if v_template_id is null then
      select nt.id, coalesce(v_selection_source, 'random'::varchar(16)), nt.mission_profile_key
      into v_template_id, v_selection_source, v_matched_mission_profile
      from public.nudge_templates nt
      where nt.category = 'mission'
        and nt.is_active = true
      order by nt.sort_order asc, nt.id asc
      limit 1;
    end if;

    if v_template_id is null then
      perform public.raise_app_error('NUDGE_NOT_FOUND');
    end if;

    insert into public.nudge_deliveries (
      template_id,
      user_id,
      delivered_at,
      delivery_local_date,
      delivery_category,
      selection_source,
      matched_mission_profile
    )
    values (
      v_template_id,
      v_user_id,
      now(),
      v_date_local,
      'mission',
      v_selection_source,
      v_matched_mission_profile
    )
    on conflict (user_id, delivery_local_date, delivery_category)
      where delivery_category = 'mission'
    do update set
      user_id = public.nudge_deliveries.user_id
    returning id into v_delivery_id;
  end if;

  if p_mark_opened then
    update public.nudge_deliveries nd
    set opened_at = coalesce(nd.opened_at, now())
    where nd.id = v_delivery_id;

    insert into public.daily_logs (
      user_id,
      date,
      nudge_opened,
      created_at,
      updated_at
    )
    values (v_user_id, v_date_local, true, now(), now())
    on conflict (user_id, date)
    do update set
      nudge_opened = true,
      updated_at = now();
  end if;

  return query
  select
    nd.id as delivery_id,
    nt.id as template_id,
    nt.type::varchar(32) as mission_type,
    nt.title::varchar(80) as title,
    coalesce(nt.subtitle, ''::varchar(120))::varchar(120) as subtitle,
    nt.body::varchar(240) as body,
    nt.duration_minutes::smallint as duration_minutes,
    coalesce(nt.checklist_json, '[]'::jsonb) as checklist_json,
    coalesce(nt.cta_label, '미션 시작하기'::varchar(32))::varchar(32) as cta_label,
    coalesce(nt.accent_icon, 'auto_awesome'::varchar(32))::varchar(32) as accent_icon,
    coalesce(nt.accent_start_color, 'violet'::varchar(16))::varchar(16) as accent_start_color,
    coalesce(nt.accent_end_color, 'indigo'::varchar(16))::varchar(16) as accent_end_color,
    nd.delivery_local_date,
    nd.opened_at,
    nd.started_at,
    nd.completed_at,
    coalesce(nd.selection_source, 'existing'::varchar(16))::varchar(16) as selection_source,
    coalesce(nd.matched_mission_profile, nt.mission_profile_key)::varchar(24) as matched_mission_profile,
    coalesce(nt.mission_goal, ''::varchar(80))::varchar(80) as mission_goal,
    coalesce(nt.mission_state_label, ''::varchar(80))::varchar(80) as mission_state_label
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.id = v_delivery_id
    and nd.user_id = v_user_id
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission'
  limit 1;

  if not found then
    perform public.raise_app_error('NUDGE_NOT_FOUND');
  end if;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.start_today_mission(
  p_delivery_id uuid
)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_delivery_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  update public.nudge_deliveries nd
  set
    opened_at = coalesce(nd.opened_at, now()),
    started_at = coalesce(nd.started_at, now()),
    delivery_category = coalesce(nd.delivery_category, 'mission')
  from public.nudge_templates nt
  where nd.id = p_delivery_id
    and nd.user_id = v_user_id
    and nd.template_id = nt.id
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission';

  if not found then
    perform public.raise_app_error('NUDGE_NOT_FOUND');
  end if;
end;
$$;

create or replace function public.complete_today_mission(
  p_delivery_id uuid
)
returns void
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_delivery_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  update public.nudge_deliveries nd
  set
    opened_at = coalesce(nd.opened_at, now()),
    started_at = coalesce(nd.started_at, now()),
    completed_at = coalesce(nd.completed_at, now()),
    delivery_category = coalesce(nd.delivery_category, 'mission')
  from public.nudge_templates nt
  where nd.id = p_delivery_id
    and nd.user_id = v_user_id
    and nd.template_id = nt.id
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission';

  if not found then
    perform public.raise_app_error('NUDGE_NOT_FOUND');
  end if;
end;
$$;

grant execute on function public.get_today_mission(boolean, varchar) to authenticated;
grant execute on function public.start_today_mission(uuid) to authenticated;
grant execute on function public.complete_today_mission(uuid) to authenticated;
