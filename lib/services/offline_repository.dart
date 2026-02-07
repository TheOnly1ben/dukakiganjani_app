import 'local_database.dart';
import 'sync_manager.dart';

/// Repository layer that provides unified data access
/// Always reads from local DB, queues writes for sync
class OfflineRepository {
  final _localDb = LocalDatabase.instance;
  final _syncManager = SyncManager.instance;

  // ==================== PRODUCTS ====================

  Future<List<Map<String, dynamic>>> getProducts({String? storeId}) async {
    return await _localDb.query(
      'products',
      where: storeId != null ? 'store_id = ?' : null,
      whereArgs: storeId != null ? [storeId] : null,
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final results = await _localDb.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> addProduct(Map<String, dynamic> product) async {
    // Add to local DB immediately
    final localId = await _localDb.insert('products', {
      ...product,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Add to sync queue
    await _localDb.addToSyncQueue(
      tableName: 'products',
      operation: 'insert',
      recordId: localId,
      data: product,
      priority: 2,
    );

    return localId;
  }

  Future<void> updateProduct(int id, Map<String, dynamic> product) async {
    // Update local DB
    await _localDb.update(
      'products',
      {
        ...product,
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync queue
    await _localDb.addToSyncQueue(
      tableName: 'products',
      operation: 'update',
      recordId: id,
      data: product,
      priority: 2,
    );
  }

  Future<void> deleteProduct(int id) async {
    // Get product before deletion (for sync)
    final product = await getProduct(id);
    if (product == null) return;

    // Delete from local DB
    await _localDb.delete('products', where: 'id = ?', whereArgs: [id]);

    // Add to sync queue
    await _localDb.addToSyncQueue(
      tableName: 'products',
      operation: 'delete',
      recordId: id,
      data: product,
      priority: 2,
    );
  }

  // ==================== SALES ====================

  Future<List<Map<String, dynamic>>> getSales({
    String? storeId,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (storeId != null) {
      where = 'store_id = ?';
      whereArgs = [storeId];

      if (employeeId != null) {
        where += ' AND employee_id = ?';
        whereArgs.add(employeeId);
      }

      if (startDate != null && endDate != null) {
        where += ' AND sale_date BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }
    }

    return await _localDb.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sale_date DESC',
    );
  }

  Future<int> addSale(Map<String, dynamic> sale) async {
    // Add to local DB immediately
    final localId = await _localDb.insert('sales', {
      ...sale,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Add to sync queue (high priority for sales)
    await _localDb.addToSyncQueue(
      tableName: 'sales',
      operation: 'insert',
      recordId: localId,
      data: sale,
      priority: 3, // High priority
    );

    return localId;
  }

  // ==================== CATEGORIES ====================

  Future<List<Map<String, dynamic>>> getCategories({String? storeId}) async {
    return await _localDb.query(
      'categories',
      where: storeId != null ? 'store_id = ?' : null,
      whereArgs: storeId != null ? [storeId] : null,
      orderBy: 'name ASC',
    );
  }

  Future<int> addCategory(Map<String, dynamic> category) async {
    final localId = await _localDb.insert('categories', {
      ...category,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _localDb.addToSyncQueue(
      tableName: 'categories',
      operation: 'insert',
      recordId: localId,
      data: category,
      priority: 1,
    );

    return localId;
  }

  Future<void> updateCategory(int id, Map<String, dynamic> category) async {
    await _localDb.update(
      'categories',
      {...category, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _localDb.addToSyncQueue(
      tableName: 'categories',
      operation: 'update',
      recordId: id,
      data: category,
      priority: 1,
    );
  }

  Future<void> deleteCategory(int id) async {
    final category = await _localDb.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (category.isEmpty) return;

    await _localDb.delete('categories', where: 'id = ?', whereArgs: [id]);

    await _localDb.addToSyncQueue(
      tableName: 'categories',
      operation: 'delete',
      recordId: id,
      data: category.first,
      priority: 1,
    );
  }

  // ==================== EXPENSES ====================

  Future<List<Map<String, dynamic>>> getExpenses({
    String? storeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (storeId != null) {
      where = 'store_id = ?';
      whereArgs = [storeId];

      if (startDate != null && endDate != null) {
        where += ' AND expense_date BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }
    }

    return await _localDb.query(
      'expenses',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'expense_date DESC',
    );
  }

  Future<int> addExpense(Map<String, dynamic> expense) async {
    final localId = await _localDb.insert('expenses', {
      ...expense,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _localDb.addToSyncQueue(
      tableName: 'expenses',
      operation: 'insert',
      recordId: localId,
      data: expense,
      priority: 2,
    );

    return localId;
  }

  Future<void> updateExpense(int id, Map<String, dynamic> expense) async {
    await _localDb.update(
      'expenses',
      {...expense, 'synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _localDb.addToSyncQueue(
      tableName: 'expenses',
      operation: 'update',
      recordId: id,
      data: expense,
      priority: 2,
    );
  }

  Future<void> deleteExpense(int id) async {
    final expense = await _localDb.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (expense.isEmpty) return;

    await _localDb.delete('expenses', where: 'id = ?', whereArgs: [id]);

    await _localDb.addToSyncQueue(
      tableName: 'expenses',
      operation: 'delete',
      recordId: id,
      data: expense.first,
      priority: 2,
    );
  }

  // ==================== DEBTS ====================

  Future<List<Map<String, dynamic>>> getDebts({String? storeId}) async {
    return await _localDb.query(
      'debts',
      where: storeId != null ? 'store_id = ?' : null,
      whereArgs: storeId != null ? [storeId] : null,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> addDebt(Map<String, dynamic> debt) async {
    final localId = await _localDb.insert('debts', {
      ...debt,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _localDb.addToSyncQueue(
      tableName: 'debts',
      operation: 'insert',
      recordId: localId,
      data: debt,
      priority: 2,
    );

    return localId;
  }

  Future<void> updateDebt(int id, Map<String, dynamic> debt) async {
    await _localDb.update(
      'debts',
      {
        ...debt,
        'synced': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _localDb.addToSyncQueue(
      tableName: 'debts',
      operation: 'update',
      recordId: id,
      data: debt,
      priority: 2,
    );
  }

  Future<void> deleteDebt(int id) async {
    final debt = await _localDb.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (debt.isEmpty) return;

    await _localDb.delete('debts', where: 'id = ?', whereArgs: [id]);

    await _localDb.addToSyncQueue(
      tableName: 'debts',
      operation: 'delete',
      recordId: id,
      data: debt.first,
      priority: 2,
    );
  }

  // ==================== EMPLOYEES ====================

  Future<List<Map<String, dynamic>>> getEmployees({String? storeId}) async {
    return await _localDb.query(
      'employees',
      where: storeId != null ? 'store_id = ?' : null,
      whereArgs: storeId != null ? [storeId] : null,
      orderBy: 'full_name ASC',
    );
  }

  // ==================== SYNC HELPERS ====================

  /// Get count of pending sync operations
  Future<int> getPendingSyncCount() async {
    final pending = await _localDb.getPendingSyncOperations();
    return pending.length;
  }

  /// Trigger manual sync
  Future<void> syncNow() async {
    await _syncManager.syncAll();
  }

  /// Check if online
  Future<bool> isOnline() async {
    return await _syncManager.isOnline();
  }
}
