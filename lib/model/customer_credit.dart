class CustomerCredit {
  final String? id;
  final String storeId;
  final String saleId;
  final String customerName;
  final String? customerPhone;
  final double totalCredit;
  final double paidAmount;
  final double balance; // Generated field: totalCredit - paidAmount
  final String status; // 'unpaid', 'partial', 'paid'
  final DateTime? dueDate;
  final DateTime createdAt;

  CustomerCredit({
    this.id,
    required this.storeId,
    required this.saleId,
    required this.customerName,
    this.customerPhone,
    required this.totalCredit,
    required this.paidAmount,
    required this.balance,
    required this.status,
    this.dueDate,
    required this.createdAt,
  });

  factory CustomerCredit.fromJson(Map<String, dynamic> json) {
    return CustomerCredit(
      id: json['id'],
      storeId: json['store_id'],
      saleId: json['sale_id'],
      customerName: json['customer_name'] ?? 'Unknown Customer',
      customerPhone: json['customer_phone'],
      totalCredit: json['total_credit']?.toDouble() ?? 0.0,
      paidAmount: json['paid_amount']?.toDouble() ?? 0.0,
      balance: json['balance']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'unpaid',
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'sale_id': saleId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_credit': totalCredit,
      'paid_amount': paidAmount,
      'balance': balance,
      'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  CustomerCredit copyWith({
    String? id,
    String? storeId,
    String? saleId,
    String? customerName,
    String? customerPhone,
    double? totalCredit,
    double? paidAmount,
    double? balance,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return CustomerCredit(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      saleId: saleId ?? this.saleId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalCredit: totalCredit ?? this.totalCredit,
      paidAmount: paidAmount ?? this.paidAmount,
      balance: balance ?? this.balance,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CustomerCreditPayment {
  final String? id;
  final String creditId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  CustomerCreditPayment({
    this.id,
    required this.creditId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
  });

  factory CustomerCreditPayment.fromJson(Map<String, dynamic> json) {
    return CustomerCreditPayment(
      id: json['id'],
      creditId: json['credit_id'],
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
      'credit_id': creditId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
