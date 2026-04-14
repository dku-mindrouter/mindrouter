- 본 문서는 shared/features 세부 개발 문서이다.

- domain 공통 제공 함수
  - String getTimeBucketByLocalTime({required DateTime now, required String timezone})
    - 설명: 공통 시간 버킷 계산

  - String mapEmotionGroup({required String tagNameKo})
    - 설명: 감정 태그를 그룹으로 매핑

  - int calculateRelationScore({required RelationScoreInput input})
    - 설명: 피드 라우팅 점수 계산

  - String mapAppErrorCodeToMessage({required String errorCode})
    - 설명: 공통 에러코드 메시지 매핑

  - bool checkRiskExpression({required String content})
    - 설명: 공통 위험 표현 탐지

- 공통 에러코드 고정안
  - 범위 구분:
    - 앱 세션/클라이언트 인증 상태: `UNAUTHENTICATED`, `SESSION_EXPIRED`
    - 백엔드 RPC/DB 권한 체계: `UNAUTHORIZED`, `FORBIDDEN`
  - UNAUTHENTICATED
  - SESSION_EXPIRED
  - UNAUTHORIZED
  - FORBIDDEN
  - INVALID_ARGUMENT
  - INTERNAL_ERROR
  - STAR_NOT_FOUND
  - DAILY_STAR_LIMIT_EXCEEDED
  - ALREADY_REACTED
  - DAILY_REACTION_LIMIT_EXCEEDED
  - BLOCKED_RELATIONSHIP
  - SELF_REACTION_NOT_ALLOWED
  - NUDGE_NOT_FOUND
  - NUDGE_OUT_OF_WINDOW
  - NUDGE_DAILY_LIMIT_EXCEEDED

- 도메인 전용 에러코드(공통 목록 제외)
  - PROFILE_INCOMPLETE (auth/profile 전용)

- 공통 타입 의존성
  - RelationScoreInput은 shared/models/relation_score_input.dart에서 정의한다.
