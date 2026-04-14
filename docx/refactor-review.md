# Refactor Review

현재 프로젝트는 새 구조 기준과 비교했을 때 "부분 정렬 상태"다.

## 이미 잘 맞는 부분

- `lib/pages/auth/data`, `lib/pages/auth/domain`
- `lib/pages/emotion/data`, `lib/pages/emotion/domain`
- `lib/pages/constellation/data`, `lib/pages/constellation/domain`
- `lib/pages/reaction/data`, `lib/pages/reaction/domain`
- `lib/shared/features/data`
- `lib/shared/models`

즉, data/domain 분리는 이미 상당 부분 진행되어 있다.

## 기준과 다른 부분

### 1. presentation 레이어 부재

- 현재 `lib/pages/*/presentation/` 폴더가 없다.
- 화면 코드는 주로 아래 파일에 모여 있다.
  - `lib/main.dart`
  - `lib/app/figma_wireframe_experience.dart`

새 기준에 맞추려면 페이지별 화면 코드를 각 `presentation/` 폴더로 이동해야 한다.

### 2. shared/widgets 부재

- 현재 공통 UI 컴포넌트를 위한 `lib/shared/widgets/` 폴더가 없다.
- 반복 사용되는 화면 조각은 추후 `shared/widgets/`로 분리하는 것이 맞다.

### 3. utils 부재

- 현재 프로젝트 범용 유틸을 위한 `lib/utils/` 또는 루트 `utils/` 폴더가 없다.
- 프로젝트 전반에서 재사용 가능한 순수 유틸 함수는 별도 utils 계층으로 정리할 필요가 있다.

### 4. 문서상 존재하는 페이지 중 미구현 영역 존재

- 문서에는 `nudge`, `profile`, `safety`가 정의돼 있다.
- 현재 `lib/pages/`에는 해당 페이지 폴더가 없다.

즉, 이 문서들은 앞으로 구현 또는 확장 시 기준 문서로 쓰면 된다.

## 권장 리팩토링 순서

1. `presentation/` 레이어 생성
   - `lib/main.dart`와 `lib/app/figma_wireframe_experience.dart`의 화면 코드를 페이지별 `presentation/`으로 분리
2. 공통 위젯 추출
   - 반복되는 UI를 `lib/shared/widgets/`로 이동
3. 범용 유틸 정리
   - 페이지/도메인에 직접 속하지 않는 순수 유틸을 `utils/`로 이동
4. 문서-코드 시그니처 정합성 점검
   - 각 repository/data source 함수명이 `docx/*.md`, `docs/api-contract.md`와 일치하는지 확인
5. 미구현 페이지 확장
   - `nudge`, `profile`, `safety`를 문서 기준으로 신규 추가

## 작업 원칙

- 앞으로는 리팩토링이나 기능 추가 시 `docx/project-structure-guide.md`를 1차 기준으로 참고한다.
- API 및 RPC 계약은 `docs/api-contract.md`를 함께 본다.
- 데이터 구조와 제약은 `docx/db.md`를 함께 본다.
