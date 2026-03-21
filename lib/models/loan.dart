class Loan {
  final int id;
  final int userId;
  final double amount;
  final String purpose;
  final String status;
  final String? createdAt;
  final String? userName;
  final String? accountNumber;

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.purpose,
    required this.status,
    this.createdAt,
    this.userName,
    this.accountNumber,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      amount: json['amount']?.toDouble() ?? 0.0,
      purpose: json['purpose'],
      status: json['status'],
      createdAt: json['created_at'],
      userName: json['user_name'] ?? json['userName'],
      accountNumber: json['account_number'] ?? json['accountNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'purpose': purpose,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (userName != null) 'user_name': userName,
      if (accountNumber != null) 'account_number': accountNumber,
    };
  }
}
