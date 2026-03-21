class Account {
  final int id;
  final int userId;
  final String accountNumber;
  final double balance;
  final String type;
  final String status;

  Account({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.balance,
    required this.type,
    required this.status,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      accountNumber: json['account_number'] ?? json['accountNumber'],
      balance: json['balance']?.toDouble() ?? 0.0,
      type: json['type'] ?? 'savings',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_number': accountNumber,
      'balance': balance,
      'type': type,
      'status': status,
    };
  }
}
