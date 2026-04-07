import '../../../shared/models/emotion_tag.dart';

abstract class EmotionRepository {
  Future<List<EmotionTag>> fetchEmotionTags();
}

