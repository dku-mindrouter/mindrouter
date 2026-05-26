abstract class NudgeDataSource {
  Future<dynamic> fetchTodayMission({
    required bool markOpened,
    String? selectedEmotionProfile,
  });

  Future<void> startTodayMission({required String deliveryId});

  Future<void> completeTodayMission({required String deliveryId});
}
