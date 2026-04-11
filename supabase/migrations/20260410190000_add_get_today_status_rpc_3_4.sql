create or replace function public.get_today_status()
returns table (
  date_local date,
  has_star_today boolean,
  today_star_id uuid,
  is_star_public_today boolean,
  is_star_expired_today boolean,
  reaction_sent_count int,
  reaction_daily_limit int,
  reaction_remaining_count int
)
language plpgsql
as $$
declare
  v_user_id uuid;
  v_timezone varchar(64);
  v_is_active boolean;
  v_date_local date;
  v_today_star_id uuid;
  v_today_visibility_status varchar(16);
  v_today_expires_at timestamptz;
  v_reaction_sent_count int;
  v_reaction_daily_limit int := 20;
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
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  if v_is_active is false then
    perform public.raise_app_error('FORBIDDEN');
  end if;

  v_date_local := (now() at time zone v_timezone)::date;

  select s.id, s.visibility_status, s.expires_at
  into v_today_star_id, v_today_visibility_status, v_today_expires_at
  from public.stars s
  where s.user_id = v_user_id
    and s.created_local_date = v_date_local
    and s.is_deleted = false
  order by s.created_at desc
  limit 1;

  v_reaction_sent_count := 0;
  select dl.reaction_sent_count
  into v_reaction_sent_count
  from public.daily_logs dl
  where dl.user_id = v_user_id
    and dl.date = v_date_local;

  v_reaction_sent_count := coalesce(v_reaction_sent_count, 0);

  return query
  select
    v_date_local as date_local,
    (v_today_star_id is not null) as has_star_today,
    v_today_star_id as today_star_id,
    (v_today_star_id is not null and v_today_visibility_status = 'public') as is_star_public_today,
    (v_today_star_id is not null and v_today_expires_at is not null and v_today_expires_at <= now()) as is_star_expired_today,
    v_reaction_sent_count as reaction_sent_count,
    v_reaction_daily_limit as reaction_daily_limit,
    greatest(v_reaction_daily_limit - v_reaction_sent_count, 0) as reaction_remaining_count;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;
