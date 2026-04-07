import '../../../shared/models/emotion_tag.dart';
import '../../../shared/models/mock_data.dart';
import 'emotion_repository.dart';

class MockEmotionRepository implements EmotionRepository {
  @override
  Future<List<EmotionTag>> fetchEmotionTags() async {
    return emotionTags;
  }

  @override
  Future<String> createStar({
    required int primaryTagId,
    required List<int> secondaryTagIds,
    required String content,
  }) async {
    return 'mock-star-id';
  }
}

