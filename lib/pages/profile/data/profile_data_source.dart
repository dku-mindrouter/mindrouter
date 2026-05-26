abstract class ProfileDataSource {
  Future<dynamic> fetchMyStats();

  Future<dynamic> fetchMyStars({int limit = 30, int offset = 0});

  Future<dynamic> fetchAvatarCollection();

  Future<dynamic> equipAvatar({required String userAvatarId});

  Future<dynamic> updateNickname({required String nickname});
}
