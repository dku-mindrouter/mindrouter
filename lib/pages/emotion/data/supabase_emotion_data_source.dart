import 'package:supabase_flutter/supabase_flutter.dart';

import 'emotion_data_source.dart';

class SupabaseEmotionDataSource implements EmotionDataSource {
  SupabaseEmotionDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchEmotionTags() async {
    final dynamic response = await _client
        .from('emotion_tags')
        .select('id,name_ko,group_name,priority,is_active')
        .eq('is_active', true)
        .order('priority', ascending: false)
        .order('id', ascending: true);

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<dynamic> createStar({
    required String content,
    required List<int> tagIds,
    required String timeBucket,
    required String visibilityStatus,
    int? emotionIntensity,
    DateTime? expiresAt,
  }) {
    return _client.rpc(
      'create_star',
      params: <String, dynamic>{
        'p_content': content,
        'p_tag_ids': tagIds,
        'p_time_bucket': timeBucket,
        'p_visibility_status': visibilityStatus,
        'p_emotion_intensity': emotionIntensity,
        'p_expires_at': expiresAt?.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<dynamic> fetchTodayStarStatus() {
    return _client.rpc('get_today_status');
  }
}
