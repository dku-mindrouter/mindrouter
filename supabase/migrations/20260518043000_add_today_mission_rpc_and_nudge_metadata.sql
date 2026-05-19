alter table public.nudge_templates
  add column if not exists category varchar(16) not null default 'comfort',
  add column if not exists subtitle varchar(120),
  add column if not exists duration_minutes smallint not null default 10,
  add column if not exists checklist_json jsonb not null default '[]'::jsonb,
  add column if not exists cta_label varchar(32) not null default '자세히 보기',
  add column if not exists accent_icon varchar(32) not null default 'auto_awesome',
  add column if not exists accent_start_color varchar(16) not null default 'violet',
  add column if not exists accent_end_color varchar(16) not null default 'indigo';

alter table public.nudge_deliveries
  add column if not exists delivery_local_date date,
  add column if not exists started_at timestamptz,
  add column if not exists completed_at timestamptz;

update public.nudge_deliveries
set delivery_local_date = coalesce(delivery_local_date, delivered_at::date)
where delivery_local_date is null;

create index if not exists idx_nudge_deliveries_user_local_date
on public.nudge_deliveries (user_id, delivery_local_date desc);

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
  accent_end_color
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
  x.accent_end_color
from (
  values
    (
      'mission_walk',
      '햇살과 함께 10분 걷기',
      '생각을 정리하려고 애쓰기보다, 먼저 몸의 리듬을 조금 바꿔보세요.',
      '무거운 기분일수록 가볍게 움직이는 것부터 시작해도 충분해요.',
      10::smallint,
      '["편한 신발을 신고 밖으로 나가기","좋아하는 음악과 함께 10분 걷기","하늘이나 나무를 한 번은 의식해서 보기"]'::jsonb,
      'wb_sunny_outlined',
      'amber',
      'orange'
    ),
    (
      'mission_grounding',
      '호흡에 집중하는 8분',
      '들숨과 날숨을 세면서 호흡의 길이를 일정하게 맞춰보세요.',
      '예민하고 불안할수록 지금 이 순간의 감각으로 돌아오는 연습이 도움이 돼요.',
      8::smallint,
      '["앉거나 기대기 좋은 자리를 찾기","4번 들이마시고 4번 내쉬는 호흡 10회 하기","마지막에 어깨 힘이 빠졌는지 확인하기"]'::jsonb,
      'air',
      'sky',
      'violet'
    ),
    (
      'mission_hydration',
      '물 한 잔과 창밖 바라보기',
      '작은 수분 보충과 시선 전환만으로도 마음의 결이 조금 달라질 수 있어요.',
      '평온함을 오래 유지하고 싶을 때는 몸의 기본 리듬을 챙기는 것이 좋아요.',
      5::smallint,
      '["물 한 잔을 천천히 마시기","창밖이나 먼 곳을 1분 이상 바라보기","지금 몸이 가장 편한 자세를 찾아보기"]'::jsonb,
      'water_drop_outlined',
      'sky',
      'indigo'
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
  accent_end_color
)
where not exists (
  select 1
  from public.nudge_templates nt
  where nt.type = x.type
);

create or replace function public.get_today_mission(
  p_mark_opened boolean default false
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
  completed_at timestamptz
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
  v_template_id bigint;
  v_mission_type varchar(32);
  v_title varchar(80);
  v_subtitle varchar(120);
  v_body varchar(240);
  v_duration_minutes smallint;
  v_checklist_json jsonb;
  v_cta_label varchar(32);
  v_accent_icon varchar(32);
  v_accent_start_color varchar(16);
  v_accent_end_color varchar(16);
  v_opened_at timestamptz;
  v_started_at timestamptz;
  v_completed_at timestamptz;
  v_latest_group varchar(32);
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

  select
    nd.id,
    nt.id,
    nt.type,
    nt.title,
    nt.subtitle,
    nt.body,
    nt.duration_minutes,
    nt.checklist_json,
    nt.cta_label,
    nt.accent_icon,
    nt.accent_start_color,
    nt.accent_end_color,
    nd.opened_at,
    nd.started_at,
    nd.completed_at
  into
    v_delivery_id,
    v_template_id,
    v_mission_type,
    v_title,
    v_subtitle,
    v_body,
    v_duration_minutes,
    v_checklist_json,
    v_cta_label,
    v_accent_icon,
    v_accent_start_color,
    v_accent_end_color,
    v_opened_at,
    v_started_at,
    v_completed_at
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.user_id = v_user_id
    and nd.delivery_local_date = v_date_local
    and nt.category = 'mission'
  order by nd.delivered_at desc
  limit 1;

  if v_delivery_id is null then
    select et.group_name
    into v_latest_group
    from public.stars s
    join public.star_emotion_maps sem on sem.star_id = s.id
    join public.emotion_tags et on et.id = sem.tag_id
    where s.user_id = v_user_id
      and s.is_deleted = false
    order by s.created_at desc, et.priority desc, et.id asc
    limit 1;

    if v_latest_group in ('anxiety', 'support_need', 'anxious') then
      v_mission_type := 'mission_grounding';
    elsif v_latest_group in ('low_energy', 'burnout', 'negative') then
      v_mission_type := 'mission_walk';
    elsif v_latest_group in ('calm_recovery', 'calm', 'positive') then
      v_mission_type := 'mission_hydration';
    else
      v_mission_type := 'mission_walk';
    end if;

    select
      nt.id,
      nt.type,
      nt.title,
      nt.subtitle,
      nt.body,
      nt.duration_minutes,
      nt.checklist_json,
      nt.cta_label,
      nt.accent_icon,
      nt.accent_start_color,
      nt.accent_end_color
    into
      v_template_id,
      v_mission_type,
      v_title,
      v_subtitle,
      v_body,
      v_duration_minutes,
      v_checklist_json,
      v_cta_label,
      v_accent_icon,
      v_accent_start_color,
      v_accent_end_color
    from public.nudge_templates nt
    where nt.category = 'mission'
      and nt.type = v_mission_type
      and nt.is_active = true
    limit 1;

    if v_template_id is null then
      select
        nt.id,
        nt.type,
        nt.title,
        nt.subtitle,
        nt.body,
        nt.duration_minutes,
        nt.checklist_json,
        nt.cta_label,
        nt.accent_icon,
        nt.accent_start_color,
        nt.accent_end_color
      into
        v_template_id,
        v_mission_type,
        v_title,
        v_subtitle,
        v_body,
        v_duration_minutes,
        v_checklist_json,
        v_cta_label,
        v_accent_icon,
        v_accent_start_color,
        v_accent_end_color
      from public.nudge_templates nt
      where nt.category = 'mission'
        and nt.is_active = true
      order by nt.id asc
      limit 1;
    end if;

    if v_template_id is null then
      perform public.raise_app_error('NUDGE_NOT_FOUND');
    end if;

    insert into public.nudge_deliveries (
      template_id,
      user_id,
      delivered_at,
      delivery_local_date
    )
    values (
      v_template_id,
      v_user_id,
      now(),
      v_date_local
    )
    returning id, opened_at, started_at, completed_at
    into v_delivery_id, v_opened_at, v_started_at, v_completed_at;
  end if;

  if p_mark_opened and v_opened_at is null then
    update public.nudge_deliveries nd
    set opened_at = now()
    where nd.id = v_delivery_id
    returning nd.opened_at into v_opened_at;

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
    v_delivery_id,
    v_template_id,
    v_mission_type,
    v_title,
    coalesce(v_subtitle, ''),
    v_body,
    v_duration_minutes,
    coalesce(v_checklist_json, '[]'::jsonb),
    v_cta_label,
    v_accent_icon,
    v_accent_start_color,
    v_accent_end_color,
    v_date_local,
    v_opened_at,
    v_started_at,
    v_completed_at;
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
    started_at = coalesce(nd.started_at, now())
  from public.nudge_templates nt
  where nd.id = p_delivery_id
    and nd.user_id = v_user_id
    and nd.template_id = nt.id
    and nt.category = 'mission';

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
    completed_at = coalesce(nd.completed_at, now())
  from public.nudge_templates nt
  where nd.id = p_delivery_id
    and nd.user_id = v_user_id
    and nd.template_id = nt.id
    and nt.category = 'mission';

  if not found then
    perform public.raise_app_error('NUDGE_NOT_FOUND');
  end if;
end;
$$;

grant execute on function public.get_today_mission(boolean) to authenticated;
grant execute on function public.start_today_mission(uuid) to authenticated;
grant execute on function public.complete_today_mission(uuid) to authenticated;

create or replace function public.get_comfort_notifications(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  notification_id uuid,
  notification_type varchar(16),
  title text,
  body text,
  event_at timestamptz,
  icon varchar(32),
  accent_color varchar(16),
  is_opened boolean
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_limit int;
  v_offset int;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  v_limit := greatest(least(coalesce(p_limit, 30), 50), 1);
  v_offset := greatest(coalesce(p_offset, 0), 0);

  return query
  with reaction_notifications as (
    select
      r.id as notification_id,
      'reaction'::varchar(16) as notification_type,
      '새로운 위로가 도착했어요'::text as title,
      format('"%s" 별에 ''%s'' 리액션이 도착했어요.', s.content, rt.label_ko)::text as body,
      r.created_at as event_at,
      coalesce(rt.icon, 'favorite')::varchar(32) as icon,
      case rt.code
        when 'WARM_TEA' then 'amber'
        when 'WARM_COFFEE' then 'coffee'
        when 'HUG' then 'rose'
        when 'YOU_DID_WELL' then 'violet'
        when 'WITH_YOU' then 'sky'
        when 'LETTER' then 'indigo'
        else 'indigo'
      end::varchar(16) as accent_color,
      true as is_opened
    from public.reactions r
    join public.stars s on s.id = r.star_id
    join public.reaction_types rt on rt.id = r.reaction_type_id
    where s.user_id = v_user_id
      and s.is_deleted = false
  ),
  nudge_notifications as (
    select
      nd.id as notification_id,
      'nudge'::varchar(16) as notification_type,
      nt.title::text as title,
      nt.body::text as body,
      nd.delivered_at as event_at,
      'auto_awesome'::varchar(32) as icon,
      'violet'::varchar(16) as accent_color,
      (nd.opened_at is not null) as is_opened
    from public.nudge_deliveries nd
    join public.nudge_templates nt on nt.id = nd.template_id
    where nd.user_id = v_user_id
      and coalesce(nt.category, 'comfort') = 'comfort'
  ),
  combined as (
    select * from reaction_notifications
    union all
    select * from nudge_notifications
  )
  select
    c.notification_id,
    c.notification_type,
    c.title,
    c.body,
    c.event_at,
    c.icon,
    c.accent_color,
    c.is_opened
  from combined c
  order by c.event_at desc
  limit v_limit
  offset v_offset;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

grant execute on function public.get_comfort_notifications(int, int) to authenticated;
