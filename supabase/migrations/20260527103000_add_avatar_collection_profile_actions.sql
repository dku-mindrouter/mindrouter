create or replace function public.ensure_starter_avatars(
  p_user_id uuid
)
returns void
language plpgsql
security definer
as $$
begin
  if p_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  insert into public.user_avatars (user_id, avatar_id, is_equipped)
  select
    p_user_id,
    ac.id,
    false
  from public.avatar_catalog ac
  where ac.code in ('moon_rabbit', 'sunny_chick')
    and ac.is_active = true
  on conflict (user_id, avatar_id) do nothing;

  perform public.ensure_equipped_avatar(p_user_id);
end;
$$;

create or replace function public.get_avatar_collection()
returns table (
  avatar_id bigint,
  user_avatar_id uuid,
  avatar_code varchar(32),
  avatar_name_ko varchar(32),
  description varchar(160),
  rarity varchar(16),
  is_unlocked boolean,
  is_equipped boolean,
  level smallint,
  xp int,
  level_title_ko varchar(32),
  current_level_xp int,
  next_level_xp int,
  total_collection_xp int,
  total_collection_level int
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_total_xp int := 0;
  v_total_level int := 0;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  perform public.ensure_starter_avatars(v_user_id);

  select coalesce(sum(ua.xp), 0), coalesce(sum(ua.level), 0)
  into v_total_xp, v_total_level
  from public.user_avatars ua
  where ua.user_id = v_user_id;

  return query
  select
    ac.id as avatar_id,
    ua.id as user_avatar_id,
    ac.code as avatar_code,
    ac.name_ko as avatar_name_ko,
    ac.description,
    ac.rarity,
    (ua.id is not null) as is_unlocked,
    coalesce(ua.is_equipped, false) as is_equipped,
    coalesce(ua.level, 0)::smallint as level,
    coalesce(ua.xp, 0) as xp,
    coalesce(alr.title_ko, '잠김')::varchar(32) as level_title_ko,
    coalesce(alr.required_total_xp, 0) as current_level_xp,
    coalesce(next_rule.required_total_xp, alr.required_total_xp, 0) as next_level_xp,
    v_total_xp as total_collection_xp,
    v_total_level as total_collection_level
  from public.avatar_catalog ac
  left join public.user_avatars ua
    on ua.avatar_id = ac.id
   and ua.user_id = v_user_id
  left join public.avatar_level_rules alr
    on alr.level = ua.level
  left join public.avatar_level_rules next_rule
    on next_rule.level = ua.level + 1
  where ac.is_active = true
  order by ac.sort_order asc, ac.id asc;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.equip_avatar(
  p_user_avatar_id uuid
)
returns table (
  user_avatar_id uuid,
  avatar_code varchar(32),
  avatar_name_ko varchar(32),
  level smallint,
  xp int
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

  if p_user_avatar_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  perform public.ensure_starter_avatars(v_user_id);

  if not exists (
    select 1
    from public.user_avatars ua
    where ua.id = p_user_avatar_id
      and ua.user_id = v_user_id
  ) then
    perform public.raise_app_error('AVATAR_NOT_OWNED');
  end if;

  update public.user_avatars
  set is_equipped = false,
      updated_at = now()
  where user_id = v_user_id
    and is_equipped = true;

  update public.user_avatars
  set is_equipped = true,
      updated_at = now()
  where id = p_user_avatar_id
    and user_id = v_user_id;

  return query
  select
    ua.id as user_avatar_id,
    ac.code as avatar_code,
    ac.name_ko as avatar_name_ko,
    ua.level,
    ua.xp
  from public.user_avatars ua
  join public.avatar_catalog ac on ac.id = ua.avatar_id
  where ua.id = p_user_avatar_id
    and ua.user_id = v_user_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

create or replace function public.update_my_nickname(
  p_nickname text
)
returns table (
  nickname varchar(24)
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_nickname text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  v_nickname := nullif(btrim(coalesce(p_nickname, '')), '');

  if v_nickname is null or length(v_nickname) < 2 or length(v_nickname) > 24 then
    perform public.raise_app_error('INVALID_NICKNAME');
  end if;

  if v_nickname ~ '[[:space:]]' then
    perform public.raise_app_error('INVALID_NICKNAME');
  end if;

  begin
    update public.profiles
    set nickname = v_nickname::varchar(24),
        updated_at = now()
    where id = v_user_id
      and is_active = true;
  exception
    when unique_violation then
      perform public.raise_app_error('NICKNAME_ALREADY_EXISTS');
  end;

  if not found then
    perform public.raise_app_error('PROFILE_NOT_FOUND');
  end if;

  return query select v_nickname::varchar(24) as nickname;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

revoke execute on function public.ensure_starter_avatars(uuid) from public, anon, authenticated;

grant execute on function public.get_avatar_collection() to authenticated;
grant execute on function public.equip_avatar(uuid) to authenticated;
grant execute on function public.update_my_nickname(text) to authenticated;
