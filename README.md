# MindfulConnect

`features/auth-emotion-stellation` 브랜치를 기준으로 프론트 작업을 이어가기 위해 정리한 Flutter 앱 워크스페이스입니다.

현재 프론트 작업 기준 브랜치는 `feature/frontend-app-shell`입니다.

## 현재 상태

- 앱이 최소 부팅 가능한 상태로 정리되어 있습니다.
- 프론트 시작점을 안전하게 잡기 위한 안정화 작업이 반영되어 있습니다.
- 백엔드 계약은 [docs/api-contract.md](/Users/yuchan/Desktop/git/mindrouter/docs/api-contract.md) 기준을 따릅니다.
- 백엔드 전달 사항은 [docs/backend-handoff.md](/Users/yuchan/Desktop/git/mindrouter/docs/backend-handoff.md)에 정리되어 있습니다.

검증 완료 항목:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

디버그 APK 결과물:

- [build/app/outputs/flutter-apk/app-debug.apk](/Users/yuchan/Desktop/git/mindrouter/build/app/outputs/flutter-apk/app-debug.apk)

## 이번에 정리한 내용

- [lib/main.dart](/Users/yuchan/Desktop/git/mindrouter/lib/main.dart)
  현재 브랜치에서 바로 실행 가능한 최소 앱 셸로 교체했습니다.
- [test/widget_test.dart](/Users/yuchan/Desktop/git/mindrouter/test/widget_test.dart)
  새 부트 화면 기준으로 스모크 테스트를 맞췄습니다.
- [analysis_options.yaml](/Users/yuchan/Desktop/git/mindrouter/analysis_options.yaml)
  예전 브랜치에서 남은 `apps/**` 같은 로컬 잔재가 분석기를 깨지 않도록 제외했습니다.

## 로컬 실행

```bash
flutter pub get
flutter run
```

검증 명령:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## 작업 범위

현재 브랜치는 프론트 시작점 정리에 집중한 상태입니다.

- `supabase/` 내부 마이그레이션은 수정하지 않았습니다.
- 백엔드 계약 문서는 직접 변경하지 않았습니다.
- 아직 실제 Supabase 초기화와 auth 진입 흐름은 연결하지 않았습니다.

## 다음 작업

1. Supabase 초기화 연결
2. anonymous auth 진입 흐름 연결
3. 최소 라우팅 흐름 구성
4. 임시 부트 화면을 실제 화면으로 교체

## 참고

- 로컬에 `apps/`, `supabase/.branches/`, `supabase/.temp/` 같은 Git 비관리 폴더가 남아 있을 수 있습니다.
- 이 항목들은 현재 브랜치의 핵심 프론트 코드와는 별개입니다.
