class DailyQuota {
  const DailyQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.isStarPublicToday,
    required this.isStarExpiredToday,
  });

  final int used;
  final int limit;
  final int remaining;
  final bool isStarPublicToday;
  final bool isStarExpiredToday;

  factory DailyQuota.fromMap(Map<String, dynamic> map) {
    final int parsedUsed = (map['reaction_sent_count'] as num?)?.toInt() ?? 0;
    final int parsedLimit =
        (map['reaction_daily_limit'] as num?)?.toInt() ?? 20;
    final int parsedRemaining =
        (map['reaction_remaining_count'] as num?)?.toInt() ??
        (parsedLimit - parsedUsed);

    return DailyQuota(
      used: parsedUsed,
      limit: parsedLimit,
      remaining: parsedRemaining < 0 ? 0 : parsedRemaining,
      isStarPublicToday: map['is_star_public_today'] == true,
      isStarExpiredToday: map['is_star_expired_today'] == true,
    );
  }
}
