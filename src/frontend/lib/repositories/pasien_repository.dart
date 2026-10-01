import 'package:isar/isar.dart';

import '../data/local/pasien_schema.dart';
import '../data/remote/api_client.dart';

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
        pasien.remoteId = (data.first as Map)['user_id'] as String?;
      }
      pasien.localStatus = 'Synced';
    } catch (_) {
      pasien.localStatus = 'Pending';
    }
    await isar.writeTxn(() => isar.pasiens.put(pasien));
  }
}
