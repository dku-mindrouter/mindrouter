import 'package:supabase_flutter/supabase_flutter.dart';

import 'nudge_data_source.dart';

class SupabaseNudgeDataSource implements NudgeDataSource {
  SupabaseNudgeDataSource({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<dynamic> fetchTodayMission({
    required bool markOpened,
    String? selectedEmotionProfile,
  }) {
    final Map<String, dynamic> params = <String, dynamic>{
      'p_mark_opened': markOpened,
    };

    if (selectedEmotionProfile != null && selectedEmotionProfile.isNotEmpty) {
      params['p_selected_emotion_profile'] = selectedEmotionProfile;
    }

    return _client.rpc(
      'get_today_mission',
      params: params,
    );
  }

  @override
  Future<void> startTodayMission({required String deliveryId}) async {
    await _client.rpc(
      'start_today_mission',
      params: <String, dynamic>{'p_delivery_id': deliveryId},
    );
  }

  @override
  Future<void> completeTodayMission({required String deliveryId}) async {
    await _client.rpc(
      'complete_today_mission',
      params: <String, dynamic>{'p_delivery_id': deliveryId},
    );
  }
}
