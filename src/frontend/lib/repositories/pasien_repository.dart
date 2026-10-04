import 'package:isar/isar.dart';

import '../core/sync/sync_queue.dart';
import '../data/local/pasien_schema.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';

/// Thrown when a patient with the same KTP number already exists locally.
/// Duplicate protection against the server catalogue remains a backend
/// responsibility; this only guards the local store.
class DuplicatePasienException implements Exception {
  const DuplicatePasienException(this.noKtp);

  final String noKtp;
}

/// LOCAL/MOCK PLACEHOLDER — not an official national MRN.
///
/// The server owns the authoritative medical record number (it is never part
/// of the sync payload). This generator only gives locally created patients a
/// readable display identifier until the first successful synchronization
/// assigns the real one. Kept behind a single function so backend integration
/// can replace or drop it without touching the UI.
String nextLocalMrn() =>
    'MRN-LOCAL-${DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';

class PasienRepository {
  PasienRepository({required this.isar, required this.apiClient});

  final Isar isar;
  final ApiClient apiClient;

  /// Offline-first create: the patient and its queue entry are written in one
  /// Isar transaction. The same queue then synchronizes it whether the device
  /// is online or offline, so there is only one code path.
  Future<Pasien> register(Pasien pasien) async {
    final ktp = pasien.noKtp?.trim() ?? '';
    if (ktp.isNotEmpty) {
      final duplicate = await isar.pasiens
          .filter()
          .noKtpEqualTo(ktp)
          .findFirst();
      if (duplicate != null) throw DuplicatePasienException(ktp);
    }
    pasien.medicalRecordNumber ??= nextLocalMrn();
    return SyncQueue.enqueuePatient(isar, pasien);
  }

  Future<List<Pasien>> findAll({String? query}) async {
    final patients = await isar.pasiens.where().findAll();
    final needle = query?.trim().toLowerCase() ?? '';
    final filtered = needle.isEmpty
        ? patients
        : patients
            .where(
              (patient) =>
                  patient.namaLengkap.toLowerCase().contains(needle) ||
                  (patient.noKtp?.toLowerCase().contains(needle) ?? false) ||
                  (patient.medicalRecordNumber?.toLowerCase().contains(needle) ?? false),
            )
            .toList();
    filtered.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
    return filtered;
  }

  Future<Pasien?> findById(Id id) => isar.pasiens.get(id);

  /// Online read-through search for the facility catalogue. Falls back to the
  /// local store when the network is unavailable.
  Future<List<Pasien>> searchRemote([String? query]) async {
    try {
      final remote = await apiClient.searchPasien(query);
      final records = remote.map(Pasien.fromApiJson).toList();
      await isar.writeTxn(() async {
        for (final record in records) {
          await isar.pasiens.put(record);
        }
      });
      return records;
    } on ApiException catch (error) {
      if (!error.isNetworkFailure) rethrow;
      return findAll(query: query);
    }
  }
}
