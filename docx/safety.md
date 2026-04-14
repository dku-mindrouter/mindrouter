- 본 문서는 pages/safety 세부 개발 문서이다.

- domain 제공 함수
  - Future<void> checkReportInput({required String reason, required String targetStarId})
    - 설명: 신고 입력값 정책 검증
    - 반환: 성공 시 void
    - 실패 코드: INVALID_REPORT_REASON

  - Future<void> checkBlockPolicy({required String blockerUserId, required String blockedUserId})
    - 설명: 차단 정책 검증(자기 자신 차단 금지)
    - 반환: 성공 시 void
    - 실패 코드: SELF_BLOCK_NOT_ALLOWED

  - List<Star> applySafetyVisibilityFilter({required List<Star> stars, required Set<String> blockedUserIds})
    - 설명: 차단 관계 기반 노출 필터
    - 반환: List<Star>

  - bool checkRiskExpression({required String content})
    - 설명: 위험 표현 탐지
    - 반환: bool

- data 제공 함수
  - Future<void> createReport({required String reporterUserId, required String targetStarId, required String reason})
    - 설명: 신고 생성
    - 반환: Future<void>
    - 매핑 테이블: reports

  - Future<void> createBlock({required String blockerUserId, required String blockedUserId})
    - 설명: 차단 생성
    - 반환: Future<void>
    - 매핑 테이블: blocks

  - Future<void> deleteBlock({required String blockerUserId, required String blockedUserId})
    - 설명: 차단 해제
    - 반환: Future<void>
    - 매핑 테이블: blocks

  - Future<Set<String>> fetchBlockRelations({required String userId})
    - 설명: 사용자 차단 관계 조회
    - 반환: Set<String>
    - 매핑 테이블: blocks

- 트랜잭션 경계
  - createReport: 단일 insert 원자 처리
  - createBlock/deleteBlock: 단일 쿼리 원자 처리
  - 노출 차단은 조회 시점 정책 필터로 강제

- 에러코드 고정안
  - INVALID_REPORT_REASON
  - SELF_BLOCK_NOT_ALLOWED
  - BLOCK_NOT_FOUND
