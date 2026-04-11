-- 인증 사용자의 참조 데이터 조회 정책(3단계 스모크 및 런타임 정합화)

alter table public.emotion_tags enable row level security;
alter table public.reaction_types enable row level security;

drop policy if exists emotion_tags_select_active on public.emotion_tags;
create policy emotion_tags_select_active
on public.emotion_tags
for select
to authenticated
using (is_active = true);

drop policy if exists reaction_types_select_active on public.reaction_types;
create policy reaction_types_select_active
on public.reaction_types
for select
to authenticated
using (is_active = true);
