import 'package:isar/isar.dart';

import '../core/sync/sync_queue.dart';
import '../data/local/istoria_schema.dart';
import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';

class IstoriaRepository {
  IstoriaRepository({required this.isar, required this.apiClient});

  final Isar isar;
  final ApiClient apiClient;

  /// Offline-first create: the clinical visit and its queue entry are written
  /// in one Isar transaction, and the same queue synchronizes it later.
  Future<IstoriaKlinis> create(IstoriaKlinis istoria) =>
      SyncQueue.enqueueClinicalVisit(isar, istoria);

  Future<List<IstoriaKlinis>> history(String pasienId) async {
    try {
      final remote = await apiClient.getIstoriaByPasien(pasienId);
      final records = remote.map(IstoriaKlinis.fromApiJson).toList();
      await isar.writeTxn(() async {
        for (final record in records) {
          await isar.istoriaKlinis.put(record);
        }
      });
    } on ApiException catch (error) {
      // Network failure or 404 (patient not yet known to the server, e.g.
      // locally created / demo records) both fall back to the local store.
      if (!error.isNetworkFailure && error.statusCode != 404) rethrow;
    }

    final local = (await isar.istoriaKlinis.where().findAll())
        .where((record) => record.pasienId == pasienId)
        .toList()
      ..sort(
        (a, b) => (b.tanggalKunjungan ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.tanggalKunjungan ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return local;
  }
}
