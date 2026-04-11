import 'reaction_exception.dart';

const int reactionDailyLimit = 20;

final Set<String> _sessionReactionKeys = <String>{};

Future<void> checkReactionTypeAllowed({
  required int reactionTypeId,
  required List<int> activeTypeIds,
}) async {
  final bool isAllowed = activeTypeIds.contains(reactionTypeId);
  if (!isAllowed) {
    throw const ReactionException(ReactionErrorCode.invalidArgument);
  }
}

Future<void> checkDuplicateReaction({
  required String senderUserId,
  required String starId,
}) async {
  final String sender = senderUserId.trim();
  final String star = starId.trim();
  if (sender.isEmpty || star.isEmpty) {
    throw const ReactionException(ReactionErrorCode.invalidArgument);
  }

  final String key = '$sender::$star';
  if (_sessionReactionKeys.contains(key)) {
    throw const ReactionException(ReactionErrorCode.alreadyReacted);
  }
}

Future<void> checkDailyReactionLimit({
  required String senderUserId,
  required DateTime localDate,
}) async {
  final String sender = senderUserId.trim();
  if (sender.isEmpty) {
    throw const ReactionException(ReactionErrorCode.invalidArgument);
  }
  if (localDate.isAfter(DateTime.now().toUtc().add(const Duration(days: 1)))) {
    throw const ReactionException(ReactionErrorCode.invalidArgument);
  }
}

Future<void> checkReactionTargetAllowed({
  required String senderUserId,
  required String starOwnerUserId,
}) async {
  final String sender = senderUserId.trim();
  final String owner = starOwnerUserId.trim();
  if (sender.isEmpty || owner.isEmpty) {
    throw const ReactionException(ReactionErrorCode.invalidArgument);
  }
  if (sender == owner) {
    throw const ReactionException(ReactionErrorCode.selfReactionNotAllowed);
  }
}

void rememberSuccessfulReaction({
  required String senderUserId,
  required String starId,
}) {
  final String sender = senderUserId.trim();
  final String star = starId.trim();
  if (sender.isEmpty || star.isEmpty) {
    return;
  }
  _sessionReactionKeys.add('$sender::$star');
}

void clearReactionPolicySessionCache() {
  _sessionReactionKeys.clear();
}
