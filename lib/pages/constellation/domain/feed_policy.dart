import 'feed_filter.dart';
import 'star.dart';
import 'star_candidate.dart';
import 'viewer_context.dart';

FeedFilter selectFeedFilter({
  required FeedFilter current,
  required FeedFilter next,
}) {
  if (current == next) {
    return current;
  }
  return next;
}

bool checkFeedVisibility({
  required StarCandidate candidate,
  required ViewerContext viewer,
}) {
  if (candidate.isBlocked ||
      viewer.blockedUserIds.contains(candidate.ownerUserId)) {
    return false;
  }
  if (candidate.isDeleted) {
    return false;
  }

  final DateTime? expiresAt = candidate.expiresAt;
  if (expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc())) {
    return false;
  }

  if (candidate.visibilityStatus != 'public') {
    return false;
  }

  return true;
}

List<Star> sortFeedByRules({required List<Star> stars}) {
  final List<Star> sorted = List<Star>.from(stars);
  sorted.sort((Star a, Star b) {
    final int byRelation = b.relationScore.compareTo(a.relationScore);
    if (byRelation != 0) {
      return byRelation;
    }
    final int byCreatedAt = b.createdAt.compareTo(a.createdAt);
    if (byCreatedAt != 0) {
      return byCreatedAt;
    }
    return a.starId.compareTo(b.starId);
  });
  return sorted;
}

List<Star> applyFeedDiversityPolicy({required List<Star> stars}) {
  if (stars.length < 2) {
    return stars;
  }

  final List<Star> unseen = stars.where((Star star) => !star.isSeen).toList();
  final List<Star> seen = stars.where((Star star) => star.isSeen).toList();

  final List<Star> lowCrowded = unseen
      .where((Star star) => star.reactionCount < _crowdedReactionThreshold)
      .toList();
  final List<Star> crowded = unseen
      .where((Star star) => star.reactionCount >= _crowdedReactionThreshold)
      .toList();

  final List<Star> diversified = _limitConsecutiveGroup(lowCrowded);
  return <Star>[...diversified, ...crowded, ...seen];
}

List<Star> _limitConsecutiveGroup(List<Star> stars) {
  if (stars.length < 2) {
    return stars;
  }

  final List<Star> queue = List<Star>.from(stars);
  final List<Star> result = <Star>[];
  String? lastGroup;
  int streak = 0;

  while (queue.isNotEmpty) {
    final int nextIndex = queue.indexWhere((Star star) {
      if (lastGroup == null) {
        return true;
      }
      final bool sameGroup = star.diversityKey == lastGroup;
      return !(sameGroup && streak >= _maxSameGroupStreak);
    });

    final int indexToTake = nextIndex >= 0 ? nextIndex : 0;
    final Star selected = queue.removeAt(indexToTake);
    result.add(selected);

    if (selected.diversityKey == lastGroup) {
      streak += 1;
    } else {
      lastGroup = selected.diversityKey;
      streak = 1;
    }
  }

  return result;
}

const int _maxSameGroupStreak = 3;
const int _crowdedReactionThreshold = 20;
