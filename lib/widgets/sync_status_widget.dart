import 'package:flutter/material.dart';
import '../services/sync_manager.dart';
import '../services/offline_repository.dart';

/// Widget that shows sync status and provides manual sync button
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final _syncManager = SyncManager.instance;
  final _repository = OfflineRepository();

  SyncStatus _currentStatus = SyncStatus.pending;
  int _pendingCount = 0;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initStatus();
    _listenToSyncStatus();
  }

  Future<void> _initStatus() async {
    final pendingCount = await _repository.getPendingSyncCount();
    final isOnline = await _repository.isOnline();

    if (mounted) {
      setState(() {
        _pendingCount = pendingCount;
        _isOnline = isOnline;
        _currentStatus = _syncManager.currentStatus;
      });
    }
  }

  void _listenToSyncStatus() {
    _syncManager.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
        _initStatus(); // Refresh pending count
      }
    });
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.pending:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.completed:
        return Icons.cloud_done;
      case SyncStatus.error:
        return Icons.error_outline;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.pending:
        return Icons.cloud_queue;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.completed:
        return _isOnline ? 'Synced' : 'Offline';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.pending:
        return 'Pending sync';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_pendingCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (_currentStatus != SyncStatus.syncing && _pendingCount > 0) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _repository.syncNow(),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: _getStatusColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Badge to show offline indicator
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({Key? key}) : super(key: key);

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final _repository = OfflineRepository();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _repository.isOnline();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Changes will sync when connected.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
