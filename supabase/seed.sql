insert into public.emotion_tags (name_ko, group_name, priority)
values
  ('공허함', 'low_energy', 1),
  ('지침', 'low_energy', 2),
  ('무기력', 'low_energy', 3),
  ('잔잔함', 'recovery', 4),
  ('안도', 'recovery', 5),
  ('불안', 'anxious', 6),
  ('외로움', 'isolation', 7),
  ('답답함', 'anxious', 8),
  ('번아웃', 'low_energy', 9),
  ('위로받고 싶음', 'isolation', 10),
  ('초조함', 'anxious', 11),
  ('가벼움', 'recovery', 12)
on conflict (name_ko) do nothing;

insert into public.reaction_types (code, label_ko, icon)
values
  ('tea', '따뜻한 차', '☕'),
  ('hug', '안아드려요', '🫂'),
  ('thanks', '고생했어요', '✨'),
  ('together', '함께해요', '🌙')
on conflict (code) do nothing;

insert into public.nudges (id, user_id, type, title, body, created_at)
select
  gen_random_uuid(),
  id,
  'template',
  '오늘의 심리 스니펫',
  body,
  now()
from public.profiles p
cross join (
  values
    ('공허한 날에는 해야 할 일을 줄이는 것도 회복의 방식이 될 수 있어요.'),
    ('지친 날에는 회복의 단위를 작게 잡아도 괜찮아요.'),
    ('불안이 큰 밤엔 지금 안전한 곳에 있는지 먼저 확인해 보세요.'),
    ('외로움이 올라오는 날엔 연결의 강도보다 빈도를 낮게 유지해도 괜찮아요.'),
    ('잔잔한 감정도 충분히 기록할 가치가 있어요.'),
    ('오늘의 감정은 고쳐야 할 문제가 아니라 알아차릴 신호일 수 있어요.'),
    ('한 번의 리액션도 누군가의 밤을 덜 차갑게 만들 수 있어요.'),
    ('오늘 별을 남겼다면 이미 마음을 돌보는 행동을 시작한 거예요.'),
    ('짧은 문장으로도 오늘의 마음을 충분히 기록할 수 있어요.'),
    ('새벽의 감정은 더 크게 느껴질 수 있으니 속도를 조금 낮춰 보세요.'),
    ('저녁의 불안은 낮의 피로가 겹친 신호일 수 있어요.'),
    ('안도감이 들었던 순간도 내 기록으로 남겨 보세요.'),
    ('답답함이 오래 가면 환경을 조금 바꾸는 것도 도움이 될 수 있어요.'),
    ('무기력한 날에는 시작 기준을 아주 작게 잡아 보세요.'),
    ('번아웃 신호가 보이면 회복 계획도 일정처럼 다뤄 보세요.'),
    ('위로받고 싶은 마음을 알아차린 것만으로도 충분한 시작이에요.'),
    ('초조한 날엔 결과보다 다음 한 걸음만 확인해 보세요.'),
    ('가벼운 날의 기록도 다음 회복의 단서가 될 수 있어요.'),
    ('반응이 많지 않아도 기록은 사라지지 않아요.'),
    ('오늘의 별은 비교가 아니라 흔적을 남기는 데 의미가 있어요.')
) as templates(body);

