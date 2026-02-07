import 'product.dart';

class SaleItem {
  final String? id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double? costPrice;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.costPrice,
  });

  double get profit =>
      costPrice != null ? (unitPrice - costPrice!) * quantity : 0.0;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      saleId: json['sale_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: json['unit_price']?.toDouble() ?? 0.0,
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      costPrice: json['cost_price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      if (costPrice != null) 'cost_price': costPrice,
    };
  }
}

enum PaymentMethod {
  cash,
  credit,
}

enum SaleStatus {
  completed,
  pending,
  cancelled,
}

class Sale {
  final String? id;
  final String storeId;
  final String soldBy;
  final List<SaleItem> items;
  final PaymentMethod paymentMethod;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final SaleStatus status;
  final DateTime? createdAt;

  Sale({
    this.id,
    required this.storeId,
    required this.soldBy,
    required this.items,
    required this.paymentMethod,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.status = SaleStatus.completed,
    this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      storeId: json['store_id'],
      soldBy: json['sold_by'],
      items: (json['sale_items'] as List<dynamic>?)
              ?.map((item) => SaleItem.fromJson(item))
              .toList() ??
          [],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      status: SaleStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'completed'),
        orElse: () => SaleStatus.completed,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'sold_by': soldBy,
      'payment_method': paymentMethod.toString().split('.').last,
      'total_amount': totalAmount,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status.toString().split('.').last,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class Payment {
  final String? id;
  final String saleId;
  final double amount;
  final String method;
  final DateTime? createdAt;

  Payment({
    this.id,
    required this.saleId,
    required this.amount,
    required this.method,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      saleId: json['sale_id'],
      amount: json['amount']?.toDouble() ?? 0.0,
      method: json['method'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sale_id': saleId,
      'amount': amount,
      'method': method,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.sellingPrice * quantity;
  String get productId => product.id!;
  String get productName => product.name;
  double get price => product.sellingPrice;
}
