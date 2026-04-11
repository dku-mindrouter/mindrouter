import 'star.dart';

class StarCandidate {
  const StarCandidate({
    required this.starId,
    required this.ownerUserId,
    required this.tagIds,
    required this.timeBucket,
    required this.reactionCount,
    required this.isDeleted,
    required this.isBlocked,
    required this.expiresAt,
    required this.visibilityStatus,
    required this.diversityKey,
  });

  final String starId;
  final String ownerUserId;
  final List<int> tagIds;
  final String timeBucket;
  final int reactionCount;
  final bool isDeleted;
  final bool isBlocked;
  final DateTime? expiresAt;
  final String visibilityStatus;
  final String diversityKey;

  factory StarCandidate.fromStar({
    required Star star,
    required bool isBlocked,
  }) {
    return StarCandidate(
      starId: star.starId,
      ownerUserId: star.userId,
      tagIds: star.tagIds,
      timeBucket: star.timeBucket,
      reactionCount: star.reactionCount,
      isDeleted: star.isDeleted,
      isBlocked: isBlocked,
      expiresAt: star.expiresAt,
      visibilityStatus: star.visibilityStatus,
      diversityKey: star.diversityKey,
    );
  }
}
