import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/emotion/domain/emotion_composer_policy.dart';
import 'package:mindfulconnect/pages/emotion/domain/emotion_composer_state.dart';
import 'package:mindfulconnect/pages/emotion/domain/emotion_exception.dart';
import 'package:mindfulconnect/pages/emotion/domain/emotion_validation_policy.dart';
import 'package:mindfulconnect/pages/emotion/domain/time_bucket_policy.dart';

void main() {
  group('Emotion domain policies', () {
    test('toggleEmotionTag adds and removes tag', () {
      const EmotionComposerState initial = EmotionComposerState(
        selectedTagIds: <int>[1],
      );

      final EmotionComposerState added = toggleEmotionTag(
        state: initial,
        tagId: 2,
        maxTags: 3,
      );
      expect(added.selectedTagIds, <int>[1, 2]);

      final EmotionComposerState removed = toggleEmotionTag(
        state: added,
        tagId: 1,
        maxTags: 3,
      );
      expect(removed.selectedTagIds, <int>[2]);
    });

    test('toggleEmotionTag throws when max tag count exceeded', () {
      const EmotionComposerState state = EmotionComposerState(
        selectedTagIds: <int>[1, 2, 3],
      );

      expect(
        () => toggleEmotionTag(state: state, tagId: 4, maxTags: 3),
        throwsA(
          isA<EmotionException>().having(
            (EmotionException error) => error.code,
            'code',
            EmotionErrorCode.tagLimitExceeded,
          ),
        ),
      );
    });

    test('checkEmotionTagLimit validates unique count', () async {
      await checkEmotionTagLimit(tagIds: <int>[1, 1, 2], maxCount: 2);

      await expectLater(
        () => checkEmotionTagLimit(tagIds: <int>[1, 2, 3], maxCount: 2),
        throwsA(
          isA<EmotionException>().having(
            (EmotionException error) => error.code,
            'code',
            EmotionErrorCode.tagLimitExceeded,
          ),
        ),
      );
    });

    test(
      'checkEmotionContentPolicy validates length and blocked words',
      () async {
        await checkEmotionContentPolicy(content: '오늘은 조금 힘들었어요', maxLength: 80);

        await expectLater(
          () => checkEmotionContentPolicy(content: 'a' * 81, maxLength: 80),
          throwsA(
            isA<EmotionException>().having(
              (EmotionException error) => error.code,
              'code',
              EmotionErrorCode.contentTooLong,
            ),
          ),
        );

        await expectLater(
          () =>
              checkEmotionContentPolicy(content: '진짜 시발 너무 힘들다', maxLength: 80),
          throwsA(
            isA<EmotionException>().having(
              (EmotionException error) => error.code,
              'code',
              EmotionErrorCode.contentBlockedWord,
            ),
          ),
        );
      },
    );

    test('getTimeBucketByLocalTime uses timezone and fallback', () {
      final DateTime utcNow = DateTime.utc(2026, 1, 1, 23, 30);

      final String seoulBucket = getTimeBucketByLocalTime(
        now: utcNow,
        timezone: 'Asia/Seoul',
      );
      expect(seoulBucket, 'morning');

      final String fallbackBucket = getTimeBucketByLocalTime(
        now: utcNow,
        timezone: 'Unknown/Zone',
      );
      expect(fallbackBucket, 'morning');
    });

    test('checkCanSubmitEmotion follows confirmed condition', () {
      expect(
        checkCanSubmitEmotion(tagIds: <int>[1], isSubmitting: false),
        isTrue,
      );
      expect(
        checkCanSubmitEmotion(tagIds: <int>[], isSubmitting: false),
        isFalse,
      );
      expect(
        checkCanSubmitEmotion(tagIds: <int>[1], isSubmitting: true),
        isFalse,
      );
    });
  });
}
