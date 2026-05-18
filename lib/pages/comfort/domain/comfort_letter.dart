class ComfortLetter {
  const ComfortLetter({
    required this.id,
    required this.starId,
    required this.starContent,
    required this.content,
    required this.deliveredAt,
    required this.openedAt,
  });

  final String id;
  final String starId;
  final String starContent;
  final String content;
  final DateTime deliveredAt;
  final DateTime? openedAt;

  factory ComfortLetter.fromMap(Map<String, dynamic> map) {
    return ComfortLetter(
      id: map['letter_id'] as String? ?? '',
      starId: map['star_id'] as String? ?? '',
      starContent: map['star_content'] as String? ?? '',
      content: map['content'] as String? ?? '',
      deliveredAt: _asDateTime(map['delivered_at']),
      openedAt: _asNullableDateTime(map['opened_at']),
    );
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw const FormatException('Invalid delivered_at value');
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
