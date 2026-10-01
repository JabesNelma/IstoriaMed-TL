import 'package:isar/isar.dart';

part 'pasien_schema.g.dart';

@collection
@Name('Pasien_538')
class Pasien {
  Id id = Isar.autoIncrement;

  String? remoteId;
  late String noKtp;
  late String namaLengkap;
  late DateTime tanggalLahir;
  late String tempatLahir;
  late String jenisKelamin;
  String? fingerprintHash;
  late String localStatus;

  Map<String, dynamic> toApiJson() => {
        'no_ktp': noKtp,
        'nama_lengkap': namaLengkap,
        'tanggal_lahir': tanggalLahir.toIso8601String(),
        'tempat_lahir': tempatLahir,
        'jenis_kelamin': jenisKelamin,
        if (fingerprintHash != null) 'fingerprint_hash': fingerprintHash,
      };

  static Pasien fromApiJson(Map<String, dynamic> json) {
    final pasien = Pasien()
      ..remoteId = json['user_id'] as String?
      ..noKtp = json['no_ktp'] as String? ?? ''
      ..namaLengkap = json['nama_lengkap'] as String? ?? ''
      ..tanggalLahir = DateTime.parse(json['tanggal_lahir'] as String)
      ..tempatLahir = json['tempat_lahir'] as String? ?? ''
      ..jenisKelamin = json['jenis_kelamin'] as String? ?? ''
      ..fingerprintHash = json['fingerprint_hash'] as String?
      ..localStatus = 'Synced';
    return pasien;
  }
}
