String mapAppErrorCodeToMessage({required String errorCode}) {
  switch (errorCode) {
    case 'UNAUTHENTICATED':
      return '로그인이 필요해요.';
    case 'SESSION_EXPIRED':
      return '세션이 만료되었어요. 다시 로그인해 주세요.';
    case 'UNAUTHORIZED':
      return '권한이 없어요.';
    case 'FORBIDDEN':
      return '접근이 제한되었어요.';
    case 'INVALID_ARGUMENT':
      return '입력값을 다시 확인해 주세요.';
    case 'STAR_NOT_FOUND':
      return '별을 찾을 수 없어요.';
    case 'DAILY_STAR_LIMIT_EXCEEDED':
      return '오늘은 이미 별을 작성했어요.';
    case 'ALREADY_REACTED':
      return '이미 반응을 보냈어요.';
    case 'DAILY_REACTION_LIMIT_EXCEEDED':
      return '오늘의 반응 한도를 초과했어요.';
    case 'BLOCKED_RELATIONSHIP':
      return '차단된 관계라서 처리할 수 없어요.';
    case 'SELF_REACTION_NOT_ALLOWED':
      return '내가 쓴 글에는 반응할 수 없어요.';
    case 'NUDGE_NOT_FOUND':
      return '널지를 찾을 수 없어요.';
    case 'NUDGE_OUT_OF_WINDOW':
      return '널지 가능 시간이 아니에요.';
    case 'NUDGE_DAILY_LIMIT_EXCEEDED':
      return '오늘의 널지 한도를 초과했어요.';
    default:
      return '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
  }
}
