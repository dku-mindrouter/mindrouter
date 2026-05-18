create or replace function public.get_my_stats()
returns table (
  date_local date,
  logged_dates date[],
  today_received_comfort_count int
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
    coalesce(v_today_received_comfort_count, 0) as today_received_comfort_count;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

grant execute on function public.get_my_stats() to authenticated;
