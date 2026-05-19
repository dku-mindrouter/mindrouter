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
  v_latest_group varchar(32);
  v_target_type varchar(32);
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

  select nd.id
  into v_delivery_id
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
      v_target_type := 'mission_grounding';
    elsif v_latest_group in ('low_energy', 'burnout', 'negative') then
      v_target_type := 'mission_walk';
    elsif v_latest_group in ('calm_recovery', 'calm', 'positive') then
      v_target_type := 'mission_hydration';
    else
      v_target_type := 'mission_walk';
    end if;

    insert into public.nudge_deliveries (
      template_id,
      user_id,
      delivered_at,
      delivery_local_date
    )
    select
      nt.id,
      v_user_id,
      now(),
      v_date_local
    from public.nudge_templates nt
    where nt.category = 'mission'
      and nt.is_active = true
      and nt.type = v_target_type
    order by nt.id asc
    limit 1
    returning id into v_delivery_id;

    if v_delivery_id is null then
      insert into public.nudge_deliveries (
        template_id,
        user_id,
        delivered_at,
        delivery_local_date
      )
      select
        nt.id,
        v_user_id,
        now(),
        v_date_local
      from public.nudge_templates nt
      where nt.category = 'mission'
        and nt.is_active = true
      order by nt.id asc
      limit 1
      returning id into v_delivery_id;
    end if;

    if v_delivery_id is null then
      perform public.raise_app_error('NUDGE_NOT_FOUND');
    end if;
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
    nd.completed_at
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.id = v_delivery_id
    and nd.user_id = v_user_id
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

grant execute on function public.get_today_mission(boolean) to authenticated;
