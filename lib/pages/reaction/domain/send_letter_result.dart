class SendLetterResult {
  const SendLetterResult({
    required this.letterId,
    required this.reactionId,
    required this.starId,
    required this.reactionCount,
    required this.deliverAt,
  });

  final String letterId;
  final String reactionId;
  final String starId;
  final int reactionCount;
  final DateTime deliverAt;

  factory SendLetterResult.fromMap(Map<String, dynamic> map) {
    return SendLetterResult(
      letterId: map['letter_id'] as String? ?? '',
      reactionId: map['reaction_id'] as String? ?? '',
      starId: map['star_id'] as String? ?? '',
      reactionCount: (map['reaction_count'] as num?)?.toInt() ?? 0,
      deliverAt: _asDateTime(map['deliver_at']),
    );
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid deliver_at value');
  }
}
