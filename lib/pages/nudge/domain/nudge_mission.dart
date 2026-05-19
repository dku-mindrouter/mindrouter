class NudgeMission {
  const NudgeMission({
    required this.deliveryId,
    required this.templateId,
    required this.missionType,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.durationMinutes,
    required this.checklist,
    required this.ctaLabel,
    required this.accentIcon,
    required this.accentStartColor,
    required this.accentEndColor,
    required this.deliveryLocalDate,
    required this.openedAt,
    required this.startedAt,
    required this.completedAt,
  });

  final String deliveryId;
  final int templateId;
  final String missionType;
  final String title;
  final String subtitle;
  final String body;
  final int durationMinutes;
  final List<String> checklist;
  final String ctaLabel;
  final String accentIcon;
  final String accentStartColor;
  final String accentEndColor;
  final DateTime deliveryLocalDate;
  final DateTime? openedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isStarted => startedAt != null;
  bool get isCompleted => completedAt != null;

  String get actionLabel {
    if (isCompleted) {
      return '오늘 미션 완료';
    }
    if (isStarted) {
      return '미션 완료하기';
    }
    return ctaLabel;
  }

  String get statusLabel {
    if (isCompleted) {
      return '완료됨';
    }
    if (isStarted) {
      return '진행 중';
    }
    return '시작 전';
  }

  factory NudgeMission.fromMap(Map<String, dynamic> map) {
    return NudgeMission(
      deliveryId: map['delivery_id'] as String? ?? '',
      templateId: (map['template_id'] as num?)?.toInt() ?? 0,
      missionType: map['mission_type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      body: map['body'] as String? ?? '',
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 10,
      checklist: _parseChecklist(map['checklist_json']),
      ctaLabel: map['cta_label'] as String? ?? '미션 시작하기',
      accentIcon: map['accent_icon'] as String? ?? 'wb_sunny_outlined',
      accentStartColor: map['accent_start_color'] as String? ?? 'amber',
      accentEndColor: map['accent_end_color'] as String? ?? 'orange',
      deliveryLocalDate: _asDateTime(map['delivery_local_date']),
      openedAt: _asNullableDateTime(map['opened_at']),
      startedAt: _asNullableDateTime(map['started_at']),
      completedAt: _asNullableDateTime(map['completed_at']),
    );
  }

  factory NudgeMission.previewMock() {
    return NudgeMission(
      deliveryId: 'preview-mission',
      templateId: 0,
      missionType: 'mission_walk',
      title: '햇살과 함께 10분 걷기',
      subtitle: '몸을 조금만 움직여도 생각의 밀도가 느슨해질 수 있어요.',
      body: '천천히 걷고, 숨이 차지 않을 정도로 몸의 긴장을 풀어보세요.',
      durationMinutes: 10,
      checklist: const <String>[
        '편한 신발을 신고 밖으로 나가기',
        '좋아하는 음악과 함께 10분 걷기',
        '하늘이나 나무를 한 번 천천히 바라보기',
      ],
      ctaLabel: '미션 시작하기',
      accentIcon: 'wb_sunny_outlined',
      accentStartColor: 'amber',
      accentEndColor: 'orange',
      deliveryLocalDate: DateTime.now(),
      openedAt: DateTime.now(),
      startedAt: null,
      completedAt: null,
    );
  }

  static List<String> _parseChecklist(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((dynamic item) => item?.toString() ?? '')
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
    return DateTime.now();
  }

  static DateTime? _asNullableDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
