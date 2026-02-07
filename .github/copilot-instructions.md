# Dukakiganjani - AI Coding Instructions

## Project Overview
Flutter mobile app for Tanzanian shop/store management with offline-first architecture. Swahili + English localization. Multi-tenant system where owners manage multiple stores with employees.

## Critical Architecture Patterns

### Offline-First Data Access
**ALWAYS use `OfflineRepository` for data operations - never call Supabase directly:**
```dart
// ❌ WRONG - Direct Supabase call
final products = await Supabase.instance.client.from('products').select();

// ✅ CORRECT - Use offline repository
final repository = OfflineRepository();
final products = await repository.getProducts(storeId: storeId);
```

**Why:** All writes go to local SQLite first, then sync queue. Reads always from local DB for instant performance.

### Repository Pattern
- **Data layer:** [`lib/services/offline_repository.dart`](lib/services/offline_repository.dart) - single entry point for CRUD
- **Local storage:** [`lib/services/local_database.dart`](lib/services/local_database.dart) - SQLite with sync queue
- **Sync layer:** [`lib/services/sync_manager.dart`](lib/services/sync_manager.dart) - automatic background sync with retry

## Authentication System

### Custom Phone + PIN Pattern
**Users authenticate with phone numbers, not traditional emails:**
- **Fake email:** `{phone}@dukakiganjani.com` (e.g., `712345678@dukakiganjani.com`)
- **Password:** `{pin}@{phone}` (e.g., `1234@712345678`)
- **Phone format:** Store WITHOUT `+255` prefix (12 char limit on DB)

**Implementation files:** [`lib/auth/owner_register.dart`](lib/auth/owner_register.dart), [`lib/auth/owner_login.dart`](lib/auth/owner_login.dart)

### Multi-Tenant Data Filtering
All queries MUST filter by `owner_id` (owners) or `store_id` (store-specific data):
```dart
// Owner sees only their stores
await repository.getStores(ownerId: currentUser.id);

// Store-specific data
await repository.getProducts(storeId: selectedStore.id);
```

## Data Models

### Store (Multi-currency, Multi-country)
- Status: `'Active'` or `'Inactive'` - controls customer visibility
- Currency: defaults to `'TZS'`, country defaults to `'Tanzania'`
- See [`lib/model/store.dart`](lib/model/store.dart) for complete schema

### Products with Images
- Images stored in Supabase Storage bucket `'products'` (must be public bucket)
- Local DB stores image URLs only
- See [`IMAGE_UPLOAD_FIX.md`](IMAGE_UPLOAD_FIX.md) for storage setup requirements

## Developer Workflows

### Running the App
```bash
flutter pub get                    # Install dependencies
flutter run                        # Run on connected device
flutter run -d chrome --web-port=8080  # Web debugging
```

### Database Operations
- Local DB auto-initializes on app start ([`lib/main.dart`](lib/main.dart))
- Sync happens automatically when online
- Manual sync: `SyncManager.instance.syncAll()`

### Adding New Entities
1. Add table to [`LocalDatabase._createTables()`](lib/services/local_database.dart)
2. Add CRUD methods to [`OfflineRepository`](lib/services/offline_repository.dart)
3. Create model class in [`lib/model/`](lib/model/)
4. Update [`SyncManager`](lib/services/sync_manager.dart) push/pull logic

## Localization

### Swahili-First UI
- Translation files: [`assets/translations/sw.json`](assets/translations/sw.json) (primary), [`en.json`](assets/translations/en.json)
- Usage: `Text('welcome'.tr())` via `easy_localization` package
- **Notifications MUST be in Swahili** - see [`lib/services/notification_service.dart`](lib/services/notification_service.dart)

### Common Swahili Terms
- Duka = Shop/Store
- Bidhaa = Product
- Mauzo = Sales  
- Madeni = Debts
- Gharama = Expenses

## Key Integration Points

### Supabase Configuration
- Credentials in [`.env`](.env) file (with hardcoded fallbacks)
- Tables: `owner_profiles`, `stores`, `products`, `sales`, `employees`, `categories`, `expenses`, `debts`
- RLS policies enforce owner/store isolation
- Storage bucket `'products'` for product images (requires public access)

### Sync Queue System
Priority levels (high to low):
1. **Priority 3:** Sales transactions (critical revenue data)
2. **Priority 2:** Products, expenses, debts
3. **Priority 1:** Categories, employees

Failed syncs auto-retry with exponential backoff.

### Notifications
Local notifications (NOT push) via [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications):
- Low stock alerts (automatic on inventory view)
- Daily sales summaries (manual trigger)
- Debt reminders
- See [`NOTIFICATIONS_GUIDE.md`](NOTIFICATIONS_GUIDE.md) for patterns

## Project-Specific Conventions

### State Management
- **Provider** package for app-wide state (no Riverpod/Bloc)
- [`AuthService`](lib/services/auth_service.dart) manages auth state via `ChangeNotifier`

### File Organization
- **Pages:** [`lib/pages/`](lib/pages/) - full screen views
- **Widgets:** [`lib/widgets/`](lib/widgets/) - reusable components
- **Services:** [`lib/services/`](lib/services/) - business logic, API calls
- **Models:** [`lib/model/`](lib/model/) - data classes with `fromJson`/`toJson`

### Error Handling
- Show user-friendly Swahili messages via `ScaffoldMessenger`
- Log technical details with `debugPrint('🚀 ...')` (emojis used for visibility)
- See custom `LoggingHttpClient` in [`main.dart`](lib/main.dart) for HTTP debugging

## Important Documentation
- [`OFFLINE_MODE_GUIDE.md`](OFFLINE_MODE_GUIDE.md) - Complete offline architecture reference
- [`IMAGE_UPLOAD_FIX.md`](IMAGE_UPLOAD_FIX.md) - Supabase Storage setup requirements
- [`NOTIFICATIONS_GUIDE.md`](NOTIFICATIONS_GUIDE.md) - Notification implementation patterns

## Testing & Debugging
- No automated tests currently (add to [`test/`](test/) directory)
- Use `flutter analyze` for linting ([`analysis_options.yaml`](analysis_options.yaml))
- Debug mode logs ALL HTTP requests/responses (see `LoggingHttpClient`)
- Sync status visible via [`SyncStatusWidget`](lib/widgets/sync_status_widget.dart) in UI
