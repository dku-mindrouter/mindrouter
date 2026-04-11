class CreateStarResult {
  const CreateStarResult({
    required this.starId,
    required this.createdAt,
    required this.createdLocalDate,
  });

  final String starId;
  final DateTime createdAt;
  final DateTime createdLocalDate;

  factory CreateStarResult.fromMap(Map<String, dynamic> map) {
    return CreateStarResult(
      starId: map['star_id'] as String? ?? '',
      createdAt: _asDateTime(map['created_at']),
      createdLocalDate: _asDateTime(map['created_local_date']),
    );
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
}
