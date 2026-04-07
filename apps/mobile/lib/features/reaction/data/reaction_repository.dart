abstract class ReactionRepository {
  Future<void> sendReaction({
    required String starId,
    required int reactionTypeId,
  });
}

