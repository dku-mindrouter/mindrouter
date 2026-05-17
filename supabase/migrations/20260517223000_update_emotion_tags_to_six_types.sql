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
