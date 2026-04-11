class EmotionTag {
  const EmotionTag({
    required this.id,
    required this.nameKo,
    required this.groupName,
    required this.priority,
    required this.isActive,
  });

  final int id;
  final String nameKo;
  final String groupName;
  final int priority;
  final bool isActive;

  factory EmotionTag.fromMap(Map<String, dynamic> map) {
    return EmotionTag(
      id: (map['id'] as num).toInt(),
      nameKo: map['name_ko'] as String? ?? '',
      groupName: map['group_name'] as String? ?? '',
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] == true,
    );
  }
}
