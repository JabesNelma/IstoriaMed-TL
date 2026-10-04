import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/sync/sync_queue.dart';
import 'package:frontend/core/sync/sync_service.dart';
import 'package:frontend/core/sync/sync_types.dart';
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
import 'package:frontend/logic/prescription_bloc/prescription_bloc.dart';
import 'package:frontend/logic/prescription_bloc/prescription_event.dart';
import 'package:frontend/logic/prescription_bloc/prescription_state.dart';
import 'package:frontend/logic/sync_bloc/sync_bloc.dart';
import 'package:frontend/logic/sync_bloc/sync_event.dart';
import 'package:frontend/logic/sync_bloc/sync_state.dart';
import 'package:frontend/repositories/istoria_repository.dart';
import 'package:frontend/repositories/pasien_repository.dart';
import 'package:frontend/repositories/prescription_repository.dart';
import 'package:isar/isar.dart';

import 'support/isar_test_support.dart';

/// Phase 4 + 5 + 6 acceptance: prescription UI data flow (patient -> visit ->
/// prescription), local persistence, sync center state and failed-operation
/// retry, driven by the real blocs and repositories over a real Isar database.
///
/// Written as a plain async test (not testWidgets) for the same documented
/// reason as patient_visit_flow_test.dart: Isar queries complete on a real
/// isolate, which the fake-async widget-test zone never drives.
void main() {
  setUpAll(initializeIsarForTests);

  late Directory directory;
  late Isar isar;
  late PasienBloc pasienBloc;
  late IstoriaBloc istoriaBloc;
  late PrescriptionBloc prescriptionBloc;
  late SyncBloc syncBloc;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('istoria-phase4-6-');
    isar = await Isar.open(
      [
        PasienSchema,
        IstoriaKlinisSchema,
        PrescriptionSchema,
        SyncOperationSchema,
      ],
      directory: directory.path,
      name: 'istoria_phase456_test',
    );
    final apiClient = OfflineApiClient();
    final syncService = SyncService(isar: isar, apiClient: apiClient);
    pasienBloc = PasienBloc(
      PasienRepository(isar: isar, apiClient: apiClient),
      syncService,
    );
    istoriaBloc = IstoriaBloc(
      IstoriaRepository(isar: isar, apiClient: apiClient),
      syncService,
    );
    prescriptionBloc = PrescriptionBloc(
      PrescriptionRepository(isar: isar, apiClient: apiClient),
      syncService,
    );
    syncBloc = SyncBloc(isar, syncService);
  });

  tearDown(() async {
    await pasienBloc.close();
    await istoriaBloc.close();
    await prescriptionBloc.close();
    await syncBloc.close();
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  Pasien newPasien() {
    return Pasien()
      ..namaLengkap = 'Paciente Rese (TEST)'
      ..tanggalLahir = DateTime(1990, 6, 15)
      ..tempatLahir = 'Dili'
      ..jenisKelamin = 'Laki-laki';
  }

  IstoriaKlinis newVisit(String patientId) {
    return IstoriaKlinis()
      ..pasienId = patientId
      ..tenantId = 'klinika-test'
      ..keluhanSubjektif = 'Isin manas'
      ..pemeriksaanObjektif = 'Temperatura 38C'
      ..analisisAsesmen = 'Febre viral'
      ..rencanaTindakan = 'Parasetamol'
      ..kodeIcd10 = 'R50.9'
      ..namaPenyakitLokal = 'Isin manas'
      ..tanggalKunjungan = DateTime(2026, 10, 4, 9, 0);
  }

  Prescription newPrescription(String visitId) {
    return Prescription()
      ..visitId = visitId
      ..prescribedAt = DateTime(2026, 10, 4, 10, 0)
      ..items = <PrescriptionItem>[
        PrescriptionItem()
          ..medicationId = 'med-1'
          ..medicationName = 'Paracetamol'
          ..dose = '1 tablet'
          ..frequency = '3x loron'
          ..quantity = 15,
      ];
  }

  test('offline chain: register patient -> visit -> prescription, all local, queue ordered', () async {
    // 1. Register patient offline.
    pasienBloc.add(RegisterPasien(newPasien()));
    final pasienState = await pasienBloc.stream
        .firstWhere((state) => state is PasienSuccess || state is PasienError);
    expect(pasienState, isA<PasienSuccess>());
    final pasien = (pasienState as PasienSuccess).pasien;

    // 2. Create clinical visit offline.
    istoriaBloc.add(CreateIstoria(newVisit(pasien.remoteId!)));
    final visitState = await istoriaBloc.stream
        .firstWhere((state) => state is IstoriaSuccess || state is IstoriaError);
    expect(visitState, isA<IstoriaSuccess>());
    final visit = (visitState as IstoriaSuccess).record;

    // 3. Create prescription offline through the prescription bloc.
    prescriptionBloc.add(CreatePrescription(newPrescription(visit.remoteId!)));
    final prescriptionState = await prescriptionBloc.stream.firstWhere(
        (state) => state is PrescriptionSaved || state is PrescriptionError);
    expect(prescriptionState, isA<PrescriptionSaved>());
    final prescription = (prescriptionState as PrescriptionSaved).prescription;

    // 4. The prescription list for the patient resolves through the visit
    //    relationship and shows the new prescription immediately.
    prescriptionBloc
        .add(LoadPatientPrescriptions(pasien.remoteId ?? pasien.id.toString()));
    final listState = await prescriptionBloc.stream
        .firstWhere((state) => state is PrescriptionListLoaded);
    final list = (listState as PrescriptionListLoaded).prescriptions;
    expect(list, hasLength(1));
    expect(list.single.remoteId, prescription.remoteId);
    expect(list.single.items.single.medicationName, 'Paracetamol');
    expect(list.single.syncStatus, SyncLocalStatus.pending);

    // 5. Queue holds exactly three CREATE operations in dependency order:
    //    PATIENT -> CLINICAL_VISIT -> PRESCRIPTION.
    final operations = (await isar.syncOperations.where().findAll())
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    expect(operations.map((operation) => operation.entityType).toList(), [
      SyncEntityType.patient,
      SyncEntityType.clinicalVisit,
      SyncEntityType.prescription,
    ]);
    // The bloc starts its post-save queue drain before the test proceeds, so
    // wait for any in-flight SYNCING attempt to settle before asserting.
    for (var i = 0; i < 100; i++) {
      if (!operations.any((operation) => operation.status == SyncStatus.syncing)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      operations
        ..clear()
        ..addAll(await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    expect(
        operations.every((operation) => operation.status == SyncStatus.pending),
        isTrue);
  });

  test('sync center: waiting count reflects the queue and survives restart', () async {
    pasienBloc.add(RegisterPasien(newPasien()));
    final pasien =
        (await pasienBloc.stream.firstWhere((state) => state is PasienSuccess)
              as PasienSuccess)
            .pasien;
    istoriaBloc.add(CreateIstoria(newVisit(pasien.remoteId!)));
    final visit = (await istoriaBloc.stream
            .firstWhere((state) => state is IstoriaSuccess) as IstoriaSuccess)
        .record;
    prescriptionBloc
        .add(CreatePrescription(newPrescription(visit.remoteId!)));
    await prescriptionBloc.stream
        .firstWhere((state) => state is PrescriptionSaved);

    syncBloc.add(const LoadSyncStatus());
    final loaded = (await syncBloc.stream
            .firstWhere((state) => state is SyncStatusLoaded) as SyncStatusLoaded);
    expect(loaded.waitingCount, 3);
    expect(loaded.failed, isEmpty);
    expect(loaded.lastSyncedAt, isNull);

    // App restart: close and reopen the same database.
    await syncBloc.close();
    await pasienBloc.close();
    await istoriaBloc.close();
    await prescriptionBloc.close();
    await isar.close();
    isar = await Isar.open(
      [
        PasienSchema,
        IstoriaKlinisSchema,
        PrescriptionSchema,
        SyncOperationSchema,
      ],
      directory: directory.path,
      name: 'istoria_phase456_test',
    );

    expect(await isar.pasiens.where().findAll(), hasLength(1));
    expect(await isar.istoriaKlinis.where().findAll(), hasLength(1));
    expect(await isar.prescriptions.where().findAll(), hasLength(1));
    expect(await isar.syncOperations.where().findAll(), hasLength(3));

    final reopenedSyncBloc =
        SyncBloc(isar, SyncService(isar: isar, apiClient: OfflineApiClient()));
    reopenedSyncBloc.add(const LoadSyncStatus());
    final after = (await reopenedSyncBloc.stream
            .firstWhere((state) => state is SyncStatusLoaded) as SyncStatusLoaded);
    expect(after.waitingCount, 3);
    await reopenedSyncBloc.close();
  });

  test('retry: a permanently failed operation is requeued without a duplicate', () async {
    // Queue patient -> visit -> prescription, then run a sync whose client
    // accepts patient and visit but permanently rejects the prescription.
    final pasien = newPasien();
    await SyncQueue.enqueuePatient(isar, pasien);
    final visit = newVisit(pasien.remoteId!);
    await SyncQueue.enqueueClinicalVisit(isar, visit);
    prescriptionBloc.add(CreatePrescription(newPrescription(visit.remoteId!)));
    final saved = await prescriptionBloc.stream
        .firstWhere((state) => state is PrescriptionSaved);
    final prescription = (saved as PrescriptionSaved).prescription;

    // The creating bloc already drained the queue once offline (transient);
    // wait out the backoff window so the rejecting run really attempts it.
    final rejector = RejectingApiClient();
    await Future<void>.delayed(const Duration(seconds: 3));
    await SyncService(
      isar: isar,
      apiClient: rejector,
      sleeper: (_) async {},
    ).syncPending();

    final failedOperation = (await isar.syncOperations.where().findAll())
        .firstWhere((operation) => operation.entityType == SyncEntityType.prescription);
    expect(failedOperation.status, SyncStatus.failed);

    // Sync Center shows the failure...
    syncBloc.add(const LoadSyncStatus());
    final loaded = (await syncBloc.stream
            .firstWhere((state) => state is SyncStatusLoaded) as SyncStatusLoaded);
    expect(loaded.failed, hasLength(1));
    expect(loaded.failed.single.lastError, 'Rejected.');

    // ...and the retry requeues the SAME operation (stable idempotency key)
    // and hands it to the existing sync service.
    syncBloc.add(RetryFailedOperationRequested(failedOperation.operationId));
    final retried = (await syncBloc.stream
            .firstWhere((state) => state is SyncStatusLoaded) as SyncStatusLoaded);
    final operations = (await isar.syncOperations.where().findAll())
        .where((operation) =>
            operation.entityType == SyncEntityType.prescription)
        .toList();
    expect(operations, hasLength(1));
    expect(operations.single.operationId, failedOperation.operationId);
    // The offline client keeps failing transiently, so the operation is back
    // in the PENDING state waiting for the next run.
    expect(operations.single.status, SyncStatus.pending);
    expect(retried.pending.map((operation) => operation.operationId),
        contains(failedOperation.operationId));
    final stored = await isar.prescriptions.get(prescription.id);
    expect(stored!.syncStatus, SyncLocalStatus.pending);
  });
}

/// Every remote call fails as a network error: only the offline/local path can
/// pass, exactly like an APK without internet.
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
  Future<List<Map<String, dynamic>>> searchPasien([String? query]) =>
      _offline();

  @override
  Future<List<Map<String, dynamic>>> getIstoriaByPasien(String pasienId) =>
      _offline();

  @override
  Future<List<Map<String, dynamic>>> getMedications({
    String? query,
    bool includeInactive = false,
  }) =>
      _offline();

  @override
  Future<List<Map<String, dynamic>>> getPrescriptionsByVisit(String visitId) =>
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

/// Sync API stub that accepts patient and visit operations but rejects every
/// prescription with a permanent 4xx failure, which classifySyncFailure maps
/// to FAILED.
class RejectingApiClient extends OfflineApiClient {
  @override
  Future<Map<String, dynamic>> submitSyncOperation({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) {
    if (entityType == SyncEntityType.prescription) {
      throw const ApiException(
        kind: ApiFailureKind.validation,
        statusCode: 400,
        message: 'Rejected.',
      );
    }
    return Future<Map<String, dynamic>>.value(<String, dynamic>{
      'status': SyncStatus.synced,
      'entity_id': entityId,
    });
  }
}
