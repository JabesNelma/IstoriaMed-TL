import 'package:isar/isar.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../../data/local/sync_operation_schema.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/api_exception.dart';
import 'sync_queue.dart';
import 'sync_types.dart';

typedef SyncClock = DateTime Function();
typedef SyncSleeper = Future<void> Function(Duration duration);

enum SyncOutcome { synced, pending, failed, skipped }

class SyncRunReport {
  const SyncRunReport({
    required this.attempted,
    required this.synced,
    required this.pending,
    required this.failed,
    required this.skipped,
  });

  final int attempted;
  final int synced;
  final int pending;
  final int failed;
  final int skipped;

  @override
  String toString() =>
      'SyncRunReport(attempted: $attempted, synced: $synced, pending: $pending, failed: $failed, skipped: $skipped)';
}

/// Single synchronization pathway for the whole application.
///
/// Responsibilities (no UI logic lives here):
///   load pending operations -> sort by createdAt -> mark SYNCING ->
///   resolve entity from Isar -> send to API -> map response ->
///   persist SYNCED / PENDING / FAILED -> continue with the next operation.
class SyncService {
  SyncService({
    required this.isar,
    required this.apiClient,
    SyncClock? clock,
    SyncSleeper? sleeper,
  })  : _clock = clock ?? DateTime.now,
        _sleeper = sleeper ?? Future<void>.delayed;

  final Isar isar;
  final ApiClient apiClient;
  final SyncClock _clock;
  final SyncSleeper _sleeper;

  Future<SyncRunReport>? _inFlight;

  /// Processes the queue exactly once. Concurrent callers join the run that is
  /// already in progress instead of starting a second parallel sync.
  Future<SyncRunReport> syncPending() {
    final running = _inFlight;
    if (running != null) return running;
    final run = _run();
    _inFlight = run;
    return run.whenComplete(() {
      _inFlight = null;
    });
  }

  Future<SyncRunReport> _run() async {
    await _recoverInterruptedOperations();

    final queued = await SyncQueue.loadPending(isar);
    var attempted = 0;
    var synced = 0;
    var pending = 0;
    var failed = 0;
    var skipped = 0;

    for (final operation in queued) {
      final outcome = await _process(operation);
      switch (outcome) {
        case SyncOutcome.synced:
          attempted += 1;
          synced += 1;
        case SyncOutcome.pending:
          attempted += 1;
          pending += 1;
        case SyncOutcome.failed:
          attempted += 1;
          failed += 1;
        case SyncOutcome.skipped:
          skipped += 1;
      }
    }

    return SyncRunReport(
      attempted: attempted,
      synced: synced,
      pending: pending,
      failed: failed,
      skipped: skipped,
    );
  }

  /// A process that dies mid-flight leaves operations in SYNCING. They are
  /// returned to PENDING so the queue resumes after an application restart.
  Future<void> _recoverInterruptedOperations() async {
    final interrupted = (await isar.syncOperations.where().findAll())
        .where((operation) => operation.status == SyncStatus.syncing)
        .toList();
    if (interrupted.isEmpty) return;
    final timestamp = _clock();
    await isar.writeTxn(() async {
      for (final operation in interrupted) {
        operation.status = SyncStatus.pending;
        operation.lastError = 'Interrupted before acknowledgement.';
        operation.nextAttemptAt = null;
        operation.updatedAt = timestamp;
        await isar.syncOperations.put(operation);
      }
    });
  }

  Future<SyncOutcome> _process(SyncOperation operation) async {
    final timestamp = _clock();

    final nextAttemptAt = operation.nextAttemptAt;
    if (nextAttemptAt != null && nextAttemptAt.isAfter(timestamp)) {
      return SyncOutcome.skipped;
    }

    final dependency = await _resolveDependency(operation);
    if (dependency == false) return SyncOutcome.skipped;

    final patient = operation.entityType == SyncEntityType.patient
        ? await isar.pasiens.get(operation.localEntityId)
        : null;
    final visit = operation.entityType == SyncEntityType.clinicalVisit
        ? await isar.istoriaKlinis.get(operation.localEntityId)
        : null;

    if (operation.entityType == SyncEntityType.patient && patient == null) {
      return _markFailed(operation, 'Local patient record is missing.');
    }
    if (operation.entityType == SyncEntityType.clinicalVisit && visit == null) {
      return _markFailed(operation, 'Local clinical visit record is missing.');
    }

    operation.status = SyncStatus.syncing;
    operation.retryCount += 1;
    operation.updatedAt = timestamp;
    await isar.writeTxn(() => isar.syncOperations.put(operation));

    try {
      final response = await apiClient.submitSyncOperation(
        operationId: operation.operationId,
        entityType: operation.entityType,
        entityId: operation.entityId,
        operationType: operation.operationType,
        payload: patient != null ? patient.toSyncPayload() : visit!.toSyncPayload(),
      );
      return _applyResponse(operation, response, patient, visit);
    } on ApiException catch (error) {
      return _applyFailure(operation, classifySyncFailure(error));
    } on Object catch (error) {
      return _applyFailure(
        operation,
        SyncFailure(kind: SyncFailureKind.transient, message: error.toString()),
      );
    }
  }

  /// Returns false when the operation must wait for a dependency.
  Future<bool> _resolveDependency(SyncOperation operation) async {
    final dependencyId = operation.dependsOnOperationId;
    if (dependencyId == null) return true;
    final dependency = await SyncQueue.findByOperationId(isar, dependencyId);
    if (dependency == null) {
      await isar.writeTxn(() {
        operation.dependsOnOperationId = null;
        operation.updatedAt = _clock();
        return isar.syncOperations.put(operation);
      });
      return true;
    }
    // FAILED dependencies keep the dependent operation PENDING so no orphan
    // clinical visit is ever produced.
    return dependency.status == SyncStatus.synced;
  }

  Future<SyncOutcome> _applyResponse(
    SyncOperation operation,
    Map<String, dynamic> response,
    Pasien? patient,
    IstoriaKlinis? visit,
  ) async {
    final status = response['status'];
    final message = response['message'] is String ? response['message'] as String : null;
    final entityId = response['entity_id'] is String ? response['entity_id'] as String : null;

    if (status != SyncStatus.synced) {
      return _markFailed(operation, message ?? 'Server rejected the operation.');
    }

    final timestamp = _clock();
    final entity = response['entity'];
    await isar.writeTxn(() async {
      if (patient != null) {
        patient.localStatus = SyncLocalStatus.synced;
        patient.remoteId = entityId ?? patient.remoteId;
        if (entity is Map) {
          final details = Map<String, dynamic>.from(entity);
          patient.medicalRecordNumber =
              details['medical_record_number'] as String? ?? patient.medicalRecordNumber;
          patient.facilityId = details['facility_id'] as String? ?? patient.facilityId;
        }
        await isar.pasiens.put(patient);
      }
      if (visit != null) {
        visit.syncStatus = SyncLocalStatus.synced;
        visit.remoteId = entityId ?? visit.remoteId;
        if (entity is Map) {
          final details = Map<String, dynamic>.from(entity);
          visit.tenantId = details['tenant_id'] as String? ?? visit.tenantId;
        }
        await isar.istoriaKlinis.put(visit);
      }
      operation.status = SyncStatus.synced;
      operation.lastError = null;
      operation.nextAttemptAt = null;
      operation.syncedAt = timestamp;
      operation.updatedAt = timestamp;
      await isar.syncOperations.put(operation);
    });
    return SyncOutcome.synced;
  }

  Future<SyncOutcome> _applyFailure(SyncOperation operation, SyncFailure failure) async {
    if (failure.isPermanent) {
      return _markFailed(operation, failure.message);
    }
    final timestamp = _clock();
    operation.status = SyncStatus.pending;
    operation.lastError = failure.message;
    operation.nextAttemptAt = timestamp.add(SyncBackoff.delayFor(operation.retryCount));
    operation.updatedAt = timestamp;
    await isar.writeTxn(() async {
      if (operation.entityType == SyncEntityType.patient) {
        final patient = await isar.pasiens.get(operation.localEntityId);
        if (patient != null) {
          patient.localStatus = SyncLocalStatus.pending;
          await isar.pasiens.put(patient);
        }
      } else {
        final visit = await isar.istoriaKlinis.get(operation.localEntityId);
        if (visit != null) {
          visit.syncStatus = SyncLocalStatus.pending;
          await isar.istoriaKlinis.put(visit);
        }
      }
      await isar.syncOperations.put(operation);
    });
    return SyncOutcome.pending;
  }

  Future<SyncOutcome> _markFailed(SyncOperation operation, String message) async {
    final timestamp = _clock();
    operation.status = SyncStatus.failed;
    operation.lastError = message;
    operation.nextAttemptAt = null;
    operation.updatedAt = timestamp;
    await isar.writeTxn(() async {
      if (operation.entityType == SyncEntityType.patient) {
        final patient = await isar.pasiens.get(operation.localEntityId);
        if (patient != null) {
          patient.localStatus = SyncLocalStatus.failed;
          await isar.pasiens.put(patient);
        }
      } else {
        final visit = await isar.istoriaKlinis.get(operation.localEntityId);
        if (visit != null) {
          visit.syncStatus = SyncLocalStatus.failed;
          await isar.istoriaKlinis.put(visit);
        }
      }
      await isar.syncOperations.put(operation);
    });
    return SyncOutcome.failed;
  }

  /// Waits out the backoff window of the oldest blocked operation.
  /// Exposed for hosts that want to schedule a follow-up run themselves.
  Future<Duration?> timeUntilNextAttempt() async {
    final queued = await SyncQueue.loadPending(isar);
    final timestamp = _clock();
    final waits = queued
        .map((operation) => operation.nextAttemptAt)
        .whereType<DateTime>()
        .where((next) => next.isAfter(timestamp))
        .map((next) => next.difference(timestamp))
        .toList();
    if (waits.isEmpty) return null;
    waits.sort();
    return waits.first;
  }

  /// Sleeps for the backoff window. Split out so tests inject an instant clock.
  Future<void> waitForNextAttempt() async {
    final wait = await timeUntilNextAttempt();
    if (wait == null) return;
    await _sleeper(wait);
  }
}
