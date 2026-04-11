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
    default:
      return mapAppErrorCodeToMessage(
        errorCode: ReactionErrorCode.internalError,
      );
  }
}
