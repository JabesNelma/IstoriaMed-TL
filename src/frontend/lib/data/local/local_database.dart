import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'istoria_schema.dart';
import 'pasien_schema.dart';
import 'prescription_schema.dart';
import 'sync_operation_schema.dart';

class LocalDatabase {
  static Future<Isar> open() async {
    final directory = await getApplicationSupportDirectory();
    return Isar.open(
      [PasienSchema, IstoriaKlinisSchema, PrescriptionSchema, SyncOperationSchema],
      directory: directory.path,
      name: 'istoria_med',
    );
  }
}
