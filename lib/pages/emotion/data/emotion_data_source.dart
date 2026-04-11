abstract class EmotionDataSource {
  Future<List<Map<String, dynamic>>> fetchEmotionTags();

  Future<dynamic> createStar({
    required String content,
    required List<int> tagIds,
    required String timeBucket,
    required String visibilityStatus,
    int? emotionIntensity,
    DateTime? expiresAt,
  });

  Future<dynamic> fetchTodayStarStatus();
}
