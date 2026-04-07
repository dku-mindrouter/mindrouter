import '../../../shared/models/my_stats.dart';

abstract class ProfileRepository {
  Future<MyStats> fetchMyStats();
}

