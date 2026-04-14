- 본 문서는 pages/constellation 세부 개발 문서이다.

- domain 제공 함수
  - FeedFilter selectFeedFilter({required FeedFilter current, required FeedFilter next})
    - 설명: 피드 필터 상태 변경
    - 반환: FeedFilter

  - int calculateRelationScore({required StarCandidate candidate, required ViewerContext viewer})
    - 설명: 라우팅 점수 계산
    - 반환: int

  - bool checkFeedVisibility({required StarCandidate candidate, required ViewerContext viewer})
    - 설명: 노출 가능 여부 판단(차단/삭제/비활성/만료)
    - 반환: bool

  - List<Star> sortFeedByRules({required List<Star> stars})
    - 설명: 정렬 규칙 적용
    - 반환: List<Star>

  - List<Star> applyFeedDiversityPolicy({required List<Star> stars})
    - 설명: 감정 편중 완화
    - 반환: List<Star>

- data 제공 함수
  - Future<List<Star>> fetchFeed({String filterName = 'all', int limit = 20, int offset = 0})
    - 실측 시그니처: pages/constellation/data/constellation_repository.dart
    - 사용 화면: constellation_feed_screen.dart
    - 반환: List<Star>
    - 매핑 RPC: get_constellation_feed
    - 서버 보정: limit max 50, offset min 0

    - RPC 요청 필드 고정(v1):
      - `filter_name text`
      - `limit int`
      - `offset int`

    - RPC 응답 필드 고정(v1):
      - `star_id uuid`
      - `user_id uuid`
      - `content text`
      - `tag_ids bigint[]`
      - `time_bucket text`
      - `reaction_count int`
      - `created_at timestamptz`
      - `expires_at timestamptz`
      - `relation_score numeric`
      - `is_seen boolean` (선택)

  - Future<Star> fetchStarById(String starId)
    - 실측 시그니처: pages/constellation/data/constellation_repository.dart
    - 사용 화면: star_detail_screen.dart
    - 반환: Star
    - 매핑 RPC: get_star_detail

    - RPC 요청 필드 고정(v1):
      - `star_id uuid`

    - RPC 응답 필드 고정(v1):
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
      - 태그는 동등하며 대표/보조 구분을 두지 않는다.
      - 타인 조회는 삭제/만료/비노출이면 `STAR_NOT_FOUND`
      - 작성자 본인 조회는 상태 필드 노출, 단 `is_reactable=false`

  - Future<void> markStarSeen({required String starId, required String userId})
    - 설명: 읽음/노출 이력 기록
    - 반환: Future<void>
    - 매핑 테이블: star_views
    - 트랜잭션 경계: 단일 insert/upsert

  - Future<TodayStatus> fetchTodayStatus()
    - 설명: 피드 진입 시 오늘 상태(작성/쿼터) 조회
    - 반환: TodayStatus(dateLocal, hasStarToday, todayStarId, reactionSentCount, reactionDailyLimit, reactionRemainingCount)
    - 매핑 RPC: get_today_status
    - 화면 분기 보조: `is_star_public_today`, `is_star_expired_today`

- 에러코드 고정안
  - UNAUTHORIZED
  - FORBIDDEN
  - STAR_NOT_FOUND
  - BLOCKED_RELATIONSHIP
  - INVALID_ARGUMENT
  - INTERNAL_ERROR

- 신규 타입 정의(소유: pages/constellation domain)
  - 파일: pages/constellation/domain/today_status.dart
  - 타입: TodayStatus
  - 역할: 피드 진입 시 오늘 상태 전달
  - 필드:
    - DateTime dateLocal
    - bool hasStarToday
    - String? todayStarId
    - bool isStarPublicToday
    - bool isStarExpiredToday
    - int reactionSentCount
    - int reactionDailyLimit
    - int reactionRemainingCount

  - 파일: pages/constellation/domain/star_candidate.dart
  - 타입: StarCandidate
  - 역할: 피드 노출/점수 계산 전 후보 데이터
  - 필드:
    - String starId
    - String ownerUserId
    - List<int> tagIds
    - String timeBucket
    - int reactionCount
    - bool isDeleted
    - bool isBlocked
    - DateTime? expiresAt

  - 파일: pages/constellation/domain/viewer_context.dart
  - 타입: ViewerContext
  - 역할: 조회 사용자 컨텍스트
  - 필드:
    - String viewerUserId
    - Set<String> blockedUserIds
    - Set<String> seenStarIds
