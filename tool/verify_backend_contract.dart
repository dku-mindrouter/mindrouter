// ignore_for_file: avoid_print, avoid_relative_lib_imports, depend_on_referenced_packages

import 'dart:convert';

import 'package:supabase/supabase.dart';

import '../lib/app/app_config.dart';

Future<void> main() async {
  final AppConfig config = AppConfig.fromEnvironment();
  final ContractVerifier verifier = ContractVerifier(config: config);
  await verifier.run();
}

class ContractVerifier {
  ContractVerifier({required this.config});

  final AppConfig config;
  final List<CheckResult> _results = <CheckResult>[];

  Future<void> run() async {
    _check(
      'config',
      config.hasSupabaseConfig,
      'Supabase URL/key are present',
      'Supabase URL/key are missing',
    );

    final SupabaseClient authorClient = _newClient();
    final SupabaseClient reactorClient = _newClient();
    final String suffix = DateTime.now().millisecondsSinceEpoch.toString();

    final UserContext author = await _step(
      'anonymous auth + profile upsert (author)',
      () => _prepareUser(
        client: authorClient,
        nickname: 'ct_author_${suffix.substring(suffix.length - 8)}',
      ),
    );

    final UserContext reactor = await _step(
      'anonymous auth + profile upsert (reactor)',
      () => _prepareUser(
        client: reactorClient,
        nickname: 'ct_reactor_${suffix.substring(suffix.length - 8)}',
      ),
    );

    final List<Map<String, dynamic>> emotionTags = await _step(
      'emotion_tags seed query',
      () async {
        final dynamic raw = await authorClient
            .from('emotion_tags')
            .select('id,name_ko,group_name,priority,is_active')
            .eq('is_active', true)
            .order('priority', ascending: false)
            .order('id', ascending: true);
        final List<Map<String, dynamic>> rows = _asRows(raw);
        _require(rows.isNotEmpty, 'No active emotion_tags rows found');
        _requireKeys(rows.first, <String>[
          'id',
          'name_ko',
          'group_name',
          'priority',
          'is_active',
        ]);
        return rows;
      },
    );

    final List<Map<String, dynamic>> reactionTypes = await _step(
      'reaction_types seed query',
      () async {
        final dynamic raw = await reactorClient
            .from('reaction_types')
            .select('id,code,label_ko,icon')
            .eq('is_active', true)
            .order('id', ascending: true);
        final List<Map<String, dynamic>> rows = _asRows(raw);
        _require(rows.isNotEmpty, 'No active reaction_types rows found');
        _requireKeys(rows.first, <String>['id', 'code', 'label_ko', 'icon']);
        return rows;
      },
    );

    await _step('get_today_status before create_star', () async {
      final Map<String, dynamic> today = _firstRow(
        await authorClient.rpc('get_today_status'),
      );
      _requireKeys(today, <String>[
        'date_local',
        'has_star_today',
        'today_star_id',
        'is_star_public_today',
        'is_star_expired_today',
        'reaction_sent_count',
        'reaction_daily_limit',
        'reaction_remaining_count',
      ]);
      _require(
        today['has_star_today'] == false,
        'Fresh anonymous author unexpectedly already has a star',
      );
      return today;
    });

    final int tagId = (emotionTags.first['id'] as num).toInt();
    final Map<String, dynamic> createdStar = await _step(
      'create_star',
      () async {
        final Map<String, dynamic> row = _firstRow(
          await authorClient.rpc(
            'create_star',
            params: <String, dynamic>{
              'p_content': '계약 검증용 테스트 별입니다',
              'p_tag_ids': <int>[tagId],
              'p_time_bucket': 'night',
              'p_visibility_status': 'public',
              'p_emotion_intensity': 1,
              'p_expires_at': null,
            },
          ),
        );
        _requireKeys(row, <String>[
          'star_id',
          'created_at',
          'created_local_date',
        ]);
        return row;
      },
    );

    final String starId = createdStar['star_id'] as String;

    await _step('get_today_status after create_star', () async {
      final Map<String, dynamic> today = _firstRow(
        await authorClient.rpc('get_today_status'),
      );
      _require(today['has_star_today'] == true, 'has_star_today stayed false');
      _require(today['today_star_id'] == starId, 'today_star_id mismatch');
      return today;
    });

    await _step('create_star duplicate limit error', () async {
      try {
        await authorClient.rpc(
          'create_star',
          params: <String, dynamic>{
            'p_content': '중복 생성 제한 검증',
            'p_tag_ids': <int>[tagId],
            'p_time_bucket': 'night',
            'p_visibility_status': 'public',
            'p_emotion_intensity': 1,
            'p_expires_at': null,
          },
        );
        throw StateError('Duplicate create_star unexpectedly succeeded');
      } catch (error) {
        final String code = _errorCode(error);
        _require(
          code == 'DAILY_STAR_LIMIT_EXCEEDED',
          'Expected DAILY_STAR_LIMIT_EXCEEDED, got $code',
        );
        return <String, dynamic>{'error_code': code};
      }
    });

    await _step('get_constellation_feed', () async {
      final List<Map<String, dynamic>> rows = _asRows(
        await reactorClient.rpc(
          'get_constellation_feed',
          params: <String, dynamic>{
            'p_filter_name': 'all',
            'p_limit': 20,
            'p_offset': 0,
          },
        ),
      );
      if (rows.isNotEmpty) {
        _requireKeys(rows.first, <String>[
          'star_id',
          'user_id',
          'content',
          'tag_ids',
          'time_bucket',
          'reaction_count',
          'created_at',
          'expires_at',
          'relation_score',
        ]);
      }
      return <String, dynamic>{'count': rows.length};
    });

    await _step('get_star_detail as another user', () async {
      final Map<String, dynamic> row = _firstRow(
        await reactorClient.rpc(
          'get_star_detail',
          params: <String, dynamic>{'p_star_id': starId},
        ),
      );
      _requireKeys(row, <String>[
        'star_id',
        'user_id',
        'content',
        'tag_ids',
        'tag_names',
        'time_bucket',
        'reaction_count',
        'created_at',
        'expires_at',
        'visibility_status',
        'is_deleted',
        'is_expired',
        'is_reactable',
      ]);
      _require(row['star_id'] == starId, 'star detail id mismatch');
      _require(row['is_reactable'] == true, 'star is not reactable');
      return row;
    });

    final int reactionTypeId = (reactionTypes.first['id'] as num).toInt();

    await _step('send_reaction', () async {
      final Map<String, dynamic> row = _firstRow(
        await reactorClient.rpc(
          'send_reaction',
          params: <String, dynamic>{
            'p_star_id': starId,
            'p_reaction_type_id': reactionTypeId,
          },
        ),
      );
      _requireKeys(row, <String>[
        'reaction_id',
        'star_id',
        'reaction_count',
        'created_at',
      ]);
      _require(row['star_id'] == starId, 'reaction star_id mismatch');
      return row;
    });

    await _step('send_reaction duplicate error', () async {
      try {
        await reactorClient.rpc(
          'send_reaction',
          params: <String, dynamic>{
            'p_star_id': starId,
            'p_reaction_type_id': reactionTypeId,
          },
        );
        throw StateError('Duplicate send_reaction unexpectedly succeeded');
      } catch (error) {
        final String code = _errorCode(error);
        _require(
          code == 'ALREADY_REACTED',
          'Expected ALREADY_REACTED, got $code',
        );
        return <String, dynamic>{'error_code': code};
      }
    });

    _printSummary(author: author, reactor: reactor, starId: starId);
  }

  SupabaseClient _newClient() {
    return SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);
  }

  Future<UserContext> _prepareUser({
    required SupabaseClient client,
    required String nickname,
  }) async {
    final AuthResponse response = await client.auth.signInAnonymously();
    final String? userId = response.user?.id ?? client.auth.currentUser?.id;
    _require(userId != null && userId.isNotEmpty, 'Anonymous user id missing');

    await client.from('profiles').upsert(<String, dynamic>{
      'id': userId,
      'nickname': nickname,
      'timezone': config.defaultTimezone,
    }, onConflict: 'id');

    final dynamic raw = await client
        .from('profiles')
        .select('id,nickname,timezone,is_active,push_token')
        .eq('id', userId!)
        .maybeSingle();

    _require(raw is Map<String, dynamic>, 'Profile row not found after upsert');
    final Map<String, dynamic> profile = raw as Map<String, dynamic>;
    _requireKeys(profile, <String>[
      'id',
      'nickname',
      'timezone',
      'is_active',
      'push_token',
    ]);
    _require(profile['is_active'] == true, 'Profile is not active');
    return UserContext(userId: userId, nickname: nickname);
  }

  Future<T> _step<T>(String name, Future<T> Function() action) async {
    try {
      final T result = await action();
      _results.add(CheckResult.pass(name));
      return result;
    } catch (error) {
      _results.add(CheckResult.fail(name, _describeError(error)));
      rethrow;
    }
  }

  void _check(String name, bool condition, String pass, String fail) {
    if (condition) {
      _results.add(CheckResult.pass('$name: $pass'));
      return;
    }
    _results.add(CheckResult.fail(name, fail));
    throw StateError(fail);
  }

  void _printSummary({
    required UserContext author,
    required UserContext reactor,
    required String starId,
  }) {
    final Map<String, dynamic> summary = <String, dynamic>{
      'supabase_url': config.supabaseUrl,
      'author_user_id': author.userId,
      'reactor_user_id': reactor.userId,
      'created_star_id': starId,
      'checks': _results.map((CheckResult result) => result.toJson()).toList(),
    };
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    print(encoder.convert(summary));
  }

  List<Map<String, dynamic>> _asRows(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _firstRow(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      return raw.first as Map<String, dynamic>;
    }
    throw StateError('Unexpected response shape: ${jsonEncode(raw)}');
  }

  void _requireKeys(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      _require(row.containsKey(key), 'Missing response key: $key');
    }
  }

  void _require(bool condition, String message) {
    if (!condition) {
      throw StateError(message);
    }
  }

  String _errorCode(Object error) {
    if (error is PostgrestException) {
      final Object? details = error.details;
      if (details is Map<String, dynamic>) {
        final Object? appCode = details['APP_ERROR_CODE'];
        if (appCode is String && appCode.isNotEmpty) {
          return appCode;
        }
      }
      final String? messageCode = _extractKnownCode(error.message);
      if (messageCode != null) {
        return messageCode;
      }
      return error.code ?? 'INTERNAL_ERROR';
    }
    final String? messageCode = _extractKnownCode(error.toString());
    return messageCode ?? 'INTERNAL_ERROR';
  }

  String _describeError(Object error) {
    if (error is PostgrestException) {
      return 'PostgrestException(code=${error.code}, message=${error.message}, details=${error.details})';
    }
    return error.toString();
  }

  String? _extractKnownCode(String text) {
    for (final String code in _knownCodes) {
      if (text.contains(code)) {
        return code;
      }
    }
    return null;
  }
}

class UserContext {
  const UserContext({required this.userId, required this.nickname});

  final String userId;
  final String nickname;
}

class CheckResult {
  const CheckResult._({required this.name, required this.status, this.error});

  factory CheckResult.pass(String name) {
    return CheckResult._(name: name, status: 'pass');
  }

  factory CheckResult.fail(String name, String error) {
    return CheckResult._(name: name, status: 'fail', error: error);
  }

  final String name;
  final String status;
  final String? error;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'status': status,
      if (error != null) 'error': error,
    };
  }
}

const List<String> _knownCodes = <String>[
  'UNAUTHORIZED',
  'FORBIDDEN',
  'STAR_NOT_FOUND',
  'ALREADY_REACTED',
  'DAILY_STAR_LIMIT_EXCEEDED',
  'DAILY_REACTION_LIMIT_EXCEEDED',
  'BLOCKED_RELATIONSHIP',
  'SELF_REACTION_NOT_ALLOWED',
  'INVALID_ARGUMENT',
  'INTERNAL_ERROR',
];
