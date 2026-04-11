class Star {
  const Star({
    required this.starId,
    required this.userId,
    required this.content,
    required this.tagIds,
    required this.tagNames,
    required this.timeBucket,
    required this.reactionCount,
    required this.createdAt,
    required this.expiresAt,
    required this.relationScore,
    required this.isSeen,
    required this.visibilityStatus,
    required this.isDeleted,
    required this.isExpired,
    required this.isReactable,
    required this.diversityKey,
  });

  final String starId;
  final String userId;
  final String content;
  final List<int> tagIds;
  final List<String> tagNames;
  final String timeBucket;
  final int reactionCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final double relationScore;
  final bool isSeen;
  final String visibilityStatus;
  final bool isDeleted;
  final bool isExpired;
  final bool isReactable;
  final String diversityKey;

  factory Star.fromFeedMap(Map<String, dynamic> map) {
    final List<int> parsedTagIds = _asIntList(map['tag_ids']);
    final String fallbackGroup = parsedTagIds.isNotEmpty
        ? 'tag:${parsedTagIds.first}'
        : 'bucket:${map['time_bucket'] as String? ?? 'unknown'}';

    return Star(
      starId: map['star_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      tagIds: parsedTagIds,
      tagNames: _asStringList(map['tag_names']),
      timeBucket: map['time_bucket'] as String? ?? 'unknown',
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      createdAt: _asDateTime(map['created_at']),
      expiresAt: _asNullableDateTime(map['expires_at']),
      relationScore: (map['relation_score'] as num?)?.toDouble() ?? 0,
      isSeen: map['is_seen'] == true,
      visibilityStatus: map['visibility_status'] as String? ?? 'public',
      isDeleted: map['is_deleted'] == true,
      isExpired: map['is_expired'] == true,
      isReactable: map['is_reactable'] != false,
      diversityKey: map['emotion_group'] as String? ?? fallbackGroup,
    );
  }

  factory Star.fromDetailMap(Map<String, dynamic> map) {
    final DateTime? expiresAt = _asNullableDateTime(map['expires_at']);
    final bool expiredByTime =
        expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc());
    final bool isExpired = map['is_expired'] == true || expiredByTime;

    return Star(
      starId: map['star_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      tagIds: _asIntList(map['tag_ids']),
      tagNames: _asStringList(map['tag_names']),
      timeBucket: map['time_bucket'] as String? ?? 'unknown',
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      createdAt: _asDateTime(map['created_at']),
      expiresAt: expiresAt,
      relationScore: (map['relation_score'] as num?)?.toDouble() ?? 0,
      isSeen: map['is_seen'] == true,
      visibilityStatus: map['visibility_status'] as String? ?? 'public',
      isDeleted: map['is_deleted'] == true,
      isExpired: isExpired,
      isReactable: map['is_reactable'] == true,
      diversityKey: _asStringList(map['tag_names']).isNotEmpty
          ? 'tagName:${_asStringList(map['tag_names']).first}'
          : 'detail',
    );
  }

  static List<int> _asIntList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<dynamic>()
          .map((dynamic item) => (item as num).toInt())
          .toList(growable: false);
    }
    return const <int>[];
  }

  static List<String> _asStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((dynamic item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid datetime value');
  }

  static DateTime? _asNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return null;
  }
}
