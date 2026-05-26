insert into public.emotion_tags (id, name_ko, group_name, priority, is_active)
values
  (1, '불안함', 'anxious', 100, true),
  (2, '우울함', 'negative', 90, true),
  (3, '지침/무기력', 'negative', 80, true),
  (4, '예민함/짜증', 'negative', 70, true),
  (5, '평온함', 'calm', 60, true),
  (6, '기대감/활력', 'positive', 50, true),
  (7, '공허함', 'legacy', 40, false),
  (8, '외로움', 'legacy', 30, false),
  (9, '번아웃', 'legacy', 20, false),
  (10, '위로받고 싶음', 'legacy', 10, false),
  (11, '행복함', 'happy', 55, true)
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

insert into public.nudge_templates (
  type,
  title,
  body,
  is_active,
  category,
  subtitle,
  duration_minutes,
  checklist_json,
  cta_label,
  accent_icon,
  accent_start_color,
  accent_end_color
)
select
  x.type,
  x.title,
  x.body,
  true,
  'mission',
  x.subtitle,
  x.duration_minutes,
  x.checklist_json,
  '미션 시작하기',
  x.accent_icon,
  x.accent_start_color,
  x.accent_end_color
from (
  values
    (
      'mission_walk',
      '햇살과 함께 10분 걷기',
      '생각을 정리하려고 애쓰기보다 먼저 몸의 리듬을 조금 바꿔보세요.',
      '무거운 기분일수록 가볍게 움직이는 것만으로도 시작이 될 수 있어요.',
      10::smallint,
      '["편한 신발을 신고 밖으로 나가기","좋아하는 음악과 함께 10분 걷기","하늘이나 나무를 한 번 천천히 바라보기"]'::jsonb,
      'wb_sunny_outlined',
      'amber',
      'orange'
    ),
    (
      'mission_grounding',
      '호흡에 집중하는 8분',
      '들숨과 날숨을 세면서 호흡의 길이를 일정하게 맞춰보세요.',
      '불안하고 예민할수록 지금 이 순간의 감각으로 돌아오는 연습이 필요해요.',
      8::smallint,
      '["편하게 기대기 좋은 자리를 찾기","4번 들이마시고 4번 내쉬는 호흡 10회 하기","마지막에 어깨와 턱에 힘이 빠졌는지 확인하기"]'::jsonb,
      'air',
      'sky',
      'violet'
    ),
    (
      'mission_hydration',
      '물 한 잔과 창밖 바라보기',
      '작은 수분 보충과 시선 전환만으로도 마음의 결이 조금 달라질 수 있어요.',
      '체온을 천천히 올리고 시야를 트는 몸의 기본 리듬을 챙기는 것이 좋아요.',
      5::smallint,
      '["물 한 잔을 천천히 마시기","창밖이나 먼 곳을 1분 이상 바라보기","지금 몸이 가장 편안한 자세를 찾아보기"]'::jsonb,
      'water_drop_outlined',
      'sky',
      'indigo'
    )
) as x(
  type,
  title,
  body,
  subtitle,
  duration_minutes,
  checklist_json,
  accent_icon,
  accent_start_color,
  accent_end_color
)
where not exists (
  select 1
  from public.nudge_templates nt
  where nt.type = x.type
);
