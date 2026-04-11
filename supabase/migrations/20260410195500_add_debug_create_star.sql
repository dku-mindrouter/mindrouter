create or replace function public.debug_create_star(
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
    raise exception 'DBG_UNAUTHORIZED';
  end if;

  select p.timezone
  into v_timezone
  from public.profiles p
  where p.id = v_user_id and p.is_active = true;

  if v_timezone is null then
    raise exception 'DBG_NO_TIMEZONE';
  end if;

  if p_content is null or btrim(p_content) = '' or length(p_content) > 80 then
    raise exception 'DBG_BAD_CONTENT';
  end if;

  if p_time_bucket is null or p_time_bucket not in ('dawn', 'morning', 'day', 'evening', 'night') then
    raise exception 'DBG_BAD_BUCKET';
  end if;

  if p_emotion_intensity is not null and (p_emotion_intensity < 1 or p_emotion_intensity > 5) then
    raise exception 'DBG_BAD_INTENSITY';
  end if;

  if p_visibility_status is null or btrim(p_visibility_status) = '' or length(p_visibility_status) > 16 then
    raise exception 'DBG_BAD_VIS';
  end if;

  if p_tag_ids is null or coalesce(array_length(p_tag_ids, 1), 0) = 0 then
    raise exception 'DBG_NO_TAGS';
  end if;

  select count(distinct t.id)
  into v_valid_tag_count
  from public.emotion_tags t
  where t.id = any (p_tag_ids) and t.is_active = true;

  if v_valid_tag_count <> (select count(distinct x) from unnest(p_tag_ids) as x) then
    raise exception 'DBG_BAD_TAGS:%:%', v_valid_tag_count, (select count(distinct x) from unnest(p_tag_ids) as x);
  end if;

  v_local_ts := now() at time zone v_timezone;
  v_local_date := v_local_ts::date;

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
  returning id, created_at into v_star_id, v_created_at;

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
  select v_star_id, v_created_at, v_local_date;
end;
$$;
