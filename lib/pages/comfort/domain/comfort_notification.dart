class ComfortNotification {
  const ComfortNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.eventAt,
    required this.icon,
    required this.accentColor,
    required this.isOpened,
  });

  final String id;
  final String notificationType;
  final String title;
  final String body;
  final DateTime eventAt;
  final String icon;
  final String accentColor;
  final bool isOpened;

  factory ComfortNotification.fromMap(Map<String, dynamic> map) {
    return ComfortNotification(
      id: map['notification_id'] as String? ?? '',
      notificationType: map['notification_type'] as String? ?? 'reaction',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      eventAt:
          DateTime.tryParse(map['event_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      icon: map['icon'] as String? ?? 'favorite',
      accentColor: map['accent_color'] as String? ?? 'indigo',
      isOpened: map['is_opened'] == true,
    );
  }
}
