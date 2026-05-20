create index if not exists idx_letter_deliveries_recipient_delivered
on public.letter_deliveries (recipient_user_id, delivered_at desc)
where delivered_at is not null and is_deleted = false;

create index if not exists idx_stars_user_created_at
on public.stars (user_id, created_at desc);

create or replace function public.get_received_letters(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  letter_id uuid,
  star_id uuid,
  star_content varchar(80),
  content varchar(240),
  delivered_at timestamptz,
  opened_at timestamptz
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
  select
    l.id as letter_id,
    l.star_id,
    s.content as star_content,
    l.content,
    l.delivered_at,
    l.opened_at
  from public.letter_deliveries l
  join public.stars s on s.id = l.star_id
  where l.recipient_user_id = v_user_id
    and l.delivered_at is not null
    and l.is_deleted = false
  order by l.delivered_at desc
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

create or replace function public.get_my_star_history(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  star_id uuid,
  content varchar(80),
  tag_names text[],
  time_bucket varchar(16),
  reaction_count int,
  created_at timestamptz,
  created_local_date date,
  visibility_status varchar(16),
  is_deleted boolean,
  is_expired boolean
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
  select
    s.id as star_id,
    s.content,
    coalesce(
      array_agg(et.name_ko::text order by et.priority desc, et.id)
        filter (where et.id is not null),
      array[]::text[]
    ) as tag_names,
    s.time_bucket,
    s.reaction_count,
    s.created_at,
    s.created_local_date,
    s.visibility_status,
    s.is_deleted,
    (s.expires_at is not null and s.expires_at <= now()) as is_expired
  from public.stars s
  left join public.star_emotion_maps sem on sem.star_id = s.id
  left join public.emotion_tags et on et.id = sem.tag_id
  where s.user_id = v_user_id
  group by
    s.id,
    s.content,
    s.time_bucket,
    s.reaction_count,
    s.created_at,
    s.created_local_date,
    s.visibility_status,
    s.is_deleted,
    s.expires_at
  order by s.created_at desc
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
        else 'indigo'
      end::varchar(16) as accent_color,
      true as is_opened
    from public.reactions r
    join public.stars s on s.id = r.star_id
    join public.reaction_types rt on rt.id = r.reaction_type_id
    where s.user_id = v_user_id
      and s.is_deleted = false
      and rt.code <> 'LETTER'
  ),
  letter_notifications as (
    select
      l.id as notification_id,
      'letter'::varchar(16) as notification_type,
      '익명 편지가 도착했어요'::text as title,
      format('"%s" 별에 하루 전 보낸 편지가 도착했어요.', s.content)::text as body,
      l.delivered_at as event_at,
      'letter'::varchar(32) as icon,
      'indigo'::varchar(16) as accent_color,
      (l.opened_at is not null) as is_opened
    from public.letter_deliveries l
    join public.stars s on s.id = l.star_id
    where l.recipient_user_id = v_user_id
      and l.delivered_at is not null
      and l.is_deleted = false
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
    select * from letter_notifications
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

grant execute on function public.get_received_letters(int, int) to authenticated;
grant execute on function public.get_my_star_history(int, int) to authenticated;
grant execute on function public.get_comfort_notifications(int, int) to authenticated;
