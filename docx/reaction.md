- 본 문서는 pages/reaction 세부 개발 문서이다.

- domain 제공 함수
  - Future<void> checkReactionTypeAllowed({required int reactionTypeId, required List<int> activeTypeIds})
    - 설명: 활성 리액션 타입 검증
    - 반환: 성공 시 void
    - 실패 코드: INVALID_ARGUMENT

  - Future<void> checkDuplicateReaction({required String senderUserId, required String starId})
    - 설명: 동일 별 중복 전송 검증
    - 반환: 성공 시 void
    - 실패 코드: ALREADY_REACTED

  - Future<void> checkDailyReactionLimit({required String senderUserId, required DateTime localDate})
    - 설명: 일일 리액션 제한 검증(20회/일)
    - 반환: 성공 시 void
    - 실패 코드: DAILY_REACTION_LIMIT_EXCEEDED

  - Future<void> checkReactionTargetAllowed({required String senderUserId, required String starOwnerUserId})
    - 설명: 자기별/차단 관계 전송 가능 여부 검증
    - 반환: 성공 시 void
    - 실패 코드: SELF_REACTION_NOT_ALLOWED, BLOCKED_RELATIONSHIP

  - String mapReactionErrorCodeToMessage({required String errorCode})
    - 설명: 에러코드 -> 사용자 메시지 매핑
    - 반환: String
    - 사용 화면: star_detail_screen.dart

- data 제공 함수
  - Future<List<ReactionType>> fetchReactionTypes()
    - 실측 시그니처: pages/reaction/data/reaction_repository.dart
    - 사용 화면: star_detail_screen.dart, reaction_sent_screen.dart
    - 반환: List<ReactionType>
    - 매핑 테이블: reaction_types (`is_active=true`)

    - 조회 응답 필드 고정(v1):
      - `id`
      - `code`
      - `label_ko`
      - `icon`

  - Future<SendReactionResult> sendReaction({required String starId, required int reactionTypeId})
    - 실측 시그니처: pages/reaction/data/reaction_repository.dart
    - 사용 화면: star_detail_screen.dart
    - 매핑 RPC: send_reaction
    - 반환: SendReactionResult(reactionId, starId, reactionCount, createdAt)
    - 영향 테이블: reactions, stars.reaction_count, daily_logs
    - 트랜잭션 경계: send_reaction RPC 내부 원자 처리

    - RPC 요청 필드 고정(v1):
      - `star_id uuid`
      - `reaction_type_id bigint`
      - `sender_user_id`, `local_date`는 클라이언트 입력 금지(서버 내부 결정)

    - RPC 응답 필드 고정(v1):
      - `reaction_id uuid`
      - `star_id uuid`
      - `reaction_count int`
      - `created_at timestamptz`

  - Future<DailyQuota> fetchReactionQuota()
    - 설명: 일일 쿼터 조회
    - 반환: DailyQuota(used, limit, remaining)
    - 매핑 RPC: get_today_status
    - 응답 매핑:
      - `used <= reaction_sent_count`
      - `limit <= reaction_daily_limit`
      - `remaining <= reaction_remaining_count`
      - 상태 분기 보조: `is_star_public_today`, `is_star_expired_today`

- 에러코드 고정안
  - UNAUTHORIZED
  - FORBIDDEN
  - STAR_NOT_FOUND
  - ALREADY_REACTED
  - DAILY_REACTION_LIMIT_EXCEEDED
  - BLOCKED_RELATIONSHIP
  - SELF_REACTION_NOT_ALLOWED
  - INVALID_ARGUMENT
  - INTERNAL_ERROR

- 신규 타입 정의(소유: pages/reaction domain)
  - 파일: pages/reaction/domain/send_reaction_result.dart
  - 타입: SendReactionResult
  - 역할: send_reaction 결과 전달
  - 필드:
    - String reactionId
    - String starId
    - int reactionCount
    - DateTime createdAt

  - 파일: pages/reaction/domain/daily_quota.dart
  - 타입: DailyQuota
  - 역할: 일일 리액션 사용량/잔여량 전달
  - 필드:
    - int used
    - int limit
    - int remaining
