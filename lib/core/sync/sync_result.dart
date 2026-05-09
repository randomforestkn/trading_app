import 'sync_status.dart';

class SyncResult {
  const SyncResult({
    required this.status,
    required this.syncedCount,
    required this.failedCount,
    this.message,
  });

  final SyncStatus status;
  final int syncedCount;
  final int failedCount;
  final String? message;

  bool get hasFailures => failedCount > 0 || status == SyncStatus.failed;
}
