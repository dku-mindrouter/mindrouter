# Mindrouter

Mindrouter는 오늘의 감정을 별처럼 기록하고, 자유 채팅 없이 사전 정의된 리액션과 부드러운 넛지로 연결되는 감정 기록 MVP입니다.

## 핵심 사이클

MVP의 성공 기준은 아래 한 사이클이 자연스럽게 이어지는 것입니다.

1. 오늘의 감정을 선택하고 별로 등록한다.
2. 별자리 피드에서 다른 사용자의 별을 탐색한다.
3. 안전한 사전 정의 리액션을 보낸다.
4. 넛지와 내 기록 화면에서 반응과 흐름을 확인한다.

## 저장소 구조

```text
apps/mobile    Flutter 앱
docs           기획, ERD, API 계약, 라우팅 규칙 문서
supabase       마이그레이션, 시드 데이터, Edge Functions
```

## 기술 스택

### 프론트엔드

- Flutter
- Riverpod
- go_router
- Dio
- Hive
- freezed + json_serializable

### 백엔드

- Supabase Auth
- PostgreSQL
- Supabase Edge Functions
- Docker 기반 로컬 개발 환경

## 협업 방식

- 장기 브랜치는 `main`, `dev` 두 개만 유지합니다.
- 일상 작업은 모두 `dev`에서 분기한 짧은 feature 브랜치에서 진행합니다.
- 예시 브랜치: `feature/mobile-auth-and-today-flow`, `feature/backend-feed-and-reaction-rpc`
- 머지는 `PR + squash merge`로 통일합니다.
- 커밋 prefix는 `feat:`, `fix:`, `refactor:`, `docs:`만 사용합니다.

## 로컬 실행

### 필요 도구

- Flutter SDK
- Dart SDK
- Supabase CLI
- Docker Desktop
- Firebase 프로젝트(FCM / Crashlytics 연결 시)

### 첫 실행 순서

1. `cd apps/mobile`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. 저장소 루트로 이동 후 `supabase start`

### 현재 검증 상태

이 저장소는 아래 항목까지 확인된 상태입니다.

- `flutter pub get` 완료
- `flutter analyze` 통과
- `flutter test` 통과
- `supabase start` 완료
- `supabase db lint --local --fail-on error` 통과

## 문서 위치

- 제품 요구사항: [docs/prd.md](/Users/yuchan/Desktop/git/mindrouter/docs/prd.md)
- 데이터 모델: [docs/erd.md](/Users/yuchan/Desktop/git/mindrouter/docs/erd.md)
- API 계약: [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md)
- 피드 라우팅 규칙: [docs/routing-rules.md](/Users/yuchan/Desktop/git/mindrouter/docs/routing-rules.md)

## 다음 작업 추천

- 프론트: 로그인 → 감정 선택 → 별 등록 화면을 실제 Supabase와 연결
- 백엔드: `create_star`, `get_constellation_feed`, `send_reaction` RPC를 앱과 연결 가능한 형태로 정교화
- 공통: 감정 태그, 리액션 타입, 넛지 템플릿 문구를 최종 확정
