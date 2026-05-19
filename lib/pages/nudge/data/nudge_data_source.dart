abstract class NudgeDataSource {
  Future<dynamic> fetchTodayMission({required bool markOpened});

  Future<void> startTodayMission({required String deliveryId});

  Future<void> completeTodayMission({required String deliveryId});
}
