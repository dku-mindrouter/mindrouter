class DailyLog {
  const DailyLog({
    required this.date,
    required this.starCreated,
    required this.reactionSentCount,
    required this.nudgeOpened,
  });

  final DateTime date;
  final bool starCreated;
  final int reactionSentCount;
  final bool nudgeOpened;
}
