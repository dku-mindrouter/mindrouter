class MyStats {
  const MyStats({
    required this.dateLocal,
    required this.currentStreak,
    required this.todayReceivedComfortCount,
    required this.avatarNameKo,
    required this.avatarLevel,
    required this.avatarXp,
    required this.avatarLevelTitleKo,
    required this.avatarCurrentLevelXp,
    required this.avatarNextLevelXp,
  });

  final DateTime dateLocal;
  final int currentStreak;
  final int todayReceivedComfortCount;
  final String avatarNameKo;
  final int avatarLevel;
  final int avatarXp;
  final String avatarLevelTitleKo;
  final int avatarCurrentLevelXp;
  final int avatarNextLevelXp;

  static const int nextBadgeGoal = 10;

  static const int maxAvatarLevel = 10;

  int get avatarLevelRange {
    return avatarNextLevelXp - avatarCurrentLevelXp;
  }

  int get avatarXpInCurrentLevel {
    return (avatarXp - avatarCurrentLevelXp).clamp(0, avatarLevelRange);
  }

  int get avatarRemainingXp {
    if (avatarLevel >= maxAvatarLevel || avatarLevelRange <= 0) {
      return 0;
    }
    return (avatarNextLevelXp - avatarXp).clamp(0, avatarNextLevelXp);
  }

  double get avatarLevelProgress {
    if (avatarLevel >= maxAvatarLevel || avatarLevelRange <= 0) {
      return 1;
    }
    return (avatarXpInCurrentLevel / avatarLevelRange).clamp(0, 1).toDouble();
  }

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
      avatarNameKo: '달토끼',
      avatarLevel: 4,
      avatarXp: 360,
      avatarLevelTitleKo: '자라나는 빛',
      avatarCurrentLevelXp: 320,
      avatarNextLevelXp: 500,
    );
  }
}
