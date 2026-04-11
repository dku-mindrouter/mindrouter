class ReactionType {
  const ReactionType({
    required this.id,
    required this.code,
    required this.labelKo,
    required this.icon,
  });

  final int id;
  final String code;
  final String labelKo;
  final String icon;

  factory ReactionType.fromMap(Map<String, dynamic> map) {
    return ReactionType(
      id: (map['id'] as num?)?.toInt() ?? 0,
      code: map['code'] as String? ?? '',
      labelKo: map['label_ko'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
    );
  }
}
