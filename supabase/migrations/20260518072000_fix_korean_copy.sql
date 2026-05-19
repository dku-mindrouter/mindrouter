update public.emotion_tags
set
  name_ko = case id
    when 1 then '불안함'
    when 2 then '우울함'
    when 3 then '지침/무기력'
    when 4 then '예민함/짜증'
    when 5 then '평온함/잔잔함'
    when 6 then '기대감/활력'
    when 7 then '공허함'
    when 8 then '외로움'
    when 9 then '번아웃'
    when 10 then '위로받고 싶음'
    else name_ko
  end
where id between 1 and 10;

update public.reaction_types
set
  label_ko = case code
    when 'WARM_TEA' then '따뜻한 차'
    when 'WARM_COFFEE' then '커피 보내기'
    when 'HUG' then '안아드려요'
    when 'YOU_DID_WELL' then '고생했어요'
    when 'WITH_YOU' then '함께해요'
    when 'LETTER' then '편지 보내기'
    else label_ko
  end
where code in ('WARM_TEA', 'WARM_COFFEE', 'HUG', 'YOU_DID_WELL', 'WITH_YOU', 'LETTER');

update public.nudge_templates
set
  title = case type
    when 'mission_walk' then '햇살과 함께 10분 걷기'
    when 'mission_grounding' then '호흡에 집중하는 8분'
    when 'mission_hydration' then '물 한 잔과 창밖 바라보기'
    else title
  end,
  body = case type
    when 'mission_walk' then '생각을 정리하려고 애쓰기보다 먼저 몸의 리듬을 조금 바꿔보세요.'
    when 'mission_grounding' then '들숨과 날숨을 세면서 호흡의 길이를 일정하게 맞춰보세요.'
    when 'mission_hydration' then '작은 수분 보충과 시선 전환만으로도 마음의 결이 조금 달라질 수 있어요.'
    else body
  end,
  subtitle = case type
    when 'mission_walk' then '무거운 기분일수록 가볍게 움직이는 것만으로도 시작이 될 수 있어요.'
    when 'mission_grounding' then '불안하고 예민할수록 지금 이 순간의 감각으로 돌아오는 연습이 필요해요.'
    when 'mission_hydration' then '체온을 천천히 올리고 시야를 트는 몸의 기본 리듬을 챙기는 것이 좋아요.'
    else subtitle
  end,
  checklist_json = case type
    when 'mission_walk' then '["편한 신발을 신고 밖으로 나가기","좋아하는 음악과 함께 10분 걷기","하늘이나 나무를 한 번 천천히 바라보기"]'::jsonb
    when 'mission_grounding' then '["편하게 기대기 좋은 자리를 찾기","4번 들이마시고 4번 내쉬는 호흡 10회 하기","마지막에 어깨와 턱에 힘이 빠졌는지 확인하기"]'::jsonb
    when 'mission_hydration' then '["물 한 잔을 천천히 마시기","창밖이나 먼 곳을 1분 이상 바라보기","지금 몸이 가장 편안한 자세를 찾아보기"]'::jsonb
    else checklist_json
  end,
  cta_label = '미션 시작하기'
where category = 'mission';

create or replace function public.get_comfort_notifications(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  notification_id uuid,
  notification_type varchar(16),
  title text,
  body text,
  event_at timestamptz,
  icon varchar(32),
  accent_color varchar(16),
  is_opened boolean
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid;
  v_limit int;
  v_offset int;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    perform public.raise_app_error('UNAUTHORIZED');
  end if;

  v_limit := greatest(least(coalesce(p_limit, 30), 50), 1);
  v_offset := greatest(coalesce(p_offset, 0), 0);

  return query
  with reaction_notifications as (
    select
      r.id as notification_id,
      'reaction'::varchar(16) as notification_type,
      '새로운 위로가 도착했어요'::text as title,
      format('"%s" 별에 ''%s'' 리액션이 도착했어요.', s.content, rt.label_ko)::text as body,
      r.created_at as event_at,
      coalesce(rt.icon, 'favorite')::varchar(32) as icon,
      case rt.code
        when 'WARM_TEA' then 'amber'
        when 'WARM_COFFEE' then 'coffee'
        when 'HUG' then 'rose'
        when 'YOU_DID_WELL' then 'violet'
        when 'WITH_YOU' then 'sky'
        when 'LETTER' then 'indigo'
        else 'indigo'
      end::varchar(16) as accent_color,
      true as is_opened
    from public.reactions r
    join public.stars s on s.id = r.star_id
    join public.reaction_types rt on rt.id = r.reaction_type_id
    where s.user_id = v_user_id
      and s.is_deleted = false
  ),
  nudge_notifications as (
    select
      nd.id as notification_id,
      'nudge'::varchar(16) as notification_type,
      nt.title::text as title,
      nt.body::text as body,
      nd.delivered_at as event_at,
      'auto_awesome'::varchar(32) as icon,
      'violet'::varchar(16) as accent_color,
      (nd.opened_at is not null) as is_opened
    from public.nudge_deliveries nd
    join public.nudge_templates nt on nt.id = nd.template_id
    where nd.user_id = v_user_id
      and coalesce(nt.category, 'comfort') = 'comfort'
  ),
  combined as (
    select * from reaction_notifications
    union all
    select * from nudge_notifications
  )
  select
    c.notification_id,
    c.notification_type,
    c.title,
    c.body,
    c.event_at,
    c.icon,
    c.accent_color,
    c.is_opened
  from combined c
  order by c.event_at desc
  limit v_limit
  offset v_offset;
exception
  when insufficient_privilege then
    perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then
    raise;
  when others then
    perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

grant execute on function public.get_comfort_notifications(int, int) to authenticated;
