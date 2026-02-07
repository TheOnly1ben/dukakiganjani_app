import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dukakiganjani.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const realTypeNullable = 'REAL';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    // Stores table
    await db.execute('''
      CREATE TABLE stores (
        id $idType,
        server_id $textTypeNullable,
        name $textType,
        type $textTypeNullable,
        location $textTypeNullable,
        status $textType,
        owner_id $textTypeNullable,
        created_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        name $textType,
        barcode $textTypeNullable,
        price $realType,
        cost $realTypeNullable,
        stock_quantity $intType,
        category $textTypeNullable,
        description $textTypeNullable,
        unit $textTypeNullable,
        buying_price $realTypeNullable,
        supplier $textTypeNullable,
        image_url $textTypeNullable,
        local_image_path $textTypeNullable,
        expires_at $textTypeNullable,
        created_at $textTypeNullable,
        updated_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        product_id $textTypeNullable,
        product_name $textType,
        quantity $intType,
        price $realType,
        total $realType,
        employee_id $textTypeNullable,
        employee_name $textTypeNullable,
        customer_name $textTypeNullable,
        payment_method $textTypeNullable,
        sale_date $textType,
        created_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Employees table
    await db.execute('''
      CREATE TABLE employees (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        full_name $textType,
        username $textType,
        phone $textTypeNullable,
        role $textTypeNullable,
        is_active $boolType,
        auth_id $textTypeNullable,
        created_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        name $textType,
        description $textTypeNullable,
        created_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        description $textType,
        amount $realType,
        category $textTypeNullable,
        payment_method $textTypeNullable,
        expense_date $textType,
        created_by $textTypeNullable,
        created_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE debts (
        id $idType,
        server_id $textTypeNullable,
        store_id $textTypeNullable,
        customer_name $textType,
        customer_phone $textTypeNullable,
        amount $realType,
        amount_paid $realTypeNullable,
        balance $realType,
        description $textTypeNullable,
        due_date $textTypeNullable,
        status $textType,
        created_by $textTypeNullable,
        created_at $textTypeNullable,
        updated_at $textTypeNullable,
        synced $boolType
      )
    ''');

    // Sync queue table - tracks operations to sync
    await db.execute('''
      CREATE TABLE sync_queue (
        id $idType,
        table_name $textType,
        operation $textType,
        record_id $intType,
        data $textType,
        priority $intType,
        retry_count $intType DEFAULT 0,
        created_at $textType,
        last_attempt $textTypeNullable
      )
    ''');

    // Last sync timestamps
    await db.execute('''
      CREATE TABLE sync_metadata (
        table_name $textType PRIMARY KEY,
        last_sync $textType,
        last_pull $textTypeNullable,
        last_push $textTypeNullable
      )
    ''');
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(String table, Map<String, dynamic> row,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.update(
      table,
      row,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Add to sync queue
  Future<int> addToSyncQueue({
    required String tableName,
    required String operation, // 'insert', 'update', 'delete'
    required int recordId,
    required Map<String, dynamic> data,
    int priority = 1,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'table_name': tableName,
      'operation': operation,
      'record_id': recordId,
      'data': data.toString(),
      'priority': priority,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'priority DESC, created_at ASC',
    );
  }

  // Remove from sync queue
  Future<int> removeFromSyncQueue(int id) async {
    final db = await database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // Update sync metadata
  Future<void> updateSyncMetadata(String tableName, String syncType) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'sync_metadata',
      {
        'table_name': tableName,
        'last_sync': now,
        if (syncType == 'pull') 'last_pull': now,
        if (syncType == 'push') 'last_push': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get last sync time
  Future<String?> getLastSyncTime(String tableName) async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      where: 'table_name = ?',
      whereArgs: [tableName],
    );

    if (result.isNotEmpty) {
      return result.first['last_sync'] as String?;
    }
    return null;
  }

  // Clear all data (for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('stores');
    await db.delete('products');
    await db.delete('sales');
    await db.delete('employees');
    await db.delete('categories');
    await db.delete('expenses');
    await db.delete('debts');
    await db.delete('sync_queue');
    await db.delete('sync_metadata');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
