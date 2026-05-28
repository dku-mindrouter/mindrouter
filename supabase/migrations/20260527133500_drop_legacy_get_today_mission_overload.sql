drop function if exists public.get_today_mission(boolean);

grant execute on function public.get_today_mission(boolean, varchar) to authenticated;

notify pgrst, 'reload schema';
