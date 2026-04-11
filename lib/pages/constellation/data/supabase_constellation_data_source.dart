import 'package:supabase_flutter/supabase_flutter.dart';

import 'constellation_data_source.dart';

class SupabaseConstellationDataSource implements ConstellationDataSource {
  SupabaseConstellationDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<dynamic> fetchFeed({
    required String filterName,
    required int limit,
    required int offset,
  }) {
    return _client.rpc(
      'get_constellation_feed',
      params: <String, dynamic>{
        'p_filter_name': filterName,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
  }

  @override
  Future<dynamic> fetchStarDetail({required String starId}) {
    return _client.rpc(
      'get_star_detail',
      params: <String, dynamic>{'p_star_id': starId},
    );
  }

  @override
  Future<dynamic> fetchTodayStatus() {
    return _client.rpc('get_today_status');
  }

  @override
  Future<void> markStarSeen({
    required String starId,
    required String userId,
  }) async {
    await _client.from('star_views').upsert(<String, dynamic>{
      'viewer_user_id': userId,
      'star_id': starId,
      'seen_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'viewer_user_id,star_id');
  }
}
