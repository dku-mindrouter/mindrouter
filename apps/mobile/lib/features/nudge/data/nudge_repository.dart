import '../../../shared/models/nudge.dart';

abstract class NudgeRepository {
  Future<List<Nudge>> fetchTodayNudges();
}

