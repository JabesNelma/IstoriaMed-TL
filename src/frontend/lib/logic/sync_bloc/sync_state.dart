import 'package:equatable/equatable.dart';

import '../../core/sync/sync_service.dart';
import '../../data/local/sync_operation_schema.dart';

sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => const [];
}

final class SyncInitial extends SyncState {
  const SyncInitial();
}

/// One snapshot of the persistent queue for the Sync Center.
final class SyncStatusLoaded extends SyncState {
  const SyncStatusLoaded({
    required this.pending,
    required this.failed,
    required this.lastSyncedAt,
    this.lastReport,
  });

  final List<SyncOperation> pending;
  final List<SyncOperation> failed;
  final DateTime? lastSyncedAt;
  final SyncRunReport? lastReport;

  int get waitingCount => pending.length + failed.length;

  @override
  List<Object?> get props => [pending, failed, lastSyncedAt, lastReport];
}

final class SyncRunning extends SyncState {
  const SyncRunning();
}

/// The queue itself could not be read (e.g. the local store is not fully
/// initialized). Shown inline by the Sync Center — never as a snackbar.
final class SyncStatusUnavailable extends SyncState {
  const SyncStatusUnavailable(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class SyncFailureMessage extends SyncState {
  const SyncFailureMessage(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
