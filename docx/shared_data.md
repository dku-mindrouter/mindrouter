- 본 문서는 shared/features/data 세부 개발 문서이다.

- data 공통 제공 함수
  - Future<T> executeRpcWithErrorMapping<T>({required String rpcName, required Map<String, dynamic> params, required T Function(dynamic raw) mapper})
    - 설명: RPC/쿼리 호출 + 에러코드 매핑
    - 반환: T

  - Future<T> executeWithErrorMapping<T>({required Future<T> Function() action})
    - 설명: non-RPC 호출 + 에러코드 매핑
    - 반환: T

  - Future<T> withRetry<T>({required Future<T> Function() task, int maxRetryCount = 2, Duration delay = const Duration(milliseconds: 80), bool Function(Object error)? shouldRetry})
    - 설명: 재시도 래퍼
    - 반환: T

  - String parsePostgrestErrorCode({required dynamic error})
    - 설명: PostgrestException에서 고정 에러코드 추출
    - 반환: String
    - 파싱 우선순위: `error.code` -> `error.details.APP_ERROR_CODE` -> `error.message` 패턴 -> 기본값 `INTERNAL_ERROR`

- 트랜잭션 경계 규칙
  - insert + counter update + log update 같은 다중 쓰기는 RPC 내부 트랜잭션으로 처리한다.
  - data 레이어에서 다중 쓰기를 분산 호출로 처리하지 않는다.
