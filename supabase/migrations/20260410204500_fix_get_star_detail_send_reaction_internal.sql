-- get_star_detail/send_reaction INTERNAL_ERROR 수정

create or replace function public.get_star_detail(
  p_star_id uuid
)
returns table (
  star_id uuid,
  user_id uuid,
  content varchar(80),
  tag_ids bigint[],
  tag_names text[],
  time_bucket varchar(16),
  reaction_count int,
  created_at timestamptz,
  expires_at timestamptz,
  visibility_status varchar(16),
  is_deleted boolean,
  is_expired boolean,
  is_reactable boolean
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_owner_user_id uuid;
  v_is_owner boolean;
  v_is_blocked boolean;
  v_is_expired boolean;
  v_is_visible_to_others boolean;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if p_star_id is null then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select s.user_id
  into v_owner_user_id
  from public.stars s
  where s.id = p_star_id;

  if v_owner_user_id is null then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  v_is_owner := (v_owner_user_id = v_user_id);

  select exists (
    select 1
    from public.blocks b
    where
      (b.blocker_user_id = v_user_id and b.blocked_user_id = v_owner_user_id)
      or (b.blocker_user_id = v_owner_user_id and b.blocked_user_id = v_user_id)
  )
  into v_is_blocked;

  if v_is_blocked then
    perform public.raise_app_error('BLOCKED_RELATIONSHIP');
  end if;

  select (s.expires_at is not null and s.expires_at <= now())
  into v_is_expired
  from public.stars s
  where s.id = p_star_id;

  select (
    s.is_deleted = false
    and s.visibility_status = 'public'
    and (s.expires_at is null or s.expires_at > now())
  )
  into v_is_visible_to_others
  from public.stars s
  where s.id = p_star_id;

  if not v_is_owner and not v_is_visible_to_others then
    perform public.raise_app_error('STAR_NOT_FOUND');
  end if;

  return query
  select
    s.id as star_id,
    s.user_id,
    s.content,
    coalesce(array_agg(sem.tag_id order by sem.tag_id) filter (where sem.tag_id is not null), '{}'::bigint[]) as tag_ids,
    coalesce(array_agg(et.name_ko::text order by sem.tag_id) filter (where et.name_ko is not null), '{}'::text[]) as tag_names,
    s.time_bucket,
    s.reaction_count,
    s.created_at,
    s.expires_at,
    s.visibility_status,
    s.is_deleted,
    v_is_expired as is_expired,
    (
      not v_is_owner
      and not s.is_deleted
      and s.visibility_status = 'public'
      and (s.expires_at is null or s.expires_at > now())
    ) as is_reactable
  from public.stars s
  left join public.star_emotion_maps sem on sem.star_id = s.id
  left join public.emotion_tags et on et.id = sem.tag_id
  where s.id = p_star_id
  group by s.id;
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

drop function if exists public.debug_get_star_detail(uuid);
drop function if exists public.debug_send_reaction(uuid, bigint);
