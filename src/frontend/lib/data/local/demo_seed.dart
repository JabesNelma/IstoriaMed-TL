import 'package:isar/isar.dart';

import '../session/demo_mode.dart';
import 'istoria_schema.dart';
import 'medication.dart';
import 'pasien_schema.dart';
import 'prescription_schema.dart';

/// DEVELOPMENT/TEST DATA — clearly synthetic, never real patient records.
///
/// Seeds a small demo catalogue (3 patients, some clinical visits) so the UI
/// can be reviewed before a backend is reachable. Only runs when [kDemoMode]
/// is enabled AND the local store is empty, and only from main() — never from
/// tests and never with queue entries, so demo data is never synchronized.
Future<void> seedDemoDataIfEmpty(Isar isar) async {
  if (!kDemoMode) return;
  if (await isar.pasiens.count() > 0) return;

  const tenants = 'demo-fasilitas';
  final patients = [
    Pasien()
      ..remoteId = 'demo-pasiente-1'
      ..noKtp = 'DEMO-0001'
      ..medicalRecordNumber = 'MRN-DEMO-0001'
      ..namaLengkap = 'Maria A. Guterres (DEMO)'
      ..tanggalLahir = DateTime(1988, 4, 12)
      ..tempatLahir = 'Dili'
      ..jenisKelamin = 'Perempuan'
      ..localStatus = 'Pending',
    Pasien()
      ..remoteId = 'demo-pasiente-2'
      ..noKtp = 'DEMO-0002'
      ..medicalRecordNumber = 'MRN-DEMO-0002'
      ..namaLengkap = 'João P. Pereira (DEMO)'
      ..tanggalLahir = DateTime(1975, 11, 30)
      ..tempatLahir = 'Maubisse'
      ..jenisKelamin = 'Laki-laki'
      ..localStatus = 'Pending',
    Pasien()
      ..remoteId = 'demo-pasiente-3'
      ..noKtp = 'DEMO-0003'
      ..medicalRecordNumber = 'MRN-DEMO-0003'
      ..namaLengkap = 'Rosa B. Ximenes (DEMO)'
      ..tanggalLahir = DateTime(2001, 2, 8)
      ..tempatLahir = 'Baucau'
      ..jenisKelamin = 'Perempuan'
      ..localStatus = 'Pending',
  ];
  final visits = [
    IstoriaKlinis()
      ..remoteId = 'demo-kunjungan-1'
      ..pasienId = 'demo-pasiente-1'
      ..tenantId = tenants
      ..keluhanSubjektif = 'Isin manas no hadok iha loron 2.'
      ..pemeriksaanObjektif = 'Temperatura 38.2C, tenkeun klaru.'
      ..analisisAsesmen = 'Isin manas komun (febre viral).'
      ..rencanaTindakan = 'Dranku be be, parasetamol 500mg.'
      ..kodeIcd10 = 'R50.9'
      ..namaPenyakitLokal = 'Isin manas'
      ..tanggalKunjungan = DateTime(2026, 9, 20, 9, 0)
      ..syncStatus = 'Pending',
    IstoriaKlinis()
      ..remoteId = 'demo-kunjungan-2'
      ..pasienId = 'demo-pasiente-1'
      ..tenantId = tenants
      ..keluhanSubjektif = 'Kabuk mhór iha loron 3.'
      ..pemeriksaanObjektif = 'Pressaun 120/80, respirasaun normal.'
      ..analisisAsesmen = 'Infeksaun respiratoriu superior.'
      ..rencanaTindakan = 'Kontrolla fali iha semana ida.'
      ..kodeIcd10 = 'J06.9'
      ..namaPenyakitLokal = 'Isin respiratoriu'
      ..tanggalKunjungan = DateTime(2026, 10, 2, 14, 30)
      ..syncStatus = 'Pending',
    IstoriaKlinis()
      ..remoteId = 'demo-kunjungan-3'
      ..pasienId = 'demo-pasiente-2'
      ..tenantId = tenants
      ..keluhanSubjektif = 'Laran moris bainhira sae hato-o.'
      ..pemeriksaanObjektif = 'Pressaun 150/95.'
      ..analisisAsesmen = 'Hipertensaun estajiu 1.'
      ..rencanaTindakan = 'Dieta paun menik, kontrola pressaun monthly.'
      ..kodeIcd10 = 'I10'
      ..namaPenyakitLokal = 'Pressaun sano'
      ..tanggalKunjungan = DateTime(2026, 9, 5, 8, 15)
      ..syncStatus = 'Pending',
  ];

  await isar.writeTxn(() async {
    await isar.pasiens.putAll(patients);
    await isar.istoriaKlinis.putAll(visits);
    await isar.prescriptions.putAll(demoPrescriptions);
  });
}

/// Synthetic medication catalogue for demo mode only. The real catalog is
/// server owned reference data read through PrescriptionRepository.medications;
/// this list only keeps the prescription flow reviewable without a backend.
const List<Medication> demoMedications = <Medication>[
  Medication(
    medicationId: 'demo-med-1',
    name: 'Paracetamol',
    genericName: 'Paracetamol',
    form: 'TABLET',
    strength: '500 mg',
    unit: 'TABLET',
  ),
  Medication(
    medicationId: 'demo-med-2',
    name: 'Amoxicillin',
    genericName: 'Amoxicillin',
    form: 'KAPSUL',
    strength: '500 mg',
    unit: 'KAPSUL',
  ),
  Medication(
    medicationId: 'demo-med-3',
    name: 'Amlodipine',
    genericName: 'Amlodipine',
    form: 'TABLET',
    strength: '5 mg',
    unit: 'TABLET',
  ),
];

/// Synthetic demo prescriptions (never queued for synchronization).
final List<Prescription> demoPrescriptions = <Prescription>[
  Prescription()
    ..remoteId = 'demo-rese-1'
    ..visitId = 'demo-kunjungan-2'
    ..prescribedAt = DateTime(2026, 10, 2, 15, 0)
    ..syncStatus = 'Pending'
    ..items = <PrescriptionItem>[
      PrescriptionItem()
        ..medicationId = 'demo-med-1'
        ..medicationName = 'Paracetamol'
        ..medicationStrength = '500 mg'
        ..dose = '1 tablet'
        ..frequency = '3x loron'
        ..duration = '5 loron'
        ..quantity = 15,
    ],
];
