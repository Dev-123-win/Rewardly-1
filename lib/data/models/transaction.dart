class Transaction {
  final String id;
  final String userId;
  final String type;
  final String subType;
  final int amount;
  final DateTime timestamp;
  final String status;
  final Map<String, dynamic>? metadata;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.subType,
    required this.amount,
    required this.timestamp,
    required this.status,
    this.metadata,
  });

  // Convert Transaction to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'subType': subType,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'metadata': metadata,
    };
  }

  // Create Transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      subType: json['subType'] ?? '',
      amount: json['amount'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'completed',
      metadata: json['metadata'],
    );
  }

  // Format subType for display (convert snake_case to Title Case)
  String get formattedSubType {
    return subType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
