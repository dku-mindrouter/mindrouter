import 'package:supabase_flutter/supabase_flutter.dart';

import 'comfort_data_source.dart';

class SupabaseComfortDataSource implements ComfortDataSource {
  SupabaseComfortDataSource({required SupabaseClient client})
    : _client = client;

  final SupabaseClient _client;

  @override
  Future<dynamic> fetchComfortNotifications({int limit = 30, int offset = 0}) {
    return _client.rpc(
      'get_comfort_notifications',
      params: <String, dynamic>{'p_limit': limit, 'p_offset': offset},
    );
  }
}
