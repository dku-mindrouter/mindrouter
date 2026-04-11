-- RPC 실행에 필요한 authenticated 권한 정합화

grant usage on schema public to authenticated;

grant select on table public.profiles to authenticated;
grant select, insert, update on table public.stars to authenticated;
grant select, insert on table public.star_emotion_maps to authenticated;
grant select on table public.emotion_tags to authenticated;
grant select on table public.blocks to authenticated;

grant select on table public.reaction_types to authenticated;
grant select, insert on table public.reactions to authenticated;
grant select, insert, update on table public.daily_logs to authenticated;

grant usage, select on all sequences in schema public to authenticated;
