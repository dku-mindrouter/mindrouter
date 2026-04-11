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
  1: '공허함',
  2: '지침',
  3: '무기력',
  4: '외로움',
  5: '번아웃',
  6: '불안',
  7: '답답함',
  8: '잔잔함',
  9: '안도',
  10: '위로받고 싶음',
};
