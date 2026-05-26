# API Contract v1

## create_star

- 목적: 감정 별 생성 + 태그 매핑 + daily_logs 반영
- RPC 이름: `create_star`
- 클라이언트 호출 인자:
  - `content` (required)
  - `tag_ids` (required, bigint[])
  - `time_bucket` (required)
  - `visibility_status` (required)
  - `emotion_intensity` (optional)
  - `expires_at` (optional, null 허용)
- Supabase RPC 파라미터 매핑:
  - `content -> p_content`
  - `tag_ids -> p_tag_ids`
  - `time_bucket -> p_time_bucket`
  - `visibility_status -> p_visibility_status`
  - `emotion_intensity -> p_emotion_intensity`
  - `expires_at -> p_expires_at`
- 응답:
  - `star_id` (uuid)
  - `created_at` (timestamptz)
  - `created_local_date` (date)
- 에러코드:
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `DAILY_STAR_LIMIT_EXCEEDED`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

예시 응답:

```json
{
  "star_id": "8cc72875-347f-47cf-a333-8808dcf28f02",
  "created_at": "2026-04-11T09:03:31.811672+00:00",
  "created_local_date": "2026-04-11"
}
```

## get_today_status

- 목적: 오늘 별 등록 상태 + 리액션 잔여량 조회
- RPC 이름: `get_today_status`
- 입력: 없음 (auth.uid 기준)
- 응답:
  - `date_local` (date)
  - `has_star_today` (bool)
  - `today_star_id` (uuid|null)
  - `is_star_public_today` (bool)
  - `is_star_expired_today` (bool)
  - `reaction_sent_count` (int)
  - `reaction_daily_limit` (int)
  - `reaction_remaining_count` (int)
- 에러코드:
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `INTERNAL_ERROR`

예시 응답:

```json
{
  "date_local": "2026-04-11",
  "has_star_today": true,
  "today_star_id": "8cc72875-347f-47cf-a333-8808dcf28f02",
  "is_star_public_today": true,
  "is_star_expired_today": false,
  "reaction_sent_count": 1,
  "reaction_daily_limit": 20,
  "reaction_remaining_count": 19
}
```

## get_constellation_feed

- 목적: constellation 피드 조회(필터/정렬/가시성 기준 적용)
- RPC 이름: `get_constellation_feed`
- 클라이언트 호출 인자:
  - `filter_name` (required: `all` | `dawn` | `morning` | `day` | `evening` | `night`, 그 외는 `all`로 보정)
  - `limit` (required, 기본 20, 최대 50)
  - `offset` (required, 0 이상)
- Supabase RPC 파라미터 매핑:
  - `filter_name -> p_filter_name`
  - `limit -> p_limit`
  - `offset -> p_offset`
- 응답(목록):
  - `star_id` (uuid)
  - `user_id` (uuid)
  - `content` (text)
  - `tag_ids` (bigint[])
  - `time_bucket` (text)
  - `reaction_count` (int)
  - `created_at` (timestamptz)
  - `expires_at` (timestamptz|null)
  - `relation_score` (numeric)
  - `is_seen` (bool, optional)
- 에러코드:
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

예시 응답:

```json
[
  {
    "star_id": "11111111-1111-1111-1111-111111111111",
    "user_id": "22222222-2222-2222-2222-222222222222",
    "content": "힘들었지만 버텼어요",
    "tag_ids": [6, 7],
    "time_bucket": "night",
    "reaction_count": 2,
    "created_at": "2026-04-11T12:00:00Z",
    "expires_at": null,
    "relation_score": 31,
    "is_seen": false
  }
]
```

## get_star_detail

- 목적: 별 상세 조회(삭제/만료/노출상태/리액션 가능 여부 포함)
- RPC 이름: `get_star_detail`
- 클라이언트 호출 인자:
  - `star_id` (required, uuid)
- Supabase RPC 파라미터 매핑:
  - `star_id -> p_star_id`
- 응답:
  - `star_id` (uuid)
  - `user_id` (uuid)
  - `content` (text)
  - `tag_ids` (bigint[])
  - `tag_names` (text[])
  - `time_bucket` (text)
  - `reaction_count` (int)
  - `created_at` (timestamptz)
  - `expires_at` (timestamptz|null)
  - `visibility_status` (text)
  - `is_deleted` (bool)
  - `is_expired` (bool)
  - `is_reactable` (bool)
- 에러코드:
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `STAR_NOT_FOUND`
  - `BLOCKED_RELATIONSHIP`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

예시 응답:

```json
{
  "star_id": "11111111-1111-1111-1111-111111111111",
  "user_id": "22222222-2222-2222-2222-222222222222",
  "content": "힘들었지만 버텼어요",
  "tag_ids": [6],
  "tag_names": ["불안"],
  "time_bucket": "night",
  "reaction_count": 2,
  "created_at": "2026-04-11T12:00:00Z",
  "expires_at": "2026-04-11T18:00:00Z",
  "visibility_status": "public",
  "is_deleted": false,
  "is_expired": false,
  "is_reactable": true
}
```

## reaction_types

- 목적: 활성 리액션 타입 목록 조회
- 테이블: `reaction_types`
- 조건: `is_active = true`
- 정렬: `id ASC`
- 응답(목록):
  - `id` (bigint)
  - `code` (text)
  - `label_ko` (text)
  - `icon` (text)

예시 응답:

```json
[
  {
    "id": 1,
    "code": "HUG",
    "label_ko": "안아드려요",
    "icon": "hug"
  }
]
```

## send_reaction

- 목적: 별에 리액션 전송 + 카운터/일일로그 반영
- RPC 이름: `send_reaction`
- 클라이언트 호출 인자:
  - `star_id` (required, uuid)
  - `reaction_type_id` (required, bigint)
- Supabase RPC 파라미터 매핑:
  - `star_id -> p_star_id`
  - `reaction_type_id -> p_reaction_type_id`
- 서버 내부 결정값:
  - `sender_user_id = auth.uid()`
  - `created_local_date = profiles.timezone 기준 계산`
- 응답:
  - `reaction_id` (uuid)
  - `star_id` (uuid)
  - `reaction_count` (int)
  - `created_at` (timestamptz)
- 에러코드:
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `STAR_NOT_FOUND`
  - `ALREADY_REACTED`
  - `DAILY_REACTION_LIMIT_EXCEEDED`
  - `BLOCKED_RELATIONSHIP`
  - `SELF_REACTION_NOT_ALLOWED`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

예시 응답:

```json
{
  "reaction_id": "33333333-3333-3333-3333-333333333333",
  "star_id": "11111111-1111-1111-1111-111111111111",
  "reaction_count": 4,
  "created_at": "2026-04-11T12:00:00Z"
}
```

## get_today_mission

- 목적: 오늘의 감정 기반 또는 랜덤 오늘 미션 1건 조회/최초 발급
- RPC 이름: `get_today_mission`
- 클라이언트 호출 인자:
  - `mark_opened` (optional, bool, 기본 `false`)
  - `selected_emotion_profile` (optional, text)
- Supabase RPC 파라미터 매핑:
  - `mark_opened -> p_mark_opened`
  - `selected_emotion_profile -> p_selected_emotion_profile`
- 감정 프로필 고정값:
  - `happy`
  - `energized`
  - `calm`
  - `depressed`
  - `lethargic`
  - `anxious`
  - `irritated`
- 정책:
  - 감정별 후보 미션은 3개씩 관리하지만, 하루에 발급되는 미션은 1개
  - 오늘 이미 시작/완료한 미션이 있으면 기존 미션을 그대로 반환
  - 감정 미선택 상태에서 발급된 미션이 아직 시작/완료 전이면, 오늘 감정 등록 후 감정 맞춤 미션으로 교체 가능
  - 오늘 감정을 선택했다면 해당 프로필 미션을 우선 추천
  - 감정을 선택하지 않았다면 랜덤 미션 발급
  - 랜덤 미션 완료 후 감정을 선택해도 기존 미션/완료 상태 유지
- 응답:
  - `delivery_id` (uuid)
  - `template_id` (bigint)
  - `mission_type` (text)
  - `title` (text)
  - `subtitle` (text)
  - `body` (text)
  - `duration_minutes` (smallint)
  - `checklist_json` (jsonb, 현재 단일 미션 정책에서는 빈 배열)
  - `cta_label` (text)
  - `accent_icon` (text)
  - `accent_start_color` (text)
  - `accent_end_color` (text)
  - `delivery_local_date` (date)
  - `opened_at` (timestamptz|null)
  - `started_at` (timestamptz|null)
  - `completed_at` (timestamptz|null)
  - `selection_source` (text: `emotion` | `random` | `existing`)
  - `matched_mission_profile` (text|null)
  - `mission_goal` (text)
  - `mission_state_label` (text)
- 에러코드:
  - `NUDGE_NOT_FOUND`
  - `UNAUTHORIZED`
  - `FORBIDDEN`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

예시 응답:

```json
{
  "delivery_id": "44444444-4444-4444-4444-444444444444",
  "template_id": 12,
  "mission_type": "mission_anxious_breathing",
  "title": "4초 들이마시고 6초 내쉬기",
  "subtitle": "몸의 호흡 리듬부터 천천히 낮춰 보세요.",
  "body": "불안할 때는 생각을 멈추는 것보다 몸의 속도를 먼저 늦추는 편이 도움이 됩니다.",
  "duration_minutes": 5,
  "checklist_json": [
    "어깨를 내려놓고 편한 자세 찾기",
    "4초 들이마시고 6초 내쉬는 호흡 5번 하기",
    "숨이 조금 느려졌는지 확인하기"
  ],
  "cta_label": "미션 시작하기",
  "accent_icon": "air",
  "accent_start_color": "sky",
  "accent_end_color": "violet",
  "delivery_local_date": "2026-05-25",
  "opened_at": "2026-05-25T03:15:00Z",
  "started_at": null,
  "completed_at": null,
  "selection_source": "emotion",
  "matched_mission_profile": "anxious",
  "mission_goal": "생각보다 몸의 속도를 먼저 낮추기",
  "mission_state_label": "마음이 조급함"
}
```

## start_today_mission

- 목적: 오늘 미션 시작 상태 반영
- RPC 이름: `start_today_mission`
- 클라이언트 호출 인자:
  - `delivery_id` (required, uuid)
- Supabase RPC 파라미터 매핑:
  - `delivery_id -> p_delivery_id`
- 동작:
  - `opened_at`이 비어 있으면 함께 채움
  - `started_at`이 비어 있을 때만 현재 시각으로 기록
- 에러코드:
  - `NUDGE_NOT_FOUND`
  - `UNAUTHORIZED`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

## complete_today_mission

- 목적: 오늘 미션 완료 상태 반영
- RPC 이름: `complete_today_mission`
- 클라이언트 호출 인자:
  - `delivery_id` (required, uuid)
- Supabase RPC 파라미터 매핑:
  - `delivery_id -> p_delivery_id`
- 동작:
  - `opened_at`, `started_at`, `completed_at`을 순차적으로 채움
  - 이미 완료된 미션은 기존 완료 시각 유지
- 에러코드:
  - `NUDGE_NOT_FOUND`
  - `UNAUTHORIZED`
  - `INVALID_ARGUMENT`
  - `INTERNAL_ERROR`

## Emotion Domain Policy Notes (2026-04-11)

- `getTimeBucketByLocalTime(now, timezone)`:
  - timezone 문자열 기준으로 클라이언트에서 즉시 계산
  - timezone 누락/실패 fallback: `Asia/Seoul`
  - 서버(DB/RPC)가 `profiles.timezone`으로 최종값 authoritative 계산
- `checkCanSubmitEmotion(tagIds, isSubmitting)`:
  - `tagIds.isNotEmpty && !isSubmitting`
- `CONTENT_BLOCKED_WORD` 금칙어 목록:
  - 현재 가안이며 운영 정책 확정 시 변경 가능
