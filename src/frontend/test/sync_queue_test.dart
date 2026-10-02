import 'dart:io';

import 'package:frontend/core/sync/sync_queue.dart';
import 'package:frontend/core/sync/sync_service.dart';
import 'package:frontend/core/sync/sync_types.dart';
import 'package:frontend/data/local/istoria_schema.dart';
import 'package:frontend/data/local/pasien_schema.dart';
import 'package:frontend/data/local/sync_operation_schema.dart';
import 'package:frontend/data/remote/api_client.dart';
import 'package:frontend/data/remote/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import 'support/isar_test_support.dart';
import 'support/scripted_http_adapter.dart';

const Uuid _uuid = Uuid();

void main() {
  group('offline queue and synchronization', () {
    late Directory directory;
    late Isar isar;
    late ApiClient apiClient;
    late ScriptedHttpAdapter adapter;

    setUpAll(initializeIsarForTests);

    Future<void> openIsar() async {
      isar = await Isar.open(
        [PasienSchema, IstoriaKlinisSchema, SyncOperationSchema],
        directory: directory.path,
        name: 'istoria_med',
      );
    }

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('istoria-sync-');
      adapter = ScriptedHttpAdapter((options) async => jsonResponse(201, const <String, dynamic>{}));
      apiClient = ApiClient(baseUrl: 'http://localhost:3000/api')..dio.httpClientAdapter = adapter;
      await openIsar();
    });

    tearDown(() async {
      if (isar.isOpen) await isar.close(deleteFromDisk: true);
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    Pasien newPatient({String name = 'Paciente Foun', String? ktp}) {
      return Pasien()
        ..namaLengkap = name
        ..tanggalLahir = DateTime(1990, 1, 1)
        ..tempatLahir = 'Dili'
        ..jenisKelamin = 'Laki-laki'
        ..noKtp = ktp
        ..localStatus = SyncLocalStatus.pending;
    }

    IstoriaKlinis newVisit(String patientId) {
      return IstoriaKlinis()
        ..pasienId = patientId
        ..tenantId = 'klinika-lokal'
        ..keluhanSubjektif = 'Febre manas'
        ..pemeriksaanObjektif = ' temperature 38'
        ..analisisAsesmen = 'Infeksaun'
        ..rencanaTindakan = 'Parasetamol'
        ..kodeIcd10 = 'R50.9'
        ..namaPenyakitLokal = 'Febre'
        ..syncStatus = SyncLocalStatus.pending
        ..tanggalKunjungan = DateTime(2026, 3, 1, 9, 30);
    }

    SyncService newSyncService({DateTime Function()? clock}) {
      return SyncService(
        isar: isar,
        apiClient: apiClient,
        clock: clock ?? () => DateTime.now(),
        sleeper: (_) async {},
      );
    }

    /// Acknowledges every request the way the NestJS sync API does.
    void acknowledgeSuccess() {
      adapter = ScriptedHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operation['operation_id'],
          'status': SyncStatus.synced,
          'entity_id': operation['entity_id'],
          'entity': <String, dynamic>{
            'medical_record_number': 'MRN-server-1',
            'facility_id': _uuid.v4(),
            'tenant_id': 'tenant-server',
            'staf_id': _uuid.v4(),
          },
        });
      });
      apiClient.dio.httpClientAdapter = adapter;
    }

    test('queue creation: offline create writes entity and queue in one transaction', () async {
      final patient = newPatient(ktp: '0001');

      await SyncQueue.enqueuePatient(isar, patient);

      final patients = await isar.pasiens.where().findAll();
      final operations = await isar.syncOperations.where().findAll();
      expect(patients, hasLength(1));
      expect(operations, hasLength(1));
      expect(operations.single.status, SyncStatus.pending);
      expect(operations.single.entityType, SyncEntityType.patient);
      expect(operations.single.operationType, SyncOperationType.create);
      expect(operations.single.retryCount, 0);
      expect(operations.single.localEntityId, patients.single.id);
      expect(operations.single.entityId, patients.single.remoteId);
      expect(Uuid.isValidUUID(fromString: operations.single.operationId), isTrue);
      expect(patients.single.localStatus, SyncLocalStatus.pending);
      // Offline: nothing may reach the network.
      expect(adapter.sentOperations, isEmpty);
    });

    test('queue creation: offline clinical visit is queued and linked to its patient', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final patientOperation = (await isar.syncOperations.where().findAll()).single;

      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);

      final operations = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(operations, hasLength(2));
      expect(operations.last.entityType, SyncEntityType.clinicalVisit);
      expect(operations.last.status, SyncStatus.pending);
      expect(operations.last.dependsOnOperationId, patientOperation.operationId);
      expect(await isar.istoriaKlinis.where().findAll(), hasLength(1));
    });

    test('restart: the queue survives closing and reopening the real Isar database', () async {
      await SyncQueue.enqueuePatient(isar, newPatient(name: 'Antes do reinicio'));
      final patient = newPatient(name: 'Depois do reinicio');
      await SyncQueue.enqueuePatient(isar, patient);
      await SyncQueue.enqueueClinicalVisit(isar, newVisit(patient.remoteId!));
      final before = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final beforeIds = before.map((operation) => operation.operationId).toList();

      await isar.close();
      await openIsar();

      final after = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(after.map((operation) => operation.operationId).toList(), beforeIds);
      expect(after.every((operation) => operation.status == SyncStatus.pending), isTrue);
      expect(await isar.pasiens.where().findAll(), hasLength(2));
      expect(await isar.istoriaKlinis.where().findAll(), hasLength(1));

      // The reopened queue is still drainable through the single pathway.
      acknowledgeSuccess();
      final report = await newSyncService().syncPending();
      expect(report.synced, 3);
      expect(after, hasLength(3));
    });

    test('successful sync: PENDING -> SYNCING -> SYNCED', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      acknowledgeSuccess();

      final report = await newSyncService().syncPending();

      expect(report.attempted, 1);
      expect(report.synced, 1);
      final operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.synced);
      expect(operation.retryCount, 1);
      expect(operation.lastError, isNull);
      expect(operation.syncedAt, isNotNull);
      expect(operation.nextAttemptAt, isNull);
      final stored = await isar.pasiens.get(patient.id);
      expect(stored!.localStatus, SyncLocalStatus.synced);
      expect(stored.medicalRecordNumber, 'MRN-server-1');
      // The server adopted the client reserved identifier: no mapping needed.
      expect(stored.remoteId, operation.entityId);
    });

    test('transient error: network failure returns the operation to PENDING with backoff', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => throw networkFailure());
      apiClient.dio.httpClientAdapter = adapter;
      var now = DateTime(2026, 3, 1, 8);

      final report = await newSyncService(clock: () => now).syncPending();

      expect(report.pending, 1);
      expect(report.synced, 0);
      var operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.pending);
      expect(operation.retryCount, 1);
      expect(operation.lastError, isNotNull);
      expect(operation.nextAttemptAt, now.add(const Duration(seconds: 2)));
      expect((await isar.pasiens.where().findAll()).single.localStatus, SyncLocalStatus.pending);

      // Second attempt with the network still down: same operation id, count 2.
      await newSyncService(clock: () => now.add(const Duration(seconds: 3))).syncPending();
      operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.retryCount, 2);
      expect(operation.status, SyncStatus.pending);
      expect(operation.nextAttemptAt, now.add(const Duration(seconds: 3)).add(const Duration(seconds: 4)));
      expect(
        adapter.sentOperationIds,
        [adapter.sentOperationIds.first, adapter.sentOperationIds.first],
        reason: 'retry must reuse the very same operation_id',
      );

      // Backoff window: the run is skipped instead of hammering the API.
      final skipped = await newSyncService(clock: () => now.add(const Duration(seconds: 4))).syncPending();
      expect(skipped.skipped, 1);
      expect(adapter.sentOperationIds, hasLength(2));
    });

    test('permanent error: 400 marks the operation FAILED and stops retrying', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => throw httpFailure(400, message: 'nama_lengkap must not be blank'));
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      final operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.failed);
      expect(operation.retryCount, 1);
      expect(operation.lastError, contains('nama_lengkap'));
      expect(operation.nextAttemptAt, isNull);
      expect((await isar.pasiens.where().findAll()).single.localStatus, SyncLocalStatus.failed);

      final second = await newSyncService().syncPending();
      expect(second.attempted, 0);
      expect(adapter.sentOperationIds, hasLength(1), reason: 'a permanent failure must not retry');
    });

    test('permanent error: a 403 facility rejection also fails permanently', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => throw httpFailure(403, message: 'Patient outside the authorized facility.'));
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      expect((await isar.syncOperations.where().findAll()).single.status, SyncStatus.failed);
    });

    test('auth error: 401 keeps the operation queued with backoff instead of dropping it', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => throw httpFailure(401));
      apiClient.dio.httpClientAdapter = adapter;
      var now = DateTime(2026, 3, 1, 8);

      final report = await newSyncService(clock: () => now).syncPending();

      expect(report.pending, 1);
      final operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.pending);
      expect(operation.nextAttemptAt, now.add(const Duration(seconds: 2)));
    });

    test('duplicate ACK: an idempotent server response resolves the operation as SYNCED', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final operationId = (await isar.syncOperations.where().findAll()).single.operationId;
      var calls = 0;
      adapter = ScriptedHttpAdapter((options) async {
        calls += 1;
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operationId,
          'status': SyncStatus.synced,
          'entity_id': patient.remoteId,
          'message': calls > 1 ? 'already processed' : null,
        });
      });
      apiClient.dio.httpClientAdapter = adapter;

      // The first attempt reaches the server but the response is lost.
      await newSyncService().syncPending();
      var operation = (await isar.syncOperations.where().findAll()).single;
      operation.status = SyncStatus.pending;
      operation.nextAttemptAt = null;
      await isar.writeTxn(() => isar.syncOperations.put(operation));

      final report = await newSyncService().syncPending();

      expect(report.synced, 1);
      expect(calls, 2);
      expect(adapter.sentOperationIds, [operationId, operationId]);
      operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.synced);
      expect(await isar.pasiens.where().findAll(), hasLength(1), reason: 'no duplicate local record');
    });

    test('duplicate ACK: a server FAILED body for a known operation is treated as permanent', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => jsonResponse(201, const <String, dynamic>{
            'status': SyncStatus.failed,
            'message': 'Patient outside the authorized facility.',
          }));
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      final operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.failed);
      expect(operation.lastError, contains('facility'));
    });

    test('dependency: the clinical visit waits for the patient, in queue order', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      final sent = <String>[];
      adapter = ScriptedHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        sent.add(operation['entity_type'] as String);
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operation['operation_id'],
          'status': SyncStatus.synced,
          'entity_id': operation['entity_id'],
        });
      });
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.synced, 2);
      expect(sent, [SyncEntityType.patient, SyncEntityType.clinicalVisit],
          reason: 'oldest first, patient before its visit');
      final operations = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(operations.every((operation) => operation.status == SyncStatus.synced), isTrue);
      expect((await isar.istoriaKlinis.get(visit.id))!.syncStatus, SyncLocalStatus.synced);
    });

    test('dependency: a FAILED patient leaves the clinical visit PENDING (no orphan visit)', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      final visit = newVisit(patient.remoteId!);
      await SyncQueue.enqueueClinicalVisit(isar, visit);
      adapter = ScriptedHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        if (operation['entity_type'] == SyncEntityType.patient) {
          return jsonResponse(201, const <String, dynamic>{
            'status': SyncStatus.failed,
            'message': 'nama_lengkap must not be blank',
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
      expect(report.skipped, 1);
      final operations = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(operations.first.status, SyncStatus.failed);
      expect(operations.last.status, SyncStatus.pending);
      expect(operations.last.retryCount, 0);
      expect((await isar.istoriaKlinis.get(visit.id))!.syncStatus, SyncLocalStatus.pending);
      expect(adapter.sentOperationIds, hasLength(1), reason: 'the visit must not be sent first');
    });

    test('restart: an interrupted SYNCING operation is recovered to PENDING', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      var operation = (await isar.syncOperations.where().findAll()).single;
      operation.status = SyncStatus.syncing;
      operation.retryCount = 1;
      await isar.writeTxn(() => isar.syncOperations.put(operation));

      await isar.close();
      await openIsar();

      acknowledgeSuccess();
      final report = await newSyncService().syncPending();

      expect(report.synced, 1);
      operation = (await isar.syncOperations.where().findAll()).single;
      expect(operation.status, SyncStatus.synced);
      expect(operation.retryCount, 2, reason: 'retry count is historical metadata and never reset');
    });

    test('queue order: operations are processed oldest first, never in parallel', () async {
      final patients = <Pasien>[];
      for (var index = 0; index < 4; index += 1) {
        final patient = newPatient(name: 'Paciente $index');
        patients.add(patient);
        await SyncQueue.enqueuePatient(isar, patient, now: DateTime(2026, 3, 1, 8, 0, index));
      }
      final sent = <String>[];
      var concurrent = 0;
      var maxConcurrent = 0;
      adapter = ScriptedHttpAdapter((options) async {
        concurrent += 1;
        maxConcurrent = concurrent > maxConcurrent ? concurrent : maxConcurrent;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final body = Map<String, dynamic>.from(options.data as Map);
        final operation = Map<String, dynamic>.from(body['operation'] as Map);
        sent.add(operation['operation_id'] as String);
        concurrent -= 1;
        return jsonResponse(201, <String, dynamic>{
          'operation_id': operation['operation_id'],
          'status': SyncStatus.synced,
          'entity_id': operation['entity_id'],
        });
      });
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.synced, 4);
      expect(maxConcurrent, 1, reason: 'the queue is processed sequentially');
      final expected = (await isar.syncOperations.where().findAll())
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      expect(sent, expected.map((operation) => operation.operationId).toList());
    });

    test('concurrent syncPending calls join one run instead of double sending', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      acknowledgeSuccess();

      final service = newSyncService();
      final reports = await Future.wait([service.syncPending(), service.syncPending()]);

      expect(reports.first.synced, 1);
      expect(adapter.sentOperationIds, hasLength(1));
    });

    test('a missing local record fails permanently instead of looping forever', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      await isar.writeTxn(() => isar.pasiens.delete(patient.id));
      acknowledgeSuccess();

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      expect((await isar.syncOperations.where().findAll()).single.status, SyncStatus.failed);
      expect(adapter.sentOperations, isEmpty);
    });

    test('the payload never carries server owned fields', () async {
      final patient = newPatient();
      await SyncQueue.enqueuePatient(isar, patient);
      await SyncQueue.enqueueClinicalVisit(isar, newVisit(patient.remoteId!));
      acknowledgeSuccess();

      await newSyncService().syncPending();

      expect(adapter.sentOperations, hasLength(2));
      for (final operation in adapter.sentOperations) {
        final payload = Map<String, dynamic>.from(operation['payload'] as Map);
        for (final protected in ['facility_id', 'tenant_id', 'staf_id', 'staff_id', 'user_id', 'membership_id']) {
          expect(payload.containsKey(protected), isFalse, reason: '$protected must be server derived');
        }
      }
      final visitPayload = adapter.sentOperations.last['payload'] as Map;
      expect(visitPayload['pasien_id'], patient.remoteId);
      expect(visitPayload['kunjungan_id'], isNotNull);
    });

    test('an unknown server status is a permanent failure, never an error swallow', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => jsonResponse(201, const <String, dynamic>{
            'status': 'PENDING',
            'message': 'Operation is already being processed.',
          }));
      apiClient.dio.httpClientAdapter = adapter;

      final report = await newSyncService().syncPending();

      expect(report.failed, 1);
      expect((await isar.syncOperations.where().findAll()).single.lastError, contains('already being processed'));
    });

    test('timeUntilNextAttempt reports the shortest remaining backoff window', () async {
      await SyncQueue.enqueuePatient(isar, newPatient());
      adapter = ScriptedHttpAdapter((options) async => throw networkFailure());
      apiClient.dio.httpClientAdapter = adapter;
      final now = DateTime(2026, 3, 1, 8);
      final service = newSyncService(clock: () => now);
      await service.syncPending();

      expect(await service.timeUntilNextAttempt(), const Duration(seconds: 2));
      await service.waitForNextAttempt();
      expect(await service.timeUntilNextAttempt(), const Duration(seconds: 2));
    });
  });

  group('api client sync contract', () {
    test('submitSyncOperation posts the queue envelope to the sync API', () async {
      final adapter = ScriptedHttpAdapter(
        (options) async => jsonResponse(201, const <String, dynamic>{'status': 'SYNCED'}),
      );
      final client = ApiClient(baseUrl: 'http://localhost:3000/api')..dio.httpClientAdapter = adapter;

      final response = await client.submitSyncOperation(
        operationId: _uuid.v4(),
        entityType: SyncEntityType.patient,
        entityId: _uuid.v4(),
        operationType: SyncOperationType.create,
        payload: const <String, dynamic>{'nama_lengkap': 'Teste'},
      );

      expect(response['status'], 'SYNCED');
      expect(adapter.requests.single.path, '/sync/operations');
      expect(adapter.requests.single.method, 'POST');
      final body = Map<String, dynamic>.from(adapter.requests.single.data as Map);
      expect((body['operation'] as Map).keys, containsAll(['operation_id', 'entity_type', 'entity_id', 'operation_type', 'payload']));
    });

    test('a Dio failure is surfaced as ApiException', () async {
      final adapter = ScriptedHttpAdapter((options) async => throw httpFailure(500));
      final client = ApiClient(baseUrl: 'http://localhost:3000/api')..dio.httpClientAdapter = adapter;

      await expectLater(
        client.submitSyncOperation(
          operationId: _uuid.v4(),
          entityType: SyncEntityType.patient,
          entityId: _uuid.v4(),
          operationType: SyncOperationType.create,
          payload: const <String, dynamic>{},
        ),
        throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 500)),
      );
    });
  });
}
