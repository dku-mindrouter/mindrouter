insert into public.emotion_tags (id, name_ko, group_name, priority, is_active)
values
  (1, '공허함', 'low_energy', 100, true),
  (2, '지침', 'low_energy', 90, true),
  (3, '무기력', 'low_energy', 80, true),
  (4, '외로움', 'loneliness', 70, true),
  (5, '번아웃', 'burnout', 60, true),
  (6, '불안', 'anxiety', 50, true),
  (7, '답답함', 'anxiety', 40, true),
  (8, '잔잔함', 'calm_recovery', 30, true),
  (9, '안도', 'calm_recovery', 20, true),
  (10, '위로받고 싶음', 'support_need', 10, true)
on conflict (id) do update
set
  name_ko = excluded.name_ko,
  group_name = excluded.group_name,
  priority = excluded.priority,
  is_active = excluded.is_active;

select setval(
  pg_get_serial_sequence('public.emotion_tags', 'id'),
  (select coalesce(max(id), 1) from public.emotion_tags),
  true
);

insert into public.reaction_types (id, code, label_ko, icon, is_active)
values
  (1, 'WARM_TEA', '따뜻한 차', 'tea', true),
  (5, 'WARM_COFFEE', '커피 보내기', 'coffee', true),
  (2, 'HUG', '안아드려요', 'hug', true),
  (3, 'YOU_DID_WELL', '고생했어요', 'clover', true),
  (4, 'WITH_YOU', '함께해요', 'stars', true),
  (6, 'LETTER', '편지 보내기', 'letter', true)
on conflict (id) do update
set
  code = excluded.code,
  label_ko = excluded.label_ko,
  icon = excluded.icon,
  is_active = excluded.is_active;

select setval(
  pg_get_serial_sequence('public.reaction_types', 'id'),
  (select coalesce(max(id), 1) from public.reaction_types),
  true
);
