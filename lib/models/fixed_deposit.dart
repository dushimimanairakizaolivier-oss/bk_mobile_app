class FixedDeposit {
  final int id;
  final int userId;
  final double amount;
  final int termMonths;
  final double interestRate;
  final String status;
  final String? createdAt;

  FixedDeposit({
    required this.id,
    required this.userId,
    required this.amount,
    required this.termMonths,
    required this.interestRate,
    required this.status,
    this.createdAt,
  });

  factory FixedDeposit.fromJson(Map<String, dynamic> json) {
    return FixedDeposit(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      amount: json['amount']?.toDouble() ?? 0.0,
      termMonths: json['term_months'] ?? json['termMonths'] ?? 0,
      interestRate: json['interest_rate']?.toDouble() ?? json['interestRate']?.toDouble() ?? 0.0,
      status: json['status'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'term_months': termMonths,
      'interest_rate': interestRate,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
