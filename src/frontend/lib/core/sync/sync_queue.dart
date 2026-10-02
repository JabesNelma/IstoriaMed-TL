import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/istoria_schema.dart';
import '../../data/local/pasien_schema.dart';
import '../../data/local/prescription_schema.dart';
import '../../data/local/sync_operation_schema.dart';
import 'sync_types.dart';

/// Owns every write to the persistent offline queue.
///
/// The local entity and its queue entry are always written inside a single
/// Isar transaction, so the device can never end up with an orphan queue entry
/// or with locally stored clinical data that was silently dropped from the
/// queue.
abstract final class SyncQueue {
  const SyncQueue._();

  static const Uuid _uuid = Uuid();

  /// Queues a patient CREATE. Returns the persisted patient.
  static Future<Pasien> enqueuePatient(
    Isar isar,
    Pasien patient, {
    String? operationId,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    return isar.writeTxn(() async {
      patient.localStatus = SyncLocalStatus.pending;
      // The canonical patient identifier is reserved by the device so the
      // server can adopt it verbatim; no id mapping is ever needed later.
      patient.remoteId ??= _uuid.v4();
      final localId = await isar.pasiens.put(patient);
      patient.id = localId;
      await isar.syncOperations.put(
        SyncOperation()
          ..operationId = operationId ?? _uuid.v4()
          ..entityType = SyncEntityType.patient
          ..localEntityId = localId
          ..entityId = patient.remoteId!
          ..operationType = SyncOperationType.create
          ..status = SyncStatus.pending
          ..retryCount = 0
          ..createdAt = timestamp
          ..updatedAt = timestamp,
      );
      return patient;
    });
  }

  /// Queues a clinical visit CREATE, atomically with the visit itself.
  ///
  /// When the referenced patient still has an unsynchronized CREATE operation
  /// the visit is linked to it, so the queue never sends an orphan visit.
  static Future<IstoriaKlinis> enqueueClinicalVisit(
    Isar isar,
    IstoriaKlinis visit, {
    String? operationId,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    return isar.writeTxn(() async {
      visit.syncStatus = SyncLocalStatus.pending;
      visit.remoteId ??= _uuid.v4();
      final localId = await isar.istoriaKlinis.put(visit);
      visit.id = localId;
      final patientOperation = await isar.syncOperations
          .filter()
          .entityIdEqualTo(visit.pasienId)
          .entityTypeEqualTo(SyncEntityType.patient)
          .findFirst();
      await isar.syncOperations.put(
        SyncOperation()
          ..operationId = operationId ?? _uuid.v4()
          ..entityType = SyncEntityType.clinicalVisit
          ..localEntityId = localId
          ..entityId = visit.remoteId!
          ..operationType = SyncOperationType.create
          ..status = SyncStatus.pending
          ..retryCount = 0
          ..dependsOnOperationId = patientOperation != null && patientOperation.status != SyncStatus.synced
              ? patientOperation.operationId
              : null
          ..createdAt = timestamp
          ..updatedAt = timestamp,
      );
      return visit;
    });
  }

  /// Queues a prescription CREATE, atomically with the prescription itself.
  ///
  /// This is the Phase 7 extension of the Phase 6 queue: it reuses the same
  /// operation, idempotency key, dependency and retry machinery rather than
  /// introducing a second queue.
  ///
  /// When the referenced clinical visit still has an unsynchronized CREATE
  /// operation the prescription is linked to it, so the queue can never send a
  /// prescription whose visit does not exist on the server yet.
  static Future<Prescription> enqueuePrescription(
    Isar isar,
    Prescription prescription, {
    String? operationId,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    return isar.writeTxn(() async {
      prescription.syncStatus = SyncLocalStatus.pending;
      // Reserved by the device so the server adopts this exact identifier and
      // the item identifiers stay stable across retries.
      prescription.remoteId ??= _uuid.v4();
      final localId = await isar.prescriptions.put(prescription);
      prescription.id = localId;
      final visitOperation = await isar.syncOperations
          .filter()
          .entityIdEqualTo(prescription.visitId)
          .entityTypeEqualTo(SyncEntityType.clinicalVisit)
          .findFirst();
      await isar.syncOperations.put(
        SyncOperation()
          ..operationId = operationId ?? _uuid.v4()
          ..entityType = SyncEntityType.prescription
          ..localEntityId = localId
          ..entityId = prescription.remoteId!
          ..operationType = SyncOperationType.create
          ..status = SyncStatus.pending
          ..retryCount = 0
          ..dependsOnOperationId = visitOperation != null && visitOperation.status != SyncStatus.synced
              ? visitOperation.operationId
              : null
          ..createdAt = timestamp
          ..updatedAt = timestamp,
      );
      return prescription;
    });
  }

  /// Reads the queue in deterministic oldest-first order.
  static Future<List<SyncOperation>> loadPending(Isar isar) async {
    final operations = await isar.syncOperations.where().findAll();
    operations.sort((a, b) {
      final byCreatedAt = a.createdAt.compareTo(b.createdAt);
      return byCreatedAt != 0 ? byCreatedAt : a.id.compareTo(b.id);
    });
    return operations.where((operation) => operation.status == SyncStatus.pending).toList();
  }

  static Future<SyncOperation?> findByOperationId(Isar isar, String operationId) {
    return isar.syncOperations.filter().operationIdEqualTo(operationId).findFirst();
  }
}
