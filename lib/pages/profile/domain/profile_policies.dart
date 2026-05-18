import 'profile_exception.dart';
import 'my_stats.dart';

int calculateStreak({
  required List<DateTime> logs,
  required DateTime todayLocal,
}) {
  final List<DateTime> normalizedLogs =
      logs
          .map((DateTime date) => DateTime(date.year, date.month, date.day))
          .toSet()
          .toList(growable: false)
        ..sort((DateTime left, DateTime right) => right.compareTo(left));

  final DateTime normalizedToday = DateTime(
    todayLocal.year,
    todayLocal.month,
    todayLocal.day,
  );

  if (normalizedLogs.isEmpty) {
    return 0;
  }

  final DateTime latestDate = normalizedLogs.first;
  final int gapFromToday = normalizedToday.difference(latestDate).inDays;
  if (gapFromToday > 1) {
    return 0;
  }

  int streak = 1;
  DateTime previousDate = latestDate;

  for (final DateTime currentDate in normalizedLogs.skip(1)) {
    final int difference = previousDate.difference(currentDate).inDays;
    if (difference != 1) {
      break;
    }
    streak += 1;
    previousDate = currentDate;
  }

  return streak;
}

Future<void> checkStatsConsistency({required MyStats stats}) async {
  if (stats.currentStreak < 0 || stats.todayReceivedComfortCount < 0) {
    throw const ProfileException(ProfileErrorCode.statsInconsistent);
  }
}
