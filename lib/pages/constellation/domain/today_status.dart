class TodayStatus {
  const TodayStatus({
    required this.dateLocal,
    required this.hasStarToday,
    required this.todayStarId,
    required this.isStarPublicToday,
    required this.isStarExpiredToday,
    required this.reactionSentCount,
    required this.reactionDailyLimit,
    required this.reactionRemainingCount,
  });

  final DateTime dateLocal;
  final bool hasStarToday;
  final String? todayStarId;
  final bool isStarPublicToday;
  final bool isStarExpiredToday;
  final int reactionSentCount;
  final int reactionDailyLimit;
  final int reactionRemainingCount;

  factory TodayStatus.fromMap(Map<String, dynamic> map) {
    return TodayStatus(
      dateLocal: _asDateTime(map['date_local']),
      hasStarToday: map['has_star_today'] == true,
      todayStarId: map['today_star_id'] as String?,
      isStarPublicToday: map['is_star_public_today'] == true,
      isStarExpiredToday: map['is_star_expired_today'] == true,
      reactionSentCount: (map['reaction_sent_count'] as num?)?.toInt() ?? 0,
      reactionDailyLimit: (map['reaction_daily_limit'] as num?)?.toInt() ?? 20,
      reactionRemainingCount:
          (map['reaction_remaining_count'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid date_local value');
  }
}
