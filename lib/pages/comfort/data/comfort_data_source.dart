abstract class ComfortDataSource {
  Future<dynamic> fetchComfortNotifications({int limit = 30, int offset = 0});

  Future<dynamic> fetchReceivedLetters({int limit = 30, int offset = 0});

  Future<dynamic> fetchReceivedGifts({int limit = 30, int offset = 0});

  Future<dynamic> openLetter({required String letterId});

  Future<dynamic> openGift({required String giftId});
}
