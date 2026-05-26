class ComfortGift {
  const ComfortGift({
    required this.id,
    required this.starId,
    required this.starContent,
    required this.giftType,
    required this.title,
    required this.description,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.openedAt,
  });

  final String id;
  final String starId;
  final String starContent;
  final String giftType;
  final String title;
  final String description;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? openedAt;

  factory ComfortGift.fromMap(Map<String, dynamic> map) {
    return ComfortGift(
      id: map['gift_id'] as String? ?? '',
      starId: map['star_id'] as String? ?? '',
      starContent: map['star_content'] as String? ?? '',
      giftType: map['gift_type'] as String? ?? 'coffee',
      title: map['title'] as String? ?? '커피 선물',
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'reserved',
      imageUrl: _asNullableString(map['image_url']),
      createdAt: _asDateTime(map['created_at']),
      openedAt: _asNullableDateTime(map['opened_at']),
    );
  }

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  static String? _asNullableString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
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
