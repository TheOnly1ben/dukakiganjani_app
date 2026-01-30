class Debt {
  final String? id;
  final String storeId;
  final String saleId;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status; // 'pending', 'paid', 'overdue'
  final DateTime saleDate;
  final DateTime? lastPaymentDate;
  final DateTime createdAt;
  final List<DebtPayment>? payments;

  Debt({
    this.id,
    required this.storeId,
    required this.saleId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.saleDate,
    this.lastPaymentDate,
    required this.createdAt,
    this.payments,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      storeId: json['store_id'],
      saleId: json['sale_id'],
      customerName: json['customer_name'] ?? 'Unknown Customer',
      customerPhone: json['customer_phone'],
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      paidAmount: json['paid_amount']?.toDouble() ?? 0.0,
      remainingAmount: json['remaining_amount']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      saleDate: DateTime.parse(json['sale_date']),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      payments: json['debt_payments'] != null
          ? (json['debt_payments'] as List)
              .map((payment) => DebtPayment.fromJson(payment))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'sale_id': saleId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'sale_date': saleDate.toIso8601String(),
      if (lastPaymentDate != null) 'last_payment_date': lastPaymentDate!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Debt copyWith({
    String? id,
    String? storeId,
    String? saleId,
    String? customerName,
    String? customerPhone,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? status,
    DateTime? saleDate,
    DateTime? lastPaymentDate,
    DateTime? createdAt,
    List<DebtPayment>? payments,
  }) {
    return Debt(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      saleId: saleId ?? this.saleId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      saleDate: saleDate ?? this.saleDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      createdAt: createdAt ?? this.createdAt,
      payments: payments ?? this.payments,
    );
  }
}

class DebtPayment {
  final String? id;
  final String debtId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'],
      debtId: json['debt_id'],
      amount: json['amount']?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      notes: json['notes'],
      paymentDate: DateTime.parse(json['payment_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
