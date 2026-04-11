abstract class ReactionDataSource {
  Future<List<Map<String, dynamic>>> fetchReactionTypes();

  Future<dynamic> sendReaction({
    required String starId,
    required int reactionTypeId,
  });

  Future<dynamic> fetchReactionQuota();
}
