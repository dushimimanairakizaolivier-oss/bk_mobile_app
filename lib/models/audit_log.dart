class AuditLog {
  final int id;
  final int adminId;
  final String action;
  final String details;
  final String? createdAt;
  final String? adminName;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.details,
    this.createdAt,
    this.adminName,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      adminId: json['admin_id'] ?? json['adminId'],
      action: json['action'],
      details: json['details'],
      createdAt: json['created_at'],
      adminName: json['admin_name'] ?? json['adminName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'action': action,
      'details': details,
      if (createdAt != null) 'created_at': createdAt,
      if (adminName != null) 'admin_name': adminName,
    };
  }
}
