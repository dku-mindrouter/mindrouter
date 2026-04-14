# Project Structure Guide

다음은 프로젝트 전반에 적용하는 폴더 구조 기준이다. 모든 개발 지시에서 이 규칙을 우선 참고한다.

## 기본 폴더 구성

```text
utils/
shared/
pages/
  (names of pages)/
    data/
    domain/
    presentation/
```

## 레이어 역할

- `pages/*/data/`
  - 데이터베이스와의 통신을 담당한다.
- `pages/*/domain/`
  - 실질적인 알고리즘과 기능 구현을 담당한다.
- `pages/*/presentation/`
  - 화면 구성을 담당한다.

## 공통 코드 배치 규칙

- 기능인데 여러 페이지에 중복으로 사용될 경우 `shared/features/`에 추가한다.
  - 각 페이지의 `domain/` 속 파일이 이를 임포트한다.
- 위젯 등 프론트 구현에 필요한 코드인데 여러 페이지에 중복 사용될 경우 `shared/widgets/` 등에 추가한다.
  - 각 페이지의 `presentation/` 속 파일이 이를 임포트한다.
- 모델인데 여러 페이지에서 중복으로 사용될 경우 `shared/models/`에 추가한다.
  - 여러 파일에서 이를 임포트한다.

## 범용 재사용 코드

- 어떤 프로젝트에서든 사용할 수 있는 재사용 코드는 `utils/`에 추가한다.

## 리팩토링 기준

- 페이지별 코드가 `data`, `domain`, `presentation` 책임을 넘나들면 해당 레이어로 분리한다.
- 여러 페이지에 중복되는 도메인 로직은 `shared/features/`로 승격한다.
- 여러 페이지에 중복되는 UI 코드는 `shared/widgets/`로 승격한다.
- 여러 페이지가 공유하는 모델은 `shared/models/`로 이동한다.
- 프로젝트 범용 유틸은 `utils/`로 이동한다.
