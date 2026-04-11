import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/constellation/domain/feed_filter.dart';
import 'package:mindfulconnect/pages/constellation/domain/feed_policy.dart';
import 'package:mindfulconnect/pages/constellation/domain/relation_score_policy.dart';
import 'package:mindfulconnect/pages/constellation/domain/star.dart';
import 'package:mindfulconnect/pages/constellation/domain/star_candidate.dart';
import 'package:mindfulconnect/pages/constellation/domain/viewer_context.dart';

void main() {
  group('Constellation domain policies', () {
    test('selectFeedFilter returns next filter', () {
      final FeedFilter selected = selectFeedFilter(
        current: FeedFilter.all,
        next: FeedFilter.morning,
      );
      expect(selected, FeedFilter.morning);
    });

    test('parseFeedFilter falls back to all on invalid input', () {
      expect(parseFeedFilter('unknown'), FeedFilter.all);
      expect(parseFeedFilter('night'), FeedFilter.night);
    });

    test('checkFeedVisibility excludes blocked, deleted, expired, hidden', () {
      const ViewerContext viewer = ViewerContext(
        viewerUserId: 'me',
        blockedUserIds: <String>{'blocked-user'},
        seenStarIds: <String>{},
      );

      final DateTime future = DateTime.now().toUtc().add(
        const Duration(hours: 2),
      );
      final DateTime past = DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      );

      final StarCandidate visible = StarCandidate(
        starId: 's1',
        ownerUserId: 'other',
        tagIds: const <int>[1],
        timeBucket: 'night',
        reactionCount: 1,
        isDeleted: false,
        isBlocked: false,
        expiresAt: future,
        visibilityStatus: 'public',
        diversityKey: 'a',
      );

      expect(checkFeedVisibility(candidate: visible, viewer: viewer), isTrue);
      expect(
        checkFeedVisibility(
          candidate: StarCandidate(
            starId: 's2',
            ownerUserId: 'blocked-user',
            tagIds: const <int>[1],
            timeBucket: 'night',
            reactionCount: 1,
            isDeleted: false,
            isBlocked: false,
            expiresAt: future,
            visibilityStatus: 'public',
            diversityKey: 'a',
          ),
          viewer: viewer,
        ),
        isFalse,
      );
      expect(
        checkFeedVisibility(
          candidate: StarCandidate(
            starId: 's3',
            ownerUserId: 'other',
            tagIds: const <int>[1],
            timeBucket: 'night',
            reactionCount: 1,
            isDeleted: true,
            isBlocked: false,
            expiresAt: future,
            visibilityStatus: 'public',
            diversityKey: 'a',
          ),
          viewer: viewer,
        ),
        isFalse,
      );
      expect(
        checkFeedVisibility(
          candidate: StarCandidate(
            starId: 's4',
            ownerUserId: 'other',
            tagIds: const <int>[1],
            timeBucket: 'night',
            reactionCount: 1,
            isDeleted: false,
            isBlocked: false,
            expiresAt: past,
            visibilityStatus: 'public',
            diversityKey: 'a',
          ),
          viewer: viewer,
        ),
        isFalse,
      );
      expect(
        checkFeedVisibility(
          candidate: StarCandidate(
            starId: 's5',
            ownerUserId: 'other',
            tagIds: const <int>[1],
            timeBucket: 'night',
            reactionCount: 1,
            isDeleted: false,
            isBlocked: false,
            expiresAt: future,
            visibilityStatus: 'private',
            diversityKey: 'a',
          ),
          viewer: viewer,
        ),
        isFalse,
      );
    });

    test('sortFeedByRules orders by relation score then createdAt desc', () {
      final DateTime now = DateTime.now().toUtc();
      final List<Star> stars = <Star>[
        _star(starId: 'a', relationScore: 100, createdAt: now),
        _star(starId: 'b', relationScore: 120, createdAt: now),
        _star(
          starId: 'c',
          relationScore: 100,
          createdAt: now.add(const Duration(minutes: 2)),
        ),
      ];

      final List<Star> sorted = sortFeedByRules(stars: stars);
      expect(sorted.map((Star star) => star.starId).toList(), <String>[
        'b',
        'c',
        'a',
      ]);
    });

    test('applyFeedDiversityPolicy pushes seen and crowded stars back', () {
      final DateTime now = DateTime.now().toUtc();
      final List<Star> stars = <Star>[
        _star(starId: 'g1-1', diversityKey: 'g1', createdAt: now),
        _star(
          starId: 'g1-2',
          diversityKey: 'g1',
          createdAt: now.add(const Duration(seconds: 1)),
        ),
        _star(
          starId: 'g1-3',
          diversityKey: 'g1',
          createdAt: now.add(const Duration(seconds: 2)),
        ),
        _star(
          starId: 'g1-4',
          diversityKey: 'g1',
          createdAt: now.add(const Duration(seconds: 3)),
        ),
        _star(
          starId: 'g2-1',
          diversityKey: 'g2',
          createdAt: now.add(const Duration(seconds: 4)),
        ),
        _star(
          starId: 'crowded',
          diversityKey: 'g2',
          reactionCount: 25,
          createdAt: now.add(const Duration(seconds: 5)),
        ),
        _star(
          starId: 'seen',
          diversityKey: 'g3',
          isSeen: true,
          createdAt: now.add(const Duration(seconds: 6)),
        ),
      ];

      final List<Star> applied = applyFeedDiversityPolicy(stars: stars);

      expect(applied.last.starId, 'seen');
      expect(applied[applied.length - 2].starId, 'crowded');
      expect(
        applied.take(5).map((Star star) => star.starId).contains('g2-1'),
        isTrue,
      );
    });

    test('calculateRelationScore delegates shared policy', () {
      const ViewerContext viewer = ViewerContext(
        viewerUserId: 'me',
        blockedUserIds: <String>{},
        seenStarIds: <String>{'s1'},
        viewerTagIds: <int>[6],
        viewerTagGroups: <String>['anxious'],
        viewerTimeBucket: 'night',
      );
      const StarCandidate candidate = StarCandidate(
        starId: 's1',
        ownerUserId: 'other',
        tagIds: <int>[6],
        timeBucket: 'night',
        reactionCount: 3,
        isDeleted: false,
        isBlocked: false,
        expiresAt: null,
        visibilityStatus: 'public',
        diversityKey: 'x',
      );

      final int score = calculateRelationScore(
        candidate: candidate,
        viewer: viewer,
      );

      expect(score, 20);
    });
  });
}

Star _star({
  required String starId,
  required DateTime createdAt,
  double relationScore = 10,
  int reactionCount = 1,
  bool isSeen = false,
  String diversityKey = 'g',
}) {
  return Star(
    starId: starId,
    userId: 'u',
    content: 'content',
    tagIds: const <int>[1],
    tagNames: const <String>[],
    timeBucket: 'night',
    reactionCount: reactionCount,
    createdAt: createdAt,
    expiresAt: null,
    relationScore: relationScore,
    isSeen: isSeen,
    visibilityStatus: 'public',
    isDeleted: false,
    isExpired: false,
    isReactable: true,
    diversityKey: diversityKey,
  );
}
