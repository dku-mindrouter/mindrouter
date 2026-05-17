import '../../../shared/features/relation_score.dart' as shared_relation_score;
import '../../../shared/features/emotion_group_mapper.dart';
import '../../../shared/models/relation_score_input.dart';
import 'star_candidate.dart';
import 'viewer_context.dart';

int calculateRelationScore({
  required StarCandidate candidate,
  required ViewerContext viewer,
}) {
  final List<String> candidateGroups = candidate.tagIds
      .map(_mapTagIdToEmotionGroup)
      .toList(growable: false);

  final RelationScoreInput input = RelationScoreInput(
    candidateTagIds: candidate.tagIds,
    viewerTagIds: viewer.viewerTagIds,
    candidateGroups: candidateGroups,
    viewerGroups: viewer.viewerTagGroups,
    candidateTimeBucket: candidate.timeBucket,
    viewerTimeBucket: viewer.viewerTimeBucket,
    isSeen: viewer.seenStarIds.contains(candidate.starId),
    reactionCount: candidate.reactionCount,
    isMine: candidate.ownerUserId == viewer.viewerUserId,
  );
  return shared_relation_score.calculateRelationScore(input: input);
}

String _mapTagIdToEmotionGroup(int tagId) {
  return mapEmotionGroup(tagNameKo: _emotionTagDictionary[tagId] ?? '');
}

const Map<int, String> _emotionTagDictionary = <int, String>{
  1: '불안함',
  2: '우울함',
  3: '지침/무기력',
  4: '예민함/짜증',
  5: '평온함/잔잔함',
  6: '기대감/활력',
};
