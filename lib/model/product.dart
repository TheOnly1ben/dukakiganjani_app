class Product {
  final String? id;
  final String storeId;
  final String? categoryId;
  final String? subCategoryId;
  final String name;
  final String? sku;
  final String? productCode;
  final double? costPrice;
  final double sellingPrice;
  final double? wholesalePrice;
  final double? discountPrice;
  final double? quantity;
  final int? lowStockAlert;
  final bool isActive;
  final String? description;
  final String? supplierName;
  final DateTime? expiryDate;
  final String? batchNumber;
  final Map<String, dynamic>? variants;
  final DateTime? supplierDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductMedia>? media;

  Product({
    this.id,
    required this.storeId,
    this.categoryId,
    this.subCategoryId,
    required this.name,
    this.sku,
    this.productCode,
    this.costPrice,
    required this.sellingPrice,
    this.wholesalePrice,
    this.discountPrice,
    this.quantity,
    this.lowStockAlert,
    this.isActive = true,
    this.description,
    this.supplierName,
    this.expiryDate,
    this.batchNumber,
    this.variants,
    this.supplierDate,
    this.createdAt,
    this.updatedAt,
    this.media,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      categoryId: json['category_id'],
      subCategoryId: json['sub_category_id'],
      name: json['name'],
      sku: json['sku'],
      productCode: json['product_code'],
      costPrice: json['cost_price']?.toDouble(),
      sellingPrice: json['selling_price']?.toDouble() ?? 0.0,
      wholesalePrice: json['wholesale_price']?.toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      quantity: json['quantity']?.toDouble(),
      lowStockAlert: json['low_stock_alert']?.toInt(),
      isActive: json['is_active'] ?? true,
      description: json['description'],
      supplierName: json['supplier_name'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      batchNumber: json['batch_number'],
      variants: json['variants'],
      supplierDate: json['supplier_date'] != null
          ? DateTime.parse(json['supplier_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      media: json['media'] != null
          ? (json['media'] as List)
              .map((e) => ProductMedia.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'name': name,
      'sku': sku,
      'product_code': productCode,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'wholesale_price': wholesalePrice,
      'discount_price': discountPrice,
      'quantity': quantity,
      'low_stock_alert': lowStockAlert,
      'is_active': isActive,
      'description': description,
      'supplier_name': supplierName,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0], // Date only
      'batch_number': batchNumber,
      'variants': variants,
      'supplier_date':
          supplierDate?.toIso8601String().split('T')[0], // Date only
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? storeId,
    String? categoryId,
    String? subCategoryId,
    String? name,
    String? sku,
    String? productCode,
    double? costPrice,
    double? sellingPrice,
    double? wholesalePrice,
    double? discountPrice,
    double? quantity,
    int? lowStockAlert,
    bool? isActive,
    String? description,
    String? supplierName,
    DateTime? expiryDate,
    String? batchNumber,
    Map<String, dynamic>? variants,
    DateTime? supplierDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProductMedia>? media,
  }) {
    return Product(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      productCode: productCode ?? this.productCode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      discountPrice: discountPrice ?? this.discountPrice,
      quantity: quantity ?? this.quantity,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      supplierName: supplierName ?? this.supplierName,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      variants: variants ?? this.variants,
      supplierDate: supplierDate ?? this.supplierDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      media: media ?? this.media,
    );
  }
}

class ProductMedia {
  final String? id;
  final String productId;
  final String storeId;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final bool isPrimary;
  final int sortOrder;
  final DateTime? createdAt;

  ProductMedia({
    this.id,
    required this.productId,
    required this.storeId,
    required this.mediaUrl,
    required this.mediaType,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory ProductMedia.fromJson(Map<String, dynamic> json) {
    return ProductMedia(
      id: json['id'],
      productId: json['product_id'],
      storeId: json['store_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      isPrimary: json['is_primary'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'store_id': storeId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ProductMedia copyWith({
    String? id,
    String? productId,
    String? storeId,
    String? mediaUrl,
    String? mediaType,
    bool? isPrimary,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return ProductMedia(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
