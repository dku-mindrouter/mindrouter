import '../models/relation_score_input.dart';

int calculateRelationScore({required RelationScoreInput input}) {
  if (input.isMine) {
    return -1000;
  }

  int score = 0;

  final Set<int> candidateTagSet = input.candidateTagIds.toSet();
  final Set<int> viewerTagSet = input.viewerTagIds.toSet();
  final int sharedTagCount = candidateTagSet.intersection(viewerTagSet).length;
  score += sharedTagCount * 25;

  final Set<String> candidateGroupSet = input.candidateGroups.toSet();
  final Set<String> viewerGroupSet = input.viewerGroups.toSet();
  final int sharedGroupCount =
      candidateGroupSet.intersection(viewerGroupSet).length;
  score += sharedGroupCount * 12;

  if (input.candidateTimeBucket == input.viewerTimeBucket) {
    score += 10;
  }

  final int cappedReactionBonus = input.reactionCount.clamp(0, 20).toInt();
  score += cappedReactionBonus;

  if (input.isSeen) {
    score -= 30;
  }

  return score;
}
