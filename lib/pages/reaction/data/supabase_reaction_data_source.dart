import 'dart:math' as math;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/features/data/app_error.dart';
import '../domain/reaction_exception.dart';
import 'reaction_data_source.dart';

const String _coffeeGiftImageBucket = 'coffee-gift-images';

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
    String? giftImageUrl,
  }) {
    return _client.rpc(
      'send_reaction',
      params: <String, dynamic>{
        'p_star_id': starId,
        'p_reaction_type_id': reactionTypeId,
        'p_gift_image_url': giftImageUrl,
      },
    );
  }

  @override
  Future<String> uploadCoffeeGiftImage({
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const MappedAppException(code: ReactionErrorCode.unauthorized);
    }

    final String normalizedExtension = fileExtension
        .replaceAll('.', '')
        .toLowerCase();
    final int nonce = math.Random.secure().nextInt(1 << 32);
    final String path =
        '$userId/${DateTime.now().microsecondsSinceEpoch}-$nonce.$normalizedExtension';

    await _client.storage
        .from(_coffeeGiftImageBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '31536000',
            upsert: false,
          ),
        );
    return _client.storage.from(_coffeeGiftImageBucket).getPublicUrl(path);
  }

  @override
  Future<dynamic> sendLetter({
    required String starId,
    required String content,
  }) {
    return _client.rpc(
      'send_letter',
      params: <String, dynamic>{'p_star_id': starId, 'p_content': content},
    );
  }

  @override
  Future<dynamic> fetchReactionQuota() {
    return _client.rpc('get_today_status');
  }

  @override
  Future<void> notifyReactionPush({required String reactionId}) async {
    await _client.functions.invoke(
      'send-reaction-push',
      body: <String, dynamic>{'reactionId': reactionId},
    );
  }
}
