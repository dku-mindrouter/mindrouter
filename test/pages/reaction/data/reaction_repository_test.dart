import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/reaction/data/reaction_data_source.dart';
import 'package:mindfulconnect/pages/reaction/data/reaction_repository.dart';
import 'package:mindfulconnect/pages/reaction/domain/coffee_gift_image.dart';
import 'package:mindfulconnect/pages/reaction/domain/reaction_exception.dart';
import 'package:mindfulconnect/shared/features/data/app_error.dart';

class FakeReactionDataSource implements ReactionDataSource {
  int fetchTypesCallCount = 0;
  int sendReactionCallCount = 0;
  int fetchQuotaCallCount = 0;

  String? lastStarId;
  int? lastReactionTypeId;
  String? lastGiftImageUrl;

  Object? typesError;
  Object? sendError;
  Object? quotaError;

  List<Map<String, dynamic>> typesResponse = <Map<String, dynamic>>[
    {'id': 1, 'code': 'HUG', 'label_ko': '안아드려요', 'icon': 'hug'},
  ];

  dynamic sendResponse = <Map<String, dynamic>>[
    {
      'reaction_id': '33333333-3333-3333-3333-333333333333',
      'star_id': '11111111-1111-1111-1111-111111111111',
      'reaction_count': 4,
      'created_at': '2026-04-11T12:00:00Z',
    },
  ];

  dynamic quotaResponse = <Map<String, dynamic>>[
    {
      'reaction_sent_count': 2,
      'reaction_daily_limit': 20,
      'reaction_remaining_count': 18,
      'is_star_public_today': true,
      'is_star_expired_today': false,
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchReactionTypes() async {
    fetchTypesCallCount += 1;
    if (typesError != null) {
      throw typesError!;
    }
    return typesResponse;
  }

  @override
  Future<dynamic> sendReaction({
    required String starId,
    required int reactionTypeId,
    String? giftImageUrl,
  }) async {
    sendReactionCallCount += 1;
    lastStarId = starId;
    lastReactionTypeId = reactionTypeId;
    lastGiftImageUrl = giftImageUrl;
    if (sendError != null) {
      throw sendError!;
    }
    return sendResponse;
  }

  @override
  Future<String> uploadCoffeeGiftImage({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    return 'https://example.com/coffee-photo.$fileExtension';
  }

  @override
  Future<dynamic> sendLetter({
    required String starId,
    required String content,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> fetchReactionQuota() async {
    fetchQuotaCallCount += 1;
    if (quotaError != null) {
      throw quotaError!;
    }
    return quotaResponse;
  }

  @override
  Future<void> notifyReactionPush({required String reactionId}) async {}
}

void main() {
  group('ReactionRepository', () {
    late FakeReactionDataSource dataSource;
    late ReactionRepository repository;

    setUp(() {
      dataSource = FakeReactionDataSource();
      repository = ReactionRepository(dataSource: dataSource);
    });

    test('fetchReactionTypes maps active reaction type rows', () async {
      final types = await repository.fetchReactionTypes();

      expect(types.length, 1);
      expect(types.first.id, 1);
      expect(types.first.code, 'HUG');
      expect(dataSource.fetchTypesCallCount, 1);
    });

    test('sendReaction maps rpc result', () async {
      final result = await repository.sendReaction(
        starId: '11111111-1111-1111-1111-111111111111',
        reactionTypeId: 1,
      );

      expect(result.reactionId, '33333333-3333-3333-3333-333333333333');
      expect(result.reactionCount, 4);
      expect(dataSource.lastStarId, '11111111-1111-1111-1111-111111111111');
      expect(dataSource.lastReactionTypeId, 1);
    });

    test('sendReaction uploads coffee gift image before rpc', () async {
      final result = await repository.sendReaction(
        starId: '11111111-1111-1111-1111-111111111111',
        reactionTypeId: 5,
        coffeeGiftImage: CoffeeGiftImage(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          fileExtension: 'jpg',
          contentType: 'image/jpeg',
        ),
      );

      expect(result.reactionId, '33333333-3333-3333-3333-333333333333');
      expect(dataSource.lastReactionTypeId, 5);
      expect(
        dataSource.lastGiftImageUrl,
        'https://example.com/coffee-photo.jpg',
      );
    });

    test('fetchReactionQuota maps quota and remaining', () async {
      final quota = await repository.fetchReactionQuota();

      expect(quota.used, 2);
      expect(quota.limit, 20);
      expect(quota.remaining, 18);
      expect(dataSource.fetchQuotaCallCount, 1);
    });

    test('sendReaction retries internal error up to max retry count', () async {
      dataSource.sendError = {'message': ReactionErrorCode.internalError};

      await expectLater(
        () => repository.sendReaction(starId: 's1', reactionTypeId: 1),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.internalError,
          ),
        ),
      );

      expect(dataSource.sendReactionCallCount, 3);
    });

    test('sendReaction maps ALREADY_REACTED', () async {
      dataSource.sendError = {'code': ReactionErrorCode.alreadyReacted};

      await expectLater(
        () => repository.sendReaction(starId: 's1', reactionTypeId: 1),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.alreadyReacted,
          ),
        ),
      );
    });

    test('sendReaction maps DAILY_REACTION_LIMIT_EXCEEDED', () async {
      dataSource.sendError = {
        'code': ReactionErrorCode.dailyReactionLimitExceeded,
      };

      await expectLater(
        () => repository.sendReaction(starId: 's1', reactionTypeId: 1),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.dailyReactionLimitExceeded,
          ),
        ),
      );
    });

    test('sendReaction maps BLOCKED_RELATIONSHIP', () async {
      dataSource.sendError = {'code': ReactionErrorCode.blockedRelationship};

      await expectLater(
        () => repository.sendReaction(starId: 's1', reactionTypeId: 1),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.blockedRelationship,
          ),
        ),
      );
    });

    test('sendReaction maps SELF_REACTION_NOT_ALLOWED', () async {
      dataSource.sendError = {'code': ReactionErrorCode.selfReactionNotAllowed};

      await expectLater(
        () => repository.sendReaction(starId: 's1', reactionTypeId: 1),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.selfReactionNotAllowed,
          ),
        ),
      );
    });

    test('fetchReactionQuota maps UNAUTHORIZED', () async {
      dataSource.quotaError = {'code': ReactionErrorCode.unauthorized};

      await expectLater(
        () => repository.fetchReactionQuota(),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.unauthorized,
          ),
        ),
      );
    });

    test('mapToReactionException keeps mapped code', () {
      final ReactionException exception = repository.mapToReactionException(
        const MappedAppException(code: ReactionErrorCode.forbidden),
      );

      expect(exception.code, ReactionErrorCode.forbidden);
    });
  });
}
