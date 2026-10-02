import 'package:isar/isar.dart';

import '../core/sync/sync_queue.dart';
import '../data/local/medication.dart';
import '../data/local/prescription_schema.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';

/// Prescription domain repository.
///
/// Prescriptions are offline-first exactly like clinical visits: a prescription
/// created without connectivity is stored locally and pushed later by the same
/// Phase 6 queue, in dependency order after its clinical visit.
class PrescriptionRepository {
  PrescriptionRepository({required this.isar, required this.apiClient});

  final Isar isar;
  final ApiClient apiClient;

  List<Medication>? _catalogCache;

  /// Offline-first create: the prescription and its queue entry are written in
  /// one Isar transaction, and the same queue synchronizes it later.
  Future<Prescription> create(Prescription prescription) =>
      SyncQueue.enqueuePrescription(isar, prescription);

  /// Reads the server owned medication catalog.
  ///
  /// The catalog is not part of the offline queue, so it needs connectivity.
  /// The last successful response is kept in memory for the current session.
  Future<List<Medication>> medications({String? query, bool refresh = false}) async {
    if (!refresh && query == null) {
      final cached = _catalogCache;
      if (cached != null) return cached;
    }
    final remote = await apiClient.getMedications(query: query);
    final catalog = remote.map(Medication.fromApiJson).toList();
    if (query == null) _catalogCache = catalog;
    return catalog;
  }

  /// Prescriptions for one clinical visit.
  ///
  /// Reads through to the server when reachable and refreshes the local cache;
  /// otherwise the locally stored prescriptions (including ones still queued)
  /// are returned so an offline device keeps showing the prescription.
  Future<List<Prescription>> forVisit(String visitId) async {
    try {
      final remote = await apiClient.getPrescriptionsByVisit(visitId);
      final records = remote.map(Prescription.fromApiJson).toList();
      await isar.writeTxn(() async {
        for (final record in records) {
          await isar.prescriptions.put(record);
        }
      });
    } on ApiException catch (error) {
      if (!error.isNetworkFailure) rethrow;
    }

    final local = (await isar.prescriptions.where().findAll())
        .where((record) => record.visitId == visitId)
        .toList()
      ..sort((a, b) {
        final byTime = (a.prescribedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.prescribedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        // Stable tiebreaker so a locally queued prescription without a
        // prescription time still has a deterministic position.
        return byTime != 0 ? byTime : (a.remoteId ?? '').compareTo(b.remoteId ?? '');
      });
    return local;
  }

  Future<Prescription?> findById(String prescriptionId) async {
    try {
      final remote = await apiClient.getPrescription(prescriptionId);
      final record = Prescription.fromApiJson(remote);
      await isar.writeTxn(() => isar.prescriptions.put(record));
      return record;
    } on ApiException catch (error) {
      if (!error.isNetworkFailure) rethrow;
    }
    return (await isar.prescriptions.where().findAll())
        .where((record) => record.remoteId == prescriptionId)
        .firstOrNull;
  }
}