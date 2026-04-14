- 본 문서는 pages/emotion 세부 개발 문서이다.

- domain 제공 함수
  - EmotionComposerState toggleEmotionTag({required EmotionComposerState state, required int tagId, required int maxTags})
    - 설명: 감정 태그 선택/해제(N:N 태그 기반)
    - 반환: 갱신된 EmotionComposerState
    - 실패 코드: TAG_LIMIT_EXCEEDED

  - Future<void> checkEmotionTagLimit({required List<int> tagIds, required int maxCount})
    - 설명: 감정 태그 최대 개수 검증
    - 반환: 성공 시 void
    - 실패 코드: TAG_LIMIT_EXCEEDED

  - Future<void> checkEmotionContentPolicy({required String content, required int maxLength})
    - 설명: 입력 문장 정책 검증
    - 반환: 성공 시 void
    - 실패 코드: CONTENT_TOO_LONG, CONTENT_BLOCKED_WORD

  - String getTimeBucketByLocalTime({required DateTime now, required String timezone})
    - 설명: 시간대 버킷 계산
    - 반환: time_bucket 문자열

  - bool checkCanSubmitEmotion({required List<int> tagIds, required bool isSubmitting})
    - 설명: 제출 가능 여부 계산
    - 반환: bool
    - 사용 화면: emotion_picker_screen.dart(composer.canSubmit)

- data 제공 함수
  - Future<List<EmotionTag>> fetchEmotionTags()
    - 실측 시그니처: pages/emotion/data/emotion_repository.dart
    - 사용 화면: emotion_picker_screen.dart
    - 매핑 테이블: emotion_tags

  - Future<CreateStarResult> createStar({required String content, required List<int> tagIds, required String timeBucket, required String visibilityStatus, int? emotionIntensity, DateTime? expiresAt})
    - 실측 시그니처: pages/emotion/data/emotion_repository.dart
    - 사용 화면: emotion_picker_screen.dart
    - 반환: CreateStarResult(starId, createdAt, createdLocalDate)
    - 매핑 RPC: create_star
    - 영향 테이블: stars, star_emotion_maps, daily_logs
    - 트랜잭션 경계: create_star RPC 내부 원자 처리

    - RPC 요청 필드 고정(v1):
      - `content text`
      - `tag_ids bigint[]`
      - `time_bucket text`
      - `emotion_intensity smallint`
      - `visibility_status text`
      - `expires_at timestamptz default null`

    - RPC 응답 필드 고정(v1):
      - `star_id uuid`
      - `created_at timestamptz`
      - `created_local_date date`

  - Future<TodayStarStatus> fetchTodayStarStatus()
    - 설명: 오늘 별 등록 상태 조회
    - 반환: TodayStarStatus(hasCreatedToday, remainingCount, latestStarId)
    - 매핑 RPC: get_today_status
    - 응답 매핑:
      - `hasCreatedToday <= has_star_today`
      - `remainingCount <= reaction_remaining_count`
      - `latestStarId <= today_star_id`
      - 화면 분기 보조: `is_star_public_today`, `is_star_expired_today`

- 에러코드 고정안
  - UNAUTHORIZED
  - FORBIDDEN
  - TAG_LIMIT_EXCEEDED
  - CONTENT_TOO_LONG
  - CONTENT_BLOCKED_WORD
  - DAILY_STAR_LIMIT_EXCEEDED
  - INVALID_ARGUMENT
  - INTERNAL_ERROR

- 정책 확정(5단계 진행 중 확정)
  - `getTimeBucketByLocalTime(now, timezone)`:
    - 사용자 `timezone` 문자열 기준으로 계산한다.
    - timezone 파싱 실패/누락 시 fallback은 `Asia/Seoul`을 사용한다.
    - 클라이언트(domain) 계산은 UI 즉시 반응용이며, 최종값은 서버(`profiles.timezone`) 계산을 우선한다.
  - `checkCanSubmitEmotion(tagIds, isSubmitting)`:
    - 확정 조건은 `tagIds.isNotEmpty && !isSubmitting`.
  - 금칙어 목록:
    - 현재는 `가안` 목록을 사용하며 운영/정책 단계에서 수정 가능하다.

- 신규 타입 정의(소유: pages/emotion domain)
  - 파일: pages/emotion/domain/create_star_result.dart
  - 타입: CreateStarResult
  - 역할: create_star 결과 전달
  - 필드:
    - String starId
    - DateTime createdAt
    - DateTime createdLocalDate

  - 파일: pages/emotion/domain/today_star_status.dart
  - 타입: TodayStarStatus
  - 역할: 오늘 별 등록 상태 전달
  - 필드:
    - bool hasCreatedToday
    - int remainingCount (reaction_remaining_count 매핑값)
    - String? latestStarId
