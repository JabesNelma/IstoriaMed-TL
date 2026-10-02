import 'package:isar/isar.dart';

import '../data/local/pasien_schema.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';

class PasienRepository {
  PasienRepository({required this.isar, required this.apiClient});

  final Isar isar;
  final ApiClient apiClient;

  Future<Pasien> register(Pasien pasien) async {
    pasien.localStatus = 'Pending';
    await isar.writeTxn(() => isar.pasiens.put(pasien));
    await _trySync(pasien);
    return pasien;
  }

  Future<void> syncPending() async {
    final pending = (await isar.pasiens.where().findAll())
        .where((pasien) => pasien.localStatus == 'Pending')
        .toList();
    for (final pasien in pending) {
      await _trySync(pasien);
    }
  }

  Future<void> _trySync(Pasien pasien) async {
    try {
      final response = await apiClient.registerPasien(pasien);
      final data = response['data'];
      if (data is List && data.isNotEmpty && data.first is Map) {
        final remote = data.first as Map;
        pasien.remoteId = remote['user_id'] as String?;
        pasien.medicalRecordNumber = remote['medical_record_number'] as String?;
        pasien.facilityId = remote['facility_id'] as String?;
      }
      pasien.localStatus = 'Synced';
    } on ApiException catch (error) {
      if (!error.isNetworkFailure) {
        pasien.localStatus = 'Failed';
        await isar.writeTxn(() => isar.pasiens.put(pasien));
        rethrow;
      }
      pasien.localStatus = 'Pending';
    }
    await isar.writeTxn(() => isar.pasiens.put(pasien));
  }
}
