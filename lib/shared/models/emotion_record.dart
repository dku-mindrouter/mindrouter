class EmotionRecord {
  const EmotionRecord({
    required this.createdAt,
    required this.tagIds,
    required this.tagNames,
  });

  final DateTime createdAt;
  final List<int> tagIds;
  final List<String> tagNames;
}
