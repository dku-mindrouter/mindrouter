drop function if exists public.get_star_detail(uuid);

create function public.get_star_detail(
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
  is_reactable boolean,
  my_reaction_type_id bigint
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
      and viewer_reaction.reaction_type_id is null
    ) as is_reactable,
    viewer_reaction.reaction_type_id as my_reaction_type_id
  from public.stars s
  left join public.star_emotion_maps sem on sem.star_id = s.id
  left join public.emotion_tags et on et.id = sem.tag_id
  left join lateral (
    select r.reaction_type_id
    from public.reactions r
    where r.star_id = s.id
      and r.sender_user_id = v_user_id
    limit 1
  ) viewer_reaction on true
  where s.id = p_star_id
  group by s.id, viewer_reaction.reaction_type_id;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;
