import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/sync/sync_service.dart';
import 'package:frontend/data/local/istoria_schema.dart';
import 'package:frontend/data/local/pasien_schema.dart';
import 'package:frontend/data/local/prescription_schema.dart';
import 'package:frontend/data/local/sync_operation_schema.dart';
import 'package:frontend/data/remote/api_client.dart';
import 'package:frontend/data/remote/api_exception.dart';
import 'package:frontend/logic/istoria_bloc/istoria_bloc.dart';
import 'package:frontend/logic/istoria_bloc/istoria_event.dart';
import 'package:frontend/logic/istoria_bloc/istoria_state.dart';
import 'package:frontend/logic/pasien_bloc/pasien_bloc.dart';
import 'package:frontend/logic/pasien_bloc/pasien_event.dart';
import 'package:frontend/logic/pasien_bloc/pasien_state.dart';
import 'package:frontend/repositories/istoria_repository.dart';
import 'package:frontend/repositories/pasien_repository.dart';
import 'package:isar/isar.dart';

import 'support/isar_test_support.dart';

/// Phase 2 + 3 acceptance: patient list -> register -> profile data ->
/// new clinical visit (SOAP) -> visit history -> search, driven by the real
/// blocs and repositories over a real Isar database. Every remote call is
/// stubbed as a network failure, so only the offline/local path can pass —
/// the same path the APK uses without internet.
///
/// Written as a plain async test (not testWidgets): Isar queries complete on
/// a real isolate, which the fake-async widget-test zone never drives. The
/// widget layer itself is covered by widget_test.dart and auth_flow_test.dart.
void main() {
  setUpAll(initializeIsarForTests);

  late Directory directory;
  late Isar isar;
  late PasienBloc pasienBloc;
  late IstoriaBloc istoriaBloc;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('istoria-flow-');
    isar = await Isar.open(
      [
        PasienSchema,
        IstoriaKlinisSchema,
        PrescriptionSchema,
        SyncOperationSchema,
      ],
      directory: directory.path,
      name: 'istoria_flow_test',
    );
    final apiClient = OfflineApiClient();
    pasienBloc = PasienBloc(
      PasienRepository(isar: isar, apiClient: apiClient),
      SyncService(isar: isar, apiClient: apiClient),
    );
    istoriaBloc = IstoriaBloc(
      IstoriaRepository(isar: isar, apiClient: apiClient),
      SyncService(isar: isar, apiClient: apiClient),
    );
  });

  tearDown(() async {
    await pasienBloc.close();
    await istoriaBloc.close();
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('offline flow: empty list -> register -> duplicate rejected -> search -> visit -> history', () async {
    // Patient list loads from the empty local store.
    pasienBloc.add(const LoadPasienList());
    expect(
      await pasienBloc.stream.firstWhere((s) => s is PasienListLoaded),
      isA<PasienListLoaded>().having((s) => s.pasiens, 'pasiens', isEmpty),
    );

    // Register a patient offline: success with a local placeholder MRN and
    // the record queued for synchronization.
    final pasien = Pasien()
      ..noKtp = 'DEMO-KTP-777'
      ..namaLengkap = 'Teste Pasiente Fuan'
      ..tanggalLahir = DateTime(1990, 5, 15)
      ..tempatLahir = 'Dili'
      ..jenisKelamin = 'Perempuan'
      ..localStatus = 'Pending';
    pasienBloc.add(RegisterPasien(pasien));
    final registered = await pasienBloc.stream
        .firstWhere((s) => s is PasienSuccess || s is PasienError);
    expect(registered, isA<PasienSuccess>());
    final saved = (registered as PasienSuccess).pasien;
    expect(saved.remoteId, isNotNull, reason: 'the device reserves the patient id');
    expect(saved.medicalRecordNumber, startsWith('MRN-LOCAL-'));
    expect(saved.localStatus, 'Pending');

    // Duplicate KTP is rejected locally.
    pasienBloc.add(RegisterPasien(
      Pasien()
        ..noKtp = 'DEMO-KTP-777'
        ..namaLengkap = 'Duplicatu'
        ..tanggalLahir = DateTime(1980, 1, 1)
        ..tempatLahir = 'Dili'
        ..jenisKelamin = 'Laki-laki'
        ..localStatus = 'Pending',
    ));
    expect(
      await pasienBloc.stream.firstWhere((s) => s is PasienError),
      isA<PasienError>(),
    );

    // The catalogue now contains the patient, searchable by name and KTP.
    pasienBloc.add(const LoadPasienList());
    var loaded = await pasienBloc.stream.firstWhere((s) => s is PasienListLoaded);
    expect((loaded as PasienListLoaded).pasiens, hasLength(1));

    pasienBloc.add(const LoadPasienList('Fuan'));
    loaded = await pasienBloc.stream.firstWhere((s) => s is PasienListLoaded);
    expect((loaded as PasienListLoaded).pasiens, hasLength(1));

    pasienBloc.add(const LoadPasienList('lae-lahe'));
    loaded = await pasienBloc.stream.firstWhere((s) => s is PasienListLoaded);
    expect((loaded as PasienListLoaded).pasiens, isEmpty);

    pasienBloc.add(const LoadPasienList('DEMO-KTP-777'));
    loaded = await pasienBloc.stream.firstWhere((s) => s is PasienListLoaded);
    expect((loaded as PasienListLoaded).pasiens, hasLength(1));

    // New clinical visit linked to the device-reserved patient id. The sync
    // attempt fails (offline) but the local write must survive.
    final visit = IstoriaKlinis()
      ..pasienId = saved.remoteId!
      ..tenantId = 'demo-fasilitas'
      ..keluhanSubjektif = 'Isin manas loron 2'
      ..pemeriksaanObjektif = 'Temperatura 38C'
      ..analisisAsesmen = 'Febre viral'
      ..rencanaTindakan = 'Parasetamol, dranku be'
      ..kodeIcd10 = 'R50.9'
      ..namaPenyakitLokal = 'Isin manas'
      ..tanggalKunjungan = DateTime(2026, 10, 4, 9, 0)
      ..syncStatus = 'Pending';
    istoriaBloc.add(CreateIstoria(visit));
    final created = await istoriaBloc.stream
        .firstWhere((s) => s is IstoriaSuccess || s is IstoriaError);
    expect(created, isA<IstoriaSuccess>());
    final savedVisit = (created as IstoriaSuccess).record;
    expect(savedVisit.remoteId, isNotNull);
    expect(savedVisit.syncStatus, 'Pending', reason: 'offline: stays queued');
    expect(
      (await isar.istoriaKlinis.where().findAll()).single.pasienId,
      saved.remoteId,
      reason: 'visit is linked to its patient',
    );

    // Visit history for this patient shows the new visit (local fallback).
    istoriaBloc.add(FetchPasienHistory(saved.remoteId!));
    final history = await istoriaBloc.stream
        .firstWhere((s) => s is IstoriaHistoryLoaded || s is IstoriaError);
    expect(history, isA<IstoriaHistoryLoaded>());
    final records = (history as IstoriaHistoryLoaded).records;
    expect(records, hasLength(1));
    expect(records.single.kodeIcd10, 'R50.9');

    // The queue holds exactly the two offline CREATE operations.
    final queue = await isar.syncOperations.where().findAll();
    expect(queue, hasLength(2));
  });
}

/// ApiClient stub: every remote call fails as a network error, so the
/// repositories exercise their offline/local fallback deterministically.
class OfflineApiClient extends ApiClient {
  Never _offline() => throw const ApiException(
        kind: ApiFailureKind.network,
        message: 'offline',
      );

  @override
  Future<Map<String, dynamic>> login({
    required String loginIdentifier,
    required String password,
  }) =>
      _offline();

  @override
  Future<List<Map<String, dynamic>>> searchPasien([String? query]) => _offline();

  @override
  Future<List<Map<String, dynamic>>> getIstoriaByPasien(String pasienId) =>
      _offline();

  @override
  Future<Map<String, dynamic>> submitSyncOperation({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) =>
      _offline();
}
