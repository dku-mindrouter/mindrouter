import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/reaction/domain/reaction_error_message_mapper.dart';
import 'package:mindfulconnect/pages/reaction/domain/reaction_exception.dart';
import 'package:mindfulconnect/pages/reaction/domain/reaction_policy.dart';

void main() {
  group('Reaction domain policies', () {
    setUp(clearReactionPolicySessionCache);

    test('checkReactionTypeAllowed validates active ids', () async {
      await checkReactionTypeAllowed(
        reactionTypeId: 2,
        activeTypeIds: <int>[1, 2, 3],
      );

      await expectLater(
        () => checkReactionTypeAllowed(
          reactionTypeId: 99,
          activeTypeIds: <int>[1, 2, 3],
        ),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('checkDuplicateReaction blocks same sender-star in session', () async {
      await checkDuplicateReaction(senderUserId: 'u1', starId: 's1');
      rememberSuccessfulReaction(senderUserId: 'u1', starId: 's1');

      await expectLater(
        () => checkDuplicateReaction(senderUserId: 'u1', starId: 's1'),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.alreadyReacted,
          ),
        ),
      );
    });

    test('checkDailyReactionLimit validates sender and date shape', () async {
      await checkDailyReactionLimit(
        senderUserId: 'u1',
        localDate: DateTime.utc(2026, 4, 11),
      );

      await expectLater(
        () => checkDailyReactionLimit(
          senderUserId: '',
          localDate: DateTime.utc(2026, 4, 11),
        ),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('checkReactionTargetAllowed blocks self reaction', () async {
      await checkReactionTargetAllowed(
        senderUserId: 'sender',
        starOwnerUserId: 'owner',
      );

      await expectLater(
        () => checkReactionTargetAllowed(
          senderUserId: 'same',
          starOwnerUserId: 'same',
        ),
        throwsA(
          isA<ReactionException>().having(
            (ReactionException error) => error.code,
            'code',
            ReactionErrorCode.selfReactionNotAllowed,
          ),
        ),
      );
    });

    test('mapReactionErrorCodeToMessage maps fixed codes', () {
      expect(
        mapReactionErrorCodeToMessage(
          errorCode: ReactionErrorCode.alreadyReacted,
        ),
        '이미 반응을 보냈어요.',
      );
      expect(
        mapReactionErrorCodeToMessage(
          errorCode: ReactionErrorCode.dailyReactionLimitExceeded,
        ),
        '오늘의 반응 한도를 초과했어요.',
      );
      expect(
        mapReactionErrorCodeToMessage(errorCode: 'UNKNOWN'),
        '일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.',
      );
    });
  });
}
