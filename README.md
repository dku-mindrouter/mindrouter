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
- `shared/widgets/`에 우주 배경 공통 위젯을 분리해 온보딩과 탭 셸, 프로필 하위 화면이 같은 배경을 재사용합니다.
- Emotion, Constellation, Reaction 일부 흐름은 Supabase RPC와 실제 연결되어 있습니다.
- Comfort/Profile 일부 화면과 홈 인사이트성 문구는 아직 mock/placeholder 상태입니다.
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
- [lib/shared/widgets/space_backdrop.dart](/Users/yuchan/Desktop/git/mindrouter/lib/shared/widgets/space_backdrop.dart)
  우주 배경을 공통 위젯으로 분리해 여러 화면에서 재사용하도록 정리했습니다.
- [docx/](/Users/yuchan/Desktop/git/mindrouter/docx)
  구조 지침, 페이지별 문서, DB 규칙, 리팩토링 검토 메모를 프로젝트 내부 기준 문서로 정리했습니다.
- [test/widget_test.dart](/Users/yuchan/Desktop/git/mindrouter/test/widget_test.dart)
  기존 missing config 부트 화면 스모크 테스트가 계속 유지되도록 검증했습니다.

## 2026-05-16 eomtaemin 대비 변경 요약

비교 기준은 `origin/eomtaemin` 브랜치입니다.

`origin/eomtaemin` 대비 현재 브랜치의 주요 변경 파일은 아래 7개입니다.

- `.gitignore`: 로컬 산출물, Supabase 임시 폴더, 분석 결과물 등이 커밋되지 않도록 정리
- `README.md`: eomtaemin 대비 변경사항과 백엔드 handoff 메모 갱신
- `lib/app/figma_wireframe_experience.dart`: `ConstellationPage`에 현재 `userId`, `isPreviewMode` 전달
- `lib/pages/emotion/presentation/emotion_home_page.dart`: 서버 emotion tag 기준 UI 매핑, 로딩/작성 완료/에러 상태 UX 보강
- `lib/pages/constellation/presentation/constellation_page.dart`: 별자리 feed/detail/reaction 실제 연결, 사진 참고 상세 UI 적용, QA 피드백 반영
- `test/pages/constellation/presentation/constellation_page_test.dart`: preview 별자리 요약 태그 및 상세 다중 태그 표시 검증
- `tool/verify_backend_contract.dart`: Supabase RPC 계약 실연동 검증 도구 추가

핵심은 `eomtaemin`의 Emotion 저장 흐름 위에 Constellation/Reaction 실연동, 백엔드 검증 도구, 그리고 Android QA 후속 UI/UX 보강을 얹은 것입니다.

### 1. Emotion 화면 실제 별 생성 흐름

- `origin/eomtaemin`의 감정 기록 입력 및 별 저장 흐름을 병합했습니다.
- 감정 태그는 서버의 `emotion_tags` 기준으로 조회하고, 사용자는 1~3개 태그를 선택할 수 있습니다.
- 별 생성은 `create_star` RPC로 연결되어 있습니다.
- 이미 오늘 별을 띄운 상태에서는 추가 작성 대신 상태 메시지를 보여줍니다.
- seed 데이터 기준과 UI 감정 버블명이 어긋날 수 있어, 서버 태그명 중심으로 UI 매핑을 정리했습니다.

### 2. 백엔드 계약 검증 도구 추가

- [tool/verify_backend_contract.dart](/Users/yuchan/Desktop/git/mindrouter/tool/verify_backend_contract.dart)를 추가했습니다.
- 검증 대상 RPC는 `docs/api-contract.md` 기준의 핵심 5개입니다.
  - `get_today_status`
  - `create_star`
  - `get_constellation_feed`
  - `get_star_detail`
  - `send_reaction`
- 실제 Supabase anon auth/RLS 환경에서 호출 검증을 수행했고, 현재 기준으로 통과를 확인했습니다.
- 빌드 산출물 및 로컬 임시 파일은 커밋하지 않도록 `.gitignore`를 보강했습니다.

### 3. Constellation 실제 피드 연결

- 별자리 탭은 더 이상 정적 mock 목록만 쓰지 않고 `get_today_status`, `get_constellation_feed`를 호출합니다.
- 필터 칩은 `FeedFilter` 도메인 값과 연결되어 `all/dawn/morning/day/evening/night` 필터를 서버에 전달합니다.
- 목록은 pull-to-refresh와 로딩/빈 상태/에러 상태를 처리합니다.
- 별 위치, 크기, 색상은 현재 프론트에서 시각화합니다.
  - 색상은 감정 선택 화면에서 쓰는 감정 태그 팔레트를 우선 사용합니다.
  - 태그가 여러 개인 별은 해당 태그 중 하나를 안정적으로 골라 색을 정합니다.
  - 크기는 `relation_score`, `reaction_count`를 반영합니다.
- 내가 띄운 별은 `user_id == 현재 사용자 id` 기준으로 판단하며, `내 별` 배지와 분홍색 링으로 별도 표시합니다.
- 여러 감정 태그가 있는 별은 맵에서는 `#첫태그 +N` 형태로 요약하고, 상세 화면에서는 오브와 태그 칩 영역에서 전체 태그를 확인할 수 있습니다.
- 서버 응답에서 `tag_names`가 비어 있을 경우를 대비해, 프론트가 `emotion_tags`를 조회해 `tag_ids`를 태그명으로 보강합니다.

### 4. 별 상세 및 정해진 리액션 전송

- 별을 탭하면 상세 화면으로 진입합니다.
- 상세 진입 시 `get_star_detail`을 호출하고, `star_views`에 읽음 기록을 upsert합니다.
- 리액션 타입은 `reaction_types`에서 조회하며, 화면에는 정해진 4종만 우선 노출합니다.
  - `WARM_TEA`: 따뜻한 차
  - `HUG`: 안아드려요
  - `YOU_DID_WELL`: 고생했어요
  - `WITH_YOU`: 함께해요
- 자유 텍스트 리액션은 제공하지 않습니다.
- 리액션 전송은 `send_reaction` RPC로 연결되어 있고, 성공 후 reaction count를 화면에 반영합니다.
- 내 별, 이미 리액션한 별, 만료/차단/비활성 별 등은 `is_reactable` 기준으로 버튼을 비활성화합니다.

### 5. Android QA 반영 사항

- 별자리 맵의 각 별은 최소 터치 영역을 넓혀 Android에서 손가락으로 누르기 쉽게 조정했습니다.
- 읽음 상태는 더 이상 별도 `읽음` 배지에만 의존하지 않고, 감정 태그 라벨을 회색 톤으로 바꿔 자연스럽게 표현합니다.
- 별자리 노드 배치는 고정 위치만 쓰지 않고, 별 크기와 태그 표시 높이를 고려해 겹침을 줄이는 방식으로 재배치합니다.
- 피드에서는 감정 태그를 모두 나열하지 않고 `#대표태그 +N`으로 요약해 밀도를 낮췄습니다.
- 상세 화면에서는 감정 태그가 3개인 경우 `+1`로 줄이지 않고 3개를 모두 보여줍니다.
- preview 별자리 데이터와 화면 테스트를 통해 다중 태그 표시를 검증합니다.

### 6. 앱 셸 연결 변경

- [lib/app/figma_wireframe_experience.dart](/Users/yuchan/Desktop/git/mindrouter/lib/app/figma_wireframe_experience.dart)에서 `ConstellationPage`에 현재 `userId`와 `isPreviewMode`를 전달합니다.
- Supabase 설정이 없거나 preview mode일 때는 샘플 별자리와 샘플 리액션 타입으로 화면 확인이 가능합니다.
- 실제 Supabase 설정이 있으면 Emotion/Constellation/Reaction의 실제 RPC 흐름을 탑니다.

## 백엔드 담당자 필수 확인 사항

### RPC 응답 계약

- `get_constellation_feed`와 `get_star_detail`은 `tag_ids`뿐 아니라 `tag_names text[]`도 내려주는 것이 문서 기준 계약입니다.
- 현재 프론트에는 `tag_names` 누락 시 `emotion_tags`로 보강하는 fallback을 넣어두었지만, 이는 방어 로직입니다.
- 백엔드에서 `tag_names`를 항상 내려주면 추가 쿼리를 줄이고 UI 표시가 더 안정적입니다.
- 여러 감정 태그를 상세 오브와 하단 칩에 모두 보여주기 때문에, `tag_names` 배열의 순서가 일관되면 프론트 표현도 더 안정적입니다.
- feed/detail 응답에는 최소한 아래 필드가 필요합니다.
  - `star_id`
  - `user_id`
  - `content`
  - `tag_ids`
  - `tag_names`
  - `time_bucket`
  - `reaction_count`
  - `created_at`
  - `expires_at`
  - `relation_score`
  - `is_seen`
  - `visibility_status`
  - `is_deleted`
  - `is_expired`
  - `is_reactable`

### RLS 및 권한

- anon 로그인 사용자가 `get_today_status`, `create_star`, `get_constellation_feed`, `get_star_detail`, `send_reaction`을 호출할 수 있어야 합니다.
- `star_views`는 프론트에서 `viewer_user_id, star_id` 기준으로 upsert합니다.
  - 해당 unique constraint 또는 conflict target이 있어야 합니다.
  - RLS상 현재 사용자가 자기 `viewer_user_id`로 insert/update할 수 있어야 합니다.
- 내 별 판별은 feed/detail의 `user_id`와 현재 auth user id 비교로 합니다. 따라서 작성자 `user_id`가 누락되면 안 됩니다.
- `is_reactable`은 서버 권한 판단의 결과로 내려와야 합니다.
  - 내 별
  - 이미 리액션한 별
  - 만료/삭제된 별
  - 차단/신고 등 정책상 막힌 별
  - 하루 리액션 제한 초과
  위 케이스는 서버에서도 `send_reaction`을 반드시 막아야 합니다.

### Reaction seed

- `reaction_types`에는 프론트가 우선 정렬하는 아래 코드가 active 상태로 있어야 합니다.
  - `WARM_TEA`
  - `HUG`
  - `YOU_DID_WELL`
  - `WITH_YOU`
- `send_reaction`은 `p_star_id`, `p_reaction_type_id`를 받아야 하며, 성공 응답에는 최신 `reaction_count`가 포함되어야 합니다.

### 실제 확인된 이슈/주의점

- 실제 feed에서 `tag_names`가 비어 보이는 케이스가 있었습니다. 프론트 fallback은 들어갔지만 백엔드 RPC 집계 확인이 필요합니다.
- `create_star`는 감정 태그 1~3개와 80자 이하 본문 기준으로 프론트에서 호출합니다. 서버에서도 같은 제약을 검증해야 합니다.
- `get_today_status`의 `has_star_today`, `reaction_remaining_count`, `reaction_daily_limit`은 UI 상태 판단에 직접 사용됩니다.
- 읽음 표시는 `star_views` upsert 성공과 `is_seen` 반영이 맞물려야 자연스럽게 동작합니다. 프론트는 optimistic update를 넣어두었지만, feed/detail 응답의 `is_seen` 값도 일관되게 유지되는 편이 좋습니다.
- service role key나 Supabase access token은 README, 코드, 커밋에 포함하지 않습니다.

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
  - 별 생성은 Emotion 흐름에서 `create_star` RPC로 연결
- Tab Shell
  - 오늘 / 별자리 / 위로 / 나 탭 구조
- Constellation
  - `get_today_status`, `get_constellation_feed`, `get_star_detail`, `star_views` 읽음 처리 연결
  - 상세 화면에서 `reaction_types` 조회 후 `send_reaction` 호출
  - 피드에서는 `#대표태그 +N` 요약, 상세에서는 다중 감정 태그 전체 표시
  - 감정 태그 팔레트 기반 별 색상 적용, 읽음 상태 회색 태그 처리, 겹침 감소 배치 적용
  - preview mode에서는 샘플 star 데이터 사용
- Comfort
  - 받은 위로 목록 시안 포팅
  - 실제 알림/추천 조회 대신 mock 카드 사용
- Profile
  - 오늘의 별 카드, 맞춤 미션 카드, streak/위로 지표, 주간 감정 차트 UI 포팅
  - 프로필 우상단 설정 진입점과 오늘의 맞춤 미션 상세 화면을 Profile 하위 화면으로 연결
  - 설정 화면은 알림/앱 환경/로그아웃/계정 탈퇴 UI를 담고, 미션 화면은 스크린샷 기준의 체크리스트와 CTA를 담습니다
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

- 감정 선택 후 "별 띄우기" 액션은 `create_star` RPC에 연결되어 있습니다.
- 홈 인사이트 카드에 들어갈 스니펫/추천 미션 데이터 소스가 필요합니다.
- 별자리 탭의 feed/detail/reaction 기본 흐름은 연결되어 있습니다.
- 위로 탭에 연결할 mission 또는 comfort 콘텐츠 조회 계약이 필요합니다.
- 따뜻한 차의 별조각/유료 위로 기능은 아직 구현 전이며, 별도 스키마/API 계약이 필요합니다.

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
- 홈 화면의 인사이트 문구는 현재 프론트 하드코딩 상태입니다.
- 별자리 탭의 실제 데이터는 Supabase RPC를 사용하지만, star 배치와 시각화 규칙은 현재 프론트에서 계산합니다.
- 위로 탭의 목록 데이터는 현재 프론트 mock 상태입니다.
- 프로필 탭의 설정/오늘의 맞춤 미션 상세 화면은 현재 프론트 placeholder 및 UI 전용입니다.
- 실제 API 연결 전까지는 UX 검증과 화면 구조 확정용으로 사용합니다.

## Placeholder 상태

- 홈 인사이트/추천 문구: 프론트 static copy
- 별조각/유료 따뜻한 차: 기획 검토 단계, 미구현
- 위로 탭: mock comfort 데이터 기반 목록 상태
- 프로필 탭: 지표/차트는 mock 데이터, auth 결과는 하단 상태 카드 노출
- 프로필 설정/오늘의 미션 화면: 백엔드 연동 없이 프론트 전용 상태

## 참고

- 로컬에 `apps/`, `supabase/.branches/`, `supabase/.temp/` 같은 Git 비관리 폴더가 남아 있을 수 있습니다.
- 이 항목들은 현재 Flutter 프론트 브랜치의 핵심 변경과는 별개입니다.
