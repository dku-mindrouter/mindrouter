class RelationScoreInput {
  const RelationScoreInput({
    required this.candidateTagIds,
    required this.viewerTagIds,
    required this.candidateGroups,
    required this.viewerGroups,
    required this.candidateTimeBucket,
    required this.viewerTimeBucket,
    required this.isSeen,
    required this.reactionCount,
    required this.isMine,
  });

  final List<int> candidateTagIds;
  final List<int> viewerTagIds;
  final List<String> candidateGroups;
  final List<String> viewerGroups;
  final String candidateTimeBucket;
  final String viewerTimeBucket;
  final bool isSeen;
  final int reactionCount;
  final bool isMine;
}
