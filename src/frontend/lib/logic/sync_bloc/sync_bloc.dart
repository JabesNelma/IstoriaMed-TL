import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';

import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_types.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// Sync Center controller. It only reads the existing queue and calls the
/// existing [SyncService.syncPending]; every decision (ordering, backoff,
/// idempotency) stays inside the sync engine.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this.isar, this.syncService) : super(const SyncInitial()) {
    on<LoadSyncStatus>((event, emit) async {
      try {
        emit(await _snapshot());
      } catch (_) {
        // Includes the test-environment IsarError when a collection is not
        // registered; the center shows this inline instead of claiming the
        // queue is empty.
        emit(const SyncStatusUnavailable('Status sinkronizasaun la konsege lee.'));
      }
    });
    on<ManualSyncRequested>((event, emit) async {
      emit(const SyncRunning());
      try {
        final report = await syncService.syncPending();
        emit(await _snapshot(lastReport: report));
      } catch (_) {
        emit(const SyncFailureMessage(
            'Sinkronizasaun la konsege. Dadus hela iha perangkat.'));
      }
    });
    on<RetryFailedOperationRequested>((event, emit) async {
      // Returns the FAILED operation to PENDING (stable identity) and lets the
      // existing sync engine run; the UI never implements its own retry.
      await SyncQueue.requeueFailed(isar, event.operationId);
      emit(const SyncRunning());
      try {
        final report = await syncService.syncPending();
        emit(await _snapshot(lastReport: report));
      } catch (_) {
        emit(const SyncFailureMessage(
            'Tenta fali la konsege. Dadus hela iha perangkat.'));
      }
    });
  }

  final Isar isar;
  final SyncService syncService;

  Future<SyncStatusLoaded> _snapshot({SyncRunReport? lastReport}) async {
    final operations = await SyncQueue.loadAll(isar);
    DateTime? lastSyncedAt;
    for (final operation in operations) {
      final syncedAt = operation.syncedAt;
      if (syncedAt != null &&
          (lastSyncedAt == null || syncedAt.isAfter(lastSyncedAt))) {
        lastSyncedAt = syncedAt;
      }
    }
    return SyncStatusLoaded(
      pending: operations
          .where((operation) => operation.status == SyncStatus.pending)
          .toList(),
      failed: operations
          .where((operation) => operation.status == SyncStatus.failed)
          .toList(),
      lastSyncedAt: lastSyncedAt,
      lastReport: lastReport,
    );
  }
}
