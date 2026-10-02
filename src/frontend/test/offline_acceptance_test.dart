import 'dart:convert';
import 'dart:io';

import 'package:frontend/core/sync/sync_queue.dart';
import 'package:frontend/core/sync/sync_service.dart';
import 'package:frontend/core/sync/sync_types.dart';
import 'package:frontend/data/local/istoria_schema.dart';
import 'package:frontend/data/local/pasien_schema.dart';
import 'package:frontend/data/local/prescription_schema.dart';
import 'package:frontend/data/local/sync_operation_schema.dart';
import 'package:frontend/data/remote/api_client.dart';
import 'package:frontend/repositories/istoria_repository.dart';
import 'package:frontend/repositories/pasien_repository.dart';
import 'package:frontend/repositories/prescription_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'support/isar_test_support.dart';

/// End to end acceptance of the offline acceptance scenario against a real
/// NestJS backend and a real PostgreSQL database.
///
///   NETWORK OFF -> create patient -> create clinical visit -> create
///   prescription -> queue persisted -> close/reopen the database -> queue
///   still there -> NETWORK ON -> syncPending() -> all SYNCED -> replay ->
///   still exactly one patient, one visit and one prescription
///
/// Phase 7 extends the Phase 6 acceptance with a prescription, which reuses the
/// same queue and must be synchronized after the clinical visit it belongs to.
/// The medication catalog is server owned, so it is read while online and only
/// its identifier travels inside the queued prescription.
/// The test is skipped (never silently passed) when the environment does not
/// point at a running backend. Run it with:
///
///   ISTORIA_SYNC_E2E_BASE_URL=http://127.0.0.1:3000/api
///   ISTORIA_SYNC_E2E_LOGIN=user@example.com
///   ISTORIA_SYNC_E2E_PASSWORD=some-password
///   flutter test test/offline_acceptance_test.dart
const _baseUrl = String.fromEnvironment('ISTORIA_SYNC_E2E_BASE_URL', defaultValue: '');
const _login = String.fromEnvironment('ISTORIA_SYNC_E2E_LOGIN', defaultValue: '');
const _password = String.fromEnvironment('ISTORIA_SYNC_E2E_PASSWORD', defaultValue: '');

/// Read from the process environment so `flutter test` needs no dart-define.
String get _envBaseUrl =>
    _baseUrl.isNotEmpty ? _baseUrl : Platform.environment['ISTORIA_SYNC_E2E_BASE_URL'] ?? '';
String get _envLogin => _login.isNotEmpty ? _login : Platform.environment['ISTORIA_SYNC_E2E_LOGIN'] ?? '';
String get _envPassword =>
    _password.isNotEmpty ? _password : Platform.environment['ISTORIA_SYNC_E2E_PASSWORD'] ?? '';

void main() {
  final configured = _envBaseUrl.isNotEmpty && _envLogin.isNotEmpty && _envPassword.isNotEmpty;

  test('offline acceptance: queue survives a restart and never duplicates a record', () async {
    if (!configured) {
      markTestSkipped(
        'Cross stack acceptance needs a running backend. Set ISTORIA_SYNC_E2E_BASE_URL, '
        'ISTORIA_SYNC_E2E_LOGIN and ISTORIA_SYNC_E2E_PASSWORD.',
      );
      return;
    }

    await initializeIsarForTests();

    // A closed local port produces a genuine transport failure through real Dio.
    const offlineBaseUrl = 'http://127.0.0.1:9/api';
    final onlineClient = ApiClient(baseUrl: _envBaseUrl);
    await onlineClient.login(loginIdentifier: _envLogin, password: _envPassword).then(
      (response) => onlineClient.setAccessToken(response['access_token'] as String),
    );
    final offlineClient = ApiClient(baseUrl: offlineBaseUrl);

    // The medication catalog is server owned reference data and is never queued,
    // so it is read once while the device is still online.
    final catalog = (await onlineClient.getMedications()).where((entry) => entry['is_active'] == true).toList();
    expect(catalog, isNotEmpty,
        reason: 'the disposable PostgreSQL database needs at least one synthetic active medication');
    final medicationId = catalog.first['medication_id'] as String;
    final medicationName = catalog.first['name'] as String;

    final directory = await Directory.systemTemp.createTemp('istoria-acceptance-');
    var isar = await _openIsar(directory);
    final suffix = DateTime.now().microsecondsSinceEpoch;

    // A controllable clock keeps the backoff windows deterministic instead of
    // sleeping through them in real time.
    var clock = DateTime.now();
    SyncClock getClock() => () => clock;

    // ---- NETWORK OFF: create patient and clinical visit -------------------
    final offlineRepository = PasienRepository(isar: isar, apiClient: offlineClient);
    final offlineSync = SyncService(
      isar: isar,
      apiClient: offlineClient,
      clock: getClock(),
      sleeper: (_) async {},
    );

    final patient = await offlineRepository.register(
      Pasien()
        ..noKtp = 'ACC-$suffix'
        ..namaLengkap = 'Paciente Aceitasaun $suffix'
        ..tanggalLahir = DateTime(1988, 4, 12)
        ..tempatLahir = 'Dili'
        ..jenisKelamin = 'Perempuan'
        ..localStatus = SyncLocalStatus.pending,
    );
    expect((await isar.pasiens.get(patient.id))!.localStatus, SyncLocalStatus.pending);

    final istoriaRepository = IstoriaRepository(isar: isar, apiClient: offlineClient);
    final visit = await istoriaRepository.create(
      IstoriaKlinis()
        ..pasienId = patient.remoteId!
        ..tenantId = 'klinika-lokal'
        ..keluhanSubjektif = 'Febre no kabuk manas'
        ..pemeriksaanObjektif = 'Temperatura 38.5, tenkeun normal'
        ..analisisAsesmen = 'Infeksaun respiratoriu superior'
        ..rencanaTindakan = 'Parasetamol 500mg, dranku beis todan'
        ..kodeIcd10 = 'J06.9'
        ..namaPenyakitLokal = 'Infeksaun saude与众不同'
        ..tanggalKunjungan = DateTime(2026, 3, 1, 8, 15)
        ..syncStatus = SyncLocalStatus.pending,
    );
    expect((await isar.istoriaKlinis.get(visit.id))!.syncStatus, SyncLocalStatus.pending);

    final prescriptionRepository = PrescriptionRepository(isar: isar, apiClient: offlineClient);
    final prescription = await prescriptionRepository.create(
      Prescription()
        ..visitId = visit.remoteId!
        ..notes = 'Resep sintetis aceitasaun'
        ..syncStatus = SyncLocalStatus.pending
        ..items = <PrescriptionItem>[
          PrescriptionItem()
            ..medicationId = medicationId
            ..medicationName = medicationName
            ..medicationStrength = catalog.first['strength'] as String?
            ..dose = '1 tablet'
            ..frequency = '3x/day'
            ..route = 'ORAL'
            ..duration = '5 days'
            ..quantity = 15
            ..instructions = 'Toma depois de haan',
        ],
    );
    expect((await isar.prescriptions.get(prescription.id))!.syncStatus, SyncLocalStatus.pending);

    var queue = await SyncQueue.loadPending(isar);
    expect(queue, hasLength(3), reason: 'queue must hold all three offline operations');
    expect(
      queue.map((operation) => operation.entityType).toList(),
      [SyncEntityType.patient, SyncEntityType.clinicalVisit, SyncEntityType.prescription],
    );
    expect(queue.every((operation) => operation.status == SyncStatus.pending), isTrue);
    final patientOperation = queue.first;
    final visitOperation = queue[1];
    final prescriptionOperation = queue.last;
    expect(visitOperation.dependsOnOperationId, patientOperation.operationId);
    expect(prescriptionOperation.dependsOnOperationId, visitOperation.operationId,
        reason: 'a prescription must wait for the clinical visit it belongs to');

    // ---- OFFLINE SYNC ATTEMPT: nothing may be lost or sent ---------------
    final offlineReport = await offlineSync.syncPending();
    expect(offlineReport.pending, 1, reason: 'the patient op fails with a real network error');
    expect(offlineReport.skipped, 2, reason: 'the visit and the prescription must wait for the patient');
    expect(offlineReport.synced, 0);
    expect(offlineReport.failed, 0);
    queue = await SyncQueue.loadPending(isar);
    expect(queue, hasLength(3), reason: 'every operation stays queued for the next run');
    expect(queue.every((operation) => operation.status == SyncStatus.pending), isTrue);
    expect(
      queue.firstWhere((operation) => operation.entityType == SyncEntityType.patient).retryCount,
      1,
    );
    for (final held in [SyncEntityType.clinicalVisit, SyncEntityType.prescription]) {
      expect(
        queue.firstWhere((operation) => operation.entityType == held).retryCount,
        0,
        reason: 'the $held was never sent while its dependency was unsynced',
      );
    }

    // ---- CLOSE / RESTART the application database -----------------------
    await isar.close();
    isar = await _openIsar(directory);

    final reloaded = (await isar.syncOperations.where().findAll())
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    expect(reloaded.map((operation) => operation.operationId).toList(), [
      patientOperation.operationId,
      visitOperation.operationId,
      prescriptionOperation.operationId,
    ]);
    expect(reloaded.every((operation) => operation.status == SyncStatus.pending), isTrue);
    expect(await isar.pasiens.where().findAll(), hasLength(1));
    expect(await isar.istoriaKlinis.where().findAll(), hasLength(1));
    expect(await isar.prescriptions.where().findAll(), hasLength(1));

    // ---- NETWORK ON: the retry backoff also survives the restart ---------
    final onlineSync = SyncService(
      isar: isar,
      apiClient: onlineClient,
      clock: getClock(),
      sleeper: (_) async {},
    );
    final tooEarly = await onlineSync.syncPending();
    expect(tooEarly.skipped, 3, reason: 'the persisted backoff window is still active');
    expect(tooEarly.synced, 0);

    // Real time passes while the app waits, then the queue is drained.
    clock = clock.add(const Duration(seconds: 5));
    final onlineReport = await onlineSync.syncPending();

    expect(onlineReport.synced, 3, reason: onlineReport.toString());
    expect(onlineReport.failed, 0);
    expect(onlineReport.pending, 0);

    final syncedQueue = (await isar.syncOperations.where().findAll())
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    expect(syncedQueue.every((operation) => operation.status == SyncStatus.synced), isTrue);
    expect((await isar.pasiens.get(patient.id))!.localStatus, SyncLocalStatus.synced);
    expect((await isar.istoriaKlinis.get(visit.id))!.syncStatus, SyncLocalStatus.synced);
    final syncedPrescription = (await isar.prescriptions.get(prescription.id))!;
    expect(syncedPrescription.syncStatus, SyncLocalStatus.synced);
    // The server adopted the identifier the device reserved.
    expect(syncedPrescription.remoteId, prescription.remoteId);
    // Ownership was derived by the server, never by the device.
    expect(syncedPrescription.prescribedByStaffId, isNotNull);
    expect(syncedPrescription.facilityId, isNotNull);
    expect(syncedPrescription.tenantId, isNotNull);

    // ---- Server side: exactly one patient and one clinical visit ---------
    final patients = await onlineClient.searchPasien('ACC-$suffix');
    expect(patients, hasLength(1), reason: 'PostgreSQL must hold exactly one patient');
    final history = await onlineClient.getIstoriaByPasien(patient.remoteId!);
    expect(history, hasLength(1), reason: 'PostgreSQL must hold exactly one clinical visit');
    expect(history.single['kunjungan_id'], visit.remoteId);
    expect(history.single['pasien_id'], patient.remoteId);

    final prescriptions = await onlineClient.getPrescriptionsByVisit(visit.remoteId!);
    expect(prescriptions, hasLength(1), reason: 'PostgreSQL must hold exactly one prescription');
    final stored = prescriptions.single;
    expect(stored['prescription_id'], prescription.remoteId);
    expect(stored['visit_id'], visit.remoteId);
    expect(stored['prescribed_by_staff_id'], isNotNull);
    expect(stored['facility_id'], isNotNull);
    expect(stored['tenant_id'], isNotNull);
    final storedItems = (stored['items'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    expect(storedItems, hasLength(1));
    expect(storedItems.single['medication_id'], medicationId);
    expect(storedItems.single['quantity'], 15);
    // The prescription belongs to the same tenant as the visit.
    expect(stored['tenant_id'], history.single['tenant_id']);

    // ---- REPLAY the same operation ids: the server must stay idempotent --
    for (final operation in syncedQueue) {
      operation.status = SyncStatus.pending;
      operation.nextAttemptAt = null;
      await isar.writeTxn(() => isar.syncOperations.put(operation));
    }
    final replayReport = await onlineSync.syncPending();
    expect(replayReport.synced, 3);
    expect(
      (await isar.syncOperations.where().findAll()).every((operation) => operation.status == SyncStatus.synced),
      isTrue,
    );
    expect(await onlineClient.getIstoriaByPasien(patient.remoteId!), hasLength(1));
    expect(await onlineClient.getPrescriptionsByVisit(visit.remoteId!), hasLength(1),
        reason: 'replaying the queue must never duplicate a prescription');
    expect(await onlineClient.searchPasien('ACC-$suffix'), hasLength(1));
    expect(await isar.pasiens.where().findAll(), hasLength(1));
    expect(await isar.istoriaKlinis.where().findAll(), hasLength(1));
    expect(await isar.prescriptions.where().findAll(), hasLength(1));

    // Identifiers for the PostgreSQL level verification step.
    final evidence = File('build/acceptance-evidence.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'patient_id': patient.remoteId,
          'visit_id': visit.remoteId,
          'patient_operation_id': patientOperation.operationId,
          'visit_operation_id': visitOperation.operationId,
          'prescription_id': prescription.remoteId,
          'prescription_operation_id': prescriptionOperation.operationId,
          'medication_id': medicationId,
          'no_ktp': 'ACC-$suffix',
        }),
      );
    // ignore: avoid_print
    print('ACCEPTANCE_EVIDENCE=${evidence.path}');
    // ignore: avoid_print
    print('ACCEPTANCE_PATIENT_ID=${patient.remoteId}');
    // ignore: avoid_print
    print('ACCEPTANCE_VISIT_ID=${visit.remoteId}');
    // ignore: avoid_print
    print('ACCEPTANCE_PRESCRIPTION_ID=${prescription.remoteId}');

    await isar.close(deleteFromDisk: true);
    directory.deleteSync(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<Isar> _openIsar(Directory directory) {
  return Isar.open(
    [PasienSchema, IstoriaKlinisSchema, PrescriptionSchema, SyncOperationSchema],
    directory: directory.path,
    name: 'istoria_med',
  );
}
