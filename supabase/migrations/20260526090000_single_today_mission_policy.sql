alter table public.nudge_templates
  add column if not exists mission_profile_key varchar(24),
  add column if not exists mission_goal varchar(80),
  add column if not exists mission_state_label varchar(80),
  add column if not exists is_random_eligible boolean not null default true,
  add column if not exists selection_weight smallint not null default 1,
  add column if not exists sort_order smallint not null default 100;

alter table public.nudge_deliveries
  add column if not exists delivery_category varchar(16) not null default 'comfort',
  add column if not exists selection_source varchar(16),
  add column if not exists matched_mission_profile varchar(24);

create unique index if not exists uq_nudge_templates_type
on public.nudge_templates (type);

create unique index if not exists uq_nudge_deliveries_user_local_date_mission
on public.nudge_deliveries (user_id, delivery_local_date, delivery_category)
where delivery_category = 'mission';

update public.nudge_templates
set is_active = false,
    is_random_eligible = false
where category = 'mission';

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
  x.mission_profile_key,
  x.mission_goal,
  x.mission_state_label,
  true,
  1::smallint,
  x.sort_order
from (
  values
    ('mission_happy_music', '좋아하는 노래 한 곡을 들으며 기분을 충분히 느끼기', '좋은 기분을 빠르게 넘기지 말고, 지금의 행복한 감각을 충분히 느껴보세요.', '지금의 행복을 조금 더 오래 머물게 하는 미션이에요.', 5::smallint, 'music_note_rounded', 'amber', 'orange', 'happy', '행복한 감각을 충분히 느끼기', '좋은 기분이 올라옴', 10::smallint),
    ('mission_happy_reason', '지금 행복한 이유를 짧게 한 줄로 남기기', '행복한 이유를 한 줄로 남기면 오늘의 좋은 감각을 나중에도 다시 꺼내볼 수 있어요.', '지금 좋은 이유를 짧게 붙잡아 보세요.', 3::smallint, 'edit_note_rounded', 'amber', 'orange', 'happy', '행복한 감각을 충분히 느끼기', '좋은 기분이 올라옴', 11::smallint),
    ('mission_happy_good_word', '가까운 사람에게 좋은 말 한마디 전하기', '좋은 기분은 나눌 때 더 선명해질 수 있어요. 부담 없는 한마디만 전해보세요.', '가벼운 좋은 말로 행복을 나눠보세요.', 3::smallint, 'chat_bubble_outline_rounded', 'orange', 'amber', 'happy', '행복한 감각을 충분히 느끼기', '좋은 기분이 올라옴', 12::smallint),
    ('mission_energized_walk_5', '5분 동안 가볍게 걷거나 몸을 흔들기', '에너지가 있을 때는 크게 몰아쓰지 말고, 몸이 기분 좋게 풀리는 정도로만 움직여 보세요.', '움직일 힘이 있는 지금, 몸을 가볍게 풀어보세요.', 5::smallint, 'directions_walk_rounded', 'amber', 'orange', 'energized', '에너지를 가볍게 풀어주기', '움직일 힘이 있음', 20::smallint),
    ('mission_energized_small_task', '지금 바로 끝낼 수 있는 작은 일 하나 처리하기', '활력이 있을 때는 작은 완료감을 하나 만드는 것이 에너지를 가볍게 쓰는 데 도움이 됩니다.', '바로 끝낼 수 있는 한 가지만 처리해보세요.', 5::smallint, 'task_alt_rounded', 'orange', 'amber', 'energized', '에너지를 가볍게 풀어주기', '움직일 힘이 있음', 21::smallint),
    ('mission_energized_music_breath', '좋아하는 노래 한 곡을 들으며 호흡 맞추기', '좋아하는 노래에 맞춰 숨을 고르면 활력을 부드럽게 정리할 수 있어요.', '노래 한 곡과 호흡의 속도를 맞춰보세요.', 5::smallint, 'music_note_rounded', 'orange', 'amber', 'energized', '에너지를 가볍게 풀어주기', '움직일 힘이 있음', 22::smallint),
    ('mission_calm_warm_tea', '따뜻한 물이나 차를 천천히 마시기', '평온한 상태는 크게 흔들지 않고 오래 유지하는 것이 좋습니다.', '지금의 잔잔함을 몸의 속도와 함께 유지해보세요.', 5::smallint, 'local_cafe_outlined', 'sky', 'indigo', 'calm', '안정된 감각을 오래 유지하기', '천천히 숨 고르는 중', 30::smallint),
    ('mission_calm_three_good', '지금 괜찮은 것 3가지를 조용히 떠올리기', '괜찮은 것들을 조용히 떠올리면 지금의 안정감을 조금 더 오래 붙잡을 수 있어요.', '괜찮은 감각 세 가지를 천천히 떠올려보세요.', 3::smallint, 'self_improvement', 'indigo', 'sky', 'calm', '안정된 감각을 오래 유지하기', '천천히 숨 고르는 중', 31::smallint),
    ('mission_calm_view_1min', '창밖이나 주변 풍경을 1분 동안 바라보기', '잔잔한 기분일 때는 주변을 천천히 바라보는 것만으로도 안정감이 이어질 수 있습니다.', '시선을 천천히 두며 숨을 골라보세요.', 3::smallint, 'landscape_outlined', 'indigo', 'sky', 'calm', '안정된 감각을 오래 유지하기', '천천히 숨 고르는 중', 32::smallint),
    ('mission_depressed_water_stand', '물 한 컵 마시고 몸을 조금 일으키기', '가라앉을 때는 억지로 밝아지려 하기보다 몸을 아주 조금 움직이는 쪽이 더 현실적입니다.', '작게라도 떠오를 수 있게 몸을 한 번만 일으켜보세요.', 5::smallint, 'water_drop_outlined', 'sky', 'violet', 'depressed', '억지로 밝아지기보다, 아주 작게 떠오르기', '가라앉는 기분', 40::smallint),
    ('mission_depressed_light_3min', '햇빛이나 밝은 조명 가까이에 3분 있기', '우울한 상태에서는 생각을 바꾸기보다 빛과 자세 같은 환경 자극을 조금 조정하는 편이 부담이 적습니다.', '밝은 곳 가까이에 3분만 머물러보세요.', 3::smallint, 'wb_sunny_outlined', 'amber', 'violet', 'depressed', '억지로 밝아지기보다, 아주 작게 떠오르기', '가라앉는 기분', 41::smallint),
    ('mission_depressed_sentence', '오늘 버틴 나에게 짧은 한 문장 남기기', '오늘을 버틴 자신에게 짧은 문장을 남기면 아주 작은 회복의 실마리가 될 수 있어요.', '오늘 버틴 나에게 한 문장만 남겨보세요.', 3::smallint, 'edit_note_rounded', 'violet', 'sky', 'depressed', '억지로 밝아지기보다, 아주 작게 떠오르기', '가라앉는 기분', 42::smallint),
    ('mission_lethargic_shoulders', '누운 자리나 앉은 자리에서 어깨 힘 빼기', '무기력할 때는 더 움직이려 하기보다 지금 자세에서 힘을 덜 쓰는 행동이 더 맞을 수 있습니다.', '지금 자리에서 할 수 있는 가장 작은 행동이에요.', 3::smallint, 'self_improvement', 'indigo', 'sky', 'lethargic', '에너지 소모를 줄이고 최소 행동만 하기', '기운이 잘 안 남', 50::smallint),
    ('mission_lethargic_wash_hands', '세수하거나 손만 가볍게 씻기', '산책이나 운동처럼 큰 행동은 지금 상태에서 부담이 될 수 있습니다.', '손만 씻어도 충분한 작은 전환이 될 수 있어요.', 3::smallint, 'wash_rounded', 'sky', 'indigo', 'lethargic', '에너지 소모를 줄이고 최소 행동만 하기', '기운이 잘 안 남', 51::smallint),
    ('mission_lethargic_move_one', '주변 물건 하나만 제자리로 옮기기', '무기력할 때는 하나만 움직이는 정도가 가장 현실적인 시작일 수 있어요.', '주변 물건 하나만 제자리로 옮겨보세요.', 3::smallint, 'inventory_2_outlined', 'indigo', 'sky', 'lethargic', '에너지 소모를 줄이고 최소 행동만 하기', '기운이 잘 안 남', 52::smallint),
    ('mission_anxious_breathing', '4초 들이마시고 6초 내쉬는 호흡 5번 하기', '불안할 때는 생각을 멈추는 것보다 몸의 속도를 먼저 늦추는 편이 도움이 됩니다.', '호흡의 길이를 천천히 맞춰보세요.', 5::smallint, 'air', 'sky', 'violet', 'anxious', '생각보다 몸의 속도를 먼저 낮추기', '마음이 조급함', 60::smallint),
    ('mission_anxious_five_objects', '눈에 보이는 물건 5개를 천천히 말해보기', '조급한 마음이 커질수록 감각으로 돌아오는 행동이 더 직접적으로 도움이 됩니다.', '지금 보이는 것들을 천천히 확인해보세요.', 5::smallint, 'visibility_rounded', 'violet', 'indigo', 'anxious', '생각보다 몸의 속도를 먼저 낮추기', '마음이 조급함', 61::smallint),
    ('mission_anxious_write_worry', '걱정되는 일을 메모장에 한 줄로 적어두기', '걱정을 머릿속에만 두기보다 한 줄로 밖에 꺼내두면 조금 거리를 둘 수 있어요.', '걱정 하나를 짧게 적어두세요.', 3::smallint, 'edit_note_rounded', 'indigo', 'violet', 'anxious', '생각보다 몸의 속도를 먼저 낮추기', '마음이 조급함', 62::smallint),
    ('mission_irritated_mute', '알림을 잠시 끄고 조용한 곳으로 이동하기', '예민한 상태에서는 새로운 자극을 더 받지 않는 것이 먼저입니다.', '반응하기 전에 자극부터 조금 줄여보세요.', 5::smallint, 'notifications_off_outlined', 'rose', 'indigo', 'irritated', '자극을 줄이고 반응을 늦추기', '작은 일도 거슬림', 70::smallint),
    ('mission_irritated_tension', '턱, 어깨, 손에 들어간 힘을 천천히 풀기', '작은 일도 거슬릴 때는 몸에 들어간 힘부터 풀어 반응을 늦추는 편이 좋습니다.', '턱과 어깨와 손의 힘을 천천히 풀어보세요.', 3::smallint, 'self_improvement', 'indigo', 'rose', 'irritated', '자극을 줄이고 반응을 늦추기', '작은 일도 거슬림', 71::smallint),
    ('mission_irritated_delay_reply', '답장이나 반응을 10분 뒤로 미루기', '짜증이 올라와 있을 때는 바로 반응하지 않는 것만으로도 상황을 덜 키울 수 있습니다.', '바로 답하지 않아도 된다면 10분만 미뤄보세요.', 5::smallint, 'schedule_send_outlined', 'indigo', 'rose', 'irritated', '자극을 줄이고 반응을 늦추기', '작은 일도 거슬림', 72::smallint)
) as x(type, title, body, subtitle, duration_minutes, accent_icon, accent_start_color, accent_end_color, mission_profile_key, mission_goal, mission_state_label, sort_order)
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
  mission_profile_key = excluded.mission_profile_key,
  mission_goal = excluded.mission_goal,
  mission_state_label = excluded.mission_state_label,
  is_random_eligible = true,
  selection_weight = 1,
  sort_order = excluded.sort_order;

drop function if exists public.get_today_mission(boolean);
drop function if exists public.get_today_mission(boolean, varchar);

create or replace function public.get_today_mission(
  p_mark_opened boolean default false,
  p_selected_emotion_profile varchar(24) default null
)
returns table (
  delivery_id uuid,
  template_id bigint,
  mission_type varchar(32),
  title varchar(80),
  subtitle varchar(120),
  body varchar(240),
  duration_minutes smallint,
  checklist_json jsonb,
  cta_label varchar(32),
  accent_icon varchar(32),
  accent_start_color varchar(16),
  accent_end_color varchar(16),
  delivery_local_date date,
  opened_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  selection_source varchar(16),
  matched_mission_profile varchar(24),
  mission_goal varchar(80),
  mission_state_label varchar(80)
)
language plpgsql
security definer
as $$
declare
  v_user_id uuid := auth.uid();
  v_timezone varchar(64);
  v_is_active boolean;
  v_date_local date;
  v_delivery_id uuid;
  v_started_at timestamptz;
  v_completed_at timestamptz;
  v_existing_profile varchar(24);
  v_existing_active boolean;
  v_profile varchar(24) := nullif(trim(lower(coalesce(p_selected_emotion_profile, ''))), '');
  v_group varchar(32);
  v_template_id bigint;
  v_source varchar(16);
begin
  if v_user_id is null then perform public.raise_app_error('UNAUTHORIZED'); end if;

  select p.timezone, p.is_active into v_timezone, v_is_active
  from public.profiles p where p.id = v_user_id;
  if v_timezone is null then perform public.raise_app_error('UNAUTHORIZED'); end if;
  if v_is_active is false then perform public.raise_app_error('FORBIDDEN'); end if;

  v_date_local := (now() at time zone v_timezone)::date;

  if v_profile is null then
    select et.group_name into v_group
    from public.stars s
    join public.star_emotion_maps sem on sem.star_id = s.id
    join public.emotion_tags et on et.id = sem.tag_id
    where s.user_id = v_user_id
      and s.created_local_date = v_date_local
      and s.is_deleted = false
    order by s.created_at desc, et.priority desc, et.id asc
    limit 1;

    v_profile := case
      when v_group in ('happy','happiness','joy') then 'happy'
      when v_group in ('positive','energized','energy','active') then 'energized'
      when v_group in ('calm_recovery','calm') then 'calm'
      when v_group in ('depressed','sad') then 'depressed'
      when v_group in ('low_energy','burnout','negative') then 'lethargic'
      when v_group in ('anxious','anxiety','support_need') then 'anxious'
      when v_group in ('irritated','anger','sensitive') then 'irritated'
      else null
    end;
  end if;

  if v_profile is not null
    and v_profile not in ('happy','energized','calm','depressed','lethargic','anxious','irritated') then
    perform public.raise_app_error('INVALID_ARGUMENT');
  end if;

  select nd.id, nd.started_at, nd.completed_at, coalesce(nd.matched_mission_profile, nt.mission_profile_key), nt.is_active
  into v_delivery_id, v_started_at, v_completed_at, v_existing_profile, v_existing_active
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.user_id = v_user_id
    and nd.delivery_local_date = v_date_local
    and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission'
  order by nd.delivered_at desc
  limit 1;

  if v_delivery_id is not null
    and v_started_at is null
    and v_completed_at is null
    and (v_existing_active is false or (v_profile is not null and coalesce(v_existing_profile, '') <> v_profile)) then
    select nt.id into v_template_id
    from public.nudge_templates nt
    where nt.category = 'mission'
      and nt.is_active = true
      and (case when v_profile is null then nt.is_random_eligible else nt.mission_profile_key = v_profile end)
    order by random(), nt.sort_order, nt.id
    limit 1;

    if v_template_id is not null then
      update public.nudge_deliveries
      set template_id = v_template_id,
          delivery_category = 'mission',
          selection_source = case when v_profile is null then 'random' else 'emotion' end,
          matched_mission_profile = v_profile
      where id = v_delivery_id;
    end if;
  end if;

  if v_delivery_id is null then
    v_source := case when v_profile is null then 'random' else 'emotion' end;

    select nt.id into v_template_id
    from public.nudge_templates nt
    where nt.category = 'mission'
      and nt.is_active = true
      and (case when v_profile is null then nt.is_random_eligible else nt.mission_profile_key = v_profile end)
    order by random(), nt.sort_order, nt.id
    limit 1;

    if v_template_id is null then perform public.raise_app_error('NUDGE_NOT_FOUND'); end if;

    begin
      insert into public.nudge_deliveries (
        template_id, user_id, delivered_at, delivery_local_date, delivery_category, selection_source, matched_mission_profile
      ) values (
        v_template_id, v_user_id, now(), v_date_local, 'mission', v_source, v_profile
      )
      returning id into v_delivery_id;
    exception
      when unique_violation then
        select nd.id into v_delivery_id
        from public.nudge_deliveries nd
        join public.nudge_templates nt on nt.id = nd.template_id
        where nd.user_id = v_user_id
          and nd.delivery_local_date = v_date_local
          and coalesce(nd.delivery_category, nt.category, 'comfort') = 'mission'
        order by nd.delivered_at desc
        limit 1;
    end;
  end if;

  if p_mark_opened then
    update public.nudge_deliveries nd set opened_at = coalesce(nd.opened_at, now()) where nd.id = v_delivery_id;
    insert into public.daily_logs (user_id, date, nudge_opened, created_at, updated_at)
    values (v_user_id, v_date_local, true, now(), now())
    on conflict (user_id, date) do update set nudge_opened = true, updated_at = now();
  end if;

  return query
  select nd.id, nt.id, nt.type::varchar(32), nt.title::varchar(80), coalesce(nt.subtitle, '')::varchar(120),
         nt.body::varchar(240), nt.duration_minutes::smallint, coalesce(nt.checklist_json, '[]'::jsonb),
         coalesce(nt.cta_label, '미션 시작하기')::varchar(32), coalesce(nt.accent_icon, 'auto_awesome')::varchar(32),
         coalesce(nt.accent_start_color, 'violet')::varchar(16), coalesce(nt.accent_end_color, 'indigo')::varchar(16),
         nd.delivery_local_date, nd.opened_at, nd.started_at, nd.completed_at,
         coalesce(nd.selection_source, 'existing')::varchar(16), coalesce(nd.matched_mission_profile, nt.mission_profile_key)::varchar(24),
         coalesce(nt.mission_goal, '')::varchar(80), coalesce(nt.mission_state_label, '')::varchar(80)
  from public.nudge_deliveries nd
  join public.nudge_templates nt on nt.id = nd.template_id
  where nd.id = v_delivery_id and nd.user_id = v_user_id
  limit 1;

  if not found then perform public.raise_app_error('NUDGE_NOT_FOUND'); end if;
exception
  when insufficient_privilege then perform public.raise_app_error('FORBIDDEN');
  when sqlstate 'P0001' then raise;
  when others then perform public.raise_app_error('INTERNAL_ERROR');
end;
$$;

grant execute on function public.get_today_mission(boolean, varchar) to authenticated;
notify pgrst, 'reload schema';
