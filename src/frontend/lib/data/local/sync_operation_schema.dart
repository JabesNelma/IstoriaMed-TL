import 'package:isar/isar.dart';

part 'sync_operation_schema.g.dart';

/// Persistent offline synchronization queue.
///
/// Every queued operation owns one stable [operationId] (UUID) that is created
/// exactly once, when the operation is queued, and is never regenerated on
/// retry. The server uses it as its idempotency key, so replaying the same
/// operation can never create a second medical record.
@collection
@Name('SyncOperation_2026_10_02')
class SyncOperation {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String operationId;

  /// `PATIENT` or `CLINICAL_VISIT`.
  late String entityType;

  /// Isar primary key of the local record this operation refers to.
  late int localEntityId;

  /// Canonical UUID the client reserved for the entity before going offline.
  /// The server reuses it, so no extra id mapping is required.
  late String entityId;

  /// `CREATE` (update/delete synchronization is deferred).
  late String operationType;

  /// `PENDING` -> `SYNCING` -> `SYNCED`, with `SYNCING` -> `PENDING` on
  /// transient failure and `SYNCING` -> `FAILED` on permanent failure.
  late String status;

  /// Incremented on every attempt and never reset, kept as historical metadata.
  late int retryCount;

  String? lastError;

  /// Operation that must reach `SYNCED` before this one may be sent
  /// (a clinical visit waits for its patient). Null when nothing is pending.
  @Index()
  String? dependsOnOperationId;

  late DateTime createdAt;
  late DateTime updatedAt;

  /// Earliest time the next attempt may run (exponential backoff ceiling).
  DateTime? nextAttemptAt;

  DateTime? syncedAt;
}
