class Notification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
