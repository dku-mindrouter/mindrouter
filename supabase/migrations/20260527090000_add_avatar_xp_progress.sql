create table if not exists public.avatar_catalog (
  id bigserial primary key,
  code varchar(32) not null unique,
  name_ko varchar(32) not null,
  description varchar(160) not null default '',
  theme_emotion_group varchar(32),
  rarity varchar(16) not null default 'common',
  is_active boolean not null default true,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.avatar_level_rules (
  level smallint primary key,
  required_total_xp int not null unique,
  title_ko varchar(32) not null,
  constraint avatar_level_rules_level_range check (level between 1 and 10),
  constraint avatar_level_rules_xp_non_negative check (required_total_xp >= 0)
);

create table if not exists public.user_avatars (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  avatar_id bigint not null references public.avatar_catalog(id),
  level smallint not null default 1,
  xp int not null default 0,
  unlocked_at timestamptz not null default now(),
  is_equipped boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint user_avatars_level_range check (level between 1 and 10),
  constraint user_avatars_xp_non_negative check (xp >= 0),
  constraint user_avatars_unique_user_avatar unique (user_id, avatar_id)
);

create unique index if not exists uq_user_avatars_one_equipped
on public.user_avatars(user_id)
where is_equipped = true;

create table if not exists public.avatar_xp_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  user_avatar_id uuid not null references public.user_avatars(id) on delete cascade,
  event_type varchar(32) not null,
  xp_amount int not null,
  source_id text not null,
  local_date date,
  created_at timestamptz not null default now(),
  constraint avatar_xp_events_amount_positive check (xp_amount > 0),
  constraint avatar_xp_events_unique_source unique (user_avatar_id, event_type, source_id)
);

create index if not exists idx_user_avatars_user_id
on public.user_avatars(user_id);

create index if not exists idx_avatar_xp_events_user_date
on public.avatar_xp_events(user_id, local_date desc, created_at desc);

alter table public.avatar_catalog enable row level security;
alter table public.avatar_level_rules enable row level security;
alter table public.user_avatars enable row level security;
alter table public.avatar_xp_events enable row level security;

drop policy if exists avatar_catalog_select_active on public.avatar_catalog;
create policy avatar_catalog_select_active
on public.avatar_catalog
for select
to authenticated
using (is_active = true);

drop policy if exists avatar_level_rules_select_all on public.avatar_level_rules;
create policy avatar_level_rules_select_all
on public.avatar_level_rules
for select
to authenticated
using (true);

drop policy if exists user_avatars_select_own on public.user_avatars;
create policy user_avatars_select_own
on public.user_avatars
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists avatar_xp_events_select_own on public.avatar_xp_events;
create policy avatar_xp_events_select_own
on public.avatar_xp_events
for select
to authenticated
using (user_id = auth.uid());

grant select on table public.avatar_catalog to authenticated;
grant select on table public.avatar_level_rules to authenticated;
grant select on table public.user_avatars to authenticated;
grant select on table public.avatar_xp_events to authenticated;

insert into public.avatar_level_rules (level, required_total_xp, title_ko)
values
  (1, 0, '처음 만난 마음'),
  (2, 80, '작은 별빛'),
  (3, 180, '또렷한 별빛'),
  (4, 320, '자라나는 빛'),
  (5, 500, '따뜻한 궤도'),
  (6, 750, '깊어진 마음'),
  (7, 1050, '은하 산책자'),
  (8, 1400, '반짝이는 동행'),
  (9, 1800, '마음 별자리'),
  (10, 2300, '완성된 별빛')
on conflict (level) do update set
  required_total_xp = excluded.required_total_xp,
  title_ko = excluded.title_ko;

insert into public.avatar_catalog (
  code,
  name_ko,
  description,
  theme_emotion_group,
  rarity,
  sort_order
)
values
  ('moon_rabbit', '달토끼', '매일의 감정을 조용히 모아 성장하는 기본 아바타', 'calm', 'common', 10),
  ('sunny_chick', '햇살 병아리', '행복한 순간을 오래 품고 자라는 아바타', 'happy', 'common', 20),
  ('star_whale', '별고래', '긴 기록을 따라 천천히 커지는 수집형 아바타', 'streak', 'rare', 30)
on conflict (code) do update set
  name_ko = excluded.name_ko,
  description = excluded.description,
  theme_emotion_group = excluded.theme_emotion_group,
  rarity = excluded.rarity,
  sort_order = excluded.sort_order,
  is_active = true;

create or replace function public.avatar_level_for_xp(
  p_xp int
)
returns smallint
language sql
stable
as $$
  select coalesce(max(alr.level), 1)::smallint
  from public.avatar_level_rules alr
  where alr.required_total_xp <= greatest(coalesce(p_xp, 0), 0);
$$;

create or replace function public.ensure_equipped_avatar(
  p_user_id uuid
)
returns uuid
language plpgsql
security definer
as $$
declare
  v_user_avatar_id uuid;
  v_default_avatar_id bigint;
begin
  if p_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  select ua.id
  into v_user_avatar_id
  from public.user_avatars ua
  where ua.user_id = p_user_id
    and ua.is_equipped = true
  order by ua.unlocked_at asc
  limit 1;

  if v_user_avatar_id is not null then
    return v_user_avatar_id;
  end if;

  select ac.id
  into v_default_avatar_id
  from public.avatar_catalog ac
  where ac.code = 'moon_rabbit'
    and ac.is_active = true
  limit 1;

  if v_default_avatar_id is null then
    perform public.raise_app_error('INTERNAL_ERROR');
  end if;

  insert into public.user_avatars (user_id, avatar_id, is_equipped)
  values (p_user_id, v_default_avatar_id, true)
  on conflict (user_id, avatar_id) do update set
    is_equipped = true,
    updated_at = now()
  returning id into v_user_avatar_id;

  update public.user_avatars
  set is_equipped = false,
      updated_at = now()
  where user_id = p_user_id
    and id <> v_user_avatar_id
    and is_equipped = true;

  return v_user_avatar_id;
end;
$$;

create or replace function public.grant_avatar_xp(
  p_user_id uuid,
  p_event_type varchar,
  p_xp_amount int,
  p_source_id text,
  p_local_date date default null
)
returns table (
  user_avatar_id uuid,
  avatar_code varchar(32),
  avatar_name_ko varchar(32),
  level smallint,
  xp int,
  xp_added int,
  current_level_xp int,
  next_level_xp int
)
language plpgsql
security definer
as $$
declare
  v_user_avatar_id uuid;
  v_event_id uuid;
  v_previous_xp int;
  v_new_xp int;
  v_max_xp int;
begin
  if p_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_event_type is null or btrim(p_event_type) = '' or p_xp_amount <= 0 or p_source_id is null or btrim(p_source_id) = '' then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select max(alr.required_total_xp)
  into v_max_xp
  from public.avatar_level_rules alr;

  v_user_avatar_id := public.ensure_equipped_avatar(p_user_id);

  insert into public.avatar_xp_events (
    user_id,
    user_avatar_id,
    event_type,
    xp_amount,
    source_id,
    local_date
  )
  values (
    p_user_id,
    v_user_avatar_id,
    p_event_type,
    p_xp_amount,
    p_source_id,
    p_local_date
  )
  on conflict (user_avatar_id, event_type, source_id) do nothing
  returning id into v_event_id;

  if v_event_id is not null then
    select ua.xp
    into v_previous_xp
    from public.user_avatars ua
    where ua.id = v_user_avatar_id
    for update;

    v_new_xp := least(coalesce(v_previous_xp, 0) + p_xp_amount, coalesce(v_max_xp, 2300));

    update public.user_avatars
    set
      xp = v_new_xp,
      level = public.avatar_level_for_xp(v_new_xp),
      updated_at = now()
    where id = v_user_avatar_id;
  end if;

  return query
  select
    ua.id as user_avatar_id,
    ac.code as avatar_code,
    ac.name_ko as avatar_name_ko,
    ua.level,
    ua.xp,
    case when v_event_id is null then 0 else p_xp_amount end as xp_added,
    current_rule.required_total_xp as current_level_xp,
    coalesce(next_rule.required_total_xp, current_rule.required_total_xp) as next_level_xp
  from public.user_avatars ua
  join public.avatar_catalog ac on ac.id = ua.avatar_id
  join public.avatar_level_rules current_rule on current_rule.level = ua.level
  left join public.avatar_level_rules next_rule on next_rule.level = ua.level + 1
  where ua.id = v_user_avatar_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.create_star(
  p_content text,
  p_tag_ids bigint[],
  p_time_bucket text,
  p_emotion_intensity smallint,
  p_visibility_status text,
  p_expires_at timestamptz default null
)
returns table (
  star_id uuid,
  created_at timestamptz,
  created_local_date date
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_timezone varchar(64);
  v_local_ts timestamp;
  v_local_date date;
  v_star_id uuid;
  v_created_at timestamptz;
  v_valid_tag_count int;
  v_current_streak int := 1;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  select p.timezone
  into v_timezone
  from public.profiles p
  where p.id = v_user_id and p.is_active = true;

  if v_timezone is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if p_content is null or btrim(p_content) = '' or length(p_content) > 80 then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if p_time_bucket is null or p_time_bucket not in ('dawn', 'morning', 'day', 'evening', 'night') then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if p_emotion_intensity is not null and (p_emotion_intensity < 1 or p_emotion_intensity > 5) then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if p_visibility_status is null or btrim(p_visibility_status) = '' or length(p_visibility_status) > 16 then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  if p_tag_ids is null or coalesce(array_length(p_tag_ids, 1), 0) = 0 then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select count(distinct t.id)
  into v_valid_tag_count
  from public.emotion_tags t
  where t.id = any (p_tag_ids) and t.is_active = true;

  if v_valid_tag_count <> (select count(distinct x) from unnest(p_tag_ids) as x) then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  v_local_ts := now() at time zone v_timezone;
  v_local_date := v_local_ts::date;

  begin
    insert into public.stars (
      user_id,
      content,
      time_bucket,
      emotion_intensity,
      visibility_status,
      created_local_date,
      expires_at
    )
    values (
      v_user_id,
      p_content,
      p_time_bucket,
      p_emotion_intensity,
      p_visibility_status,
      v_local_date,
      p_expires_at
    )
    returning id, stars.created_at into v_star_id, v_created_at;
  exception
    when unique_violation then
      perform public.raise_app_error('DAILY_STAR_LIMIT_EXCEEDED');
  end;

  insert into public.star_emotion_maps (star_id, tag_id)
  select v_star_id, x.tag_id
  from (select distinct unnest(p_tag_ids) as tag_id) x;

  insert into public.daily_logs (user_id, date, star_created, created_at, updated_at)
  values (v_user_id, v_local_date, true, now(), now())
  on conflict (user_id, date)
  do update set
    star_created = true,
    updated_at = now();

  perform public.grant_avatar_xp(
    v_user_id,
    'emotion_record',
    20,
    v_star_id::text,
    v_local_date
  );

  with recursive streak_days(day_value) as (
    select v_local_date
    union all
    select day_value - 1
    from streak_days
    where exists (
      select 1
      from public.stars s
      where s.user_id = v_user_id
        and s.created_local_date = day_value - 1
        and s.is_deleted = false
    )
  )
  select count(*)::int
  into v_current_streak
  from streak_days;

  if v_current_streak >= 3 and v_current_streak % 3 = 0 then
    perform public.grant_avatar_xp(
      v_user_id,
      'emotion_streak_3',
      20,
      v_local_date::text,
      v_local_date
    );
  end if;

  if v_current_streak >= 7 and v_current_streak % 7 = 0 then
    perform public.grant_avatar_xp(
      v_user_id,
      'emotion_streak_7',
      50,
      v_local_date::text,
      v_local_date
    );
  end if;

  return query
  select
    v_star_id as star_id,
    v_created_at as created_at,
    v_local_date as created_local_date;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
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
  v_date_local date;
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
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission'
  returning nd.delivery_local_date into v_date_local;

  if not found then
    perform public.raise_app_error('NUDGE_NOT_FOUND');
  end if;

  perform public.grant_avatar_xp(
    v_user_id,
    'mission_complete',
    30,
    p_delivery_id::text,
    v_date_local
  );
end;
$$;

drop function if exists public.get_my_stats();

create or replace function public.get_my_stats()
returns table (
  date_local date,
  logged_dates date[],
  today_received_comfort_count int,
  equipped_user_avatar_id uuid,
  avatar_code varchar(32),
  avatar_name_ko varchar(32),
  avatar_level smallint,
  avatar_xp int,
  avatar_level_title_ko varchar(32),
  avatar_current_level_xp int,
  avatar_next_level_xp int
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_timezone varchar(64);
  v_is_active boolean;
  v_date_local date;
  v_logged_dates date[];
  v_today_received_comfort_count int := 0;
  v_user_avatar_id uuid;
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
    perform public.raise_app_error('PROFILE_NOT_FOUND');
  end if;

  if v_is_active is false then
    perform public.raise_app_error('FORBIDDEN');
  end if;

  v_date_local := (now() at time zone v_timezone)::date;
  v_user_avatar_id := public.ensure_equipped_avatar(v_user_id);

  select coalesce(array_agg(dl.date order by dl.date desc), '{}'::date[])
  into v_logged_dates
  from public.daily_logs dl
  where dl.user_id = v_user_id
    and dl.star_created = true
    and dl.date <= v_date_local;

  select coalesce(s.reaction_count, 0)
  into v_today_received_comfort_count
  from public.stars s
  where s.user_id = v_user_id
    and s.created_local_date = v_date_local
    and s.is_deleted = false
  order by s.created_at desc
  limit 1;

  return query
  select
    v_date_local as date_local,
    coalesce(v_logged_dates, '{}'::date[]) as logged_dates,
    coalesce(v_today_received_comfort_count, 0) as today_received_comfort_count,
    ua.id as equipped_user_avatar_id,
    ac.code as avatar_code,
    ac.name_ko as avatar_name_ko,
    ua.level as avatar_level,
    ua.xp as avatar_xp,
    current_rule.title_ko as avatar_level_title_ko,
    current_rule.required_total_xp as avatar_current_level_xp,
    coalesce(next_rule.required_total_xp, current_rule.required_total_xp) as avatar_next_level_xp
  from public.user_avatars ua
  join public.avatar_catalog ac on ac.id = ua.avatar_id
  join public.avatar_level_rules current_rule on current_rule.level = ua.level
  left join public.avatar_level_rules next_rule on next_rule.level = ua.level + 1
  where ua.id = v_user_avatar_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

revoke execute on function public.ensure_equipped_avatar(uuid) from public, anon, authenticated;
revoke execute on function public.grant_avatar_xp(uuid, varchar, int, text, date) from public, anon, authenticated;

grant execute on function public.avatar_level_for_xp(int) to authenticated;
grant execute on function public.create_star(text, bigint[], text, smallint, text, timestamptz) to authenticated;
grant execute on function public.complete_today_mission(uuid) to authenticated;
grant execute on function public.get_my_stats() to authenticated;
