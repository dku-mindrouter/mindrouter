-- create_star/send_reaction OUT 파라미터 이름 충돌(ambiguous created_at) 수정

drop function if exists public.debug_create_star(text, bigint[], text, smallint, text, timestamptz);

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
as $$
declare
  v_user_id uuid;
  v_timezone varchar(64);
  v_local_ts timestamp;
  v_local_date date;
  v_star_id uuid;
  v_created_at timestamptz;
  v_valid_tag_count int;
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
