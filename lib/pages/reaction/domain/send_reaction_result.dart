class SendReactionResult {
  const SendReactionResult({
    required this.reactionId,
    required this.starId,
    required this.reactionCount,
    required this.createdAt,
  });

  final String reactionId;
  final String starId;
  final int reactionCount;
  final DateTime createdAt;

  factory SendReactionResult.fromMap(Map<String, dynamic> map) {
    return SendReactionResult(
      reactionId: map['reaction_id'] as String? ?? '',
      starId: map['star_id'] as String? ?? '',
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      createdAt: _asDateTime(map['created_at']),
    );
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid created_at value');
  }
}
