import '../model/product.dart';
import '../model/sales.dart';
import '../model/expenses.dart';
import '../model/employees.dart';
import '../model/category.dart';
import '../model/customer_credit.dart';
import 'offline_repository.dart';
import 'supabase_service.dart';

/// High-level service that provides data access
/// Currently wraps SupabaseService - offline features to be integrated
class OfflineDataService {
  static final _repository = OfflineRepository();

  // ==================== PRODUCTS ====================

  static Future<List<Product>> getProductsForStore(String storeId) async {
    return await SupabaseService.getProductsForStore(storeId);
  }

  static Future<Product> addProductWithParams({
    required String storeId,
    required String? categoryId,
    String? subCategoryId,
    required String name,
    String? sku,
    String? productCode,
    required double costPrice,
    required double sellingPrice,
    double? wholesalePrice,
    double? discountPrice,
    required int quantity,
    int? lowStockAlert,
    String? description,
    String? supplierName,
    DateTime? expiryDate,
    String? batchNumber,
    DateTime? supplierDate,
  }) async {
    return await SupabaseService.addProduct(
      storeId: storeId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      name: name,
      sku: sku,
      productCode: productCode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      discountPrice: discountPrice,
      quantity: quantity.toDouble(),
      lowStockAlert: lowStockAlert,
      description: description,
      supplierName: supplierName,
      expiryDate: expiryDate,
      batchNumber: batchNumber,
      supplierDate: supplierDate,
    );
  }

  static Future<Product> updateProductWithParams({
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
    int? quantity,
    int? lowStockAlert,
    String? description,
    String? supplierName,
    DateTime? expiryDate,
    String? batchNumber,
    DateTime? supplierDate,
  }) async {
    return await SupabaseService.updateProduct(
      productId: productId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      name: name,
      sku: sku,
      productCode: productCode,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      wholesalePrice: wholesalePrice,
      discountPrice: discountPrice,
      quantity: quantity?.toDouble(),
      lowStockAlert: lowStockAlert,
      description: description,
      supplierName: supplierName,
      expiryDate: expiryDate,
      batchNumber: batchNumber,
      supplierDate: supplierDate,
    );
  }

  static Future<void> deleteProduct(int productId) async {
    await SupabaseService.deleteProduct(productId.toString());
  }

  // ==================== SALES ====================

  static Future<Sale> createSale({
    required String storeId,
    required List<CartItem> cartItems,
    required PaymentMethod paymentMethod,
    String? customerName,
    String? customerPhone,
  }) async {
    return await SupabaseService.createSale(
      storeId: storeId,
      cartItems: cartItems,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }

  // ==================== EXPENSES ====================

  static Future<List<Expense>> getExpensesForStore(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
  }) async {
    return await SupabaseService.getExpensesForStore(
      storeId,
      startDate: startDate,
      endDate: endDate,
      paymentMethod: paymentMethod,
    );
  }

  static Future<Expense> addExpenseWithParams({
    required String storeId,
    required String purpose,
    required double amount,
    String? paymentMethod,
    String? notes,
    required DateTime expenseDate,
  }) async {
    return await SupabaseService.addExpense(
      storeId: storeId,
      purpose: purpose,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      expenseDate: expenseDate,
    );
  }

  static Future<Expense> updateExpenseWithParams({
    required String expenseId,
    String? purpose,
    double? amount,
    String? paymentMethod,
    String? notes,
    DateTime? expenseDate,
  }) async {
    return await SupabaseService.updateExpense(
      expenseId: expenseId,
      purpose: purpose,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      expenseDate: expenseDate,
    );
  }

  static Future<void> deleteExpense(int expenseId) async {
    await SupabaseService.deleteExpense(expenseId.toString());
  }

  // ==================== DEBTS ====================

  static Future<List<CustomerCredit>> getDebtsForStore(String storeId) async {
    return await SupabaseService.getCustomerCreditsForStore(storeId);
  }

  // ==================== EMPLOYEES ====================

  static Future<List<StoreEmployee>> getEmployeesForStore(
      String storeId) async {
    return await SupabaseService.getEmployeesForStore(storeId);
  }

  // ==================== CATEGORIES ====================

  static Future<List<Category>> getCategoriesForStore(String storeId) async {
    return await SupabaseService.getCategoriesForStore(storeId);
  }

  // ==================== SYNC STATUS ====================

  static Future<int> getPendingSyncCount() async {
    return await _repository.getPendingSyncCount();
  }

  static Future<void> syncNow() async {
    await _repository.syncNow();
  }

  static Future<bool> isOnline() async {
    return await _repository.isOnline();
  }
}
