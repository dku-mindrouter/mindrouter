import '../../../shared/models/emotion_tag.dart';

abstract class EmotionRepository {
  Future<List<EmotionTag>> fetchEmotionTags();
  Future<String> createStar({
    required int primaryTagId,
    required List<int> secondaryTagIds,
    required String content,
  });
}

