create table if not exists public.letter_deliveries (
  id uuid primary key default gen_random_uuid(),
  star_id uuid not null references public.stars(id) on delete cascade,
  reaction_id uuid not null unique references public.reactions(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id),
  recipient_user_id uuid not null references public.profiles(id),
  content varchar(240) not null,
  deliver_at timestamptz not null,
  delivered_at timestamptz null,
  opened_at timestamptz null,
  created_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  check (length(btrim(content)) between 1 and 240),
  check (sender_user_id <> recipient_user_id)
);

create unique index if not exists idx_letter_deliveries_unique_star_sender
on public.letter_deliveries (star_id, sender_user_id)
where is_deleted = false;

create index if not exists idx_letter_deliveries_due
on public.letter_deliveries (deliver_at)
where delivered_at is null and is_deleted = false;

alter table public.letter_deliveries enable row level security;

drop policy if exists letter_deliveries_select_recipient on public.letter_deliveries;
create policy letter_deliveries_select_recipient
on public.letter_deliveries
for select
to authenticated
using (
  recipient_user_id = auth.uid()
  and delivered_at is not null
  and is_deleted = false
);

create or replace function public.send_letter(
  p_star_id uuid,
  p_content text
)
returns table (
  letter_id uuid,
  reaction_id uuid,
  star_id uuid,
  reaction_count int,
  deliver_at timestamptz
)
language plpgsql
security definer
as $$
declare
  v_sender_user_id uuid;
  v_sender_timezone varchar(64);
  v_local_date date;
  v_target_owner_id uuid;
  v_today_count int;
  v_reaction_id uuid;
  v_reaction_count int;
  v_letter_id uuid;
  v_deliver_at timestamptz;
begin
  v_sender_user_id := auth.uid();
  if v_sender_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_star_id is null or p_content is null or length(btrim(p_content)) = 0 or length(p_content) > 240 then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select s.user_id
  into v_target_owner_id
  from public.stars s
  where s.id = p_star_id
    and s.is_deleted = false
    and s.visibility_status = 'public'
    and (s.expires_at is null or s.expires_at > now());

  if v_target_owner_id is null then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  if v_target_owner_id = v_sender_user_id then
    perform public.raise_app_error('SELF_REACTION_NOT_ALLOWED');
  end if;

  if exists (
    select 1
    from public.blocks b
    where
      (b.blocker_user_id = v_sender_user_id and b.blocked_user_id = v_target_owner_id)
      or (b.blocker_user_id = v_target_owner_id and b.blocked_user_id = v_sender_user_id)
  ) then
    perform public.raise_app_error('BLOCKED_RELATIONSHIP');
  end if;

  if exists (
    select 1
    from public.reactions r
    where r.star_id = p_star_id
      and r.sender_user_id = v_sender_user_id
      and r.reaction_type_id = 6
  ) then
    perform public.raise_app_error('ALREADY_REACTED');
  end if;

  if exists (
    select 1
    from public.letter_deliveries l
    where l.star_id = p_star_id
      and l.sender_user_id = v_sender_user_id
      and l.is_deleted = false
  ) then
    perform public.raise_app_error('ALREADY_REACTED');
  end if;

  select p.timezone
  into v_sender_timezone
  from public.profiles p
  where p.id = v_sender_user_id and p.is_active = true;

  if v_sender_timezone is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  v_local_date := (now() at time zone v_sender_timezone)::date;

  select count(*)
  into v_today_count
  from public.reactions r
  where r.sender_user_id = v_sender_user_id
    and r.created_local_date = v_local_date;

  if v_today_count >= 20 then
    perform public.raise_app_error('DAILY_REACTION_LIMIT_EXCEEDED');
  end if;

  insert into public.reactions (
    star_id,
    sender_user_id,
    reaction_type_id,
    created_local_date
  )
  values (
    p_star_id,
    v_sender_user_id,
    6,
    v_local_date
  )
  returning id into v_reaction_id;

  v_deliver_at := now() + interval '1 day';

  insert into public.letter_deliveries (
    star_id,
    reaction_id,
    sender_user_id,
    recipient_user_id,
    content,
    deliver_at
  )
  values (
    p_star_id,
    v_reaction_id,
    v_sender_user_id,
    v_target_owner_id,
    btrim(p_content),
    v_deliver_at
  )
  returning id into v_letter_id;

  update public.stars
  set reaction_count = stars.reaction_count + 1
  where id = p_star_id
  returning stars.reaction_count into v_reaction_count;

  insert into public.daily_logs (user_id, date, reaction_sent_count, created_at, updated_at)
  values (v_sender_user_id, v_local_date, 1, now(), now())
  on conflict (user_id, date)
  do update set
    reaction_sent_count = public.daily_logs.reaction_sent_count + 1,
    updated_at = now();

  return query
  select
    v_letter_id as letter_id,
    v_reaction_id as reaction_id,
    p_star_id as star_id,
    v_reaction_count as reaction_count,
    v_deliver_at as deliver_at;
exception
  when unique_violation then
    perform public.raise_app_error('ALREADY_REACTED');
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.open_letter(
  p_letter_id uuid
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
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_letter_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if not exists (
    select 1
    from public.letter_deliveries l
    where l.id = p_letter_id
      and l.recipient_user_id = v_user_id
      and l.delivered_at is not null
      and l.is_deleted = false
  ) then
    perform public.raise_app_error('LETTER_NOT_FOUND');
  end if;

  update public.letter_deliveries
  set opened_at = coalesce(opened_at, now())
  where id = p_letter_id;

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
  where l.id = p_letter_id;
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
      format('"%s" 별에 편지가 도착했어요.', s.content)::text as body,
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

grant execute on function public.send_letter(uuid, text) to authenticated;
grant execute on function public.open_letter(uuid) to authenticated;
grant execute on function public.get_comfort_notifications(int, int) to authenticated;
