class Transaction {
  final int id;
  final int accountId;
  final String type;
  final double amount;
  final String description;
  final String? relatedAccountNumber;
  final String? createdAt;
  final String? reference;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    this.relatedAccountNumber,
    this.createdAt,
    this.reference,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['account_id'] ?? json['accountId'],
      type: json['type'],
      amount: json['amount']?.toDouble() ?? 0.0,
      description: json['description'],
      relatedAccountNumber: json['related_account_number'] ?? json['relatedAccountNumber'],
      createdAt: json['created_at'] ?? json['timestamp'],
      reference: json['reference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'type': type,
      'amount': amount,
      'description': description,
      if (relatedAccountNumber != null) 'related_account_number': relatedAccountNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (reference != null) 'reference': reference,
    };
  }
}
