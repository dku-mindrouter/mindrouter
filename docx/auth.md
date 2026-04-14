- 본 문서는 pages/auth 세부 개발 문서이다.

- domain 제공 함수
  - Future<void> checkAuthenticatedUser({required String? userId})
    - 설명: 인증 유저 존재 여부 검증
    - 반환: 성공 시 void
    - 실패 코드: UNAUTHENTICATED

  - Future<void> checkSessionValidity({required DateTime? expiresAt})
    - 설명: 세션 만료 여부 검증
    - 반환: 성공 시 void
    - 실패 코드: SESSION_EXPIRED

  - Future<void> checkProfileCompleted({required String? nickname})
    - 설명: 최소 프로필 완성 여부 검증
    - 반환: 성공 시 void
    - 실패 코드: PROFILE_INCOMPLETE

  - Future<void> checkNicknamePolicy({required String nickname})
    - 설명: 닉네임 정책 검증(길이/금칙어)
    - 반환: 성공 시 void
    - 실패 코드: INVALID_NICKNAME, NICKNAME_BLOCKED_WORD

  - String resolveAuthNextRoute()
    - 설명: 인증/프로필 점검 후 다음 페이지 라우트 결정
    - 반환: String (기본값: `emotion`)

- data 제공 함수
  - Stream<AuthStatus> authStateChanges()
    - 실측 시그니처: pages/auth/data/auth_repository.dart
    - 사용 화면: login_screen.dart
    - 매핑: Supabase auth state stream

  - Future<void> signInForDevelopment()
    - 실측 시그니처: pages/auth/data/auth_repository.dart
    - 사용 화면: login_screen.dart
    - 매핑: Supabase Auth signInAnonymously
    - 비고: 현재 단계는 개발용 로그인만 사용하며, Google/Apple 로그인은 후속 단계에서 추가한다.

  - Future<void> signOut()
    - 실측 시그니처: pages/auth/data/auth_repository.dart
    - 매핑: Supabase Auth signOut

  - Future<Map<String, dynamic>?> getProfileByUserId({required String userId})
    - 설명: 사용자 프로필 1건 조회
    - 매핑 테이블: profiles

  - Future<void> upsertProfile({required String userId, required String nickname, required String timezone})
    - 설명: 사용자 프로필 생성/갱신
    - 매핑 테이블: profiles
    - 트랜잭션 경계: 단일 upsert 쿼리

  - Future<void> updatePushToken({required String userId, required String pushToken})
    - 설명: 푸시 토큰 갱신
    - 매핑 테이블: profiles.push_token

- 에러코드 고정안
  - UNAUTHENTICATED
  - SESSION_EXPIRED
  - PROFILE_INCOMPLETE
  - INVALID_NICKNAME
  - NICKNAME_BLOCKED_WORD
