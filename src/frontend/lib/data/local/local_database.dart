import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'istoria_schema.dart';
import 'pasien_schema.dart';

class LocalDatabase {
  static Future<Isar> open() async {
    final directory = await getApplicationSupportDirectory();
    return Isar.open(
      [PasienSchema, IstoriaKlinisSchema],
      directory: directory.path,
      name: 'istoria_med',
    );
  }
}
