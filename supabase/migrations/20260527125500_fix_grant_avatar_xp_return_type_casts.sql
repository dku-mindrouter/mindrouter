create or replace function public.grant_avatar_xp(
  p_user_id uuid,
  p_event_type varchar,
  p_xp_amount int,
  p_source_id text,
  p_local_date date default null
)
returns table (
  user_avatar_id uuid,
  avatar_code varchar,
  avatar_name_ko varchar,
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
  on conflict on constraint avatar_xp_events_unique_source do nothing
  returning id into v_event_id;

  if v_event_id is not null then
    select ua.xp
    into v_previous_xp
    from public.user_avatars ua
    where ua.id = v_user_avatar_id
    for update;

    v_new_xp := least(
      coalesce(v_previous_xp, 0) + p_xp_amount,
      coalesce(v_max_xp, 2300)
    );

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
    ac.code::varchar as avatar_code,
    ac.name_ko::varchar as avatar_name_ko,
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

revoke execute on function public.grant_avatar_xp(uuid, varchar, int, text, date) from public, anon, authenticated;
