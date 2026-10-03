import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import request from 'supertest';
import type { App } from 'supertest/types';
import { randomUUID } from 'node:crypto';

import { AppModule } from '../src/app.module';

interface OperationPayload {
  operation_id: string;
  entity_type: 'PATIENT' | 'CLINICAL_VISIT';
  operation_type: 'CREATE';
  entity_id: string;
  payload: Record<string, unknown>;
}

describe('Offline sync operations (e2e)', () => {
  let app: INestApplication<App>;
  let database: DataSource;
  let doctorAToken: string;
  let doctorBToken: string;
  let pharmacyToken: string;
  let unverifiedToken: string;
  let facilityAId: string;
  let facilityBId: string;
  let tenantA: string;
  let staffAId: string;

  async function createApp(): Promise<INestApplication<App>> {
    const moduleFixture: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const instance = moduleFixture.createNestApplication();
    instance.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true, forbidNonWhitelisted: true }));
    await instance.init();
    return instance;
  }

  async function registerUser(loginIdentifier: string, password: string): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/auth/register')
      .send({ login_identifier: loginIdentifier, password })
      .expect(201);
    return response.body.user.user_id as string;
  }

  async function login(loginIdentifier: string, password: string): Promise<string> {
    const response = await request(app.getHttpServer())
      .post('/api/auth/login')
      .send({ login_identifier: loginIdentifier, password })
      .expect(201);
    return response.body.access_token as string;
  }

  async function createFacility(userId: string, code: string, tenant: string, role: string): Promise<string> {
    const facilityId = randomUUID();
    // Phase 9: tenant identity is an authoritative row now, so it must exist
    // before the facility that references it.
    await database.query(
      `INSERT INTO tenants (tenant_id, name, is_active, created_at, updated_at)
       VALUES ($1, $1, true, NOW(), NOW())
       ON CONFLICT (tenant_id) DO NOTHING`,
      [tenant],
    );
    await database.query(
      `INSERT INTO facilities (facility_id, facility_code, facility_name, facility_type, tenant_id, created_at, updated_at)
       VALUES ($1, $2, $3, 'CHC', $4, NOW(), NOW())`,
      [facilityId, code, code, tenant],
    );
    await addMembership(userId, facilityId, role);
    return facilityId;
  }

  async function addMembership(userId: string, facilityId: string, role: string): Promise<void> {
    await database.query(
      `INSERT INTO facility_memberships (membership_id, user_id, facility_id, role, is_active, created_at)
       VALUES ($1, $2, $3, $4, true, NOW())`,
      [randomUUID(), userId, facilityId, role],
    );
  }

  async function createStaff(userId: string, facilityId: string, verificationStatus: string): Promise<string> {
    const staffId = randomUUID();
    await database.query(
      `INSERT INTO staff_profiles (staff_id, user_id, facility_id, medical_license, profession, verification_status, created_at)
       VALUES ($1, $2, $3, $4, 'Doctor', $5, NOW())`,
      [staffId, userId, facilityId, `L-${randomUUID()}`, verificationStatus],
    );
    return staffId;
  }

  function patientOperation(overrides: Partial<OperationPayload> = {}): OperationPayload {
    const patientId = overrides.entity_id ?? randomUUID();
    return {
      operation_id: randomUUID(),
      entity_type: 'PATIENT',
      operation_type: 'CREATE',
      entity_id: patientId,
      payload: {
        patient_id: patientId,
        no_ktp: null,
        nama_lengkap: 'Offline Patient',
        tanggal_lahir: '1990-01-01',
        tempat_lahir: 'Dili',
        jenis_kelamin: 'Laki-laki',
      },
      ...overrides,
    };
  }

  function visitOperation(patientId: string, overrides: Partial<OperationPayload> = {}): OperationPayload {
    const visitId = overrides.entity_id ?? randomUUID();
    return {
      operation_id: randomUUID(),
      entity_type: 'CLINICAL_VISIT',
      operation_type: 'CREATE',
      entity_id: visitId,
      payload: {
        kunjungan_id: visitId,
        pasien_id: patientId,
        keluhan_subjektif: 'Febre manas',
        kode_icd10: 'R50.9',
      },
      ...overrides,
    };
  }

  function sendOperation(token: string, operation: OperationPayload) {
    return request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${token}`)
      .send({ operation });
  }

  async function countRows(table: string, where: string, values: unknown[]): Promise<number> {
    const rows = await database.query(`SELECT COUNT(*)::int AS total FROM ${table} WHERE ${where}`, values);
    return rows[0].total as number;
  }

  beforeEach(async () => {
    app = await createApp();
    database = app.get(DataSource);
    await database.query('DELETE FROM sync_operations');
    // Phase 7: prescriptions RESTRICT their visit, staff and medication
    // references, so clinical records must be cleared children first.
    await database.query('DELETE FROM prescription_items');
    await database.query('DELETE FROM prescriptions');
    await database.query('DELETE FROM medications');
    await database.query('DELETE FROM clinical_visits');
    await database.query('DELETE FROM patients');
    await database.query('DELETE FROM staff_profiles');
    await database.query('DELETE FROM facility_memberships');
    await database.query('DELETE FROM facilities');
    await database.query('DELETE FROM tenants');
    await database.query('DELETE FROM users');

    const password = 'sync-password-123';
    const doctorA = await registerUser('sync-a@example.com', password);
    const doctorB = await registerUser('sync-b@example.com', password);
    const pharmacy = await registerUser('sync-pharmacy@example.com', password);
    const unverified = await registerUser('sync-unverified@example.com', password);

    tenantA = `tenant-sync-a-${randomUUID()}`;
    const tenantB = `tenant-sync-b-${randomUUID()}`;
    facilityAId = await createFacility(doctorA, `A-${randomUUID()}`, tenantA, 'DOCTOR');
    facilityBId = await createFacility(doctorB, `B-${randomUUID()}`, tenantB, 'DOCTOR');
    await createFacility(pharmacy, `P-${randomUUID()}`, `tenant-sync-p-${randomUUID()}`, 'PHARMACY');
    // The unverified doctor shares facility A with the verified doctor so the
    // staff check, not the facility check, is the one under test.
    await addMembership(unverified, facilityAId, 'DOCTOR');
    staffAId = await createStaff(doctorA, facilityAId, 'Approved');
    await createStaff(doctorB, facilityBId, 'Approved');
    await createStaff(unverified, facilityAId, 'Pending');

    doctorAToken = await login('sync-a@example.com', password);
    doctorBToken = await login('sync-b@example.com', password);
    pharmacyToken = await login('sync-pharmacy@example.com', password);
    unverifiedToken = await login('sync-unverified@example.com', password);
  });

  afterEach(async () => {
    await app.close();
  });

  it('1. creates exactly one operation and one entity for a queued patient', async () => {
    const operation = patientOperation();

    const response = await sendOperation(doctorAToken, operation).expect(201);

    expect(response.body).toEqual(
      expect.objectContaining({
        operation_id: operation.operation_id,
        status: 'SYNCED',
        entity_id: operation.entity_id,
      }),
    );
    expect(await countRows('sync_operations', 'operation_id = $1', [operation.operation_id])).toBe(1);
    expect(await countRows('patients', 'patient_id = $1', [operation.entity_id])).toBe(1);

    const stored = await database.query('SELECT status, retry_count, processed_at FROM sync_operations WHERE operation_id = $1', [
      operation.operation_id,
    ]);
    expect(stored[0].status).toBe('SYNCED');
    expect(stored[0].processed_at).not.toBeNull();
  });

  it('2. replaying the same operation twice keeps one operation and one entity', async () => {
    const operation = patientOperation();
    const payload = { ...operation, payload: { ...operation.payload } };

    const first = await sendOperation(doctorAToken, payload).expect(201);
    const second = await sendOperation(doctorAToken, payload).expect(201);

    expect(first.body.status).toBe('SYNCED');
    expect(second.body.status).toBe('SYNCED');
    expect(second.body.entity_id).toBe(first.body.entity_id);
    expect(await countRows('sync_operations', 'operation_id = $1', [operation.operation_id])).toBe(1);
    expect(await countRows('patients', 'patient_id = $1', [operation.entity_id])).toBe(1);
  });

  it('3. replaying the same operation three times keeps one operation and one entity', async () => {
    const operation = patientOperation();
    const payload = { ...operation, payload: { ...operation.payload } };

    for (let attempt = 0; attempt < 3; attempt += 1) {
      const response = await sendOperation(doctorAToken, payload).expect(201);
      expect(response.body.status).toBe('SYNCED');
    }

    expect(await countRows('sync_operations', 'operation_id = $1', [operation.operation_id])).toBe(1);
    expect(await countRows('patients', 'patient_id = $1', [operation.entity_id])).toBe(1);
  });

  it('4. rejects an invalid operation without creating an entity', async () => {
    const invalid = patientOperation({
      payload: { patient_id: randomUUID(), nama_lengkap: '   ', tanggal_lahir: 'bukan-tanggal' },
    });

    const response = await sendOperation(doctorAToken, invalid).expect(201);
    expect(response.body.status).toBe('FAILED');
    expect(response.body.message).toEqual(expect.any(String));
    expect(await countRows('patients', 'patient_id = $1', [invalid.entity_id])).toBe(0);

    const stored = await database.query('SELECT status FROM sync_operations WHERE operation_id = $1', [invalid.operation_id]);
    expect(stored[0].status).toBe('FAILED');

    // A structurally malformed envelope is rejected by the validation pipe.
    await request(app.getHttpServer())
      .post('/api/sync/operations')
      .set('Authorization', `Bearer ${doctorAToken}`)
      .send({ operation: { operation_id: 'not-a-uuid', entity_type: 'PATIENT', operation_type: 'CREATE', entity_id: randomUUID(), payload: {} } })
      .expect(400);
    // Phase 7 made PRESCRIPTION a supported sync type, so the unsupported-type
    // guard is now exercised with a type that is still unknown.
    await sendOperation(doctorAToken, { ...patientOperation(), entity_type: 'LAB_RESULT' as 'PATIENT' }).expect(400);
  });

  it('5. rejects a clinical visit that targets another facility', async () => {
    const patient = patientOperation();
    await sendOperation(doctorAToken, patient).expect(201);

    const crossFacilityVisit = visitOperation(patient.entity_id);
    const response = await sendOperation(doctorBToken, crossFacilityVisit).expect(201);

    expect(response.body.status).toBe('FAILED');
    expect(response.body.message).toContain('facility');
    expect(await countRows('clinical_visits', 'visit_id = $1', [crossFacilityVisit.entity_id])).toBe(0);
    expect(await countRows('sync_operations', "operation_id = $1 AND status = 'SYNCED'", [crossFacilityVisit.operation_id])).toBe(0);
  });

  it('6. rejects a client supplied tenant and derives ownership from the membership', async () => {
    const hostile = patientOperation();
    const rejected = await sendOperation(doctorAToken, {
      ...hostile,
      payload: { ...hostile.payload, tenant_id: `tenant-attacker-${randomUUID()}` },
    }).expect(201);

    expect(rejected.body.status).toBe('FAILED');
    expect(rejected.body.message).toContain('tenant_id');
    expect(await countRows('patients', 'patient_id = $1', [hostile.entity_id])).toBe(0);

    const accepted = patientOperation();
    await sendOperation(doctorAToken, accepted).expect(201);
    const rows = await database.query('SELECT facility_id FROM patients WHERE patient_id = $1', [accepted.entity_id]);
    expect(rows[0].facility_id).toBe(facilityAId);
  });

  it('7. rejects a clinical visit without an approved staff profile and a client supplied staff id', async () => {
    const patient = patientOperation();
    await sendOperation(doctorAToken, patient).expect(201);

    const unverifiedVisit = visitOperation(patient.entity_id);
    const unverifiedResponse = await sendOperation(unverifiedToken, unverifiedVisit).expect(201);
    expect(unverifiedResponse.body.status).toBe('FAILED');
    expect(unverifiedResponse.body.message).toContain('staff');
    expect(await countRows('clinical_visits', 'visit_id = $1', [unverifiedVisit.entity_id])).toBe(0);

    const forgedStaff = visitOperation(patient.entity_id);
    const forgedResponse = await sendOperation(doctorAToken, {
      ...forgedStaff,
      payload: { ...forgedStaff.payload, staf_id: randomUUID() },
    }).expect(201);
    expect(forgedResponse.body.status).toBe('FAILED');
    expect(forgedResponse.body.message).toContain('staf_id');

    const accepted = visitOperation(patient.entity_id);
    const acceptedResponse = await sendOperation(doctorAToken, accepted).expect(201);
    expect(acceptedResponse.body.status).toBe('SYNCED');
    const visits = await database.query(
      'SELECT staf_id, facility_id, tenant_id, status_sinkronisasi FROM clinical_visits WHERE visit_id = $1',
      [accepted.entity_id],
    );
    expect(visits[0].staf_id).toBe(staffAId);
    expect(visits[0].facility_id).toBe(facilityAId);
    expect(visits[0].tenant_id).toBe(tenantA);
    expect(visits[0].status_sinkronisasi).toBe('Synced');
  });

  it('8. a database failure never produces a false successful operation', async () => {
    const operation = patientOperation({ payload: { ...patientOperation().payload } });
    operation.payload.nama_lengkap = 'DATABASE-FAILURE-CASE';
    await database.query(`ALTER TABLE patients ADD CONSTRAINT sync_test_failure CHECK (nama_lengkap <> 'DATABASE-FAILURE-CASE')`);

    try {
      const response = await sendOperation(doctorAToken, operation).expect(500);
      expect(response.body.message).toEqual(expect.any(String));
    } finally {
      await database.query('ALTER TABLE patients DROP CONSTRAINT sync_test_failure');
    }

    expect(await countRows('patients', 'patient_id = $1', [operation.entity_id])).toBe(0);
    expect(await countRows('sync_operations', "operation_id = $1 AND status = 'SYNCED'", [operation.operation_id])).toBe(0);
    const stored = await database.query('SELECT status, last_error FROM sync_operations WHERE operation_id = $1', [operation.operation_id]);
    expect(stored[0].status).not.toBe('SYNCED');
    expect(stored[0].last_error).toEqual(expect.any(String));

    // A database uniqueness failure is permanent and must not create a second record.
    const ktp = `SYNC-KTP-${randomUUID()}`;
    const first = patientOperation({ payload: { ...patientOperation().payload, no_ktp: ktp } });
    await sendOperation(doctorAToken, first).expect(201);
    const duplicate = patientOperation({ payload: { ...patientOperation().payload, no_ktp: ktp } });
    const duplicateResponse = await sendOperation(doctorAToken, duplicate).expect(201);
    expect(duplicateResponse.body.status).toBe('FAILED');
    expect(await countRows('patients', 'no_ktp = $1', [ktp])).toBe(1);
    expect(await countRows('sync_operations', "operation_id = $1 AND status = 'SYNCED'", [duplicate.operation_id])).toBe(0);
  });

  it('honours the client entity id and requires authentication plus a clinical role', async () => {
    const operation = patientOperation();
    operation.payload.patient_id = operation.entity_id;

    const response = await sendOperation(doctorAToken, operation).expect(201);
    expect(response.body.entity_id).toBe(operation.entity_id);
    expect(await countRows('patients', 'patient_id = $1', [operation.entity_id])).toBe(1);

    await request(app.getHttpServer())
      .post('/api/sync/operations')
      .send({ operation: patientOperation() })
      .expect(401);
    await sendOperation(pharmacyToken, patientOperation()).expect(403);
  });

  it('keeps a clinical visit pending on the server until its patient exists', async () => {
    const patient = patientOperation();
    const visit = visitOperation(patient.entity_id);

    const orphan = await sendOperation(doctorAToken, visit).expect(201);
    expect(orphan.body.status).toBe('FAILED');
    expect(await countRows('clinical_visits', 'visit_id = $1', [visit.entity_id])).toBe(0);

    await sendOperation(doctorAToken, patient).expect(201);
    const resolved = await sendOperation(doctorAToken, visit).expect(201);
    // The failed attempt is terminal for the server, so the client must queue a
    // fresh operation; replaying the same operation must not create a record.
    expect(resolved.body.status).toBe('FAILED');
    expect(await countRows('clinical_visits', 'visit_id = $1', [visit.entity_id])).toBe(0);

    const retried = visitOperation(patient.entity_id, { entity_id: visit.entity_id });
    const retriedResponse = await sendOperation(doctorAToken, retried).expect(201);
    expect(retriedResponse.body.status).toBe('SYNCED');
    expect(await countRows('clinical_visits', 'visit_id = $1', [visit.entity_id])).toBe(1);
  });
});
