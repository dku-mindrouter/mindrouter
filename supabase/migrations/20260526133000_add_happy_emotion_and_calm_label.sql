insert into public.emotion_tags (id, name_ko, group_name, priority, is_active)
values
  (5, '평온함', 'calm', 60, true),
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
  accent_end_color,
  mission_profile_key,
  mission_goal,
  mission_state_label,
  is_random_eligible,
  selection_weight,
  sort_order
)
select
  x.type,
  x.title,
  x.body,
  true,
  'mission',
  x.subtitle,
  x.duration_minutes,
  '[]'::jsonb,
  '미션 시작하기',
  x.accent_icon,
  x.accent_start_color,
  x.accent_end_color,
  'happy',
  '행복한 감각을 충분히 느끼기',
  '좋은 기분이 올라옴',
  true,
  1::smallint,
  x.sort_order
from (
  values
    ('mission_happy_music', '좋아하는 노래 한 곡을 들으며 기분을 충분히 느끼기', '좋은 기분을 빠르게 넘기지 말고, 지금의 행복한 감각을 충분히 느껴보세요.', '지금의 행복을 조금 더 오래 머물게 하는 미션이에요.', 5::smallint, 'music_note_rounded', 'amber', 'orange', 10::smallint),
    ('mission_happy_reason', '지금 행복한 이유를 짧게 한 줄로 남기기', '행복한 이유를 한 줄로 남기면 오늘의 좋은 감각을 나중에도 다시 꺼내볼 수 있어요.', '지금 좋은 이유를 짧게 붙잡아 보세요.', 3::smallint, 'edit_note_rounded', 'amber', 'orange', 11::smallint),
    ('mission_happy_good_word', '가까운 사람에게 좋은 말 한마디 전하기', '좋은 기분은 나눌 때 더 선명해질 수 있어요. 부담 없는 한마디만 전해보세요.', '가벼운 좋은 말로 행복을 나눠보세요.', 3::smallint, 'chat_bubble_outline_rounded', 'orange', 'amber', 12::smallint)
) as x(type, title, body, subtitle, duration_minutes, accent_icon, accent_start_color, accent_end_color, sort_order)
on conflict (type) do update set
  title = excluded.title,
  body = excluded.body,
  is_active = true,
  category = 'mission',
  subtitle = excluded.subtitle,
  duration_minutes = excluded.duration_minutes,
  checklist_json = '[]'::jsonb,
  cta_label = excluded.cta_label,
  accent_icon = excluded.accent_icon,
  accent_start_color = excluded.accent_start_color,
  accent_end_color = excluded.accent_end_color,
  mission_profile_key = 'happy',
  mission_goal = '행복한 감각을 충분히 느끼기',
  mission_state_label = '좋은 기분이 올라옴',
  is_random_eligible = true,
  selection_weight = 1,
  sort_order = excluded.sort_order;
