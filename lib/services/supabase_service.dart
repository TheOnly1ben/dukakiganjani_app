import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/store.dart';
import '../model/category.dart' as model_category;
import '../model/category.dart' show SubCategory;
import '../model/product.dart';
import '../model/sales.dart';
import '../model/expenses.dart';
import '../model/debt.dart';
import '../model/customer_credit.dart';
import '../model/employees.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<AuthResponse> registerOwner({
    required String fullName,
    required String phone,
    required String pin,
    String? email,
  }) async {
    // Create fake email using phone number
    final fakeEmail = '$phone@dukakiganjani.com';

    // Create password as pin@phone
    final password = '$pin@$phone';

    // Register with Supabase Auth
    final authResponse = await _client.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (authResponse.user != null) {
      // Insert into owner_profiles table
      await _client.from('owner_profiles').insert({
        'auth_id': authResponse.user!.id,
        'full_name': fullName,
        'email': email,
        'phone': phone, // Store phone without +255 prefix to fit VARCHAR(12)
      });
    }

    return authResponse;
  }

  static Future<AuthResponse> loginOwner({
    required String phone,
    required String pin,
  }) async {
    // Create fake email using phone number
    final fakeEmail = '$phone@dukakiganjani.com';

    // Create password as pin@phone
    final password = '$pin@$phone';

    // Login with Supabase Auth
    final authResponse = await _client.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );

    return authResponse;
  }

  static Future<void> updateOwnerPhone({
    required String authId,
    required String newPhone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Update phone in owner_profiles table
    await _client
        .from('owner_profiles')
        .update({'phone': newPhone}).eq('auth_id', authId);
  }

  static Future<List<Store>> getStoresForUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('stores')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Store.fromJson(json)).toList();
  }

  static Future<Store> addStore({
    required String name,
    required String type,
    String? description,
    String? location,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final storeData = {
      'owner_id': user.id,
      'name': name,
      'type': type,
      'description': description,
      'location': location,
      'status': 'Active',
      'currency': 'TZS',
      'country': 'Tanzania',
    };

    final response =
        await _client.from('stores').insert(storeData).select().single();

    return Store.fromJson(response);
  }

  static Future<Store> updateStore({
    required String storeId,
    required String name,
    required String type,
    String? description,
    String? location,
    String? status,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      'name': name,
      'type': type,
      'description': description,
      'location': location,
      if (status != null) 'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('stores')
        .update(updateData)
        .eq('id', storeId)
        .eq('owner_id', user.id) // Ensure user can only update their own stores
        .select()
        .single();

    return Store.fromJson(response);
  }

  static Future<void> deleteStore(String storeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('stores').delete().eq('id', storeId).eq(
          'owner_id',
          user.id,
        ); // Ensure user can only delete their own stores
  }

  static Future<Store> toggleStoreStatus(String storeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First get the current status
    final currentStore = await _client
        .from('stores')
        .select()
        .eq('id', storeId)
        .eq('owner_id', user.id)
        .single();

    final newStatus =
        currentStore['status'] == 'Active' ? 'Inactive' : 'Active';

    // Update the status
    final response = await _client
        .from('stores')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', storeId)
        .eq('owner_id', user.id)
        .select()
        .single();

    return Store.fromJson(response);
  }

  // Category CRUD operations
  static Future<List<model_category.Category>> getCategoriesForStore(
    String storeId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('categories')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => model_category.Category.fromJson(json))
        .toList();
  }

  static Future<model_category.Category> addCategory({
    required String storeId,
    required String name,
    String? description,
    int sortOrder = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final categoryData = {
      'store_id': storeId,
      'name': name,
      'description': description,
      'sort_order': sortOrder,
    };

    final response =
        await _client.from('categories').insert(categoryData).select().single();

    return model_category.Category.fromJson(response);
  }

  static Future<model_category.Category> updateCategory({
    required String categoryId,
    required String name,
    String? description,
    bool? isActive,
    int? sortOrder,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      'name': name,
      'description': description,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('categories')
        .update(updateData)
        .eq('id', categoryId)
        .select()
        .single();

    return model_category.Category.fromJson(response);
  }

  static Future<void> deleteCategory(String categoryId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('categories').delete().eq('id', categoryId);
  }

  // SubCategory CRUD operations
  static Future<List<SubCategory>> getSubCategoriesForCategory(
    String categoryId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('sub_categories')
        .select()
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SubCategory.fromJson(json))
        .toList();
  }

  static Future<SubCategory> addSubCategory({
    required String categoryId,
    required String storeId,
    required String name,
    String? description,
    int sortOrder = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final subCategoryData = {
      'category_id': categoryId,
      'store_id': storeId,
      'name': name,
      'description': description,
      'sort_order': sortOrder,
    };

    final response = await _client
        .from('sub_categories')
        .insert(subCategoryData)
        .select()
        .single();

    return SubCategory.fromJson(response);
  }

  static Future<SubCategory> updateSubCategory({
    required String subCategoryId,
    required String name,
    String? description,
    bool? isActive,
    int? sortOrder,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      'name': name,
      'description': description,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('sub_categories')
        .update(updateData)
        .eq('id', subCategoryId)
        .select()
        .single();

    return SubCategory.fromJson(response);
  }

  static Future<void> deleteSubCategory(String subCategoryId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('sub_categories').delete().eq('id', subCategoryId);
  }

  // Product CRUD operations
  static Future<List<Product>> getProductsForStore(
    String storeId, {
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    dynamic query = _client
        .from('products')
        .select('*, product_media(*)')
        .eq('store_id', storeId);

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  static Future<Product> getProductById(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('products')
        .select('*, product_media(*)')
        .eq('id', productId)
        .single();

    return Product.fromJson(response);
  }

  static Future<Product> addProduct({
    required String storeId,
    String? categoryId,
    String? subCategoryId,
    required String name,
    String? sku,
    String? productCode,
    double? costPrice,
    required double sellingPrice,
    double? wholesalePrice,
    double? discountPrice,
    double? quantity,
    int? lowStockAlert,
    String? description,
    String? supplierName,
    DateTime? expiryDate,
    String? batchNumber,
    DateTime? supplierDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final productData = {
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
      'description': description,
      'supplier_name': supplierName,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'batch_number': batchNumber,
      'supplier_date': supplierDate?.toIso8601String().split('T')[0],
    };

    final response = await _client
        .from('products')
        .insert(productData)
        .select('*, product_media(*)')
        .single();

    return Product.fromJson(response);
  }

  static Future<Product> updateProduct({
    required String productId,
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
    DateTime? supplierDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (productCode != null) 'product_code': productCode,
      if (costPrice != null) 'cost_price': costPrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (discountPrice != null) 'discount_price': discountPrice,
      if (quantity != null) 'quantity': quantity,
      if (lowStockAlert != null) 'low_stock_alert': lowStockAlert,
      if (isActive != null) 'is_active': isActive,
      if (description != null) 'description': description,
      if (supplierName != null) 'supplier_name': supplierName,
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      if (batchNumber != null) 'batch_number': batchNumber,
      'supplier_date': supplierDate?.toIso8601String().split('T')[0],
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('products')
        .update(updateData)
        .eq('id', productId)
        .select('*, product_media(*)')
        .single();

    return Product.fromJson(response);
  }

  static Future<void> deleteProduct(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('products').delete().eq('id', productId);
  }

  // Product Media operations
  static Future<ProductMedia> uploadProductMedia({
    required String productId,
    required String storeId,
    required String filePath,
    required String fileName,
    required String mediaType,
    bool isPrimary = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Mtumiaji hajajiandikisha. Tafadhali ingia tena.');
    }

    // Step 1: Validate file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Faili halipatikani: $filePath');
    }

    // Step 2: Validate file size (max 10MB for free tier)
    final fileSize = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      throw Exception(
        'Faili kubwa sana (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Kiwango cha juu: 10MB',
      );
    }

    debugPrint(
      '📤 Kuanza kupakia picha: $fileName (${(fileSize / 1024).toStringAsFixed(1)}KB)',
    );

    // Step 3: Check if products bucket exists (skip strict validation)
    try {
      final buckets = await _client.storage.listBuckets();
      debugPrint(
        '📦 Available buckets: ${buckets.map((b) => b.name).toList()}',
      );

      if (buckets.isNotEmpty) {
        final productsBucket = buckets.firstWhere(
          (bucket) => bucket.name == 'products_images',
          orElse: () => buckets.first,
        );

        debugPrint(
          '✅ Using bucket: "${productsBucket.name}" (${productsBucket.public ? "Public" : "Private"})',
        );
      } else {
        debugPrint('⚠️ No buckets found in list, will try uploading anyway...');
      }
    } catch (e) {
      debugPrint('⚠️ Bucket check failed: $e - Continuing with upload...');
    }

    String mediaUrl = '';

    try {
      // Step 4: Prepare file for upload
      final fileExt = fileName.split('.').last.toLowerCase();
      final fileNameWithoutExt = fileName.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${fileNameWithoutExt}_$timestamp.$fileExt';

      debugPrint('📎 Jina la faili: $storageFileName');

      // Step 5: Upload with retry logic
      String? uploadPath;
      int retries = 0;
      const maxRetries = 2;

      while (retries <= maxRetries) {
        try {
          debugPrint('🔄 Jaribio ${retries + 1}/${maxRetries + 1}...');

          uploadPath = await _client.storage
              .from('products_images')
              .upload(storageFileName, file);

          debugPrint('✅ Upload imekamilika: $uploadPath');
          break;
        } catch (uploadError) {
          retries++;
          if (retries > maxRetries) {
            throw Exception(
              'Kupakia kumeshindwa baada ya majaribio $maxRetries: $uploadError',
            );
          }
          debugPrint('⚠️ Jaribio ${retries} limeshindwa, tunajaribu tena...');
          await Future.delayed(Duration(seconds: retries));
        }
      }

      if (uploadPath == null || uploadPath.isEmpty) {
        throw Exception('Kupakia kumeshindwa: Hakuna majibu kutoka server');
      }

      // Step 6: Get the public URL
      mediaUrl =
          _client.storage.from('products_images').getPublicUrl(storageFileName);

      if (mediaUrl.isEmpty) {
        throw Exception('Kushindwa kupata URL ya picha');
      }

      debugPrint('✅ URL ya picha: $mediaUrl');

      // Step 7: Verify URL is accessible (optional but recommended)
      if (mediaUrl.startsWith('http')) {
        debugPrint('✅ Picha imehifadhiwa vizuri');
      } else {
        debugPrint('⚠️ URL ya picha haionekani sahihi: $mediaUrl');
      }
    } catch (e) {
      debugPrint('❌ Hitilafu wakati wa kupakia: $e');

      // Provide specific error messages
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('bucket') && errorStr.contains('not found')) {
        throw Exception(
          'Storage bucket "products_images" haipo. Unda bucket kwenye Supabase Dashboard > Storage',
        );
      } else if (errorStr.contains('permission') ||
          errorStr.contains('policy')) {
        throw Exception(
          'Hakuna ruhusa ya kupakia picha. Angalia Storage Policies kwenye Supabase Dashboard',
        );
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw Exception('Tatizo la mtandao. Hakikisha uko kwenye intaneti');
      } else if (errorStr.contains('size') || errorStr.contains('large')) {
        throw Exception('Picha kubwa sana. Tumia picha ndogo kuliko 10MB');
      }

      // Generic error
      throw Exception(
        'Kushindwa kupakia picha: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }

    // Step 8: Insert into product_media table
    try {
      final mediaData = {
        'product_id': productId,
        'store_id': storeId,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'is_primary': isPrimary,
        'sort_order': 0,
      };

      debugPrint('💾 Kuhifadhi rekodi ya picha kwenye database...');

      final response = await _client
          .from('product_media')
          .insert(mediaData)
          .select()
          .single();

      debugPrint('✅ Picha imehifadhiwa kikamilifu!');

      return ProductMedia.fromJson(response);
    } catch (e) {
      debugPrint('❌ Kushindwa kuhifadhi rekodi ya picha: $e');

      // Image is uploaded but database record failed - this is recoverable
      throw Exception(
        'Picha imepakiwa lakini rekodi haikuhifadhiwa kwenye database: ${e.toString()}',
      );
    }
  }

  static Future<void> deleteProductMedia(String mediaId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get media URL before deleting
    final media = await _client
        .from('product_media')
        .select('media_url')
        .eq('id', mediaId)
        .single();

    // Delete from storage
    final fileName = media['media_url'].split('/').last;
    await _client.storage.from('products').remove([fileName]);

    // Delete from database
    await _client.from('product_media').delete().eq('id', mediaId);
  }

  static Future<void> setPrimaryProductMedia(
    String mediaId,
    String productId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Reset all media for this product to not primary
    await _client
        .from('product_media')
        .update({'is_primary': false}).eq('product_id', productId);

    // Set the selected media as primary
    await _client
        .from('product_media')
        .update({'is_primary': true}).eq('id', mediaId);
  }

  // Sales methods
  static Future<Sale> createSale({
    required String storeId,
    required List<CartItem> cartItems,
    required PaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final totalAmount = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    // Calculate total profit for the sale
    double totalProfit = 0;
    for (final cartItem in cartItems) {
      // Get product cost_price
      final productResponse = await _client
          .from('products')
          .select('cost_price')
          .eq('id', cartItem.productId)
          .single();

      final costPrice = productResponse['cost_price']?.toDouble() ?? 0.0;
      final profitPerItem = (cartItem.price - costPrice) * cartItem.quantity;
      totalProfit += profitPerItem;
    }

    // Create the sale record
    final saleData = {
      'store_id': storeId,
      'sold_by': user.id,
      'payment_method': paymentMethod.toString().split('.').last,
      'total_amount': totalAmount,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': 'completed',
    };

    final saleResponse =
        await _client.from('sales').insert(saleData).select().single();

    final sale = Sale.fromJson(saleResponse);

    // Create sale items
    for (final cartItem in cartItems) {
      final saleItemData = {
        'sale_id': sale.id,
        'product_id': cartItem.productId,
        'product_name': cartItem.productName,
        'quantity': cartItem.quantity,
        'unit_price': cartItem.price,
        // subtotal is GENERATED ALWAYS, so we don't provide it
      };

      await _client.from('sale_items').insert(saleItemData);
    }

    // Create payment record
    final paymentData = {
      'sale_id': sale.id,
      'amount': totalAmount,
      'method': paymentMethod.toString().split('.').last,
    };

    await _client.from('payments').insert(paymentData);

    // If credit sale, create customer credit record
    if (paymentMethod == PaymentMethod.credit) {
      final creditData = {
        'store_id': storeId,
        'sale_id': sale.id,
        'customer_name': customerName ?? 'Unknown Customer',
        'customer_phone': customerPhone,
        'total_credit': totalAmount,
        'paid_amount': 0,
        'status': 'unpaid',
      };

      await _client.from('customer_credits').insert(creditData);
    } else {
      // For cash sales, create store ledger entry for profit immediately
      if (totalProfit > 0) {
        final ledgerData = {
          'store_id': storeId,
          'source_type': 'sale',
          'source_id': sale.id,
          'amount': totalProfit,
          'entry_type': 'profit',
          'entry_date': DateTime.now().toIso8601String().split('T')[0],
        };

        await _client.from('store_ledger').insert(ledgerData);
      }
    }

    // Update product quantities
    for (final cartItem in cartItems) {
      final currentProduct = await getProductById(cartItem.productId);
      final newQuantity = (currentProduct.quantity ?? 0) - cartItem.quantity;

      await updateProduct(productId: cartItem.productId, quantity: newQuantity);
    }

    return sale;
  }

  // Reports methods
  static Future<Map<String, dynamic>> getSalesReport({
    required String storeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Default to today if no dates provided
    final now = DateTime.now();
    final start = startDate ?? DateTime(now.year, now.month, now.day);
    final end = endDate ?? DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Get sales data
    final salesResponse = await _client
        .from('sales')
        .select('*, sale_items(*)')
        .eq('store_id', storeId)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);

    final sales =
        (salesResponse as List).map((json) => Sale.fromJson(json)).toList();

    // Get net profit from store ledger (profits - expenses)
    final ledgerResponse = await _client
        .from('store_ledger')
        .select('amount, entry_type')
        .eq('store_id', storeId)
        .gte('entry_date', start.toIso8601String().split('T')[0])
        .lte('entry_date', end.toIso8601String().split('T')[0]);

    double totalProfit = 0;
    double totalExpenses = 0;

    for (final entry in ledgerResponse) {
      final amount = entry['amount']?.toDouble() ?? 0.0;
      final entryType = entry['entry_type'];

      if (entryType == 'profit') {
        totalProfit += amount;
      } else if (entryType == 'expense') {
        totalExpenses += amount;
      }
    }

    final netProfit = totalProfit - totalExpenses;

    // Calculate totals
    final totalSales = sales.length;
    final totalRevenue = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final cashSales =
        sales.where((sale) => sale.paymentMethod == PaymentMethod.cash).length;
    final creditSales = sales
        .where((sale) => sale.paymentMethod == PaymentMethod.credit)
        .length;

    return {
      'total_sales': totalSales,
      'total_revenue': totalRevenue,
      'total_profit': totalProfit,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'cash_sales': cashSales,
      'credit_sales': creditSales,
      'sales': sales,
      'date_range': {'start': start, 'end': end},
    };
  }

  static Future<List<Product>> getInventoryReport(String storeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('products')
        .select()
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('quantity', ascending: true);

    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  static Future<List<Sale>> getRecentSales(
    String storeId, {
    int limit = 50,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('sales')
        .select('*, sale_items(*)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Sale.fromJson(json)).toList();
  }

  static Future<List<Sale>> getEmployeeSales({
    required String storeId,
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    dynamic query = _client
        .from('sales')
        .select('*, sale_items(*)')
        .eq('store_id', storeId)
        .eq('sold_by', employeeId);

    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    query = query.order('created_at', ascending: false);

    final response = await query;
    return (response as List).map((json) => Sale.fromJson(json)).toList();
  }

  // Expense methods
  static Future<List<Expense>> getExpensesForStore(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    dynamic query = _client
        .from('expenses')
        .select()
        .eq('store_id', storeId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    if (startDate != null) {
      query = query.gte(
        'expense_date',
        startDate.toIso8601String().split('T')[0],
      );
    }

    if (endDate != null) {
      query = query.lte(
        'expense_date',
        endDate.toIso8601String().split('T')[0],
      );
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      query = query.eq('payment_method', paymentMethod);
    }

    final response = await query;
    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  static Future<Expense> addExpense({
    required String storeId,
    required String purpose,
    required double amount,
    String? paymentMethod,
    String? notes,
    required DateTime expenseDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final expenseData = {
      'store_id': storeId,
      'purpose': purpose,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'created_by': user.id,
    };

    final response =
        await _client.from('expenses').insert(expenseData).select().single();

    final expense = Expense.fromJson(response);

    // Create store ledger entry for expense
    final ledgerData = {
      'store_id': storeId,
      'source_type': 'expense',
      'source_id': expense.id,
      'amount': amount,
      'entry_type': 'expense',
      'entry_date': expenseDate.toIso8601String().split('T')[0],
    };

    await _client.from('store_ledger').insert(ledgerData);

    return expense;
  }

  static Future<Expense> updateExpense({
    required String expenseId,
    String? purpose,
    double? amount,
    String? paymentMethod,
    String? notes,
    DateTime? expenseDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {
      if (purpose != null) 'purpose': purpose,
      if (amount != null) 'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      if (expenseDate != null)
        'expense_date': expenseDate.toIso8601String().split('T')[0],
    };

    final response = await _client
        .from('expenses')
        .update(updateData)
        .eq('id', expenseId)
        .select()
        .single();

    return Expense.fromJson(response);
  }

  static Future<void> deleteExpense(String expenseId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('expenses').delete().eq('id', expenseId);
  }

  static Future<Map<String, dynamic>> getExpenseSummary(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenses = await getExpensesForStore(
      storeId,
      startDate: startDate,
      endDate: endDate,
    );

    final totalExpenses = expenses.length;
    final totalAmount = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    // Group by payment method
    final paymentMethodCounts = <String, int>{};
    for (final expense in expenses) {
      final method = expense.paymentMethod ?? 'other';
      paymentMethodCounts[method] = (paymentMethodCounts[method] ?? 0) + 1;
    }

    return {
      'total_expenses': totalExpenses,
      'total_amount': totalAmount,
      'payment_method_counts': paymentMethodCounts,
      'expenses': expenses,
    };
  }

  // Debt methods
  static Future<List<Debt>> getDebtsForStore(String storeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('debts')
        .select('*, debt_payments(*)')
        .eq('store_id', storeId)
        .neq('status', 'paid')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Debt.fromJson(json)).toList();
  }

  static Future<Debt> getDebtById(String debtId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('debts')
        .select('*, debt_payments(*)')
        .eq('id', debtId)
        .single();

    return Debt.fromJson(response);
  }

  static Future<Debt> createDebt({
    required String storeId,
    required String saleId,
    required String customerName,
    String? customerPhone,
    required double totalAmount,
    required double paidAmount,
    required DateTime saleDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final remainingAmount = totalAmount - paidAmount;
    final status = remainingAmount <= 0 ? 'paid' : 'pending';

    final debtData = {
      'store_id': storeId,
      'sale_id': saleId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'sale_date': saleDate.toIso8601String().split('T')[0],
      'last_payment_date':
          paidAmount > 0 ? DateTime.now().toIso8601String() : null,
    };

    final response = await _client
        .from('debts')
        .insert(debtData)
        .select('*, debt_payments(*)')
        .single();

    return Debt.fromJson(response);
  }

  static Future<DebtPayment> addDebtPayment({
    required String debtId,
    required double amount,
    required String paymentMethod,
    String? notes,
    required DateTime paymentDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First get the current debt
    final debt = await getDebtById(debtId);
    if (debt.remainingAmount < amount) {
      throw Exception('Payment amount cannot exceed remaining balance');
    }

    // Create payment record
    final paymentData = {
      'debt_id': debtId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
    };

    final paymentResponse = await _client
        .from('debt_payments')
        .insert(paymentData)
        .select()
        .single();

    // Update debt
    final newPaidAmount = debt.paidAmount + amount;
    final newRemainingAmount = debt.totalAmount - newPaidAmount;
    final newStatus = newRemainingAmount <= 0 ? 'paid' : 'pending';

    await _client.from('debts').update({
      'paid_amount': newPaidAmount,
      'remaining_amount': newRemainingAmount,
      'status': newStatus,
      'last_payment_date': paymentDate.toIso8601String(),
    }).eq('id', debtId);

    // If debt is fully paid, add to profit
    if (newStatus == 'paid') {
      // The profit was already calculated when the sale was created
      // No additional action needed as the profit is already in store_ledger
    }

    return DebtPayment.fromJson(paymentResponse);
  }

  static Future<Debt> updateDebt({
    required String debtId,
    double? paidAmount,
    String? status,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final debt = await getDebtById(debtId);

    final updateData = <String, dynamic>{};
    if (paidAmount != null) {
      updateData['paid_amount'] = paidAmount;
      updateData['remaining_amount'] = debt.totalAmount - paidAmount;
      updateData['status'] =
          (debt.totalAmount - paidAmount) <= 0 ? 'paid' : 'pending';
    }
    if (status != null) {
      updateData['status'] = status;
    }

    final response = await _client
        .from('debts')
        .update(updateData)
        .eq('id', debtId)
        .select('*, debt_payments(*)')
        .single();

    return Debt.fromJson(response);
  }

  static Future<Map<String, dynamic>> getDebtSummary(String storeId) async {
    final debts = await getDebtsForStore(storeId);

    final totalDebts = debts.length;
    final totalOutstanding = debts.fold<double>(
      0,
      (sum, debt) => sum + debt.remainingAmount,
    );
    final totalPaid = debts.fold<double>(
      0,
      (sum, debt) => sum + debt.paidAmount,
    );

    // Group by status
    final statusCounts = <String, int>{};
    for (final debt in debts) {
      statusCounts[debt.status] = (statusCounts[debt.status] ?? 0) + 1;
    }

    return {
      'total_debts': totalDebts,
      'total_outstanding': totalOutstanding,
      'total_paid': totalPaid,
      'status_counts': statusCounts,
      'debts': debts,
    };
  }

  // Customer Credit methods
  static Future<List<CustomerCredit>> getCustomerCreditsForStore(
    String storeId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('customer_credits')
        .select()
        .eq('store_id', storeId)
        .neq('status', 'paid')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CustomerCredit.fromJson(json))
        .toList();
  }

  static Future<CustomerCredit> getCustomerCreditById(String creditId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('customer_credits')
        .select()
        .eq('id', creditId)
        .single();

    return CustomerCredit.fromJson(response);
  }

  static Future<CustomerCredit> updateCustomerCreditPayment({
    required String creditId,
    required double paidAmount,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get current credit
    final credit = await getCustomerCreditById(creditId);

    // Calculate new status
    final newPaidAmount = credit.paidAmount + paidAmount;
    final newBalance = credit.totalCredit - newPaidAmount;
    String newStatus;

    if (newBalance <= 0) {
      newStatus = 'paid';
      // If fully paid, add profit to store ledger
      final profitAmount = credit.totalCredit -
          (credit.totalCredit *
              0.2); // Assuming 20% profit margin, adjust as needed

      final ledgerData = {
        'store_id': credit.storeId,
        'source_type': 'sale',
        'source_id': credit.saleId,
        'amount': profitAmount,
        'entry_type': 'profit',
        'entry_date': DateTime.now().toIso8601String().split('T')[0],
      };

      await _client.from('store_ledger').insert(ledgerData);
    } else if (newPaidAmount > 0) {
      newStatus = 'partial';
    } else {
      newStatus = 'unpaid';
    }

    // Update customer credit
    final updateData = {'paid_amount': newPaidAmount, 'status': newStatus};

    final response = await _client
        .from('customer_credits')
        .update(updateData)
        .eq('id', creditId)
        .select()
        .single();

    return CustomerCredit.fromJson(response);
  }

  static Future<Map<String, dynamic>> getCustomerCreditSummary(
    String storeId,
  ) async {
    final credits = await getCustomerCreditsForStore(storeId);

    final totalCredits = credits.length;
    final totalOutstanding = credits.fold<double>(
      0,
      (sum, credit) => sum + credit.balance,
    );
    final totalPaid = credits.fold<double>(
      0,
      (sum, credit) => sum + credit.paidAmount,
    );

    // Group by status
    final statusCounts = <String, int>{};
    for (final credit in credits) {
      statusCounts[credit.status] = (statusCounts[credit.status] ?? 0) + 1;
    }

    return {
      'total_credits': totalCredits,
      'total_outstanding': totalOutstanding,
      'total_paid': totalPaid,
      'status_counts': statusCounts,
      'credits': credits,
    };
  }

  // Employee methods
  static Future<List<StoreEmployee>> getEmployeesForStore(
    String storeId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Debug: Get count before filtering (all employees including deactivated)
    final totalResponse = await _client
        .from('store_employees')
        .select('*, employees!inner(*)')
        .eq('store_id', storeId);

    final totalCount = (totalResponse as List).length;

    // Get filtered employees (only active)
    final response = await _client
        .from('store_employees')
        .select('*, employees!inner(*)')
        .eq('store_id', storeId)
        .eq('employees.is_active', true)
        .order('created_at', ascending: false);

    final filteredCount = (response as List).length;

    // Debug prints
    debugPrint('=== getEmployeesForStore Debug ===');
    debugPrint('Store ID: $storeId');
    debugPrint(
      'Query: SELECT *, employees!inner(*) FROM store_employees WHERE store_id = $storeId AND employees.is_active = true',
    );
    debugPrint('Total employees (before filtering): $totalCount');
    debugPrint('Active employees (after filtering): $filteredCount');
    debugPrint('Excluded deactivated employees: ${totalCount - filteredCount}');
    debugPrint('==================================');

    return response.map((json) => StoreEmployee.fromJson(json)).toList();
  }

  static Future<Employee> createEmployee({
    required String fullName,
    required String username,
    String? phone,
    required String pin,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create fake email using username
    final fakeEmail = '$username@dukakiganjani.com';

    // Create password using PIN
    final password = '$pin@dukakiganjani';

    // Register with Supabase Auth
    final authResponse = await _client.auth.signUp(
      email: fakeEmail,
      password: password,
    );

    if (authResponse.user != null) {
      // Insert into employees table
      final employeeData = {
        'id': authResponse.user!.id,
        'full_name': fullName,
        'username': username,
        'phone': phone,
        'is_active': true,
      };

      final response = await _client
          .from('employees')
          .insert(employeeData)
          .select()
          .single();

      return Employee.fromJson(response);
    } else {
      throw Exception('Failed to create employee authentication');
    }
  }

  static Future<StoreEmployee> addEmployeeToStore({
    required String storeId,
    required String employeeId,
    required EmployeeRole role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Check if employee already exists in store
    final existingResponse = await _client
        .from('store_employees')
        .select()
        .eq('store_id', storeId)
        .eq('employee_id', employeeId)
        .maybeSingle();

    if (existingResponse != null) {
      throw Exception('Employee is already assigned to this store');
    }

    final storeEmployeeData = {
      'store_id': storeId,
      'employee_id': employeeId,
      'role': role.value,
    };

    final response = await _client
        .from('store_employees')
        .insert(storeEmployeeData)
        .select('*, employees(*)')
        .single();

    return StoreEmployee.fromJson(response);
  }

  static Future<StoreEmployee> updateStoreEmployee({
    required String storeEmployeeId,
    required EmployeeRole role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = {'role': role.value};

    final response = await _client
        .from('store_employees')
        .update(updateData)
        .eq('id', storeEmployeeId)
        .select('*, employees(*)')
        .single();

    return StoreEmployee.fromJson(response);
  }

  static Future<void> removeEmployeeFromStore(String storeEmployeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('store_employees').delete().eq('id', storeEmployeeId);
  }

  static Future<Employee> updateEmployee({
    required String employeeId,
    String? fullName,
    String? phone,
    bool? isActive,
    DateTime? deactivatedAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (phone != null) updateData['phone'] = phone;
    if (isActive != null) updateData['is_active'] = isActive;
    if (deactivatedAt != null)
      updateData['deactivated_at'] = deactivatedAt.toIso8601String();

    final response = await _client
        .from('employees')
        .update(updateData)
        .eq('id', employeeId)
        .select()
        .single();

    return Employee.fromJson(response);
  }

  static Future<void> deleteEmployee(String employeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Remove from all stores first
      await _client
          .from('store_employees')
          .delete()
          .eq('employee_id', employeeId);

      // Then delete the employee record
      await _client.from('employees').delete().eq('id', employeeId);
    } catch (e) {
      try {
        await _client
            .from('employees')
            .update({'is_active': false}).eq('id', employeeId);
      } catch (deactivateError) {
        throw Exception(
          'Unable to delete or deactivate employee: $deactivateError',
        );
      }
    }
  }

  static Future<Employee> deactivateEmployee(String employeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await updateEmployee(
      employeeId: employeeId,
      isActive: false,
      deactivatedAt: DateTime.now(),
    );
  }

  static Future<Employee> reactivateEmployee(String employeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await updateEmployee(
      employeeId: employeeId,
      isActive: true,
      deactivatedAt: null,
    );
  }

  static Future<Employee> updateEmployeePhone({
    required String employeeId,
    required String newPhone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return await updateEmployee(employeeId: employeeId, phone: newPhone);
  }

  static Future<void> permanentlyDeleteEmployee(String employeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First remove from all stores
      await _client
          .from('store_employees')
          .delete()
          .eq('employee_id', employeeId);

      // Delete the employee record
      await _client.from('employees').delete().eq('id', employeeId);
    } catch (e) {
      if (e is PostgrestException) {
        // Handle PostgrestException specifically
        debugPrint('PostgrestException during employee deletion:');
        debugPrint('Message: ${e.message}');
        debugPrint('Code: ${e.code}');
        debugPrint('Details: ${e.details}');
        debugPrint('Hint: ${e.hint}');
        throw Exception(
          'Employee deactivation failed (${e.code}): ${e.message} — ${e.details}',
        );
      } else if (e is AuthException) {
        // Handle AuthException specifically
        debugPrint('AuthException during employee deletion: ${e.message}');
        throw Exception('Employee deactivation failed: ${e.message}');
      } else {
        // For other exceptions, try to deactivate as fallback
        try {
          await _client
              .from('employees')
              .update({'is_active': false}).eq('id', employeeId);
        } catch (deactivateError) {
          if (deactivateError is PostgrestException) {
            debugPrint('PostgrestException during deactivation:');
            debugPrint('Message: ${deactivateError.message}');
            debugPrint('Code: ${deactivateError.code}');
            debugPrint('Details: ${deactivateError.details}');
            debugPrint('Hint: ${deactivateError.hint}');
            throw Exception(
              'Employee deactivation failed (${deactivateError.code}): ${deactivateError.message} — ${deactivateError.details}',
            );
          } else if (deactivateError is AuthException) {
            debugPrint(
              'AuthException during deactivation: ${deactivateError.message}',
            );
            throw Exception(
              'Employee deactivation failed: ${deactivateError.message}',
            );
          } else {
            throw Exception(
              'Unable to delete or deactivate employee: $deactivateError',
            );
          }
        }
      }
    }

    // Note: In a production environment, you would also delete the Supabase Auth user
    // However, this requires admin privileges and should be handled carefully
    // For now, we'll just mark them as inactive in the database
    // The auth user will remain but won't be able to access the system
  }

  static Future<Employee?> authenticateEmployee({
    required String username,
    required String pin,
  }) async {
    // Normalize phone number - remove +255 prefix if present
    String normalizedUsername = username;
    if (username.startsWith('+255')) {
      normalizedUsername = username.substring(4); // Remove +255
    } else if (username.startsWith('255')) {
      normalizedUsername = username.substring(3); // Remove 255
    }

    // Create fake email using normalized username
    final fakeEmail = '$normalizedUsername@dukakiganjani.com';

    // Create password using PIN
    final password = '$pin@dukakiganjani';

    // Login with Supabase Auth
    final authResponse = await _client.auth.signInWithPassword(
      email: fakeEmail,
      password: password,
    );

    if (authResponse.user != null) {
      // Get employee record and check if active
      final employeeResponse = await _client
          .from('employees')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      if (employeeResponse != null) {
        final employee = Employee.fromJson(employeeResponse);
        // Check if employee is active
        if (employee.isActive) {
          return employee;
        } else {
          throw Exception('Employee account is deactivated');
        }
      } else {
        throw Exception('Employee record not found');
      }
    } else {
      throw Exception('Invalid credentials');
    }
  }

  static Future<List<Store>> getEmployeeStores(String employeeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // First check if employee is active
    final employeeResponse = await _client
        .from('employees')
        .select('is_active')
        .eq('id', employeeId)
        .maybeSingle();

    if (employeeResponse == null || employeeResponse['is_active'] != true) {
      return []; // Return empty list if employee is not active
    }

    // Get all stores where the employee is assigned
    final response = await _client
        .from('store_employees')
        .select('*, stores(*)')
        .eq('employee_id', employeeId);

    return (response as List).map((json) {
      return Store.fromJson(json['stores']);
    }).toList();
  }

  // Debug method to test media URL generation
  static Future<String> testMediaUrl(String fileName) async {
    try {
      final mediaUrl = _client.storage.from('products').getPublicUrl(fileName);
      print('Generated media URL: $mediaUrl');
      return mediaUrl;
    } catch (e) {
      print('Error generating media URL: $e');
      throw e;
    }
  }

  // Method to check if storage bucket exists and is configured
  static Future<void> checkStorageConfiguration() async {
    try {
      final buckets = await _client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name)}');

      // Check if products bucket exists
      Bucket? productsBucket;
      for (final bucket in buckets) {
        if (bucket.name == 'products') {
          productsBucket = bucket;
          break;
        }
      }

      if (productsBucket != null) {
        print('Products bucket found: ${productsBucket.name}');
        print('Public: ${productsBucket.public}');
      } else {
        print('Products bucket not found');
      }
    } catch (e) {
      print('Error checking storage configuration: $e');
      throw e;
    }
  }
}
