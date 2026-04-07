import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/emotion_tag.dart';
import 'emotion_repository.dart';

class SupabaseEmotionRepository implements EmotionRepository {
  SupabaseEmotionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<EmotionTag>> fetchEmotionTags() async {
    final response = await _client
        .from('emotion_tags')
        .select('id, name_ko, group_name')
        .eq('is_active', true)
        .order('priority');

    return response.map<EmotionTag>((item) {
      return EmotionTag(
        id: item['id'] as int,
        nameKo: item['name_ko'] as String,
        groupName: item['group_name'] as String,
      );
    }).toList();
  }

  @override
  Future<String> createStar({
    required int primaryTagId,
    required List<int> secondaryTagIds,
    required String content,
  }) async {
    final response = await _client.rpc(
      'create_star',
      params: <String, dynamic>{
        'p_primary_tag_id': primaryTagId,
        'p_secondary_tag_ids': secondaryTagIds,
        'p_content': content.isEmpty ? null : content,
        'p_visibility_status': 'public',
        'p_emotion_intensity': 3,
      },
    );

    return response['id'] as String;
  }
}

