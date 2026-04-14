- 본 문서는 pages/profile 세부 개발 문서이다.

- domain 제공 함수
  - int calculateStreak({required List<DailyLog> logs})
    - 설명: 연속 기록일 계산
    - 반환: int

  - Map<String, int> aggregateEmotionFrequency({required List<EmotionRecord> records, required int days})
    - 설명: 기간 감정 빈도 집계
    - 반환: Map<String, int>

  - ProfileSummary buildProfileSummary({required String nickname, required String timezone})
    - 설명: 프로필 요약 구성
    - 반환: ProfileSummary

  - Future<void> checkStatsConsistency({required MyStats stats})
    - 설명: 통계 일관성 검증
    - 반환: 성공 시 void
    - 실패 코드: STATS_INCONSISTENT

- data 제공 함수
  - Future<MyStats> fetchMyStats()
    - 실측 시그니처: pages/profile/data/profile_repository.dart
    - 사용 화면: profile_screen.dart(mock 교체 대상)
    - 반환: MyStats
    - 매핑: me_stats RPC 또는 daily_logs/reactions 집계

  - Future<Map<String, int>> fetchEmotionHistory({required String userId, int days = 7})
    - 설명: 최근 감정 빈도 조회
    - 반환: Map<String, int>
    - 매핑: stars + emotion_tags 집계

  - Future<List<Star>> fetchMyStars({required String userId, int limit = 20, int offset = 0})
    - 설명: 내 별 목록 조회
    - 반환: List<Star>
    - 매핑 테이블: stars

- 에러코드 고정안
  - PROFILE_INCOMPLETE
  - PROFILE_NOT_FOUND
  - STATS_INCONSISTENT
