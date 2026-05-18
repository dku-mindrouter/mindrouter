class MyStats {
  const MyStats({
    required this.dateLocal,
    required this.currentStreak,
    required this.todayReceivedComfortCount,
  });

  final DateTime dateLocal;
  final int currentStreak;
  final int todayReceivedComfortCount;

  static const int nextBadgeGoal = 10;

  double get nextBadgeProgress {
    if (nextBadgeGoal <= 0) {
      return 0;
    }
    return (currentStreak / nextBadgeGoal).clamp(0, 1).toDouble();
  }

  factory MyStats.previewMock() {
    return MyStats(
      dateLocal: DateTime.now(),
      currentStreak: 7,
      todayReceivedComfortCount: 3,
    );
  }
}
