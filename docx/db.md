# db 개발 규칙 및 확정 스키마

이 문서는 데이터베이스 구조 설계/구현 시 적용하는 세부 개발 문서다.

## 1. DB 설계 원칙

- 본 프로젝트 DB는 Supabase(PostgreSQL) 기준으로 작성한다.
- 감정 태그와 별(star)의 관계는 N:N으로 설계한다.
- 감정 태그는 동등 우선순위로 취급하며, 대표 태그 개념을 두지 않는다.
- `stars.expires_at`은 `NULL`이면 무제한 노출로 본다.
- 리액션/차단/일일제한 관련 제약은 DB 레벨에서 우선 강제한다.

## 2. 테이블 목록

- `profiles`
- `emotion_tags`
- `stars`
- `star_emotion_maps`
- `reaction_types`
- `reactions`
- `nudge_templates`
- `nudge_deliveries`
- `daily_logs`
- `star_views`
- `reports`
- `blocks`

## 3. 테이블 상세

### 3-1. profiles

역할:
- 인증 사용자(`auth.users`)의 앱 프로필 저장

컬럼:
- `id uuid` PK, FK -> `auth.users(id)` (on delete cascade)
- `nickname varchar(24)` NOT NULL UNIQUE: 앱 내 닉네임
- `avatar_type varchar(32)` NOT NULL DEFAULT `'default'`: 아바타 타입
- `push_token text` NULL: 푸시 토큰
- `timezone varchar(64)` NOT NULL DEFAULT `'Asia/Seoul'`: 사용자 시간대
- `is_active boolean` NOT NULL DEFAULT `true`: 활성/비활성 상태
- `created_at timestamptz` NOT NULL DEFAULT `now()`: 생성 시각
- `updated_at timestamptz` NOT NULL DEFAULT `now()`: 수정 시각

### 3-2. emotion_tags

역할:
- 감정 태그 사전 데이터

컬럼:
- `id bigserial` PK
- `name_ko varchar(32)` NOT NULL: 감정명
- `group_name varchar(32)` NOT NULL: 감정 그룹(라우팅 계산용)
- `priority int` NOT NULL DEFAULT `0`: 정렬 우선값
- `is_active boolean` NOT NULL DEFAULT `true`: 사용 여부

### 3-3. stars

역할:
- 사용자가 등록한 감정 별(게시물) 본문 저장

컬럼:
- `id uuid` PK DEFAULT `gen_random_uuid()`
- `user_id uuid` NOT NULL FK -> `profiles(id)`: 작성자
- `content varchar(80)` NOT NULL: 감정 문장
- `time_bucket varchar(16)` NOT NULL: 시간대 버킷
- `emotion_intensity smallint` NULL: 감정 강도(1~5)
- `visibility_status varchar(16)` NOT NULL DEFAULT `'public'`: 노출 상태
- `reaction_count int` NOT NULL DEFAULT `0`: 받은 리액션 집계
- `created_local_date date` NOT NULL: 사용자 로컬 작성일(일일 제한용)
- `created_at timestamptz` NOT NULL DEFAULT `now()`: 생성 시각
- `expires_at timestamptz` NULL: 노출 만료 시각(`NULL`이면 무제한)
- `is_deleted boolean` NOT NULL DEFAULT `false`: 소프트 삭제 여부

제약:
- `UNIQUE (user_id, created_local_date)` (하루 1회 등록 제한)
- `CHECK (time_bucket IN ('dawn','morning','day','evening','night'))`
- `CHECK (emotion_intensity BETWEEN 1 AND 5 OR emotion_intensity IS NULL)`

### 3-4. star_emotion_maps

역할:
- `stars`와 `emotion_tags` 연결 N:N 매핑 테이블

컬럼:
- `id bigserial` PK
- `star_id uuid` NOT NULL FK -> `stars(id)` ON DELETE CASCADE
- `tag_id bigint` NOT NULL FK -> `emotion_tags(id)`
- `created_at timestamptz` NOT NULL DEFAULT `now()`

제약:
- `UNIQUE (star_id, tag_id)` (중복 태그 연결 방지)

### 3-5. reaction_types

역할:
- 허용 리액션 사전 데이터

컬럼:
- `id bigserial` PK
- `code varchar(32)` NOT NULL UNIQUE: 내부 코드
- `label_ko varchar(32)` NOT NULL: 화면 노출 라벨
- `icon varchar(64)` NOT NULL: 아이콘 키
- `is_active boolean` NOT NULL DEFAULT `true`: 사용 여부

### 3-6. reactions

역할:
- 사용자가 별에 보낸 리액션 로그

컬럼:
- `id uuid` PK DEFAULT `gen_random_uuid()`
- `star_id uuid` NOT NULL FK -> `stars(id)` ON DELETE CASCADE
- `sender_user_id uuid` NOT NULL FK -> `profiles(id)`
- `reaction_type_id bigint` NOT NULL FK -> `reaction_types(id)`
- `created_local_date date` NOT NULL: 발신자 로컬 날짜(일일 제한용)
- `created_at timestamptz` NOT NULL DEFAULT `now()`: 생성 시각

제약:
- `UNIQUE (star_id, sender_user_id)` (동일 별 중복 리액션 방지)

### 3-7. nudge_templates

역할:
- 넛지 템플릿 마스터

컬럼:
- `id bigserial` PK
- `type varchar(32)` NOT NULL: 템플릿 유형
- `title varchar(80)` NOT NULL: 제목 템플릿
- `body varchar(240)` NOT NULL: 본문 템플릿
- `is_active boolean` NOT NULL DEFAULT `true`: 사용 여부

### 3-8. nudge_deliveries

역할:
- 넛지 템플릿의 사용자별 노출/열람 로그

컬럼:
- `id uuid` PK DEFAULT `gen_random_uuid()`
- `template_id bigint` NOT NULL FK -> `nudge_templates(id)`
- `user_id uuid` NOT NULL FK -> `profiles(id)`
- `delivered_at timestamptz` NOT NULL DEFAULT `now()`: 실제 노출 시각
- `opened_at timestamptz` NULL: 사용자 열람 시각

### 3-9. daily_logs

역할:
- 사용자 일별 활동 집계(streak 계산 포함)

컬럼:
- `id bigserial` PK
- `user_id uuid` NOT NULL FK -> `profiles(id)` ON DELETE CASCADE
- `date date` NOT NULL: 사용자 로컬 기준 날짜
- `star_created boolean` NOT NULL DEFAULT `false`: 별 등록 여부
- `reaction_sent_count int` NOT NULL DEFAULT `0`: 리액션 전송 횟수
- `nudge_opened boolean` NOT NULL DEFAULT `false`: 넛지 열람 여부
- `streak_count int` NOT NULL DEFAULT `0`: 해당 일자의 streak 스냅샷
- `created_at timestamptz` NOT NULL DEFAULT `now()`
- `updated_at timestamptz` NOT NULL DEFAULT `now()`

제약:
- `UNIQUE (user_id, date)`

### 3-10. reports

역할:
- 신고 접수 로그

컬럼:
- `id bigserial` PK
- `reporter_user_id uuid` NOT NULL FK -> `profiles(id)`
- `target_star_id uuid` NOT NULL FK -> `stars(id)`
- `reason varchar(64)` NOT NULL: 신고 사유
- `created_at timestamptz` NOT NULL DEFAULT `now()`

### 3-11. blocks

역할:
- 사용자 간 차단 관계 저장

컬럼:
- `id bigserial` PK
- `blocker_user_id uuid` NOT NULL FK -> `profiles(id)`
- `blocked_user_id uuid` NOT NULL FK -> `profiles(id)`
- `created_at timestamptz` NOT NULL DEFAULT `now()`

제약:
- `UNIQUE (blocker_user_id, blocked_user_id)` (중복 차단 방지)
- `CHECK (blocker_user_id <> blocked_user_id)` (자기 자신 차단 금지)

### 3-12. star_views

역할:
- 피드/상세에서 조회한 별 읽음 이력 저장

컬럼:
- `id bigserial` PK
- `viewer_user_id uuid` NOT NULL FK -> `profiles(id)` ON DELETE CASCADE
- `star_id uuid` NOT NULL FK -> `stars(id)` ON DELETE CASCADE
- `seen_at timestamptz` NOT NULL DEFAULT `now()`

제약:
- `UNIQUE (viewer_user_id, star_id)` (동일 사용자-동일 별 중복 이력 방지)

## 4. 정규화 점검(3NF)

- 감정 태그-별은 `star_emotion_maps`로 분리되어 N:N 정규화가 유지된다.
- 리액션/넛지 유형은 각각 사전 테이블(`reaction_types`, `nudge_templates`)로 분리되어 전이 종속을 줄인다.
- `reaction_count`, `streak_count`는 조회 성능을 위한 최소 비정규화 값으로 허용한다.
- 결론: 실무 기준에서 3NF를 충족한다.

## 5. RPC 공통 규칙

- RPC 대상:
  - `create_star`
  - `get_constellation_feed`
  - `send_reaction`
  - `get_star_detail`
  - `get_today_status`

- `create_star`는 `primary/secondary` 구조를 쓰지 않고 `tag_ids`를 사용한다.
  - 최종 입력 시그니처(v1):
    - `content text`
    - `tag_ids bigint[]`
    - `time_bucket text`
    - `emotion_intensity smallint`
    - `visibility_status text`
    - `expires_at timestamptz default null`
  - 서버 내부 결정값:
    - `user_id = auth.uid()`
    - `created_local_date = profiles.timezone 기반 계산`
  - 출력 시그니처(v1):
    - `star_id uuid`
    - `created_at timestamptz`
    - `created_local_date date`
  - 감정 태그는 동등 우선순위이므로 N:N(`star_emotion_maps`)에 일괄 저장한다.

- `get_constellation_feed` 파라미터는 아래로 확정한다.
  - `filter_name text`
  - `limit int`
  - `offset int`

- `get_constellation_feed`는 서버에서 `limit` 상한을 강제한다.
  - 기본값: `20`
  - 최대값: `50`
  - 클라이언트가 50 초과 값을 보내면 서버에서 50으로 clamp 처리한다.
  - `offset`이 0 미만이면 0으로 보정한다.

- `send_reaction` 입력 형식은 최소 입력만 받는다.
  - `star_id uuid`
  - `reaction_type_id bigint`
  - `sender_user_id`, `local_date`는 클라이언트에서 받지 않는다.
  - `sender_user_id`는 `auth.uid()`로 서버에서 결정한다.
  - `created_local_date`는 `profiles.timezone` 기준으로 서버에서 계산한다.

- `get_star_detail` 계약(v1)은 아래로 확정한다.
  - 입력:
    - `star_id uuid`
  - 출력:
    - `star_id uuid`
    - `user_id uuid`
    - `content text`
    - `tag_ids bigint[]`
    - `tag_names text[]`
    - `time_bucket text`
    - `reaction_count int`
    - `created_at timestamptz`
    - `expires_at timestamptz`
    - `visibility_status text`
    - `is_deleted boolean`
    - `is_expired boolean`
    - `is_reactable boolean`
    - 태그는 `tag_ids/tag_names` 배열로 제공하며 순위(대표/보조)를 두지 않는다.
  - 에러코드:
    - `UNAUTHORIZED`
    - `FORBIDDEN`
    - `INVALID_ARGUMENT`
    - `STAR_NOT_FOUND`
    - `BLOCKED_RELATIONSHIP`
    - `INTERNAL_ERROR`
  - 보안 노출 규칙:
    - 타인 조회 시 `is_deleted=true` / `expires_at <= now()` / 비노출 상태는 `STAR_NOT_FOUND`로 처리한다.
    - 작성자 본인 조회는 row를 반환하되 상태 필드(`is_deleted`, `is_expired`, `visibility_status`)로 구분한다.
    - 작성자 본인 조회에서도 `is_reactable=false`로 반환한다.

- `get_today_status` 계약(v1)은 아래로 확정한다.
  - 입력:
    - 없음(`auth.uid()` 인증 사용자 기준)
  - 출력:
    - `date_local date`
    - `has_star_today boolean`
    - `today_star_id uuid null`
    - `is_star_public_today boolean`
    - `is_star_expired_today boolean`
    - `reaction_sent_count int`
    - `reaction_daily_limit int`
    - `reaction_remaining_count int`
  - 계산 규칙:
    - `date_local`은 `profiles.timezone` 기준 로컬 날짜로 계산한다.
    - `has_star_today`는 “오늘 작성 사실” 기준으로 계산한다.
      - `today && is_deleted=false`일 때 `true`다.
      - `visibility_status`, `expires_at`는 `has_star_today` 계산에 포함하지 않는다.
    - `is_star_public_today`는 오늘 star의 `visibility_status='public'` 여부를 반환한다.
    - `is_star_expired_today`는 오늘 star의 `expires_at <= now()` 여부를 반환한다.
    - `reaction_sent_count`는 `daily_logs.reaction_sent_count`를 우선 사용한다.
      - 데이터 복구는 별도 관리자/배치 경로에서 `reactions` 실집계 재계산으로 처리한다.
  - 에러코드:
    - `UNAUTHORIZED`
    - `FORBIDDEN`
    - `INTERNAL_ERROR`
  - 프로필 상태 규칙:
    - `profiles` row 없음: `UNAUTHORIZED`
    - `profiles.is_active=false`: `FORBIDDEN`

- 일일 리액션 제한은 `20회/일`로 확정한다.
  - 초과 시 `DAILY_REACTION_LIMIT_EXCEEDED`를 반환한다.
  - 무결성 강화를 위해 `send_reaction` RPC 1차 검증 + `reactions` BEFORE INSERT 트리거 2차 검증을 함께 적용한다.
  - 트리거는 RPC 우회(직접 insert) 시에도 동일 제한을 강제해야 한다.

- 모든 RPC 에러 응답은 `APP_ERROR_CODE` 문자열로 통일한다.
  - 예시 코드:
    - `UNAUTHORIZED`
    - `FORBIDDEN`
    - `STAR_NOT_FOUND`
    - `ALREADY_REACTED`
    - `DAILY_STAR_LIMIT_EXCEEDED`
    - `DAILY_REACTION_LIMIT_EXCEEDED`
    - `BLOCKED_RELATIONSHIP`
    - `SELF_REACTION_NOT_ALLOWED`
    - `INVALID_ARGUMENT`
    - `INTERNAL_ERROR`
  - 예외 메시지 원문(postgres message)에 의존한 분기를 금지하고,
    프론트는 `APP_ERROR_CODE`만 기준으로 분기한다.

## 6. 인덱스 확정 규칙

- `stars(created_at, time_bucket)` 인덱스를 생성한다.
  - 피드 기본 정렬/시간대 필터 성능을 위한 인덱스다.
- `star_emotion_maps(tag_id, star_id)` 인덱스를 생성한다.
  - 감정 태그 기준 조인/필터 성능을 위한 인덱스다.
- 기존 문서의 `stars(created_at, primary_tag_id, time_bucket)` 규칙은 사용하지 않는다.
  - 현재 스키마에는 `primary_tag_id`가 없으므로 대체 규칙으로 본 섹션을 적용한다.

## 7. 초기 마스터 데이터(기획 기준)

주의:
- 본 섹션의 감정 태그/리액션 타입 목록은 현재 단계의 가안이다.
- 사용자 테스트, 기획 변경, 운영 정책 변경에 따라 언제든 수정될 수 있다.
- 확정 전까지는 마이그레이션 하드코딩보다 seed 데이터로 관리한다.

### 7-1. emotion_tags 초기값

용도:
- 앱에서 감정 선택 화면에 노출할 기준 목록
- 피드 라우팅 시 `group_name` 기반 유사 감정 계산

초기 태그 목록(권장 10개):

| name_ko | group_name | priority | is_active |
|---|---|---:|---|
| 공허함 | low_energy | 100 | true |
| 지침 | low_energy | 90 | true |
| 무기력 | low_energy | 80 | true |
| 외로움 | loneliness | 70 | true |
| 번아웃 | burnout | 60 | true |
| 불안 | anxiety | 50 | true |
| 답답함 | anxiety | 40 | true |
| 잔잔함 | calm_recovery | 30 | true |
| 안도 | calm_recovery | 20 | true |
| 위로받고 싶음 | support_need | 10 | true |

운영 규칙:
- 초기에는 운영자 고정 목록으로 관리한다.
- 삭제 대신 `is_active=false` 비활성화를 사용한다.
- `priority`는 UI 정렬 및 추천 기본 가중치 보조값으로 사용한다.

### 7-2. reaction_types 초기값

용도:
- 별 상세 화면에서 리액션 버튼/유형 기준 목록
- 자유 텍스트 없이 사전 정의 공감 신호만 허용

초기 리액션 목록(권장 4개):

| code | label_ko | icon | is_active |
|---|---|---|---|
| WARM_TEA | 따뜻한 차 | tea | true |
| HUG | 안아드려요 | hug | true |
| YOU_DID_WELL | 고생했어요 | clover | true |
| WITH_YOU | 함께해요 | stars | true |

운영 규칙:
- `code`는 불변 식별자로 사용한다(앱 로직 분기 키).
- 라벨/아이콘 변경이 필요하면 `label_ko`, `icon`만 수정한다.
- 사용 중단은 삭제 대신 `is_active=false`로 처리한다.
