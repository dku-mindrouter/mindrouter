import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/nudge/domain/mission_selection_source.dart';
import 'package:mindfulconnect/pages/nudge/domain/nudge_error_message_mapper.dart';
import 'package:mindfulconnect/pages/nudge/domain/nudge_exception.dart';
import 'package:mindfulconnect/pages/nudge/domain/nudge_mission_profile_mapper.dart';
import 'package:mindfulconnect/pages/nudge/domain/nudge_policy.dart';

void main() {
  group('Nudge domain', () {
    test(
      'mapSelectedEmotionToMissionProfile maps Korean and server groups',
      () {
        expect(
          mapSelectedEmotionToMissionProfile(emotionGroup: '불안'),
          'anxious',
        );
        expect(
          mapSelectedEmotionToMissionProfile(emotionGroup: '행복함'),
          'happy',
        );
        expect(
          mapSelectedEmotionToMissionProfile(emotionGroup: 'positive'),
          'energized',
        );
        expect(
          mapSelectedEmotionToMissionProfile(emotionGroup: 'calm_recovery'),
          'calm',
        );
        expect(
          mapSelectedEmotionToMissionProfile(emotionGroup: 'low_energy'),
          'lethargic',
        );
      },
    );

    test('mapSelectedEmotionToMissionProfile rejects unknown input', () async {
      await expectLater(
        () async => mapSelectedEmotionToMissionProfile(emotionGroup: 'unknown'),
        throwsA(
          isA<NudgeException>().having(
            (NudgeException error) => error.code,
            'code',
            NudgeErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('mapNudgeErrorCodeToMessage maps fixed codes', () {
      expect(
        mapNudgeErrorCodeToMessage(errorCode: NudgeErrorCode.nudgeNotFound),
        '오늘의 미션을 찾을 수 없어요.',
      );
      expect(
        mapNudgeErrorCodeToMessage(errorCode: NudgeErrorCode.invalidArgument),
        '미션 요청 값이 올바르지 않아요.',
      );
      expect(
        mapNudgeErrorCodeToMessage(errorCode: 'UNKNOWN'),
        '오늘의 미션을 불러오지 못했어요. 잠시 뒤 다시 시도해 주세요.',
      );
    });

    test('checkMissionDeliveryFixedForToday validates local date', () async {
      await checkMissionDeliveryFixedForToday(
        localDate: DateTime.utc(2026, 5, 25),
        hasExistingDelivery: false,
      );

      await expectLater(
        () => checkMissionDeliveryFixedForToday(
          localDate: DateTime.utc(-1, 5, 25),
          hasExistingDelivery: true,
        ),
        throwsA(
          isA<NudgeException>().having(
            (NudgeException error) => error.code,
            'code',
            NudgeErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test('MissionSelectionSource keeps fixed values', () {
      expect(MissionSelectionSource.emotion, 'emotion');
      expect(MissionSelectionSource.random, 'random');
      expect(MissionSelectionSource.existing, 'existing');
    });
  });
}
