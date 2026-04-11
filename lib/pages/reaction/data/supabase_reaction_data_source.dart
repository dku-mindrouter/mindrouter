import 'package:supabase_flutter/supabase_flutter.dart';

import 'reaction_data_source.dart';

class SupabaseReactionDataSource implements ReactionDataSource {
  SupabaseReactionDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchReactionTypes() async {
    final dynamic response = await _client
        .from('reaction_types')
        .select('id,code,label_ko,icon')
        .eq('is_active', true)
        .order('id', ascending: true);

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<dynamic> sendReaction({
    required String starId,
    required int reactionTypeId,
  }) {
    return _client.rpc(
      'send_reaction',
      params: <String, dynamic>{
        'p_star_id': starId,
        'p_reaction_type_id': reactionTypeId,
      },
    );
  }

  @override
  Future<dynamic> fetchReactionQuota() {
    return _client.rpc('get_today_status');
  }
}
