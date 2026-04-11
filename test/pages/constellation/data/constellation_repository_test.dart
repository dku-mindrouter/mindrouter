import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/constellation/data/constellation_data_source.dart';
import 'package:mindfulconnect/pages/constellation/data/constellation_repository.dart';
import 'package:mindfulconnect/pages/constellation/domain/constellation_exception.dart';
import 'package:mindfulconnect/shared/features/data/app_error.dart';

class FakeConstellationDataSource implements ConstellationDataSource {
  String? lastFilterName;
  int? lastLimit;
  int? lastOffset;
  String? lastDetailStarId;
  String? lastSeenStarId;
  String? lastSeenUserId;

  int feedCallCount = 0;
  int detailCallCount = 0;
  int statusCallCount = 0;
  int seenCallCount = 0;

  Object? feedError;
  Object? detailError;
  Object? statusError;
  Object? seenError;

  dynamic feedResponse = <Map<String, dynamic>>[
    {
      'star_id': '11111111-1111-1111-1111-111111111111',
      'user_id': '22222222-2222-2222-2222-222222222222',
      'content': '힘들었지만 버텼어요',
      'tag_ids': <int>[6],
      'time_bucket': 'night',
      'reaction_count': 2,
      'created_at': '2026-04-11T12:00:00Z',
      'expires_at': null,
      'relation_score': 31,
      'is_seen': false,
    },
  ];

  dynamic detailResponse = <Map<String, dynamic>>[
    {
      'star_id': '11111111-1111-1111-1111-111111111111',
      'user_id': '22222222-2222-2222-2222-222222222222',
      'content': '힘들었지만 버텼어요',
      'tag_ids': <int>[6],
      'tag_names': <String>['불안'],
      'time_bucket': 'night',
      'reaction_count': 2,
      'created_at': '2026-04-11T12:00:00Z',
      'expires_at': '2026-04-11T18:00:00Z',
      'visibility_status': 'public',
      'is_deleted': false,
      'is_expired': false,
      'is_reactable': true,
    },
  ];

  dynamic statusResponse = <Map<String, dynamic>>[
    {
      'date_local': '2026-04-11',
      'has_star_today': true,
      'today_star_id': '11111111-1111-1111-1111-111111111111',
      'is_star_public_today': true,
      'is_star_expired_today': false,
      'reaction_sent_count': 1,
      'reaction_daily_limit': 20,
      'reaction_remaining_count': 19,
    },
  ];

  @override
  Future<dynamic> fetchFeed({
    required String filterName,
    required int limit,
    required int offset,
  }) async {
    feedCallCount += 1;
    lastFilterName = filterName;
    lastLimit = limit;
    lastOffset = offset;
    if (feedError != null) {
      throw feedError!;
    }
    return feedResponse;
  }

  @override
  Future<dynamic> fetchStarDetail({required String starId}) async {
    detailCallCount += 1;
    lastDetailStarId = starId;
    if (detailError != null) {
      throw detailError!;
    }
    return detailResponse;
  }

  @override
  Future<dynamic> fetchTodayStatus() async {
    statusCallCount += 1;
    if (statusError != null) {
      throw statusError!;
    }
    return statusResponse;
  }

  @override
  Future<void> markStarSeen({
    required String starId,
    required String userId,
  }) async {
    seenCallCount += 1;
    lastSeenStarId = starId;
    lastSeenUserId = userId;
    if (seenError != null) {
      throw seenError!;
    }
  }
}

void main() {
  group('ConstellationRepository', () {
    late FakeConstellationDataSource dataSource;
    late ConstellationRepository repository;

    setUp(() {
      dataSource = FakeConstellationDataSource();
      repository = ConstellationRepository(dataSource: dataSource);
    });

    test('fetchFeed maps rpc rows and clamps params', () async {
      final stars = await repository.fetchFeed(
        filterName: 'invalid',
        limit: 100,
        offset: -3,
      );

      expect(stars.length, 1);
      expect(stars.first.starId, '11111111-1111-1111-1111-111111111111');
      expect(dataSource.lastFilterName, 'all');
      expect(dataSource.lastLimit, 50);
      expect(dataSource.lastOffset, 0);
    });

    test('fetchStarById maps detail row', () async {
      final star = await repository.fetchStarById(
        '11111111-1111-1111-1111-111111111111',
      );

      expect(star.tagNames, <String>['불안']);
      expect(star.isReactable, isTrue);
      expect(
        dataSource.lastDetailStarId,
        '11111111-1111-1111-1111-111111111111',
      );
    });

    test('fetchTodayStatus maps response', () async {
      final status = await repository.fetchTodayStatus();

      expect(status.hasStarToday, isTrue);
      expect(status.reactionRemainingCount, 19);
      expect(status.reactionDailyLimit, 20);
      expect(dataSource.statusCallCount, 1);
    });

    test('markStarSeen delegates upsert target', () async {
      await repository.markStarSeen(starId: 's1', userId: 'u1');

      expect(dataSource.seenCallCount, 1);
      expect(dataSource.lastSeenStarId, 's1');
      expect(dataSource.lastSeenUserId, 'u1');
    });

    test('retries internal errors up to max retry count', () async {
      dataSource.feedError = {'message': ConstellationErrorCode.internalError};

      await expectLater(
        () => repository.fetchFeed(),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.internalError,
          ),
        ),
      );

      expect(dataSource.feedCallCount, 3);
    });

    test('fetchStarById maps STAR_NOT_FOUND', () async {
      dataSource.detailError = {'code': ConstellationErrorCode.starNotFound};

      await expectLater(
        () => repository.fetchStarById('missing'),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.starNotFound,
          ),
        ),
      );
    });

    test('fetchFeed maps FORBIDDEN', () async {
      dataSource.feedError = {'code': ConstellationErrorCode.forbidden};

      await expectLater(
        () => repository.fetchFeed(filterName: 'all'),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.forbidden,
          ),
        ),
      );
    });

    test('fetchTodayStatus maps UNAUTHORIZED', () async {
      dataSource.statusError = {'code': ConstellationErrorCode.unauthorized};

      await expectLater(
        () => repository.fetchTodayStatus(),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.unauthorized,
          ),
        ),
      );
    });

    test('fetchFeed maps INVALID_ARGUMENT', () async {
      dataSource.feedError = {'code': ConstellationErrorCode.invalidArgument};

      await expectLater(
        () => repository.fetchFeed(filterName: 'all'),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('fetchStarById maps BLOCKED_RELATIONSHIP', () async {
      dataSource.detailError = {
        'code': ConstellationErrorCode.blockedRelationship,
      };

      await expectLater(
        () => repository.fetchStarById('blocked'),
        throwsA(
          isA<ConstellationException>().having(
            (ConstellationException error) => error.code,
            'code',
            ConstellationErrorCode.blockedRelationship,
          ),
        ),
      );
    });

    test('fetchFeed keeps morning filter input', () async {
      await repository.fetchFeed(filterName: 'morning', limit: 10, offset: 5);
      expect(dataSource.lastFilterName, 'morning');
      expect(dataSource.lastLimit, 10);
      expect(dataSource.lastOffset, 5);
    });

    test('mapToConstellationException keeps mapped code', () {
      final ConstellationException exception = repository
          .mapToConstellationException(
            const MappedAppException(code: ConstellationErrorCode.forbidden),
          );

      expect(exception.code, ConstellationErrorCode.forbidden);
    });
  });
}
