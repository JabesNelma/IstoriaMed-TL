import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadSyncStatus extends SyncEvent {
  const LoadSyncStatus();
}

final class ManualSyncRequested extends SyncEvent {
  const ManualSyncRequested();
}

final class RetryFailedOperationRequested extends SyncEvent {
  const RetryFailedOperationRequested(this.operationId);

  final String operationId;

  @override
  List<Object?> get props => [operationId];
}
