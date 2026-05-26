create table if not exists public.coffee_gift_deliveries (
  id uuid primary key default gen_random_uuid(),
  star_id uuid not null references public.stars(id) on delete cascade,
  reaction_id uuid not null references public.reactions(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id),
  recipient_user_id uuid not null references public.profiles(id),
  gift_type varchar(32) not null default 'coffee',
  title varchar(80) not null default '커피 선물',
  description varchar(160) not null default '기프티콘 API 연동 전까지 앱 안에서 확인할 수 있는 커피 선물입니다.',
  status varchar(24) not null default 'reserved',
  opened_at timestamptz null,
  created_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  unique (reaction_id),
  unique (star_id, sender_user_id),
  check (gift_type in ('coffee')),
  check (status in ('reserved', 'issued', 'redeemed', 'expired', 'cancelled'))
);

create index if not exists idx_coffee_gift_deliveries_recipient_created
on public.coffee_gift_deliveries (recipient_user_id, created_at desc)
where is_deleted = false;

alter table public.coffee_gift_deliveries enable row level security;

drop policy if exists coffee_gift_deliveries_select_recipient on public.coffee_gift_deliveries;
create policy coffee_gift_deliveries_select_recipient
on public.coffee_gift_deliveries
for select
to authenticated
using (
  recipient_user_id = auth.uid()
  and is_deleted = false
);

insert into public.coffee_gift_deliveries (
  star_id,
  reaction_id,
  sender_user_id,
  recipient_user_id
)
select
  r.star_id,
  r.id,
  r.sender_user_id,
  s.user_id
from public.reactions r
join public.reaction_types rt on rt.id = r.reaction_type_id
join public.stars s on s.id = r.star_id
where rt.code = 'WARM_COFFEE'
  and s.user_id <> r.sender_user_id
on conflict do nothing;

create or replace function public.get_received_gifts(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  gift_id uuid,
  star_id uuid,
  star_content varchar(80),
  gift_type varchar(32),
  title varchar(80),
  description varchar(160),
  status varchar(24),
  created_at timestamptz,
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
    g.id as gift_id,
    g.star_id,
    s.content as star_content,
    g.gift_type,
    g.title,
    g.description,
    g.status,
    g.created_at,
    g.opened_at
  from public.coffee_gift_deliveries g
  join public.stars s on s.id = g.star_id
  where g.recipient_user_id = v_user_id
    and g.is_deleted = false
  order by g.created_at desc
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

create or replace function public.open_gift(
  p_gift_id uuid
)
returns table (
  gift_id uuid,
  star_id uuid,
  star_content varchar(80),
  gift_type varchar(32),
  title varchar(80),
  description varchar(160),
  status varchar(24),
  created_at timestamptz,
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

  if p_gift_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if not exists (
    select 1
    from public.coffee_gift_deliveries g
    where g.id = p_gift_id
      and g.recipient_user_id = v_user_id
      and g.is_deleted = false
  ) then
    perform public.raise_app_error('GIFT_NOT_FOUND');
  end if;

  update public.coffee_gift_deliveries
  set opened_at = coalesce(opened_at, now())
  where id = p_gift_id;

  return query
  select
    g.id as gift_id,
    g.star_id,
    s.content as star_content,
    g.gift_type,
    g.title,
    g.description,
    g.status,
    g.created_at,
    g.opened_at
  from public.coffee_gift_deliveries g
  join public.stars s on s.id = g.star_id
  where g.id = p_gift_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.send_reaction(
  p_star_id uuid,
  p_reaction_type_id bigint
)
returns table (
  reaction_id uuid,
  star_id uuid,
  reaction_count int,
  created_at timestamptz
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
  v_reaction_created_at timestamptz;
  v_reaction_count int;
begin
  v_sender_user_id := auth.uid();
  if v_sender_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_star_id is null or p_reaction_type_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select s.user_id
  into v_target_owner_id
  from public.stars s
  where s.id = p_star_id and s.is_deleted = false;

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

  if not exists (
    select 1
    from public.reaction_types rt
    where rt.id = p_reaction_type_id and rt.is_active = true
  ) then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if exists (
    select 1
    from public.reactions r
    where r.star_id = p_star_id
      and r.sender_user_id = v_sender_user_id
      and (
        (
          p_reaction_type_id in (5, 6)
          and r.reaction_type_id = p_reaction_type_id
        )
        or (
          p_reaction_type_id not in (5, 6)
          and r.reaction_type_id not in (5, 6)
        )
      )
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

  begin
    insert into public.reactions (
      star_id,
      sender_user_id,
      reaction_type_id,
      created_local_date
    )
    values (
      p_star_id,
      v_sender_user_id,
      p_reaction_type_id,
      v_local_date
    )
    returning id, reactions.created_at into v_reaction_id, v_reaction_created_at;
  exception
    when unique_violation then
      perform public.raise_app_error('ALREADY_REACTED');
  end;

  if p_reaction_type_id = 5 then
    insert into public.coffee_gift_deliveries (
      star_id,
      reaction_id,
      sender_user_id,
      recipient_user_id
    )
    values (
      p_star_id,
      v_reaction_id,
      v_sender_user_id,
      v_target_owner_id
    );
  end if;

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
    v_reaction_id as reaction_id,
    p_star_id as star_id,
    v_reaction_count as reaction_count,
    v_reaction_created_at as created_at;
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
      and rt.code not in ('LETTER', 'WARM_COFFEE')
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

grant execute on function public.get_received_gifts(int, int) to authenticated;
grant execute on function public.open_gift(uuid) to authenticated;
grant execute on function public.send_reaction(uuid, bigint) to authenticated;
grant execute on function public.get_comfort_notifications(int, int) to authenticated;
