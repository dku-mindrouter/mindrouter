class EmotionComposer {
  const EmotionComposer({
    required this.primaryTagId,
    required this.secondaryTagIds,
    required this.content,
  });

  final int primaryTagId;
  final List<int> secondaryTagIds;
  final String content;
}

