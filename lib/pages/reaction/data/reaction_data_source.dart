import 'dart:typed_data';

abstract class ReactionDataSource {
  Future<List<Map<String, dynamic>>> fetchReactionTypes();

  Future<dynamic> sendReaction({
    required String starId,
    required int reactionTypeId,
    String? giftImageUrl,
  });

  Future<String> uploadCoffeeGiftImage({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  });

  Future<dynamic> sendLetter({required String starId, required String content});

  Future<dynamic> fetchReactionQuota();

  Future<void> notifyReactionPush({required String reactionId});
}
