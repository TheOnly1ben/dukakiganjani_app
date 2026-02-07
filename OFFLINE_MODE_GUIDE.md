# Offline-First Implementation Guide

## Overview

The Dukakiganjani app now supports **full offline functionality** for all basic operations. This means:
- ✅ **All operations work offline** (sales, inventory, expenses, debts, categories)
- ✅ **Automatic sync** when internet connection is available
- ✅ **Fast performance** - no waiting for server responses
- ✅ **Data safety** - everything saved locally first
- ✅ **Conflict resolution** - handles multiple devices editing same data

## Architecture

```
┌─────────────────┐
│   UI Layer      │
│  (Pages/Widgets)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Repository    │  ← Single point of data access
│     Layer       │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌─────────┐
│ Local  │  │ Sync    │
│SQLite  │  │ Queue   │
│   DB   │  │         │
└────────┘  └─────────┘
         │
         ▼ (when online)
    ┌─────────┐
    │Supabase │
    └─────────┘
```

## Core Components

### 1. Local Database (`local_database.dart`)
- SQLite database that mirrors Supabase schema
- Tables: stores, products, sales, employees, categories, expenses, debts
- Sync queue table for tracking pending operations
- Sync metadata for tracking last sync times

### 2. Sync Manager (`sync_manager.dart`)
- Monitors internet connectivity
- Automatically syncs when online
- Handles push (local → server) and pull (server → local)
- Retry mechanism for failed operations
- Broadcasts sync status to UI

### 3. Offline Repository (`offline_repository.dart`)
- Unified interface for data access
- **All reads** go to local database (instant!)
- **All writes** saved locally + queued for sync
- Transparent to UI - looks like normal database calls

### 4. Sync Status Widget (`sync_status_widget.dart`)
- Shows current sync status (offline/syncing/synced)
- Displays pending operations count
- Manual sync button
- Offline indicator banner

## How to Use

### Basic Usage Example

Instead of calling Supabase directly, use the repository:

```dart
// OLD WAY (Online only)
final products = await SupabaseService.getProductsForStore(storeId);

// NEW WAY (Offline-first)
final repository = OfflineRepository();
final products = await repository.getProducts(storeId: storeId);
```

### Adding Data (Works Offline!)

```dart
final repository = OfflineRepository();

// Add a sale - saves locally, queues for sync
await repository.addSale({
  'store_id': store.id,
  'product_id': product.id,
  'product_name': product.name,
  'quantity': 2,
  'price': 5000.0,
  'total': 10000.0,
  'sale_date': DateTime.now().toIso8601String(),
});

// ✅ Sale saved instantly to local DB
// ✅ Will sync to Supabase when online
// ✅ UI updates immediately
```

### Showing Sync Status

Add to your AppBar or anywhere in UI:

```dart
import '../widgets/sync_status_widget.dart';

AppBar(
  title: Text('My Page'),
  actions: [
    SyncStatusWidget(), // Shows sync status
  ],
)

// Or add offline indicator banner
Column(
  children: [
    OfflineIndicator(), // Shows when offline
    // ... rest of your UI
  ],
)
```

### Manual Sync Trigger

```dart
final repository = OfflineRepository();

// Trigger sync manually
await repository.syncNow();

// Check if online
bool isOnline = await repository.isOnline();

// Get pending operations count
int pending = await repository.getPendingSyncCount();
```

## Migration Steps for Existing Pages

### Step 1: Import Repository

```dart
import '../services/offline_repository.dart';
```

### Step 2: Create Repository Instance

```dart
class _InventoryPageState extends State<InventoryPage> {
  final _repository = OfflineRepository();
  
  // ... rest of code
}
```

### Step 3: Replace SupabaseService Calls

```dart
// BEFORE
Future<void> _loadProducts() async {
  final products = await SupabaseService.getProductsForStore(widget.store.id);
  setState(() {
    _products = products;
  });
}

// AFTER
Future<void> _loadProducts() async {
  final products = await _repository.getProducts(storeId: widget.store.id);
  setState(() {
    _products = products.map((p) => Product.fromMap(p)).toList();
  });
}
```

### Step 4: Add Sync Status Widget

```dart
AppBar(
  title: Text('inventory.title'.tr()),
  actions: [
    const SyncStatusWidget(), // Add this
  ],
)
```

## API Reference

### OfflineRepository Methods

#### Products
```dart
// Get all products for a store
List<Map<String, dynamic>> products = await repository.getProducts(storeId: 'store-id');

// Get single product
Map<String, dynamic>? product = await repository.getProduct(localId);

// Add product (works offline)
int localId = await repository.addProduct({
  'store_id': 'store-id',
  'name': 'Product Name',
  'price': 5000.0,
  'stock_quantity': 100,
});

// Update product
await repository.updateProduct(localId, {
  'name': 'Updated Name',
  'price': 6000.0,
});

// Delete product
await repository.deleteProduct(localId);
```

#### Sales
```dart
// Get sales (with optional filters)
List<Map<String, dynamic>> sales = await repository.getSales(
  storeId: 'store-id',
  employeeId: 'employee-id', // optional
  startDate: DateTime(2024, 1, 1), // optional
  endDate: DateTime(2024, 12, 31), // optional
);

// Add sale
int localId = await repository.addSale({
  'store_id': 'store-id',
  'product_id': 'product-id',
  'product_name': 'Product Name',
  'quantity': 2,
  'price': 5000.0,
  'total': 10000.0,
  'employee_id': 'emp-id',
  'sale_date': DateTime.now().toIso8601String(),
});
```

#### Categories
```dart
// Get categories
List<Map<String, dynamic>> categories = await repository.getCategories(storeId: 'store-id');

// Add category
await repository.addCategory({
  'store_id': 'store-id',
  'name': 'Category Name',
  'description': 'Description',
});

// Update category
await repository.updateCategory(localId, {
  'name': 'Updated Name',
});

// Delete category
await repository.deleteCategory(localId);
```

#### Expenses
```dart
// Get expenses
List<Map<String, dynamic>> expenses = await repository.getExpenses(
  storeId: 'store-id',
  startDate: DateTime(2024, 1, 1), // optional
  endDate: DateTime(2024, 12, 31), // optional
);

// Add expense
await repository.addExpense({
  'store_id': 'store-id',
  'description': 'Rent payment',
  'amount': 50000.0,
  'category': 'Rent',
  'expense_date': DateTime.now().toIso8601String(),
});
```

#### Debts
```dart
// Get debts
List<Map<String, dynamic>> debts = await repository.getDebts(storeId: 'store-id');

// Add debt
await repository.addDebt({
  'store_id': 'store-id',
  'customer_name': 'John Doe',
  'customer_phone': '0712345678',
  'amount': 10000.0,
  'balance': 10000.0,
  'status': 'pending',
});

// Update debt (e.g., payment made)
await repository.updateDebt(localId, {
  'amount_paid': 5000.0,
  'balance': 5000.0,
});
```

## Sync Behavior

### Automatic Sync
- Triggers when app detects internet connection
- Runs in background
- Prioritizes based on operation importance:
  - **Priority 3**: Sales (highest)
  - **Priority 2**: Products, Expenses, Debts
  - **Priority 1**: Categories

### Manual Sync
Users can trigger sync manually via:
- Sync status widget (refresh button)
- Pull-to-refresh in pages
- Settings page sync button

### Conflict Resolution
Currently uses **last-write-wins** strategy:
- Newer timestamp overrides older
- Suitable for shop operations where latest data is correct
- Future: Can implement more sophisticated strategies

## Benefits

### 1. ⚡ Performance
- Instant response (no network delay)
- Smooth user experience
- Works in areas with poor network

### 2. 💾 Reliability
- No lost transactions
- Data saved immediately
- Automatic retry on failure

### 3. 📶 Offline Capability
- Full functionality offline
- Sales never interrupted
- Syncs when connection returns

### 4. 🔄 Seamless Sync
- Automatic background sync
- User doesn't need to think about it
- Clear status indicators

## Limitations & Future Enhancements

### Current Limitations
1. **Initial data load**: First sync downloads all data (can be slow)
2. **Storage**: Local database grows over time
3. **Conflict resolution**: Simple last-write-wins
4. **Image sync**: Product images not yet optimized for offline

### Planned Enhancements
1. **Incremental sync**: Only sync changed records
2. **Data pruning**: Auto-delete old synced data
3. **Image caching**: Offline product images
4. **Smart conflict resolution**: User prompts for conflicts
5. **Background sync worker**: Periodic background sync
6. **Compression**: Reduce sync data size

## Testing Offline Mode

### Enable Airplane Mode
1. Turn on airplane mode on device
2. Use app normally - everything works!
3. Check sync status widget shows "Offline"
4. Make changes (add sales, update inventory)
5. Turn off airplane mode
6. Watch automatic sync happen
7. Verify changes in Supabase dashboard

### Test Scenarios
- ✅ Make sale while offline
- ✅ Add new product while offline
- ✅ Record expense while offline
- ✅ Update inventory while offline
- ✅ Check pending sync count
- ✅ Trigger manual sync
- ✅ Verify data appears in Supabase

## Troubleshooting

### Sync Not Working
1. Check internet connection
2. Check Supabase credentials
3. View sync queue: `SELECT * FROM sync_queue` in local DB
4. Check for errors in console

### Data Not Appearing
1. Verify local DB has data: use SQLite browser
2. Check `synced` column (0 = pending, 1 = synced)
3. Trigger manual sync
4. Check Supabase dashboard

### Performance Issues
1. Check local DB size
2. Run vacuum: `VACUUM` in SQLite
3. Consider data pruning
4. Check sync queue size

## Support

For issues or questions:
1. Check console logs for errors
2. Verify sync status widget shows correct state
3. Test with airplane mode on/off
4. Check SQLite database directly if needed

---

**Ready to use! The app now works fully offline! 🎉**
