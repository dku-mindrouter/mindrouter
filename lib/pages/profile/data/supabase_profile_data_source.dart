import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_data_source.dart';

class SupabaseProfileDataSource implements ProfileDataSource {
  SupabaseProfileDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<dynamic> fetchMyStats() {
    return _client.rpc('get_my_stats');
  }

  @override
  Future<dynamic> fetchMyStars({int limit = 30, int offset = 0}) {
    return _client.rpc(
      'get_my_star_history',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': offset},
    );
  }
}
