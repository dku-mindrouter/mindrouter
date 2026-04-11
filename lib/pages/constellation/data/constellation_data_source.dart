abstract class ConstellationDataSource {
  Future<dynamic> fetchFeed({
    required String filterName,
    required int limit,
    required int offset,
  });

  Future<dynamic> fetchStarDetail({required String starId});

  Future<dynamic> fetchTodayStatus();

  Future<void> markStarSeen({required String starId, required String userId});
}
