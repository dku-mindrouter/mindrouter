import '../../../shared/features/error_message_mapper.dart';
import 'reaction_exception.dart';

String mapReactionErrorCodeToMessage({required String errorCode}) {
  switch (errorCode) {
    case ReactionErrorCode.alreadyReacted:
    case ReactionErrorCode.dailyReactionLimitExceeded:
    case ReactionErrorCode.selfReactionNotAllowed:
    case ReactionErrorCode.blockedRelationship:
    case ReactionErrorCode.starNotFound:
    case ReactionErrorCode.unauthorized:
    case ReactionErrorCode.forbidden:
    case ReactionErrorCode.invalidArgument:
    case ReactionErrorCode.internalError:
      return mapAppErrorCodeToMessage(errorCode: errorCode);
    case ReactionErrorCode.letterBlockedByModeration:
      return '상대방이 상처받을 수 있는 내용이라 편지를 보낼 수 없어요.';
    case ReactionErrorCode.letterModerationUnavailable:
      return 'LLM 검수 사용량이 부족하거나 일시적으로 사용할 수 없어 편지를 보낼 수 없어요.';
    default:
      return mapAppErrorCodeToMessage(
        errorCode: ReactionErrorCode.internalError,
      );
  }
}
