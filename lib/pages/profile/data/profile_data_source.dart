abstract class ProfileDataSource {
  Future<dynamic> fetchMyStats();

  Future<dynamic> fetchMyStars({int limit = 30, int offset = 0});
}
