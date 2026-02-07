import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();

  SyncManager._init();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Sync status stream
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Initialize sync manager
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (results.isNotEmpty && results.first != ConnectivityResult.none) {
          // Connected to internet, trigger sync
          syncAll();
        }
      },
    );

    // Check if we're online and sync
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.isNotEmpty &&
        connectivity.first != ConnectivityResult.none) {
      syncAll();
    }
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivity = await _connectivity.checkConnectivity();
    return connectivity.isNotEmpty &&
        connectivity.first != ConnectivityResult.none;
  }

  // Sync all data
  Future<void> syncAll() async {
    if (_isSyncing) return; // Prevent concurrent syncs

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Check if online
      if (!await isOnline()) {
        _syncStatusController.add(SyncStatus.offline);
        _isSyncing = false;
        return;
      }

      // Push local changes to server
      await _pushChanges();

      // Pull updates from server
      await _pullUpdates();

      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Push local changes to Supabase
  Future<void> _pushChanges() async {
    final db = LocalDatabase.instance;
    final supabase = Supabase.instance.client;

    // Get pending sync operations
    final pendingOps = await db.getPendingSyncOperations();

    for (var op in pendingOps) {
      try {
        final tableName = op['table_name'] as String;
        final operation = op['operation'] as String;
        final recordId = op['record_id'] as int;

        // Get the actual record from local DB
        final records = await db.query(
          tableName,
          where: 'id = ?',
          whereArgs: [recordId],
        );

        if (records.isEmpty) continue;
        final record = Map<String, dynamic>.from(records.first);

        // Remove local-only fields
        record.remove('id');
        record.remove('synced');

        // Handle different operations
        switch (operation) {
          case 'insert':
            final response =
                await supabase.from(tableName).insert(record).select().single();
            // Update local record with server ID
            await db.update(
              tableName,
              {
                'server_id': response['id'].toString(),
                'synced': 1,
              },
              where: 'id = ?',
              whereArgs: [recordId],
            );
            break;

          case 'update':
            final serverId = record['server_id'];
            if (serverId != null) {
              record.remove('server_id');
              await supabase.from(tableName).update(record).eq('id', serverId);
              await db.update(
                tableName,
                {'synced': 1},
                where: 'id = ?',
                whereArgs: [recordId],
              );
            }
            break;

          case 'delete':
            final serverId = record['server_id'];
            if (serverId != null) {
              await supabase.from(tableName).delete().eq('id', serverId);
            }
            break;
        }

        // Remove from sync queue
        await db.removeFromSyncQueue(op['id'] as int);
      } catch (e) {
        print('Error pushing ${op['table_name']}: $e');
        // Update retry count
        final retryCount = (op['retry_count'] as int? ?? 0) + 1;
        await db.update(
          'sync_queue',
          {
            'retry_count': retryCount,
            'last_attempt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [op['id']],
        );
      }
    }
  }

  // Pull updates from Supabase
  Future<void> _pullUpdates() async {
    final db = LocalDatabase.instance;
    final supabase = Supabase.instance.client;

    // Tables to sync (in order of dependencies)
    final tables = [
      'categories',
      'products',
      'employees',
      'sales',
      'expenses',
      'debts',
    ];

    for (var tableName in tables) {
      try {
        // Get last sync time for this table
        final lastSync = await db.getLastSyncTime(tableName);

        // Fetch updates from server
        var query = supabase.from(tableName).select();

        if (lastSync != null) {
          // Only get records updated after last sync
          query = query.gt('updated_at', lastSync);
        }

        final records = await query;

        // Update local database
        for (var record in records) {
          final serverId = record['id'].toString();

          // Check if record exists locally
          final existingRecords = await db.query(
            tableName,
            where: 'server_id = ?',
            whereArgs: [serverId],
          );

          final localRecord = {
            ...record,
            'server_id': serverId,
            'synced': 1,
          };
          localRecord.remove('id'); // Remove server ID from insert

          if (existingRecords.isEmpty) {
            // Insert new record
            await db.insert(tableName, localRecord);
          } else {
            // Update existing record
            await db.update(
              tableName,
              localRecord,
              where: 'server_id = ?',
              whereArgs: [serverId],
            );
          }
        }

        // Update sync metadata
        await db.updateSyncMetadata(tableName, 'pull');
      } catch (e) {
        print('Error pulling $tableName: $e');
      }
    }
  }

  // Manual sync trigger
  Future<void> manualSync() async {
    await syncAll();
  }

  // Get sync status
  SyncStatus get currentStatus {
    if (_isSyncing) return SyncStatus.syncing;
    if (_lastSyncTime == null) return SyncStatus.pending;
    return SyncStatus.completed;
  }

  // Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus {
  pending,
  syncing,
  completed,
  error,
  offline,
}
