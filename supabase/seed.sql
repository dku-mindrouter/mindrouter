insert into public.emotion_tags (id, name_ko, group_name, priority, is_active)
values
  (1, '불안함', 'anxious', 100, true),
  (2, '우울함', 'negative', 90, true),
  (3, '지침/무기력', 'negative', 80, true),
  (4, '예민함/짜증', 'negative', 70, true),
  (5, '평온함/잔잔함', 'calm', 60, true),
  (6, '기대감/활력', 'positive', 50, true),
  (7, '공허함', 'legacy', 40, false),
  (8, '외로움', 'legacy', 30, false),
  (9, '번아웃', 'legacy', 20, false),
  (10, '위로받고 싶음', 'legacy', 10, false)
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
