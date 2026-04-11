-- RPC를 SECURITY DEFINER로 고정해 호출자 권한/RLS 편차 제거

alter function public.create_star(text, bigint[], text, smallint, text, timestamptz) security definer;
alter function public.get_constellation_feed(text, int, int) security definer;
alter function public.send_reaction(uuid, bigint) security definer;
alter function public.get_star_detail(uuid) security definer;
alter function public.get_today_status() security definer;

grant execute on function public.create_star(text, bigint[], text, smallint, text, timestamptz) to authenticated;
grant execute on function public.get_constellation_feed(text, int, int) to authenticated;
grant execute on function public.send_reaction(uuid, bigint) to authenticated;
grant execute on function public.get_star_detail(uuid) to authenticated;
grant execute on function public.get_today_status() to authenticated;
