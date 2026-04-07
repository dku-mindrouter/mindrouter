class Star {
  const Star({
    required this.id,
    required this.primaryTag,
    required this.content,
    required this.timeBucket,
    required this.reactionCount,
    required this.relationScore,
    required this.createdAt,
  });

  final String id;
  final String primaryTag;
  final String content;
  final String timeBucket;
  final int reactionCount;
  final int relationScore;
  final DateTime createdAt;
}

