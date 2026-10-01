import 'package:isar/isar.dart';

import '../data/local/istoria_schema.dart';
import '../data/remote/api_client.dart';

class IstoriaRepository {
  IstoriaRepository({required this.isar, required this.apiClient});

  final Isar isar;
  final ApiClient apiClient;

  Future<IstoriaKlinis> create(IstoriaKlinis istoria) async {
    istoria.syncStatus = 'Pending';
    await isar.writeTxn(() => isar.istoriaKlinis.put(istoria));
    await _trySync(istoria);
    return istoria;
  }

  Future<List<IstoriaKlinis>> history(String pasienId) async {
    try {
      final remote = await apiClient.getIstoriaByPasien(pasienId);
      final records = remote.map(IstoriaKlinis.fromApiJson).toList();
      await isar.writeTxn(() async {
        for (final record in records) {
          await isar.istoriaKlinis.put(record);
        }
      });
    } catch (_) {}

    return (await isar.istoriaKlinis.where().findAll())
        .where((record) => record.pasienId == pasienId)
        .toList()
      ..sort((a, b) => (b.tanggalKunjungan ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.tanggalKunjungan ?? DateTime.fromMillisecondsSinceEpoch(0)));
  }

  Future<void> syncPending() async {
    final pending = (await isar.istoriaKlinis.where().findAll())
        .where((record) => record.syncStatus == 'Pending')
        .toList();
    for (final record in pending) {
      await _trySync(record);
    }
  }

  Future<void> _trySync(IstoriaKlinis istoria) async {
    try {
      final response = await apiClient.createIstoria(istoria);
      istoria.remoteId = response['kunjungan_id'] as String?;
      istoria.tanggalKunjungan = response['tanggal_kunjungan'] == null
          ? istoria.tanggalKunjungan
          : DateTime.parse(response['tanggal_kunjungan'] as String);
      istoria.syncStatus = 'Synced';
    } catch (_) {
      istoria.syncStatus = 'Pending';
    }
    await isar.writeTxn(() => isar.istoriaKlinis.put(istoria));
  }
}
