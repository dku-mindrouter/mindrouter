# MindfulConnect

`feature/figma-wireframe-porting` 브랜치에서 Figma 와이어프레임을 Flutter 앱에 옮기고, 페이지 중심 구조로 리팩토링 중인 프론트 워크스페이스입니다.

기준 프로젝트는 Flutter 모바일 앱이며, 현재 목표는 Figma 시안의 첫 진입 경험을 실제 앱 UI로 안전하게 포팅하면서 아래 구조 규칙을 코드베이스에 반영하는 것입니다.

```text
utils/
shared/
pages/
  (names of pages)/
    data/
    domain/
    presentation/
```

- `data/`: 데이터베이스 및 API 통신
- `domain/`: 비즈니스 규칙, 알고리즘, 정책
- `presentation/`: 화면 구성
- `shared/features/`: 여러 페이지에서 쓰는 공통 기능 로직
- `shared/widgets/`: 여러 페이지에서 쓰는 공통 UI 위젯
- `shared/models/`: 여러 페이지에서 쓰는 공통 모델
- `utils/`: 프로젝트 전반에서 재사용 가능한 범용 유틸

## 현재 상태

- Supabase 부트스트랩과 익명 auth 진입 흐름은 유지하고 있습니다.
- Supabase 설정이 없을 때도 프론트 확인용 preview mode로 바로 진입할 수 있습니다.
- `ready` 상태 이후 임시 완료 화면 대신 Figma 시안 기반 UI를 붙였습니다.
- 온보딩 3단계와 기본 탭 셸이 Flutter로 포팅되어 있습니다.
- auth, emotion, constellation, comfort, profile 화면이 각 페이지의 `presentation/`으로 분리되어 있습니다.
- `shared/widgets/`에 첫 공통 UI 위젯(`AppPanelCard`)을 추가했습니다.
- 아직 실제 데이터 조회/저장 연결은 들어가지 않았고 일부 인터랙션은 placeholder 상태입니다.
- 백엔드 계약은 [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md) 기준을 따릅니다.
- 백엔드 전달 사항 원본은 [docs/backend-handoff.md](/Users/yuchan/Desktop/git/mindrouter/docs/backend-handoff.md)에 있습니다.
- 구조 및 페이지별 개발 지침은 [docx/](/Users/yuchan/Desktop/git/mindrouter/docx) 폴더를 우선 참고합니다.

## 이번 브랜치에서 반영한 내용

- [lib/main.dart](/Users/yuchan/Desktop/git/mindrouter/lib/main.dart)
  앱 엔트리만 담당하도록 정리했고, auth 진입 UI는 페이지 presentation으로 분리했습니다.
- [lib/app/figma_wireframe_experience.dart](/Users/yuchan/Desktop/git/mindrouter/lib/app/figma_wireframe_experience.dart)
  온보딩과 탭 셸 중심으로 정리했고, 페이지 화면은 각 `presentation/` 파일을 조립하도록 바꿨습니다.
- [lib/pages/](/Users/yuchan/Desktop/git/mindrouter/lib/pages)
  `auth`, `emotion`, `constellation`, `comfort`, `profile`, `reaction` 기준으로 페이지 구조를 정리했습니다.
- [lib/shared/widgets/app_panel_card.dart](/Users/yuchan/Desktop/git/mindrouter/lib/shared/widgets/app_panel_card.dart)
  반복되는 카드 박스 스타일을 공통 위젯으로 추출했습니다.
- [docx/](/Users/yuchan/Desktop/git/mindrouter/docx)
  구조 지침, 페이지별 문서, DB 규칙, 리팩토링 검토 메모를 프로젝트 내부 기준 문서로 정리했습니다.
- [test/widget_test.dart](/Users/yuchan/Desktop/git/mindrouter/test/widget_test.dart)
  기존 missing config 부트 화면 스모크 테스트가 계속 유지되도록 검증했습니다.

## 문서 우선순위

작업 시 아래 순서로 문서를 확인합니다.

1. [docx/project-structure-guide.md](/Users/yuchan/Desktop/git/mindrouter/docx/project-structure-guide.md)
2. 관련 페이지 문서 (`docx/auth.md`, `docx/emotion.md`, `docx/constellation.md` 등)
3. [docx/db.md](/Users/yuchan/Desktop/git/mindrouter/docx/db.md)
4. [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md)
5. [docs/backend-handoff.md](/Users/yuchan/Desktop/git/mindrouter/docs/backend-handoff.md)

## 현재 구조

- [lib/pages/auth](/Users/yuchan/Desktop/git/mindrouter/lib/pages/auth)
- [lib/pages/emotion](/Users/yuchan/Desktop/git/mindrouter/lib/pages/emotion)
- [lib/pages/constellation](/Users/yuchan/Desktop/git/mindrouter/lib/pages/constellation)
- [lib/pages/comfort](/Users/yuchan/Desktop/git/mindrouter/lib/pages/comfort)
- [lib/pages/profile](/Users/yuchan/Desktop/git/mindrouter/lib/pages/profile)
- [lib/pages/reaction](/Users/yuchan/Desktop/git/mindrouter/lib/pages/reaction)
- [lib/shared/features](/Users/yuchan/Desktop/git/mindrouter/lib/shared/features)
- [lib/shared/models](/Users/yuchan/Desktop/git/mindrouter/lib/shared/models)
- [lib/shared/widgets](/Users/yuchan/Desktop/git/mindrouter/lib/shared/widgets)
- [lib/utils](/Users/yuchan/Desktop/git/mindrouter/lib/utils)

## 로컬 실행

```bash
flutter pub get
flutter run
```

Supabase 값 없이 실행하면 preview mode로 진입합니다.
실제 auth/Supabase 연동까지 확인하려면 `--dart-define=SUPABASE_URL=...` 와 `--dart-define=SUPABASE_ANON_KEY=...` 를 함께 넣어 실행하면 됩니다.

검증 명령:

```bash
flutter analyze
flutter test
```

## 현재 UI 범위

- Onboarding
  - Figma 시안의 분위기와 동선을 반영한 3-step 진입 화면
  - 실제 회원가입 UI 대신 현재 개발 단계 설명과 진입 목적을 보여주는 형태로 조정
- Home
  - 감정 구슬 선택 인터랙션
  - 선택 결과에 따른 인사이트 카드
  - 실제 저장/전송 대신 placeholder snackbar 처리
- Tab Shell
  - 오늘 / 별자리 / 위로 / 나 탭 구조
- Constellation
  - 필터 칩과 은하수 캔버스 형태의 시안 UI 포팅
  - 실제 피드/상세 연결 대신 mock star 데이터 사용
- Comfort
  - 받은 위로 목록 시안 포팅
  - 실제 알림/추천 조회 대신 mock 카드 사용
- Profile
  - 오늘의 별 카드, 맞춤 미션 카드, streak/위로 지표, 주간 감정 차트 UI 포팅
  - auth 결과값은 하단 상태 카드로 유지

## 검증

```bash
flutter analyze
flutter test
```

현재 기준으로 `analyze`와 `test`는 통과 상태입니다.

## 프론트 작업 원칙

- 이 브랜치에서는 프론트 범위만 수정합니다.
- `supabase/` 내부 마이그레이션이나 백엔드 스키마는 직접 수정하지 않습니다.
- 백엔드 미구현 영역은 mock, placeholder, static copy로 처리합니다.
- 매 푸시마다 백엔드 연결 필요 사항과 handoff 메모를 함께 남깁니다.

## 백엔드 연결 필요 사항

- 감정 선택 후 "별 띄우기" 액션을 실제 emotion 생성 API 또는 RPC에 연결해야 합니다.
- 홈 인사이트 카드에 들어갈 스니펫/추천 미션 데이터 소스가 필요합니다.
- 별자리 탭에 연결할 constellation feed 조회 흐름이 필요합니다.
- 위로 탭에 연결할 mission 또는 comfort 콘텐츠 조회 계약이 필요합니다.

## 계약 확인 필요

- 감정 선택 결과를 저장할 때 필요한 request shape
  - 감정 태그 배열만 보내는지
  - 자유 텍스트 본문도 함께 보내는지
  - time bucket은 서버 계산인지 클라이언트 계산인지
- 홈에서 받아올 "심리 스니펫" 데이터의 응답 구조
- 위로/미션 추천 데이터의 노출 우선순위와 fallback 정책
- constellation feed 초기 진입 시 필요한 최소 필드 집합

## Handoff 메모

- 현재 온보딩은 실제 계정 생성 화면이 아니라, 익명 auth 기반 현재 개발 단계를 설명하는 프론트용 UI입니다.
- Supabase 설정이 없으면 preview mode의 mock 사용자(`preview_guest`)로 화면을 바로 확인할 수 있습니다.
- Figma 시안의 회원가입 입력창은 그대로 연결하지 않았습니다.
- 홈 화면의 감정 선택 조합과 인사이트 문구는 현재 프론트 하드코딩 상태입니다.
- 별자리 탭의 star 배치와 위로 탭의 목록 데이터는 현재 프론트 mock 상태입니다.
- 실제 API 연결 전까지는 UX 검증과 화면 구조 확정용으로 사용합니다.

## Placeholder 상태

- 별 띄우기 버튼: snackbar만 표시
- 별자리 탭: mock star 데이터 기반 상세 미연결 상태
- 위로 탭: mock comfort 데이터 기반 목록 상태
- 프로필 탭: 지표/차트는 mock 데이터, auth 결과는 하단 상태 카드 노출

## 참고

- 로컬에 `apps/`, `supabase/.branches/`, `supabase/.temp/` 같은 Git 비관리 폴더가 남아 있을 수 있습니다.
- 이 항목들은 현재 Flutter 프론트 브랜치의 핵심 변경과는 별개입니다.
