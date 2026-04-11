class ViewerContext {
  const ViewerContext({
    required this.viewerUserId,
    required this.blockedUserIds,
    required this.seenStarIds,
    this.viewerTagIds = const <int>[],
    this.viewerTagGroups = const <String>[],
    this.viewerTimeBucket = 'unknown',
  });

  final String viewerUserId;
  final Set<String> blockedUserIds;
  final Set<String> seenStarIds;
  final List<int> viewerTagIds;
  final List<String> viewerTagGroups;
  final String viewerTimeBucket;
}
