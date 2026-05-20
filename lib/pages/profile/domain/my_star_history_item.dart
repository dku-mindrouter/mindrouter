class MyStarHistoryItem {
  const MyStarHistoryItem({
    required this.id,
    required this.content,
    required this.tagNames,
    required this.timeBucket,
    required this.reactionCount,
    required this.createdAt,
    required this.createdLocalDate,
    required this.visibilityStatus,
    required this.isDeleted,
    required this.isExpired,
  });

  final String id;
  final String content;
  final List<String> tagNames;
  final String timeBucket;
  final int reactionCount;
  final DateTime createdAt;
  final DateTime createdLocalDate;
  final String visibilityStatus;
  final bool isDeleted;
  final bool isExpired;

  factory MyStarHistoryItem.fromMap(Map<String, dynamic> map) {
    return MyStarHistoryItem(
      id: map['star_id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      tagNames: _asStringList(map['tag_names']),
      timeBucket: map['time_bucket'] as String? ?? '',
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      createdAt: _asDateTime(map['created_at']),
      createdLocalDate: _asDateTime(map['created_local_date']),
      visibilityStatus: map['visibility_status'] as String? ?? 'public',
      isDeleted: map['is_deleted'] == true,
      isExpired: map['is_expired'] == true,
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<Object>()
        .map((Object item) => item.toString())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid star history date value');
  }
}
