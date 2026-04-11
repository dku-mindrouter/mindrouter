import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/emotion/data/emotion_data_source.dart';
import 'package:mindfulconnect/pages/emotion/data/emotion_repository.dart';
import 'package:mindfulconnect/pages/emotion/domain/emotion_exception.dart';
import 'package:mindfulconnect/shared/features/data/app_error.dart';

class FakeEmotionDataSource implements EmotionDataSource {
  int fetchTagsCallCount = 0;
  int createStarCallCount = 0;
  int statusCallCount = 0;

  Object? tagsError;
  Object? createError;
  Object? statusError;

  List<Map<String, dynamic>> tags = <Map<String, dynamic>>[
    {
      'id': 1,
      'name_ko': '불안',
      'group_name': 'anxiety',
      'priority': 50,
      'is_active': true,
    },
  ];
  dynamic createResponse = <Map<String, dynamic>>[
    {
      'star_id': '00000000-0000-0000-0000-000000000001',
      'created_at': '2026-04-11T12:00:00Z',
      'created_local_date': '2026-04-11',
    },
  ];
  dynamic statusResponse = <Map<String, dynamic>>[
    {
      'has_star_today': true,
      'today_star_id': '00000000-0000-0000-0000-000000000001',
      'reaction_remaining_count': 19,
      'is_star_public_today': true,
      'is_star_expired_today': false,
    },
  ];

  @override
  Future<dynamic> createStar({
    required String content,
    required List<int> tagIds,
    required String timeBucket,
    required String visibilityStatus,
    int? emotionIntensity,
    DateTime? expiresAt,
  }) async {
    createStarCallCount += 1;
    if (createError != null) {
      throw createError!;
    }
    return createResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEmotionTags() async {
    fetchTagsCallCount += 1;
    if (tagsError != null) {
      throw tagsError!;
    }
    return tags;
  }

  @override
  Future<dynamic> fetchTodayStarStatus() async {
    statusCallCount += 1;
    if (statusError != null) {
      throw statusError!;
    }
    return statusResponse;
  }
}

void main() {
  group('EmotionRepository', () {
    late FakeEmotionDataSource dataSource;
    late EmotionRepository repository;

    setUp(() {
      dataSource = FakeEmotionDataSource();
      repository = EmotionRepository(dataSource: dataSource);
    });

    test('fetchEmotionTags returns active tags with mapping', () async {
      final tags = await repository.fetchEmotionTags();
      expect(tags.length, 1);
      expect(tags.first.nameKo, '불안');
      expect(dataSource.fetchTagsCallCount, 1);
    });

    test('createStar maps rpc result', () async {
      final result = await repository.createStar(
        content: '오늘은 지쳐요',
        tagIds: <int>[1, 2],
        timeBucket: 'night',
        visibilityStatus: 'public',
      );

      expect(result.starId, '00000000-0000-0000-0000-000000000001');
      expect(result.createdLocalDate.year, 2026);
      expect(dataSource.createStarCallCount, 1);
    });

    test('fetchTodayStarStatus maps status response', () async {
      final status = await repository.fetchTodayStarStatus();

      expect(status.hasCreatedToday, isTrue);
      expect(status.remainingCount, 19);
      expect(status.latestStarId, '00000000-0000-0000-0000-000000000001');
      expect(dataSource.statusCallCount, 1);
    });

    test('retries internal errors up to max retry count', () async {
      dataSource.createError = {'message': EmotionErrorCode.internalError};

      await expectLater(
        () => repository.createStar(
          content: 'a',
          tagIds: <int>[1],
          timeBucket: 'day',
          visibilityStatus: 'public',
        ),
        throwsA(isA<MappedAppException>()),
      );

      expect(dataSource.createStarCallCount, 3);
    });

    test('mapToEmotionException keeps mapped code', () {
      final EmotionException exception = repository.mapToEmotionException(
        const MappedAppException(code: EmotionErrorCode.forbidden),
      );

      expect(exception.code, EmotionErrorCode.forbidden);
    });
  });
}
