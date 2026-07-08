class NotificationItem {
  final String id;
  final String title;
  final String? subtitle;
  final String type; // deadline | pc_alarm | status | gate
  final DateTime firedAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.firedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'firedAt': firedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      type: json['type']?.toString() ?? 'status',
      firedAt: DateTime.tryParse(json['firedAt']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] == true,
    );
  }
}
