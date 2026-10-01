import 'package:isar/isar.dart';

part 'istoria_schema.g.dart';

@collection
@Name('IstoriaKlinis_10267')
class IstoriaKlinis {
  Id id = Isar.autoIncrement;

  String? remoteId;
  late String pasienId;
  late String tenantId;
  late String keluhanSubjektif;
  late String pemeriksaanObjektif;
  late String analisisAsesmen;
  late String rencanaTindakan;
  late String kodeIcd10;
  late String namaPenyakitLokal;
  late String syncStatus;
  DateTime? tanggalKunjungan;

  Map<String, dynamic> toApiJson() => {
        'pasien_id': pasienId,
        'tenant_id': tenantId,
        'keluhan_subjektif': keluhanSubjektif,
        'pemeriksaan_objektif': pemeriksaanObjektif,
        'analisis_asesmen': analisisAsesmen,
        'rencana_tindakan': rencanaTindakan,
        'kode_icd10': kodeIcd10,
        'nama_penyakit_lokal': namaPenyakitLokal,
      };

  static IstoriaKlinis fromApiJson(Map<String, dynamic> json) {
    return IstoriaKlinis()
      ..remoteId = json['kunjungan_id'] as String?
      ..pasienId = json['pasien_id'] as String? ?? ''
      ..tenantId = json['tenant_id'] as String? ?? ''
      ..keluhanSubjektif = json['keluhan_subjektif'] as String? ?? ''
      ..pemeriksaanObjektif = json['pemeriksaan_objektif'] as String? ?? ''
      ..analisisAsesmen = json['analisis_asesmen'] as String? ?? ''
      ..rencanaTindakan = json['rencana_tindakan'] as String? ?? ''
      ..kodeIcd10 = json['kode_icd10'] as String? ?? ''
      ..namaPenyakitLokal = json['nama_penyakit_lokal'] as String? ?? ''
      ..syncStatus = json['status_sinkronisasi'] as String? ?? 'Synced'
      ..tanggalKunjungan = json['tanggal_kunjungan'] == null
          ? null
          : DateTime.parse(json['tanggal_kunjungan'] as String);
  }
}
