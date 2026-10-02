import 'dart:io';

import 'package:frontend/core/sync/sync_queue.dart';
import 'package:frontend/core/sync/sync_service.dart';
import 'package:frontend/core/sync/sync_types.dart';
import 'package:frontend/data/local/istoria_schema.dart';
import 'package:frontend/data/local/pasien_schema.dart';
import 'package:frontend/data/local/prescription_schema.dart';
import 'package:frontend/data/local/sync_operation_schema.dart';
import 'package:frontend/data/remote/api_client.dart';
import 'package:frontend/repositories/prescription_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'support/isar_test_support.dart';
import 'support/scripted_http_adapter.dart';

const Uuid _uuid = Uuid();

void main() {
  group('offline prescription queue and synchronization', () {
    late Directory directory;
    late Isar isar;
    late ApiClient apiClient;
    late ScriptedHttpAdapter adapter;

    setUpAll(initializeIsarForTests);

    Future<void> openIsar() async {
      isar = await Isar.open(
        [PasienSchema, IstoriaKlinisSchema, PrescriptionSchema, SyncOperationSchema],
        directory: directory.path,
        name: 'istoria_med',
      );
    }

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('istoria-prescription-');
      adapter = ScriptedHttpAdapter((options) async => jsonResponse(201, const <String, dynamic>{}));
      apiClient = ApiClient(baseUrl: 'http://localhost:3000/api')..dio.httpClientAdapter = adapter;
      await openIsar();
    });

    tearDown(() async {
      if (isar.isOpen) await isar.close(deleteFromDisk: true);
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    Pasien newPatient() {
      return Pasien()
        ..namaLengkap = 'Paciente Foun'
        ..tanggalLahir = DateTime(1990, 1, 1)
        ..tempatLahir = 'Dili'
        ..jenisKelamin = 'Laki-laki'
        ..localStatus = SyncLocalStatus.pending;
    }

    IstoriaKlinis newVisit(String patientId) {
      return IstoriaKlinis()
        ..pasienId = patientId
        ..tenantId = 'klinika-lokal'
        ..keluhanSubjektif = 'Febre manas'
        ..pemeriksaanObjektif = 'temperature 38'
        ..analisisAsesmen = 'Infeksaun'
        ..rencanaTindakan = 'Parasetamol'
        ..kodeIcd10 = 'R50.9'
        ..namaPenyakitLokal = 'Febre'
        ..syncStatus = SyncLocalStatus.pending
        ..tanggalKunjungan = DateTime(2026, 3, 1, 9, 30);
    }

    Prescription newPrescription(String visitId, {String medicationId = '22222222-2222-4222-8222-222222222222'}) {
      return Prescription()
        ..visitId = visitId
        ..notes = 'Synthetic offline prescription'
        ..syncStatus = SyncLocalStatus.pending
        ..items = <PrescriptionItem>[
          PrescriptionItem()
            ..medicationId = medicationId
            ..medicationName = 'Paracetamol'
            ..medicationStrength = '500 mg'
            ..dose = '1 tablet'
            ..frequency = '3x/day'
            ..route = 'ORAL'
            ..duration = '5 days'
            ..quantity = 15
            ..instructions = 'Take after food',
        ];
    }

    SyncService newSyncService({DateTime Function()? clock}) {
      return SyncService(
        isar: isar,
        apiClient: apiClient,
        clock: clock ?? () => DateTime.now(),
        sleeper: (_) async {},
      );
    }

    /// Acknowledges every request the way the NestJS sync API does, echoing the
    /// server owned identity back exactly as the backend does.
    void acknowledgeSuccess() {
      adapter = ScriptedHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        final payload = Map<String, dynamic>.from(operation['payload'] as Map);
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operation['operation_id'],
          'status': SyncStatus.synced,
          'entity_id': operation['entity_id'],
          'entity': <String, dynamic>{
            'visit_id': payload['visit_id'],
            'prescribed_by_staff_id': _uuid.v4(),
            'facility_id': _uuid.v4(),
            'tenant_id': 'tenant-server',
            'item_count': 1,
          },
        });
      });
      apiClient.dio.httpClientAdapter = adapter;
    }

    test('queue creation: offline prescription writes entity and queue in one transaction', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);

      final prescription = newPrescription(visit.remoteId!);
      await SyncQueue.enqueuePrescription(isar, prescription);

      final stored = await isar.prescriptions.where().findAll();
      final operations = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(stored, hasLength(1));
      expect(stored.single.items, hasLength(1));
      expect(operations, hasLength(3));
      expect(operations.last.entityType, SyncEntityType.prescription);
      expect(operations.last.status, SyncStatus.pending);
      expect(operations.last.operationType, SyncOperationType.create);
      expect(operations.last.localEntityId, stored.single.id);
      expect(Uuid.isValidUUID(fromString: operations.last.operationId), isTrue);
      expect(Uuid.isValidUUID(fromString: stored.single.remoteId!), isTrue);
      expect(stored.single.remoteId, operations.last.entityId);
      // Offline: nothing may reach the network.
      expect(adapter.sentOperations, isEmpty);
    });

    test('queue creation: prescription is ordered after the clinical visit it belongs to', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      final visitOperation = (await isar.syncOperations.where().findAll())
          .firstWhere((entry) => entry.entityType == SyncEntityType.clinicalVisit);

      await SyncQueue.enqueuePrescription(isar, newPrescription(visit.remoteId!));

      final operations = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final prescriptionOperation = operations.last;
      expect(prescriptionOperation.entityType, SyncEntityType.prescription);
      expect(prescriptionOperation.dependsOnOperationId, visitOperation.operationId);
    });

    test('payload: never sends client owned identity fields', () async {
      final prescription = newPrescription(_uuid.v4())
        ..facilityId = 'client-facility'
        ..tenantId = 'client-tenant'
        ..prescribedByStaffId = 'client-staff'
        ..remoteId = '33333333-3333-4333-8333-333333333333';

      final payload = prescription.toSyncPayload();

      expect(payload['prescription_id'], '33333333-3333-4333-8333-333333333333');
      expect(payload['visit_id'], prescription.visitId);
      expect(payload.containsKey('facility_id'), isFalse);
      expect(payload.containsKey('tenant_id'), isFalse);
      expect(payload.containsKey('prescribed_by_staff_id'), isFalse);
      expect(payload['items'], hasLength(1));
      final item = (payload['items'] as List).single as Map<String, dynamic>;
      expect(item['medication_id'], '22222222-2222-4222-8222-222222222222');
      expect(item['quantity'], 15);
      expect(item.containsKey('medication_name'), isFalse);
      expect(item.containsKey('prescription_item_id'), isFalse);
    });

    test('payload: omits optional item fields instead of sending empty strings', () async {
      final prescription = newPrescription(_uuid.v4());
      prescription.items = <PrescriptionItem>[
        PrescriptionItem()
          ..medicationId = _uuid.v4()
          ..dose = '1 tablet'
          ..frequency = '3x/day'
          ..quantity = 5,
      ];

      final item = (prescription.toSyncPayload()['items'] as List).single as Map<String, dynamic>;

      expect(item.containsKey('route'), isFalse);
      expect(item.containsKey('duration'), isFalse);
      expect(item.containsKey('instructions'), isFalse);
    });

    test('successful sync: prescription reaches SYNCED and adopts the server identity', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      final prescription = newPrescription(visit.remoteId!);
      await SyncQueue.enqueuePrescription(isar, prescription);
      acknowledgeSuccess();

      final report = await newSyncService().syncPending();

      // patient, visit and prescription are drained by the same single queue.
      expect(report.synced, 3);
      expect(report.failed, 0);
      final stored = await isar.prescriptions.get(prescription.id);
      expect(stored!.syncStatus, SyncLocalStatus.synced);
      // The reserved identifier was adopted, never remapped.
      expect(stored.remoteId, prescription.remoteId);
      // Ownership now comes from the server, not from the device.
      expect(stored.tenantId, 'tenant-server');
      expect(stored.prescribedByStaffId, isNotNull);
      expect(stored.facilityId, isNotNull);
      final operation = (await isar.syncOperations.where().findAll())
          .firstWhere((entry) => entry.entityType == SyncEntityType.prescription);
      expect(operation.status, SyncStatus.synced);
      expect(operation.retryCount, 1);
      expect(operation.syncedAt, isNotNull);
    });

    test('dependency: a prescription never overtakes an unsynchronized visit', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      await SyncQueue.enqueuePrescription(isar, newPrescription(visit.remoteId!));

      // The visit permanently fails, so the prescription must not be sent and
      // must never become an orphan.
      adapter = ScriptedHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        if (operation['entity_type'] == SyncEntityType.clinicalVisit) {
          return jsonResponse(201, <String, dynamic>{
            'operation_id': operation['operation_id'],
            'status': SyncStatus.failed,
            'entity_id': operation['entity_id'],
            'message': 'Rejected.',
          });
        }
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operation['operation_id'],
          'status': SyncStatus.synced,
          'entity_id': operation['entity_id'],
        });
      });
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      final operations = await isar.syncOperations.where().findAll();
      final prescriptionOperation =
          operations.firstWhere((entry) => entry.entityType == SyncEntityType.prescription);
      expect(prescriptionOperation.status, SyncStatus.pending);
      final sentTypes =
          adapter.sentOperations.map((operation) => operation['entity_type'] as String).toList();
      expect(sentTypes, isNot(contains(SyncEntityType.prescription)));
    });

    test('idempotency: a retry reuses the same operation and entity identifiers', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      // Drain the dependency chain first so the prescription is not held back.
      acknowledgeSuccess();
      await newSyncService().syncPending();

      final prescription = newPrescription(visit.remoteId!);
      await SyncQueue.enqueuePrescription(isar, prescription);

      // The first attempt fails transiently.
      var now = DateTime(2026, 3, 1, 8);
      adapter = ScriptedHttpAdapter((options) async => throw networkFailure());
      apiClient.dio.httpClientAdapter = adapter;
      await newSyncService(clock: () => now).syncPending();

      final firstAttempt = (await isar.syncOperations.where().findAll())
          .firstWhere((entry) => entry.entityType == SyncEntityType.prescription);
      expect(firstAttempt.retryCount, 1);
      expect(firstAttempt.status, SyncStatus.pending);
      expect(firstAttempt.nextAttemptAt, isNotNull);

      // The backoff window must actually hold the operation back.
      acknowledgeSuccess();
      final held = await newSyncService(clock: () => now).syncPending();
      expect(held.skipped, 1);
      expect(held.attempted, 0);

      // After the backoff window the retry must present the very same
      // idempotency key and entity id, so the server can never create a second
      // prescription.
      now = now.add(const Duration(minutes: 5));
      await newSyncService(clock: () => now).syncPending();

      final secondAttempt = (await isar.syncOperations.where().findAll())
          .firstWhere((entry) => entry.entityType == SyncEntityType.prescription);
      expect(secondAttempt.operationId, firstAttempt.operationId);
      expect(secondAttempt.entityId, firstAttempt.entityId);
      expect(secondAttempt.entityId, prescription.remoteId);
      expect(secondAttempt.retryCount, 2);
      expect(secondAttempt.status, SyncStatus.synced);
      expect(await isar.prescriptions.where().findAll(), hasLength(1));
    });

    test('permanent rejection marks the local prescription FAILED', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      acknowledgeSuccess();
      await newSyncService().syncPending();

      final prescription = newPrescription(visit.remoteId!);
      await SyncQueue.enqueuePrescription(isar, prescription);
      adapter = ScriptedHttpAdapter((options) async => throw httpFailure(400));
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      expect((await isar.prescriptions.get(prescription.id))!.syncStatus, SyncLocalStatus.failed);
    });

    test('restart: the queued prescription survives closing and reopening Isar', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      await SyncQueue.enqueuePrescription(isar, newPrescription(visit.remoteId!));
      final before = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      await isar.close();
      await openIsar();

      final after = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(after.map((entry) => entry.operationId).toList(),
          before.map((entry) => entry.operationId).toList());
      expect(await isar.prescriptions.where().findAll(), hasLength(1));
    });
  });

  group('prescription repository', () {
    late Directory directory;
    late Isar isar;
    late ApiClient apiClient;
    late ScriptedHttpAdapter adapter;

    setUpAll(initializeIsarForTests);

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('istoria-prescription-repo-');
      adapter = ScriptedHttpAdapter((options) async => jsonListResponse(200, const <dynamic>[]));
      apiClient = ApiClient(baseUrl: 'http://localhost:3000/api')..dio.httpClientAdapter = adapter;
      isar = await Isar.open(
        [PasienSchema, IstoriaKlinisSchema, PrescriptionSchema, SyncOperationSchema],
        directory: directory.path,
        name: 'istoria_med',
      );
    });

    tearDown(() async {
      if (isar.isOpen) await isar.close(deleteFromDisk: true);
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    test('medications: reads the server owned catalog and caches it', () async {
      adapter = ScriptedHttpAdapter((options) async => jsonListResponse(200, <dynamic>[
            <String, dynamic>{
              'medication_id': '22222222-2222-4222-8222-222222222222',
              'name': 'Paracetamol',
              'generic_name': 'Paracetamol',
              'form': 'TABLET',
              'strength': '500 mg',
              'unit': 'TABLET',
              'is_active': true,
            },
          ]));
      apiClient.dio.httpClientAdapter = adapter;
      final repository = PrescriptionRepository(isar: isar, apiClient: apiClient);

      final first = await repository.medications();
      final second = await repository.medications();

      expect(first, hasLength(1));
      expect(first.single.name, 'Paracetamol');
      expect(first.single.label, 'Paracetamol - 500 mg - TABLET');
      // The second read is served from the session cache.
      expect(second.single.medicationId, first.single.medicationId);
    });

    test('forVisit: falls back to the local prescription when the device is offline', () async {
      adapter = ScriptedHttpAdapter((options) async => throw networkFailure());
      apiClient.dio.httpClientAdapter = adapter;
      final repository = PrescriptionRepository(isar: isar, apiClient: apiClient);

      final visitId = _uuid.v4();
      final local = Prescription()
        ..visitId = visitId
        ..syncStatus = SyncLocalStatus.pending
        ..items = <PrescriptionItem>[];
      await SyncQueue.enqueuePrescription(isar, local);

      final result = await repository.forVisit(visitId);

      expect(result, hasLength(1));
      expect(result.single.remoteId, local.remoteId);
    });
  });
}