class PaymentMethod {
  final String type; // 'upi' or 'bank'
  final Map<String, String> details;

  PaymentMethod({required this.type, required this.details});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: json['type'] as String,
      details: Map<String, String>.from(json['details'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'details': details};
  }

  static PaymentMethod createUPI(String upiId) {
    return PaymentMethod(type: 'upi', details: {'upiId': upiId});
  }

  static PaymentMethod createBankAccount({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) {
    return PaymentMethod(
      type: 'bank',
      details: {
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'accountHolderName': accountHolderName,
      },
    );
  }
}
