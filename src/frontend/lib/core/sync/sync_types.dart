import '../../data/remote/api_exception.dart';

/// Entity types supported by the offline queue.
///
/// Phase 7 extends the Phase 6 queue with `PRESCRIPTION`, which reuses the same
/// operation, idempotency and retry machinery. The medication catalog is
/// deliberately absent: it is server owned reference data and is never queued.
abstract final class SyncEntityType {
  static const patient = 'PATIENT';
  static const clinicalVisit = 'CLINICAL_VISIT';
  static const prescription = 'PRESCRIPTION';

  static const supported = <String>[patient, clinicalVisit, prescription];
}

/// Operation types supported by the offline queue in Phase 6.
abstract final class SyncOperationType {
  static const create = 'CREATE';
}

/// Queue state machine.
abstract final class SyncStatus {
  static const pending = 'PENDING';
  static const syncing = 'SYNCING';
  static const synced = 'SYNCED';
  static const failed = 'FAILED';

  static const all = <String>[pending, syncing, synced, failed];
}

/// Local display status stored on the clinical entities themselves.
abstract final class SyncLocalStatus {
  static const pending = 'Pending';
  static const synced = 'Synced';
  static const failed = 'Failed';
}

abstract final class SyncBackoff {
  static const ceiling = Duration(seconds: 60);

  /// 2s, 4s, 8s, 16s, 32s, 60s, 60s ... for retry 1, 2, 3, ...
  static Duration delayFor(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    final exponent = retryCount > 6 ? 6 : retryCount;
    final seconds = 1 << exponent;
    return Duration(seconds: seconds > 60 ? 60 : seconds);
  }
}

enum SyncFailureKind {
  /// Retry later: offline, timeout, 5xx, 408, 429.
  transient,

  /// Never retry automatically: 4xx business/authorization rejection.
  permanent,

  /// Session is no longer valid. Kept in the queue (not FAILED) because
  /// re-authentication makes the very same operation valid again.
  authRequired,
}

class SyncFailure {
  const SyncFailure({required this.kind, required this.message, this.statusCode});

  final SyncFailureKind kind;
  final String message;
  final int? statusCode;

  bool get isPermanent => kind == SyncFailureKind.permanent;
}

/// Classifies a transport/HTTP failure into a retry decision.
SyncFailure classifySyncFailure(ApiException error) {
  final statusCode = error.statusCode;
  if (error.isNetworkFailure) {
    return SyncFailure(kind: SyncFailureKind.transient, message: error.message, statusCode: statusCode);
  }
  if (statusCode == null) {
    return SyncFailure(kind: SyncFailureKind.transient, message: error.message);
  }
  if (statusCode == 401) {
    return SyncFailure(
      kind: SyncFailureKind.authRequired,
      message: 'Authentication required before this operation can be sent.',
      statusCode: statusCode,
    );
  }
  if (statusCode == 408 || statusCode == 429 || statusCode >= 500) {
    return SyncFailure(kind: SyncFailureKind.transient, message: error.message, statusCode: statusCode);
  }
  if (statusCode >= 400) {
    return SyncFailure(kind: SyncFailureKind.permanent, message: error.message, statusCode: statusCode);
  }
  return SyncFailure(kind: SyncFailureKind.transient, message: error.message, statusCode: statusCode);
}
