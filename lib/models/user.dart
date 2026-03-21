class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? createdAt;
  final String? accountNumber;
  final double? balance;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'active',
    this.createdAt,
    this.accountNumber,
    this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
      accountNumber: json['account_number'],
      balance: json['balance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (accountNumber != null) 'account_number': accountNumber,
      if (balance != null) 'balance': balance,
    };
  }
}
