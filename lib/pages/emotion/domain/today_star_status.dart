class TodayStarStatus {
  const TodayStarStatus({
    required this.hasCreatedToday,
    required this.remainingCount,
    required this.latestStarId,
    this.isStarPublicToday = false,
    this.isStarExpiredToday = false,
  });

  final bool hasCreatedToday;
  final int remainingCount;
  final String? latestStarId;
  final bool isStarPublicToday;
  final bool isStarExpiredToday;

  factory TodayStarStatus.fromMap(Map<String, dynamic> map) {
    return TodayStarStatus(
      hasCreatedToday: map['has_star_today'] == true,
      remainingCount: (map['reaction_remaining_count'] as num?)?.toInt() ?? 0,
      latestStarId: map['today_star_id'] as String?,
      isStarPublicToday: map['is_star_public_today'] == true,
      isStarExpiredToday: map['is_star_expired_today'] == true,
    );
  }
}
