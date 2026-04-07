import '../../../shared/models/star.dart';

abstract class ConstellationRepository {
  Future<List<Star>> fetchFeed({
    String filterName = 'all',
    int limit = 20,
    int offset = 0,
  });
}

