- 본 문서는 pages/nudge 세부 개발 문서이다.

- domain 제공 함수
  - NudgeContext buildNudgeContext({required MyStats stats, required Map<String, int> recentEmotionGroupCounts, required int receivedReactionCount})
    - 설명: 넛지 추천 컨텍스트 생성
    - 반환: NudgeContext

  - NudgePreview selectNudgeTemplate({required NudgeContext context})
    - 설명: 템플릿 기반 넛지 선택
    - 반환: NudgePreview

  - Future<void> checkNudgeSendWindow({required DateTime now, required String timezone})
    - 설명: 발송 시간대 검증
    - 반환: 성공 시 void
    - 실패 코드: NUDGE_OUT_OF_WINDOW

  - Future<void> checkNudgeFrequencyLimit({required String userId, required DateTime localDate})
    - 설명: 일일 넛지 제한 검증
    - 반환: 성공 시 void
    - 실패 코드: NUDGE_DAILY_LIMIT_EXCEEDED

- data 제공 함수
  - Future<List<Nudge>> fetchTodayNudges()
    - 실측 시그니처: pages/nudge/data/nudge_repository.dart
    - 사용 화면: nudge_home_screen.dart(mock 교체 대상)
    - 반환: List<Nudge>
    - 매핑 테이블: nudge_deliveries + nudge_templates

  - Future<NudgePreview> createNudgePreview({required List<int> tagIds, required String timeBucket})
    - 설명: 감정 태그/시간대 기반 미리보기 생성
    - 반환: NudgePreview
    - 매핑 RPC: preview_nudge(추가) 또는 룰 조회

  - Future<void> markNudgeOpened({required String nudgeId, required String userId})
    - 설명: 넛지 열람 기록
    - 반환: Future<void>
    - 매핑 테이블: nudge_deliveries.opened_at, daily_logs.nudge_opened
    - 트랜잭션 경계: opened_at + daily_logs 업데이트 원자 처리

- 에러코드 고정안
  - NUDGE_NOT_FOUND
  - NUDGE_OUT_OF_WINDOW
  - NUDGE_DAILY_LIMIT_EXCEEDED
  - INVALID_ARGUMENT
  - INTERNAL_ERROR

- 신규 타입 정의(소유: pages/nudge domain)
  - 파일: pages/nudge/domain/nudge_context.dart
  - 타입: NudgeContext
  - 역할: 넛지 템플릿 선택 입력 컨텍스트
  - 필드:
    - String dominantEmotionGroup
    - String timeBucket
    - int streakDays
    - int receivedReactionCount
