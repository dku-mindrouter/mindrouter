import 'nudge_exception.dart';

String mapNudgeErrorCodeToMessage({required String errorCode}) {
  switch (errorCode) {
    case NudgeErrorCode.nudgeNotFound:
      return '오늘의 미션을 찾을 수 없어요.';
    case NudgeErrorCode.unauthorized:
      return '로그인 상태를 다시 확인해 주세요.';
    case NudgeErrorCode.forbidden:
      return '오늘의 미션을 불러올 권한이 없어요.';
    case NudgeErrorCode.invalidArgument:
      return '미션 요청 값이 올바르지 않아요.';
    default:
      return '오늘의 미션을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.';
  }
}
