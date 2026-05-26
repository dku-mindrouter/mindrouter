import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulconnect/pages/nudge/data/nudge_data_source.dart';
import 'package:mindfulconnect/pages/nudge/data/nudge_repository.dart';
import 'package:mindfulconnect/pages/nudge/domain/nudge_exception.dart';
import 'package:mindfulconnect/shared/features/data/app_error.dart';

class FakeNudgeDataSource implements NudgeDataSource {
  int fetchMissionCallCount = 0;
  int startCallCount = 0;
  int completeCallCount = 0;

  bool? lastMarkOpened;
  String? lastSelectedEmotionProfile;
  String? lastDeliveryId;

  Object? fetchError;
  Object? startError;
  Object? completeError;

  dynamic fetchResponse = <Map<String, dynamic>>[
    <String, dynamic>{
      'delivery_id': '44444444-4444-4444-4444-444444444444',
      'template_id': 12,
      'mission_type': 'mission_anxious_breathing',
      'title': '4초 들이마시고 6초 내쉬기',
      'subtitle': '몸의 호흡 리듬부터 천천히 낮춰 보세요.',
      'body': '불안할 때는 생각을 멈추는 것보다 몸의 속도를 먼저 늦추는 편이 도움이 됩니다.',
      'duration_minutes': 5,
      'checklist_json': <String>[
        '어깨를 내려놓고 편한 자세 찾기',
        '4초 들이마시고 6초 내쉬는 호흡 5번 하기',
      ],
      'cta_label': '미션 시작하기',
      'accent_icon': 'air',
      'accent_start_color': 'sky',
      'accent_end_color': 'violet',
      'delivery_local_date': '2026-05-25',
      'opened_at': null,
      'started_at': null,
      'completed_at': null,
      'selection_source': 'emotion',
      'matched_mission_profile': 'anxious',
      'mission_goal': '생각보다 몸의 속도를 먼저 낮추기',
      'mission_state_label': '마음이 조급함',
    },
  ];

  @override
  Future<dynamic> fetchTodayMission({
    required bool markOpened,
    String? selectedEmotionProfile,
  }) async {
    fetchMissionCallCount += 1;
    lastMarkOpened = markOpened;
    lastSelectedEmotionProfile = selectedEmotionProfile;
    if (fetchError != null) {
      throw fetchError!;
    }
    return fetchResponse;
  }

  @override
  Future<void> startTodayMission({required String deliveryId}) async {
    startCallCount += 1;
    lastDeliveryId = deliveryId;
    if (startError != null) {
      throw startError!;
    }
  }

  @override
  Future<void> completeTodayMission({required String deliveryId}) async {
    completeCallCount += 1;
    lastDeliveryId = deliveryId;
    if (completeError != null) {
      throw completeError!;
    }
  }
}

void main() {
  group('NudgeRepository', () {
    late FakeNudgeDataSource dataSource;
    late NudgeRepository repository;

    setUp(() {
      dataSource = FakeNudgeDataSource();
      repository = NudgeRepository(dataSource: dataSource);
    });

    test('fetchTodayMission maps mission and forwards selected profile', () async {
      final mission = await repository.fetchTodayMission(
        markOpened: true,
        selectedEmotionProfile: 'anxious',
      );

      expect(mission.deliveryId, '44444444-4444-4444-4444-444444444444');
      expect(mission.selectionSource, 'emotion');
      expect(mission.matchedMissionProfile, 'anxious');
      expect(mission.missionGoal, '생각보다 몸의 속도를 먼저 낮추기');
      expect(dataSource.lastMarkOpened, true);
      expect(dataSource.lastSelectedEmotionProfile, 'anxious');
    });

    test('startTodayMission forwards delivery id', () async {
      await repository.startTodayMission(
        deliveryId: '44444444-4444-4444-4444-444444444444',
      );

      expect(dataSource.startCallCount, 1);
      expect(dataSource.lastDeliveryId, '44444444-4444-4444-4444-444444444444');
    });

    test('completeTodayMission forwards delivery id', () async {
      await repository.completeTodayMission(
        deliveryId: '44444444-4444-4444-4444-444444444444',
      );

      expect(dataSource.completeCallCount, 1);
      expect(dataSource.lastDeliveryId, '44444444-4444-4444-4444-444444444444');
    });

    test('fetchTodayMission retries internal error', () async {
      dataSource.fetchError = <String, dynamic>{
        'message': NudgeErrorCode.internalError,
      };

      await expectLater(
        () => repository.fetchTodayMission(markOpened: false),
        throwsA(
          isA<NudgeException>().having(
            (NudgeException error) => error.code,
            'code',
            NudgeErrorCode.internalError,
          ),
        ),
      );

      expect(dataSource.fetchMissionCallCount, 3);
    });

    test('mapToNudgeException keeps mapped code', () {
      final exception = repository.mapToNudgeException(
        const MappedAppException(code: NudgeErrorCode.forbidden),
      );

      expect(exception.code, NudgeErrorCode.forbidden);
    });
  });
}
