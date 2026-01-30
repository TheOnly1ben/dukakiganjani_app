class Expense {
  final String? id;
  final String storeId;
  final String purpose;
  final double amount;
  final String? paymentMethod;
  final String? notes;
  final DateTime expenseDate;
  final String createdBy;
  final DateTime? createdAt;

  Expense({
    this.id,
    required this.storeId,
    required this.purpose,
    required this.amount,
    this.paymentMethod,
    this.notes,
    required this.expenseDate,
    required this.createdBy,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      storeId: json['store_id'],
      purpose: json['purpose'],
      amount: json['amount']?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      expenseDate: DateTime.parse(json['expense_date']),
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'purpose': purpose,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'expense_date': expenseDate.toIso8601String().split('T')[0], // Date only
      'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? storeId,
    String? purpose,
    double? amount,
    String? paymentMethod,
    String? notes,
    DateTime? expenseDate,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      purpose: purpose ?? this.purpose,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      expenseDate: expenseDate ?? this.expenseDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
