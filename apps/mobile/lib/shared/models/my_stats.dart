class MyStats {
  const MyStats({
    required this.streakDays,
    required this.receivedReactionCount,
    required this.recentEmotionCounts,
  });

  final int streakDays;
  final int receivedReactionCount;
  final Map<String, int> recentEmotionCounts;
}

