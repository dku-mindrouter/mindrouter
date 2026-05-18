abstract class ReactionDataSource {
  Future<List<Map<String, dynamic>>> fetchReactionTypes();

  Future<dynamic> sendReaction({
    required String starId,
    required int reactionTypeId,
  });

  Future<dynamic> sendLetter({required String starId, required String content});

  Future<dynamic> fetchReactionQuota();

  Future<void> notifyReactionPush({required String reactionId});
}
